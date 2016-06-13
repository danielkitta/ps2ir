; vim:ft=pic:sts=8:sw=8:et:

                title    "PS/2 IR adapter"
                subtitle "Keyboard functionality"

                include "common.inc"
                include "keycodes.inc"

                extern  IRSTAT                  ; bank 0
                extern  PS2IODATA               ; bank 0

                extern  ps2recvbyte
                extern  ps2sendbyte

; Keyboard commands
CMDSETLEDS      equ     h'ED'                   ; set keyboard LEDs
CMDCODESET      equ     h'F0'                   ; get/set scancode set

; Response codes
RESERROR        equ     h'00'                   ; buffer overrun or other error
RESTESTPASS     equ     h'AA'                   ; self test passed
RESECHO         equ     h'EE'                   ; echo reply
RESACK          equ     h'FA'                   ; command acknowledged
RESRESEND       equ     h'FE'                   ; request for resend

; Prefix codes
EXTPREFIX       equ     h'E0'                   ; extended scancode prefix byte
BREAKPREFIX     equ     h'F0'                   ; key release prefix byte

KEYBOARDID      equ     h'AB83'                 ; keyboard identification code
BUFLOGSIZE      equ     5                       ; log2 of output buffer size

BANK0           udata

KBSTAT:         res     1                       ; status flags
KBSCANCODE:     res     1                       ; scancode of key being pressed
KBSCANMODS:     res     1                       ; scancode modifier flags
BUFWRPOS:       res     1                       ; output queue write index
BUFRDPOS:       res     1                       ; output queue read index
LASTSENT:       res     1                       ; previously sent byte
LASTCMD:        res     1                       ; previously received command
ARG0:           res     1                       ; 1st saved argument
ARG1:           res     1                       ; 2nd saved argument

                global  KBSTAT, KBSCANCODE, KBSCANMODS

BANK1           udata

OUTBUF:         res     1<<BUFLOGSIZE           ; ring buffer for output queue

PROG0           code

; Reset keyboard state.
; Pre    : bank 0 active, ints off
; Post   : bank 0 active, ints off
; Output : IRSTAT, KBSTAT
; Scratch: WREG, STATUS
;
resetkb:        movlw   3<<TMR1CS0 | 1<<NOT_T1SYNC
                movwf   T1CON                   ; timer 1: async LFINTOSC 1:1
                movlw   1<<TMR1GE | 1<<T1GSPM
                movwf   T1GCON                  ; single pulse mode, negative
                clrf    TMR1L                   ; reset timer
                clrf    TMR1H
                clrf    PIR1                    ; clear event flags

                clrf    IRSTAT                  ; reset IR decode state
                clrf    KBSTAT                  ; reset PS/2 state
                clrf    BUFWRPOS                ; initialize output queue
                clrf    BUFRDPOS
                clrf    LASTSENT

                bsf     T1GCON, T1GGO           ; start pulse acquisition
                bsf     T1GCON, T1GPOL          ; trigger pulse edge

                banksel IOCAP                   ; bank 7
                movlw   1<<PS2CLK
                movwf   IOCAP                   ; detect PS/2 clock rising edge
                clrf    IOCAF                   ; clear event flags

                banksel PORTA                   ; bank 0
                return

; Keyboard power-on reset.
; This does a reset and then places the code for "self-test passed" into
; the output queue.
; Pre    : bank 0 active, ints off
; Post   : bank 0 active, ints off
; Output : IRSTAT, KBSTAT
; Scratch: WREG, STATUS
;
kbpoweron:      call    resetkb
                movlw   RESTESTPASS
                goto    queuebyte               ; queue self-test passed

                global  kbpoweron

