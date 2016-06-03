; vim:ft=pic:sts=8:sw=8:et:

                title    "PS/2 IR adapter"
                subtitle "Main entry points"

                include "common.inc"

                __idlocs h'4952'

                __config _CONFIG1, _FOSC_INTOSC & _MCLRE_OFF
                __config _CONFIG2, _WRT_ALL & _PLLEN_OFF & _BORV_HI & _LVP_OFF

BLINKP          equ     d'1937'                 ; 0.5s at LFINTOSC/8

code_reset      code    h'0000'

                goto    main

code_int        code    h'0004'

                banksel PIR1                    ; bank 0
                bcf     T1CON, TMR1ON           ; stop timer
                bcf     PIR1, TMR1IF            ; clear int flag
                movlw   low(-BLINKP)            ; reset timer
                movwf   TMR1L
                movlw   high(-BLINKP)
                movwf   TMR1H
                bsf     T1CON, TMR1ON           ; restart timer

                banksel LATA                    ; bank 2
                movlw   1<<LATA5
                xorwf   LATA, f                 ; toggle LED

                retfie

code_main       code

main:           banksel OSCCON                  ; bank 1
                movlw   h'D'<<IRCF0 | b'10'     ; INTOSC, 4 MHz
                movwf   OSCCON

                banksel LATA                    ; bank 2
                movlw   1<<LATA5                ; RA5 high, others low
                movwf   LATA

                banksel ANSELA                  ; bank 3
                clrf    ANSELA                  ; all digital I/O

                banksel WPUA                    ; bank 4
                movlw   b'00011111'             ; enable pull-ups on
                movwf   WPUA                    ; all but RA5

                banksel ODCONA                  ; bank 5
                clrf    ODCONA                  ; enable push/pull I/Os

                banksel TRISA                   ; bank 1
                movlw   1<<INTEDG | 1<<PSA | 7  ; clear /WPUEN to
                movwf   OPTION_REG              ; enable pull-ups
                movlw   b'00011111'             ; configure RA5 as output
                movwf   TRISA

                banksel PIR1                    ; bank 0
                movlw   3<<TMR1CS0 | 3<<T1CKPS0 | 1<<NOT_T1SYNC
                movwf   T1CON                   ; async LFINTOSC/8
                clrf    PIR1
                movlw   low(-BLINKP)
                movwf   TMR1L
                movlw   high(-BLINKP)
                movwf   TMR1H
                bsf     T1CON, TMR1ON           ; start timer

                banksel PIE1                    ; bank 1
                bsf     PIE1, TMR1IE
                movlw   1<<GIE | 1<<PEIE        ; enable interrupts
                movwf   INTCON

mainloop:       sleep
                bra     mainloop

                end
