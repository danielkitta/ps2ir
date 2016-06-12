; vim:ft=pic:sts=8:sw=8:et:

                title    "PS/2 IR adapter"
                subtitle "IR decoding routines"

                include "common.inc"

                extern  IRDEVADR                ; symbolic constant
                extern  KBSCANCODE              ; bank 0
                extern  KBSCANMODS              ; bank 0

                extern  kbqueuemake
                extern  kbqueuebreak
                extern  keycodemap

; IR pulse and distance length bounds in timer ticks at 31 kHz.
; Allow for large tolerances to accomodate deviations from the NEC spec
; and to account for the inaccuracy of the LFINTOSC clock source.
;
MINSTARTP       equ     d'50' * d'31' / d'10'   ; start pulse min: 5000us
MAXSTARTP       equ     MINSTARTP + h'100'      ; start pulse max: 13.2ms
MINSTARTD       equ     d'32' * d'31' / d'10'   ; start delta min: 3200us
MAXSTARTD       equ     d'67' * d'31' / d'10'   ; start delta max: 6700us
MINREPD         equ     d'11' * d'31' / d'10'   ; repeat delta min: 1100us
MINBIT0         equ     d'3'  * d'31' / d'10'   ; bit 0 delta min: 300us
MINBIT1         equ     d'11' * d'31' / d'10'   ; bit 1 delta min: 1100us
MAXBIT1         equ     d'25' * d'31' / d'10'   ; bit 1 delta max: 2500us
MAXREPDELAY     equ     d'130' * d'31'          ; max repeat delay: 130ms

BANK0           udata

IRSTAT:         res     1                       ; status flags
IRADRL:         res     1                       ; received address
IRADRH:         res     1                       ; extended or inverted address
IRCMD:          res     1                       ; received command
IRCMDINV:       res     1                       ; inverted command
IRBITPOS:       res     1                       ; decoder bit position
NEWCMD:         res     1                       ; latest received IR command

                global  IRSTAT

PROG0           code

; Routine invoked from the interrupt handler upon completion
; of a IR timer pulse event or overflow.
; Pre    : bank 0 active
; Post   : bank 0 active
; Output : IRSTAT, IRADRL, IRADRH, IRCMD, IRCMDINV
; Scratch: WREG, STATUS, IRBITPOS
;
irpulseevent:   bcf     PIR1, TMR1GIF           ; acknowledge pulse event
                bcf     T1CON, TMR1ON           ; stop timer
                btfsc   PIR1, TMR1IF            ; timer overflow?
                bra     stopdecode              ; yes: bail out

                btfss   IRSTAT, IRACTIVE        ; decoder active?
                bra     startdecode             ; no: initialize decoder

                btfss   T1GCON, T1GPOL          ; measuring pulse distance?
                bra     startpulse              ; no: check for start pulse

                movf    IRBITPOS, w
                btfsc   STATUS, Z               ; bit position 0?
                bra     startpause              ; yes: check for start pause

                movlw   MAXBIT1-MINBIT0
                addwf   TMR1L, w
                btfss   STATUS, C               ; distance >= minimum?
                bra     stopdecode              ; no: bail out

                addlw   MINBIT0-MINBIT1         ; C = (duration >= min bit 1)
                rrf     IRCMDINV                ; shift bit into datagram
                rrf     IRCMD
                rrf     IRADRH
                rrf     IRADRL

                btfsc   IRBITPOS, 5             ; 32nd bit reached?
                bra     lastbit                 ; yes: done decoding

nextbit:        incf    IRBITPOS
                movlw   -MAXBIT1                ; overflow if distance >= max
                movwf   TMR1L                   ; leave TMR1H at -1
                bsf     T1GCON, T1GGO           ; re-arm timer gate
                bsf     T1CON, TMR1ON           ; start timer
                return

startdecode:    movlw   low(-MAXSTARTP)
                movwf   TMR1L                   ; set timer to overflow after
                movlw   high(-MAXSTARTP)        ; max start pulse duration
                movwf   TMR1H
                bsf     T1GCON, T1GGO           ; re-arm timer gate
                bcf     T1GCON, T1GPOL          ; wake up on rising edge
                bsf     T1CON, TMR1ON           ; start timer

                bsf     IRSTAT, IRACTIVE        ; mark active
                clrf    IRBITPOS                ; reset bit position
                return