; Check if the output queue has enough space left for a number of bytes
; about to be queued. If there is not enough space left, the error code
; for buffer overflow is automatically appended to the queue. One byte
; of the buffer space is reserved for this purpose. If the reserved byte
; is already used up, the queue is left as is.
; On return, the overflow state will be indicated in the KBOVERFLOW bit
; of KBSTAT.
; Pre    : bank 0 active
; Post   : bank 0 active
; Input  : WREG
; Output : KBSTAT.KBOVERFLOW
; Scratch: WREG, STATUS, FSR0, ARG0
;
preparequeue:   btfsc   KBSTAT, KBOVERFLOW      ; already overflown?
                return                          ; yes: bail out

                movwf   ARG0                    ; save requested length
                movf    BUFRDPOS, w
                subwf   BUFWRPOS, w
                iorlw   -1<<BUFLOGSIZE          ; sign extend
                addwf   ARG0, w
                btfss   STATUS, C               ; would overflow?
                return                          ; no: done

                bsf     KBSTAT, KBOVERFLOW      ; indicate overflow
                movlw   RESERROR
                goto    queuebyte               ; queue error response

; Append a byte to the keyboard output queue, preceded by a break prefix.
; Pre    : bank 0 active
; Post   : bank 0 active
; Input  : WREG
; Output : KBSTAT.KBQUEUED
; Scratch: WREG, STATUS, FSR0, ARG0, ARG1
;
queuebreakcode: movwf   ARG1                    ; remember scancode
                movlw   BREAKPREFIX
                call    queuebyte               ; queue break prefix

                movf    ARG1, w                 ; queue scancode

; Append a byte to the keyboard output queue.
; Pre    : bank 0 active
; Post   : bank 0 active
; Input  : WREG
; Output : KBSTAT.KBQUEUED
; Scratch: WREG, STATUS, FSR0, ARG0
;
queuebyte:      movwf   ARG0                    ; save byte to be queued
                movlw   OUTBUF
                addwf   BUFWRPOS, w             ; compute write address
                clrf    FSR0H
                movwf   FSR0L
                movf    ARG0, w
                movwf   INDF0                   ; write byte to buffer
                incf    BUFWRPOS                ; advance write position
                bcf     BUFWRPOS, BUFLOGSIZE    ; wrap around

                bsf     KBSTAT, KBQUEUED        ; indicate data availability
                return

; Routine invoked on a request from the host.
; Pre    : bank 0 active
; Post   : bank 0 active
; Output : KBSTAT
; Scratch: WREG, STATUS, FSR0, ARG0
;
kbhandlecmd:    call    ps2recvbyte             ; read in command byte

                btfsc   KBSTAT, KBIOABORT       ; transfer interrupted?
                return                          ; yes: ignore

                movlw   ~(1<<KBQUEUED | 1<<KBOVERFLOW | 1<<KBKEYHELD)
                andwf   KBSTAT
                clrf    BUFWRPOS                ; clear output queue
                clrf    BUFRDPOS

                btfsc   KBSTAT, KBIOERROR       ; I/O error?
                bra     reqresend               ; yes: request resend

                btfsc   KBSTAT, KBEXPECTARG     ; argument byte?
                bra     handlearg               ; yes: evaluate

                movf    PS2IODATA, w
                movwf   LASTCMD                 ; remember command
                addlw   -CMDSETLEDS
                btfss   STATUS, C               ; invalid command?
                bra     reqresend               ; yes: request resend

                brw                             ; index jump table
                bra     expectarg               ; ED: set LEDs
                bra     cmdecho                 ; EE: echo request
                bra     reqresend               ; EF: invalid
                bra     expectarg               ; F0: get/set scancode set
                bra     reqresend               ; F1: invalid
                bra     cmdidentify             ; F2: identify keyboard
                bra     expectarg               ; F3: set typematic rate/delay
                bra     cmdscanon               ; F4: enable scanning
                bra     cmdscanoff              ; F5: disable scanning
                bra     ackcommand              ; F6: set default parameters
                bra     ackcommand              ; F7: set all typematic/auto
                bra     ackcommand              ; F8: set all make/release
                bra     ackcommand              ; F9: set all make only
                bra     ackcommand              ; FA: set all tm/auto/make/rel
                bra     expectarg               ; FB: set key typematic/auto
                bra     expectarg               ; FC: set key make/release
                bra     expectarg               ; FD: set key make only
                bra     cmdresend               ; FE: resend last byte
                                                ; FF: reset and self-test
                bcf     INTCON, GIE
                call    resetkb                 ; reset keyboard state
                bsf     INTCON, GIE
                movlw   RESACK
                call    queuebyte               ; queue acknowledge
                movlw   RESTESTPASS
                goto    queuebyte               ; queue self-test passed

