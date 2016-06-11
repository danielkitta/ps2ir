; vim:ft=pic:sts=8:sw=8:et:

                title    "PS/2 IR adapter"
                subtitle "Keyboard functionality"

                include "common.inc"

                extern  IRSTAT                  ; bank 0
                extern  PS2IODATA               ; bank 0

                extern  ps2recvbyte
                extern  ps2sendbyte

; Keyboard commands
CMDSETLEDS      equ     h'ED'                   ; set keyboard LEDs
CMDCODESET      equ     h'F0'                   ; get/set scancode set

; Response codes
RESECHO         equ     h'EE'                   ; echo reply
RESACK          equ     h'FA'                   ; command acknowledged
RESRESEND       equ     h'FE'                   ; request for resend
RESERROR        equ     h'FF'                   ; buffer overrun or other error

; Prefix codes
KEYEXTPREFIX    equ     h'E0'                   ; extended scancode prefix byte
KEYRELPREFIX    equ     h'F0'                   ; key release prefix byte

KEYBOARDID      equ     h'AB83'                 ; keyboard identification code
BUFLOGSIZE      equ     5                       ; log2 of output buffer size

BANK0           udata

KBSTAT:         res     1                       ; status flags
KBOUTWRPOS:     res     1                       ; output queue write index
KBOUTRDPOS:     res     1                       ; output queue read index
KBOUTLAST:      res     1                       ; previously sent byte
KBLASTCMD:      res     1                       ; previously received command
SCANCODE:       res     1                       ; scancode of key being pressed
ARG0:           res     1                       ; 1st saved argument

                global  KBSTAT

BANK1           udata

KBOUTBUF:       res     1<<BUFLOGSIZE           ; ring buffer for output queue

PROG0           code

; Reset keyboard state.
; Pre    : bank 0 active, ints off
; Post   : bank 0 active, ints off
; Output : IRSTAT, KBSTAT
; Scratch: WREG, STATUS
;
kbreset:        movlw   3<<TMR1CS0 | 1<<NOT_T1SYNC
                movwf   T1CON                   ; timer 1: async LFINTOSC 1:1
                movlw   1<<TMR1GE | 1<<T1GSPM
                movwf   T1GCON                  ; single pulse mode, negative
                clrf    TMR1L                   ; reset timer
                clrf    TMR1H
                clrf    PIR1                    ; clear event flags

                clrf    IRSTAT                  ; reset IR decode state
                clrf    KBSTAT                  ; reset PS/2 state
                clrf    KBOUTWRPOS              ; initialize output queue
                clrf    KBOUTRDPOS
                clrf    KBOUTLAST

                bsf     T1GCON, T1GGO           ; start pulse acquisition
                bsf     T1GCON, T1GPOL          ; trigger pulse edge

                banksel IOCAP                   ; bank 7
                movlw   1<<PS2CLK
                movwf   IOCAP                   ; detect PS/2 clock rising edge
                clrf    IOCAF                   ; clear event flags

                banksel KBSTAT                  ; bank 0
                return

                global  kbreset

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
kbwantqueue:    btfsc   KBSTAT, KBOVERFLOW      ; already overflown?
                return                          ; yes: bail out

                movwf   ARG0                    ; save requested length
                movf    KBOUTRDPOS, w
                subwf   KBOUTWRPOS, w
                iorlw   -1<<BUFLOGSIZE          ; sign extend
                addwf   ARG0, w
                btfss   STATUS, C               ; would overflow?
                return                          ; no: done

                bsf     KBSTAT, KBOVERFLOW      ; indicate overflow
                movlw   RESERROR                ; queue error response

                global  kbwantqueue

; Append a byte to the keyboard output queue.
; Pre    : bank 0 active
; Post   : bank 0 active
; Input  : WREG
; Output : KBSTAT.KBQUEUED
; Scratch: WREG, STATUS, FSR0, ARG0
;
kbqueuebyte:    movwf   ARG0                    ; save byte to be queued
                movlw   KBOUTBUF
                addwf   KBOUTWRPOS, w           ; compute write address
                clrf    FSR0H
                movwf   FSR0L
                movf    ARG0, w
                movwf   INDF0                   ; write byte to buffer
                incf    KBOUTWRPOS              ; advance write position
                bcf     KBOUTWRPOS, BUFLOGSIZE  ; wrap around

                bsf     KBSTAT, KBQUEUED        ; indicate data availability
                return

                global  kbqueuebyte

; Routine invoked on a request from the host.
; Pre    : bank 0 active
; Post   : bank 0 active
; Output : KBSTAT
; Scratch: WREG, STATUS, FSR0, ARG0
;
kbhandlecmd:    call    ps2recvbyte             ; read in command byte

                clrf    KBOUTWRPOS              ; clear output queue
                clrf    KBOUTRDPOS
                bcf     KBSTAT, KBQUEUED
                bcf     KBSTAT, KBOVERFLOW

                btfsc   KBSTAT, KBIOABORT       ; transfer interrupted?
                return                          ; yes: ignore

                btfsc   KBSTAT, KBIOERROR       ; I/O error?
                bra     reqresend               ; yes: request resend

                btfsc   KBSTAT, KBEXPECTARG     ; argument byte?
                bra     handlearg               ; yes: evaluate

                movf    PS2IODATA, w
                movwf   KBLASTCMD               ; remember command
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
                call    kbreset                 ; reset keyboard state
                bsf     INTCON, GIE
                movlw   RESACK
                call    kbqueuebyte             ; queue acknowledge
                movlw   RESTESTPASS
                goto    kbqueuebyte             ; queue self-test passed

reqresend:      movlw   RESRESEND               ; ask host to resend byte
                goto    kbqueuebyte