startpulse:     comf    TMR1H, w
                btfss   STATUS, Z               ; duration >= minimum?
                bra     stopdecode              ; no: bail out

                movlw   -MAXSTARTD              ; overflow if distance >= max
                movwf   TMR1L                   ; leave TMR1H at -1
                bsf     T1GCON, T1GGO           ; re-arm timer gate
                bsf     T1GCON, T1GPOL          ; wake up on falling edge
                bsf     T1CON, TMR1ON           ; start timer
                return

startpause:     movlw   MAXSTARTD-MINREPD
                addwf   TMR1L, w
                btfss   STATUS, C               ; distance >= minimum?
                bra     stopdecode              ; no: bail out

                addlw   MINREPD-MINSTARTD
                btfss   STATUS, C               ; distance >= min start bit?
                bra     timerelease             ; no: repeat code

                bcf     IRSTAT, IRPENDING       ; withdraw previous datagram
                bra     nextbit                 ; wait for first data bit

lastbit:        bsf     IRSTAT, IRPENDING       ; indicate datagram availability
timerelease:    bcf     IRSTAT, IRACTIVE        ; mark inactive
                movlw   low(-MAXREPDELAY)
                movwf   TMR1L                   ; set timer to overflow when
                movlw   high(-MAXREPDELAY)      ; the repeat code is past due
                movwf   TMR1H
                bsf     T1GCON, T1GGO           ; re-arm timer gate
                bsf     T1CON, TMR1ON           ; start timer
                return

stopdecode:     bcf     IRSTAT, IRACTIVE        ; mark inactive
                bsf     IRSTAT, IRRELEASE       ; trigger key release
                bcf     PIR1, TMR1IF            ; acknowledge overflow
                bsf     T1GCON, T1GGO           ; re-arm timer gate
                bsf     T1GCON, T1GPOL          ; wake up on falling edge
                return

                global  irpulseevent

; Routine invoked from the main loop if an IR command has been decoded
; and is available for processing.
; Pre    : bank 0 active, ints off
; Post   : bank 0 active, ints on
; Input  : IRSTAT, KBSTAT, KBSCANCODE, KBSCANMODS
; Output : IRSTAT, KBSTAT, KBSCANCODE, KBSCANMODS
; Scratch: WREG, STATUS, FSR0, PMCON1, PMADR, PMDAT, NEWCMD
;
irhandlecmd:    bcf     IRSTAT, IRRELEASE       ; acknowledge release request
                btfss   IRSTAT, IRPENDING       ; pending IR datagram?
                bra     breakonly               ; no: skip key press

                bcf     IRSTAT, IRPENDING       ; acknowledge IR datagram
                comf    IRCMDINV, w
                movwf   NEWCMD
                xorwf   IRCMD, w
                btfss   STATUS, Z               ; command matches inverse
                bra     breakonly               ; no: skip key press

                movlw   low IRDEVADR
                xorwf   IRADRL, w
                btfss   STATUS, Z               ; address low matches?
                bra     breakonly               ; no: skip key press

                movlw   high IRDEVADR
                xorwf   IRADRH, w
                btfss   STATUS, Z               ; address high matches?
                bra     breakonly               ; no: skip key press

                bsf     INTCON, GIE             ; interrupts are safe now
                call    kbqueuebreak            ; queue release for last key

                movlw   low keycodemap
                addwf   NEWCMD, w
                banksel PMCON1                  ; bank 3
                movwf   PMADRL
                movlw   high keycodemap
                clrf    PMADRH
                addwfc  PMADRH
                clrf    PMCON1
                bsf     PMCON1, RD              ; look up IR command code
                nop
                nop
                movf    PMDATL, w               ; read scancode byte
                banksel KBSCANCODE              ; bank 0

                btfsc   STATUS, Z               ; scancode assigned?
                return                          ; no: ignore key press

                movwf   KBSCANCODE
                banksel PMDATH                  ; bank 3
                movf    PMDATH, w               ; read modifier flags
                banksel KBSCANMODS              ; bank 0
                movwf   KBSCANMODS
                goto    kbqueuemake             ; queue key press code

breakonly:      bsf     INTCON, GIE             ; interrupts are safe now
                goto    kbqueuebreak            ; queue release for last key

                global  irhandlecmd

                end