reqresend:      movlw   RESRESEND               ; ask host to resend byte
                goto    queuebyte

expectarg:      bsf     KBSTAT, KBEXPECTARG     ; prepare for argument
                movlw   RESACK
                goto    queuebyte               ; queue acknowledge

handlearg:      bcf     KBSTAT, KBEXPECTARG     ; got expected argument
                movlw   CMDCODESET
                xorwf   LASTCMD, w
                btfss   STATUS, Z               ; command get/set scancode set?
                bra     ackcommand              ; no: silently ignore

                movf    PS2IODATA, w
                btfsc   STATUS, Z               ; argument is 0?
                bra     cmdgetcodeset           ; yes: return scancode set

                xorlw   2
                btfss   STATUS, Z               ; argument is 2?
                bra     reqresend               ; no: disallow change

ackcommand:     movlw   RESACK                  ; queue acknowledge
                goto    queuebyte

cmdecho:        movlw   RESECHO                 ; queue echo reply
                goto    queuebyte

cmdidentify:    movlw   RESACK
                call    queuebyte               ; queue acknowledge
                movlw   high KEYBOARDID
                call    queuebyte               ; queue keyboard ID
                movlw   low KEYBOARDID
                goto    queuebyte

cmdscanon:      bcf     KBSTAT, KBDISABLE       ; allow keys to be sent
                movlw   RESACK
                goto    queuebyte

cmdscanoff:     bsf     KBSTAT, KBDISABLE       ; disallow keys to be sent
                movlw   RESACK
                goto    queuebyte

cmdresend:      movf    LASTSENT, w
                goto    queuebyte

cmdgetcodeset:  movlw   RESACK                  ; queue acknowledge
                call    queuebyte
                movlw   2                       ; report fixed scan code set
                goto    queuebyte

                global  kbhandlecmd

; Queue the make scancodes for the active key and its modifiers.
; Any modifier make codes are sent first, followed by the make code
; of the active key.
; Pre    : bank 0 active
; Post   : bank 0 active
; Input  : KBSTAT, KBSCANCODE, KBSCANMODS
; Output : KBSTAT
; Scratch: WREG, STATUS, FSR0, ARG0
;
kbqueuemake:    btfss   KBSTAT, KBDISABLE       ; scanning disabled
                btfsc   KBSTAT, KBEXPECTARG     ; or processing command?
                return                          ; yes: do nothing

                movlw   1                       ; count bytes needed
                btfsc   KBSCANMODS, MODSHIFT
                incf    WREG, w
                btfsc   KBSCANMODS, MODCTRL
                incf    WREG, w
                btfsc   KBSCANMODS, MODALT
                incf    WREG, w
                btfsc   KBSCANMODS, MODSUPER
                addlw   2
                btfsc   KBSCANMODS, MODEXT
                incf    WREG, w

                call    preparequeue
                btfsc   KBSTAT, KBOVERFLOW      ; would overflow?
                return                          ; yes: bail out

                movlw   KEYLSHIFT
                btfsc   KBSCANMODS, MODSHIFT    ; Shift modifier?
                call    queuebyte               ; yes: queue Shift scancode

                movlw   KEYLCTRL
                btfsc   KBSCANMODS, MODCTRL     ; Control modifier?
                call    queuebyte               ; yes: queue Control scancode

                movlw   KEYLALT
                btfsc   KBSCANMODS, MODALT      ; Alt modifier?
                call    queuebyte               ; yes: queue Alt scancode

                btfss   KBSCANMODS, MODSUPER    ; Super modifier?
                bra     queuekeymake            ; no: skip

                movlw   EXTPREFIX
                call    queuebyte               ; queue prefix code
                movlw   low KEYLSUPER
                call    queuebyte               ; queue Super scancode

