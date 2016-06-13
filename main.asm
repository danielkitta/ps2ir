; vim:ft=pic:sts=8:sw=8:et:

                title    "PS/2 IR adapter"
                subtitle "Main entry points"

                include "common.inc"

                __idlocs h'4952'                ; "IR"

                __config _CONFIG1, _FOSC_INTOSC & _WDTE_NSLEEP & _PWRTE_ON & _MCLRE_OFF
                __config _CONFIG2, _WRT_ALL & _PLLEN_OFF & _BORV_HI & _LVP_OFF

                extern  IRSTAT                  ; bank 0
                extern  KBSTAT                  ; bank 0

                extern  irhandlecmd
                extern  irpulseevent
                extern  kbhandlecmd
                extern  kbpoweron
                extern  kbsendnext

code_reset      code    h'0000'                 ; reset entry point

                banksel OSCCON                  ; bank 1
                movlw   h'D'<<IRCF0
                movwf   OSCCON                  ; HFINTOSC, 4 MHz
                goto    main

code_int        code    h'0004'                 ; interrupt handler

                banksel PIR1                    ; bank 0
                btfss   PIR1, TMR1IF            ; timer overflow or
                btfsc   PIR1, TMR1GIF           ; timer gate cycle completed?
                call    irpulseevent            ; yes: dispatch to IR handler

                bcf     INTCON, IOCIE           ; awake, stop I/O change ints
                retfie

PROG0           code

; Main program.
; Initialize peripherals and run the event loop.
;
main:           banksel ANSELA                  ; bank 3
                clrf    ANSELA                  ; all digital I/O

                banksel LATA                    ; bank 2
                clrf    LATA                    ; all outputs low

                banksel WPUA                    ; bank 4
                movlw   1<<WPUA3 | 1<<PS2CLK | 1<<PS2DAT
                movwf   WPUA                    ; pull up /MCLR and PS/2 lines

                banksel TRISA                   ; bank 1
                movlw   1<<INTEDG | 1<<PSA | 7<<PS0_OPTION_REG
                movwf   OPTION_REG              ; enable pull-ups
                movlw   1<<IRDET | 1<<TRISA3 | 1<<PS2CLK | 1<<PS2DAT
                movwf   TRISA                   ; set I/O directions

waitforosc:     btfss   OSCSTAT, HFIOFL         ; HFINTOSC locked?
                bra     waitforosc              ; no: wait until it is

                banksel PORTA                   ; bank 0
                call    kbpoweron               ; initialize keyboard state

                banksel PIE1                    ; bank 1
                movlw   1<<TMR1GIE | 1<<TMR1IE
                movwf   PIE1                    ; enable timer 1 interrupts
                movlw   1<<PEIE
                movwf   INTCON                  ; enable peripheral interrupts

mainloop:       banksel IOCAF                   ; bank 7
                clrf    IOCAF                   ; acknowledge I/O change events
                banksel PORTA                   ; bank 0
                bcf     INTCON, GIE             ; block ints to avoid races

                btfss   KBSTAT, KBDISABLE       ; scanning disabled
                btfsc   KBSTAT, KBEXPECTARG     ; or waiting for argument?
                bra     checkps2                ; yes: skip IR processing

                btfss   IRSTAT, IRPENDING       ; IR command available
                btfsc   IRSTAT, IRRELEASE       ; or key to be released?
                bra     onircommand             ; yes: dispatch to handler

checkps2:       btfss   PORTA, PS2CLK           ; PS/2 clock line free?
                bra     entersleep              ; no: wait for rising edge

                btfss   PORTA, PS2DAT           ; PS/2 host request?
                bra     onkbhostreq             ; yes: dispatch to handler

                btfss   KBSTAT, KBEMPTY         ; keyboard output queued?
                bra     onkbqueued              ; yes: dispatch to handler

entersleep:     bsf     INTCON, IOCIE           ; wake up on I/O change
                sleep
                bcf     INTCON, IOCIE           ; woken, block I/O change ints
                bsf     INTCON, GIE             ; but do process other ints now
                bra     mainloop

onircommand:    call    irhandlecmd             ; returns with ints enabled
                bra     mainloop

onkbhostreq:    bsf     INTCON, GIE             ; re-enable interrupts
                call    kbhandlecmd
                bra     mainloop

onkbqueued:     bsf     INTCON, GIE             ; re-enable interrupts
                call    kbsendnext
                bra     mainloop

                end