expectarg:      bsf     KBSTAT, KBEXPECTARG     ; prepare for argument
                movlw   RESACK
                goto    kbqueuebyte             ; queue acknowledge

handlearg:      bcf     KBSTAT, KBEXPECTARG     ; got expected argument
                movlw   CMDCODESET
                xorwf   KBLASTCMD, w
                btfss   STATUS, Z               ; command get/set scancode set?
                bra     ackcommand              ; no: silently ignore

                movf    PS2IODATA, w
                btfsc   STATUS, Z               ; argument is 0?
                bra     cmdgetcodeset           ; yes: return scancode set

                xorlw   2
                btfss   STATUS, Z               ; argument is 2?
                bra     reqresend               ; no: disallow change

ackcommand:     movlw   RESACK                  ; queue acknowledge
                goto    kbqueuebyte

cmdecho:        movlw   RESECHO                 ; queue echo reply
                goto    kbqueuebyte

cmdidentify:    movlw   RESACK
                call    kbqueuebyte             ; queue acknowledge
                movlw   high KEYBOARDID
                call    kbqueuebyte             ; queue keyboard ID
                movlw   low KEYBOARDID
                goto    kbqueuebyte

cmdscanon:      bcf     KBSTAT, KBDISABLE       ; allow keys to be sent
                movlw   RESACK
                goto    kbqueuebyte

cmdscanoff:     bsf     KBSTAT, KBDISABLE       ; disallow keys to be sent
                movlw   RESACK
                goto    kbqueuebyte

cmdresend:      movf    KBOUTLAST, w
                goto    kbqueuebyte

cmdgetcodeset:  movlw   RESACK                  ; queue acknowledge
                call    kbqueuebyte
                movlw   2                       ; report fixed scan code set
                goto    kbqueuebyte

                global  kbhandlecmd

; Queue a make code.
; Pre    : bank 0 active
; Post   : bank 0 active
; Input  : WREG
; Output : KBSTAT, SCANCODE
; Scratch: WREG, STATUS, FSR0, ARG0
;
kbqueuemake:    btfsc   KBSTAT, KBDISABLE       ; scanning disabled?
                return                          ; yes: do nothing

                movwf   SCANCODE
                movlw   1
                btfsc   SCANCODE, KEYEXTBIT     ; extended scancode?
                movlw   2                       ; yes: extra byte for prefix
                call    kbwantqueue
                btfsc   KBSTAT, KBOVERFLOW      ; would overflow?
                return                          ; yes: bail out

                bsf     KBSTAT, KBKEYHELD       ; indicate active key press
                movlw   KEYEXTPREFIX
                btfsc   SCANCODE, KEYEXTBIT     ; extended scancode?
                call    kbqueuebyte             ; yes: queue prefix

                movlw   (1<<KEYEXTBIT)-1
                andwf   SCANCODE, w             ; mask out extended flag
                goto    kbqueuebyte             ; queue key scancode

                global  kbqueuemake

; Queue the break code corresponding to the last queued make code.
; Pre    : bank 0 active
; Post   : bank 0 active
; Input  : SCANCODE
; Output : KBSTAT
; Scratch: WREG, STATUS, FSR0, ARG0
;
kbqueuebrklast: btfss   KBSTAT, KBDISABLE       ; scanning disabled
                btfss   KBSTAT, KBKEYHELD       ; or no active key press?
                return                          ; yes: do nothing

                movlw   2
                btfsc   SCANCODE, KEYEXTBIT     ; extended scancode?
                movlw   3                       ; yes: extra byte for prefix
                call    kbwantqueue
                btfsc   KBSTAT, KBOVERFLOW      ; would overflow?
                return                          ; yes: bail out

                bcf     KBSTAT, KBKEYHELD       ; clear active key press
                movlw   KEYEXTPREFIX
                btfsc   SCANCODE, KEYEXTBIT     ; extended scancode?
                call    kbqueuebyte             ; yes: queue prefix

                movlw   KEYRELPREFIX
                call    kbqueuebyte             ; queue release prefix
                movlw   (1<<KEYEXTBIT)-1
                andwf   SCANCODE, w             ; mask out extended flag
                goto    kbqueuebyte             ; queue key scancode

                global  kbqueuebrklast

; Take the front item from the output queue and send it off.
; Pre    : bank 0 active
; Post   : bank 0 active
; Output : KBSTAT
; Scratch: WREG, STATUS, FSR0, ARG0
;
kbsendnext:     movlw   KBOUTBUF
                addwf   KBOUTRDPOS, w           ; compute read address
                clrf    FSR0H
                movwf   FSR0L

                movf    INDF0, w                ; read byte from buffer
                movwf   PS2IODATA
                call    ps2sendbyte             ; transmit byte

                btfss   KBSTAT, KBIOABORT       ; I/O aborted
                btfsc   KBSTAT, KBIOERROR       ; or other error?
                return                          ; leave byte queued

                incf    KBOUTRDPOS, w           ; advance read position
                andlw   (1<<BUFLOGSIZE)-1       ; wrap around
                movwf   KBOUTRDPOS
                xorwf   KBOUTWRPOS, w
                btfsc   STATUS, Z               ; output queue empty?
                bcf     KBSTAT, KBQUEUED        ; yes: indicate status
                bcf     KBSTAT, KBOVERFLOW

                movlw   RESRESEND
                xorwf   INDF0, w
                btfsc   STATUS, Z               ; sent byte was FE (resend)?
                return                          ; yes: do not remember

                movf    INDF0, w
                movwf   KBOUTLAST               ; remember last byte sent
                return

                global  kbsendnext

                end