queuekeymake:   movlw   EXTPREFIX
                btfsc   KBSCANMODS, MODEXT      ; extended scancode?
                call    queuebyte               ; yes: queue prefix code

                bsf     KBSTAT, KBKEYHELD       ; indicate active key press
                movf    KBSCANCODE, w
                goto    queuebyte               ; queue key scancode

                global  kbqueuemake

; Queue the break scancodes for the active key and its modifiers.
; The break code for the active key is sent first, followed by the
; break codes of any modifiers.
; Pre    : bank 0 active
; Post   : bank 0 active
; Input  : KBSTAT, KBSCANCODE, KBSCANMODS
; Output : KBSTAT
; Scratch: WREG, STATUS, FSR0, ARG0, ARG1
;
kbqueuebreak:   btfss   KBSTAT, KBKEYHELD       ; any active key press?
                return                          ; no: nothing to do

                movlw   2                       ; count bytes needed
                btfsc   KBSCANMODS, MODEXT
                incf    WREG, w
                btfsc   KBSCANMODS, MODSUPER
                addlw   3
                btfsc   KBSCANMODS, MODALT
                addlw   2
                btfsc   KBSCANMODS, MODCTRL
                addlw   2
                btfsc   KBSCANMODS, MODSHIFT
                addlw   2

                call    preparequeue
                btfsc   KBSTAT, KBOVERFLOW      ; would overflow?
                return                          ; yes: bail out

                movlw   EXTPREFIX
                btfsc   KBSCANMODS, MODEXT      ; extended scancode?
                call    queuebyte               ; yes: queue prefix

                bcf     KBSTAT, KBKEYHELD       ; clear active key press
                movf    KBSCANCODE, w
                call    queuebreakcode          ; queue key break code

                btfss   KBSCANMODS, MODSUPER    ; Super modifier?
                bra     checkaltbreak           ; no: skip

                movlw   EXTPREFIX
                call    queuebyte               ; queue prefix code
                movlw   low KEYLSUPER
                call    queuebreakcode          ; queue Super break code

checkaltbreak:  movlw   KEYLALT
                btfsc   KBSCANMODS, MODALT      ; Alt modifier?
                call    queuebreakcode          ; yes: queue Alt break code

                movlw   KEYLCTRL
                btfsc   KBSCANMODS, MODCTRL     ; Control modifier?
                call    queuebreakcode          ; yes: queue Control break code

                btfss   KBSCANMODS, MODSHIFT    ; Shift modifier?
                return                          ; no: done
                movlw   KEYLSHIFT
                goto    queuebreakcode          ; yes: queue Shift break code

                global  kbqueuebreak

; Take the front item from the output queue and send it off.
; Pre    : bank 0 active
; Post   : bank 0 active
; Output : KBSTAT
; Scratch: WREG, STATUS, FSR0, ARG0
;
kbsendnext:     movlw   OUTBUF
                addwf   BUFRDPOS, w             ; compute read address
                clrf    FSR0H
                movwf   FSR0L

                movf    INDF0, w                ; read byte from buffer
                movwf   PS2IODATA
                call    ps2sendbyte             ; transmit byte

                btfss   KBSTAT, KBIOABORT       ; I/O aborted
                btfsc   KBSTAT, KBIOERROR       ; or other error?
                return                          ; leave byte queued

                incf    BUFRDPOS, w             ; advance read position
                andlw   (1<<BUFLOGSIZE)-1       ; wrap around
                movwf   BUFRDPOS
                xorwf   BUFWRPOS, w
                btfsc   STATUS, Z               ; output queue empty?
                bcf     KBSTAT, KBQUEUED        ; yes: indicate status
                bcf     KBSTAT, KBOVERFLOW

                movlw   RESRESEND
                xorwf   INDF0, w
                btfsc   STATUS, Z               ; sent byte was FE (resend)?
                return                          ; yes: do not remember

                movf    INDF0, w
                movwf   LASTSENT                ; remember last byte sent
                return

                global  kbsendnext

                end
