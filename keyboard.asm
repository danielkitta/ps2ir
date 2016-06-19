; vim:ft=pic:sts=8:sw=8:et:

                title    "PS/2 IR adapter"
                subtitle "Keyboard functionality"

                include "common.inc"
                include "keycodes.inc"

                extern  PS2IODATA               ; bank 0

                extern  ps2recvbyte
                extern  ps2sendbyte

; Keyboard commands
CMDSETLEDS      equ     h'ED'                   ; set keyboard LEDs
CMDCODESET      equ     h'F0'                   ; get/set scancode set
CMDTYPEMATIC    equ     h'F3'                   ; set typematic rate and delay
CMDRESEND       equ     h'FE'                   ; resend last byte

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
DEFREPDELAY     equ     500/125                 ; default auto-repeat delay

BANK0           udata

KBSTAT:         res     1                       ; status flags
KBSCANCODE:     res     1                       ; scancode of key being pressed
KBSCANMODS:     res     1                       ; scancode modifier flags
REPDELAY:       res     1                       ; typematic delay in 125ms units
REPCOUNT:       res     1                       ; auto-repeat tick counter
BUFWRPOS:       res     1                       ; output queue write index
BUFRDPOS:       res     1                       ; output queue read index
LASTSENT:       res     1                       ; previously sent byte
LASTCMD:        res     1                       ; previously received command

                global  KBSTAT, KBSCANCODE, KBSCANMODS

BANK0OVR        udata_ovr

ARG:            res     1                       ; saved argument

BANK1           udata

OUTBUF:         res     1<<BUFLOGSIZE           ; ring buffer for output queue

PROG0           code

; Keyboard power-on reset.
; Initialize keyboard state and place the code for "self-test passed"
; into the output queue.
; Pre    : bank 0 active, ints off
; Post   : bank 0 active, ints off
; Output : KBSTAT, LASTSENT, BUFWRPOS, BUFRDPOS
; Scratch: WREG, STATUS, FSR0
;
kbpoweron:      clrf    KBSTAT                  ; clear keyboard state
                movlw   DEFREPDELAY
                movwf   REPDELAY                ; set default repeat delay
                clrf    LASTSENT
                clrf    BUFWRPOS                ; initialize output queue
                clrf    BUFRDPOS
                movlw   OUTBUF
                movwf   FSR0L                   ; prepare write pointer
                clrf    FSR0H
                movlw   RESTESTPASS
                goto    bufwritebyte            ; queue self-test passed

                global  kbpoweron

; Check if the output queue has enough space left for a number of bytes
; about to be queued. If there is not enough space left, the error code
; for buffer overflow is automatically appended to the queue. One byte
; of the buffer space is reserved for this purpose. If the reserved byte
; is already used up, the queue is left as is.
; On return, the overflow state will be indicated in the KBOVERFLOW bit
; of KBSTAT. If there is no overflow, at least one byte must be written
; to the buffer after this routine returns. This also implies that the
; requested byte count must not be zero.
; Pre    : bank 0 active
; Post   : bank 0 active
; Input  : WREG, KBSTAT, BUFRDPOS, BUFWRPOS
; Output : KBSTAT, FSR0
; Scratch: WREG, STATUS, ARG
;
preparequeue:   btfsc   KBSTAT, KBOVERFLOW      ; already overflown?
                return                          ; yes: bail out

                movwf   ARG                     ; save requested length
                movlw   OUTBUF
                addwf   BUFWRPOS, w
                movwf   FSR0L                   ; set up write pointer
                clrf    FSR0H
                bcf     KBSTAT, KBEMPTY         ; about to queue something

                movf    BUFRDPOS, w
                subwf   BUFWRPOS, w
                iorlw   -1<<BUFLOGSIZE          ; sign extend
                addwf   ARG, w
                btfss   STATUS, C               ; would overflow?
                return                          ; no: done

                bsf     KBSTAT, KBOVERFLOW      ; indicate overflow
                movlw   RESERROR
                goto    bufwritebyte            ; queue error code

; Append a byte to the keyboard output queue, preceded by a break prefix.
; Pre    : bank 0 active
; Post   : bank 0 active
; Input  : WREG, FSR0, BUFWRPOS
; Output : FSR0, BUFWRPOS
; Scratch: WREG, STATUS, ARG
;
bufwritebreak:  movwf   ARG                     ; remember scancode
                movlw   BREAKPREFIX
                call    bufwritebyte            ; queue break prefix

                movf    ARG, w                  ; queue scancode

; Write a byte to the output buffer. Prior to calling this routine,
; preparequeue must be used to set up the queue state for writing.
; Pre    : bank 0 active, FSR0 prepared
; Post   : bank 0 active
; Input  : WREG, FSR0, BUFWRPOS
; Output : FSR0, BUFWRPOS
; Scratch: WREG, STATUS
;
bufwritebyte:   movwi   FSR0++                  ; write byte
                incf    BUFWRPOS                ; advance position
                movlw   -1<<BUFLOGSIZE
                andwf   BUFWRPOS, w             ; isolate carry
                xorwf   BUFWRPOS                ; wrap around
                subwf   FSR0L
                return

; Routine invoked on a request from the host.
; Pre    : bank 0 active
; Post   : bank 0 active
; Output : KBSTAT
; Scratch: WREG, STATUS, FSR0, ARG
;
kbhandlecmd:    call    ps2recvbyte             ; read in command byte

                btfsc   KBSTAT, KBIOABORT       ; transfer interrupted?
                return                          ; yes: ignore

                clrf    BUFWRPOS                ; clear output queue
                clrf    BUFRDPOS
                bcf     KBSTAT, KBOVERFLOW
                bcf     KBSTAT, KBEMPTY         ; about to queue something
                movlw   OUTBUF
                movwf   FSR0L                   ; prepare write pointer
                clrf    FSR0H

                btfsc   KBSTAT, KBIOERROR       ; I/O error?
                bra     reqresend               ; yes: request resend

                btfsc   KBSTAT, KBEXPECTARG     ; argument byte?
                bra     handlearg               ; yes: evaluate

newcommand:     bcf     KBSTAT, KBEXPECTARG     ; reset command state
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
                bra     cmddefaults             ; F6: set default parameters
                bra     ackcommand              ; F7: set all typematic/auto
                bra     ackcommand              ; F8: set all make/release
                bra     ackcommand              ; F9: set all make only
                bra     ackcommand              ; FA: set all tm/auto/make/rel
                bra     expectarg               ; FB: set key typematic/auto
                bra     expectarg               ; FC: set key make/release
                bra     expectarg               ; FD: set key make only
                bra     cmdresend               ; FE: resend last byte
                                                ; FF: reset and self-test
                clrf    KBSTAT
                call    cmddefaults             ; apply default settings
                movlw   RESTESTPASS
                goto    bufwritebyte            ; queue self-test passed

reqresend:      movlw   RESRESEND               ; ask host to resend byte
                goto    bufwritebyte

expectarg:      bsf     KBSTAT, KBEXPECTARG     ; prepare for argument
                movlw   RESACK
                goto    bufwritebyte            ; queue acknowledge

handlearg:      movlw   CMDRESEND
                subwf   PS2IODATA, w
                btfsc   STATUS, Z               ; request to resend?
                bra     cmdresend               ; yes: resend last byte

                addlw   CMDRESEND-h'E0'
                btfsc   STATUS, C               ; argument below E0?
                bra     newcommand              ; no: interpret as new command

                movlw   CMDTYPEMATIC
                xorwf   LASTCMD, w
                btfsc   STATUS, Z               ; set typematic rate/delay?
                bra     cmdsetdelay             ; yes: extract parameter

                xorlw   CMDTYPEMATIC^CMDCODESET
                btfss   STATUS, Z               ; command get/set scancode set?
                bra     ackargument             ; no: silently ignore

                movf    PS2IODATA, w
                btfsc   STATUS, Z               ; argument is 0?
                bra     cmdgetcodeset           ; yes: return scancode set

                xorlw   2
                btfss   STATUS, Z               ; argument is 2?
                bra     reqresend               ; no: disallow change

ackargument:    bcf     KBSTAT, KBEXPECTARG     ; argument handled
ackcommand:     movlw   RESACK                  ; queue acknowledge
                goto    bufwritebyte

cmdecho:        movlw   RESECHO                 ; queue echo reply
                goto    bufwritebyte

cmdidentify:    movlw   RESACK
                call    bufwritebyte            ; queue acknowledge
                movlw   high KEYBOARDID
                call    bufwritebyte            ; queue keyboard ID
                movlw   low KEYBOARDID
                goto    bufwritebyte

cmdscanon:      bcf     KBSTAT, KBDISABLE       ; allow keys to be sent
                movlw   RESACK
                goto    bufwritebyte

cmdscanoff:     bsf     KBSTAT, KBDISABLE       ; disallow keys to be sent
cmddefaults:    movlw   DEFREPDELAY
                movwf   REPDELAY                ; set default repeat delay
                movlw   RESACK
                goto    bufwritebyte

cmdresend:      movf    LASTSENT, w
                goto    bufwritebyte

cmdsetdelay:    swapf   PS2IODATA, w            ; extract delay (scaled by 2)
                andlw   b'00000110'             ; ignore repeat rate bits
                addlw   2                       ; offset by 250ms base value
                movwf   REPDELAY                ; store setting
                goto    ackargument

cmdgetcodeset:  call    ackargument             ; acknowledge argument
                movlw   2
                goto    bufwritebyte            ; report fixed scan code set

                global  kbhandlecmd

; Routine invoked from the main loop on repeat interval ticks, if no other
; input events are currently pending. If a key press is currently active and
; the auto-repeat delay has passed, queue the key's make scancode without
; any modifiers. The repeat tick interval is expected to be roughly between
; 100ms to 120ms, which matches the repeat interval of the NEC IR protocol.
; Pre    : bank 0 active
; Post   : bank 0 active
; Input  : KBSTAT, KBSCANCODE, KBSCANMODS
; Output : KBSTAT
; Scratch: WREG, STATUS, FSR0, ARG
;
kbautorepeat:   btfsc   KBSTAT, KBKEYHELD       ; a key press is active
                btfsc   KBSCANMODS, MODONCE     ; and the key is repeating?
                return                          ; no: nothing to do

                movf    REPDELAY, w
                subwf   REPCOUNT, w
                btfss   STATUS, C               ; repeat count < delay?
                bra     countrepeat             ; yes: increment and return

                movlw   1                       ; count bytes needed
                btfsc   KBSCANMODS, MODEXT
                movlw   2
                call    preparequeue
                btfss   KBSTAT, KBOVERFLOW      ; would overflow?
                goto    queuekeymake            ; no: queue make scancode
                return

countrepeat:    incf    REPCOUNT                ; count repeat event
                return                          ; wait for next tick

                global  kbautorepeat

; Queue the make scancodes for the active key and its modifiers.
; Any modifier make codes are sent first, followed by the make code
; of the active key.
; Pre    : bank 0 active
; Post   : bank 0 active
; Input  : KBSTAT, KBSCANCODE, KBSCANMODS
; Output : KBSTAT
; Scratch: WREG, STATUS, FSR0, ARG
;
kbqueuemake:    movlw   1                       ; count bytes needed
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

                bsf     KBSTAT, KBKEYHELD       ; indicate active key press
                clrf    REPCOUNT                ; reset auto-repeat counter
                movlw   KEYLSHIFT
                btfsc   KBSCANMODS, MODSHIFT    ; Shift modifier?
                call    bufwritebyte            ; yes: queue Shift scancode

                movlw   KEYLCTRL
                btfsc   KBSCANMODS, MODCTRL     ; Control modifier?
                call    bufwritebyte            ; yes: queue Control scancode

                movlw   KEYLALT
                btfsc   KBSCANMODS, MODALT      ; Alt modifier?
                call    bufwritebyte            ; yes: queue Alt scancode

                btfss   KBSCANMODS, MODSUPER    ; Super modifier?
                bra     queuekeymake            ; no: skip

                movlw   EXTPREFIX
                call    bufwritebyte            ; queue prefix code
                movlw   low KEYLSUPER
                call    bufwritebyte            ; queue Super scancode

queuekeymake:   movlw   EXTPREFIX
                btfsc   KBSCANMODS, MODEXT      ; extended scancode?
                call    bufwritebyte            ; yes: queue prefix code

                movf    KBSCANCODE, w
                goto    bufwritebyte            ; queue key scancode

                global  kbqueuemake

; Queue the break scancodes for the active key and its modifiers.
; The break code for the active key is sent first, followed by the
; break codes of any modifiers.
; Pre    : bank 0 active
; Post   : bank 0 active
; Input  : KBSTAT, KBSCANCODE, KBSCANMODS
; Output : KBSTAT
; Scratch: WREG, STATUS, FSR0, ARG
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
                call    bufwritebyte            ; yes: queue prefix

                bcf     KBSTAT, KBKEYHELD       ; clear active key press
                movf    KBSCANCODE, w
                call    bufwritebreak           ; queue key break code

                btfss   KBSCANMODS, MODSUPER    ; Super modifier?
                bra     checkaltbreak           ; no: skip

                movlw   EXTPREFIX
                call    bufwritebyte            ; queue prefix code
                movlw   low KEYLSUPER
                call    bufwritebreak           ; queue Super break code

checkaltbreak:  movlw   KEYLALT
                btfsc   KBSCANMODS, MODALT      ; Alt modifier?
                call    bufwritebreak           ; yes: queue Alt break code

                movlw   KEYLCTRL
                btfsc   KBSCANMODS, MODCTRL     ; Control modifier?
                call    bufwritebreak           ; yes: queue Control break code

                btfss   KBSCANMODS, MODSHIFT    ; Shift modifier?
                return                          ; no: done
                movlw   KEYLSHIFT
                goto    bufwritebreak           ; yes: queue Shift break code

                global  kbqueuebreak

; Take the front item from the output queue and send it off.
; Pre    : bank 0 active
; Post   : bank 0 active
; Output : KBSTAT
; Scratch: WREG, STATUS, FSR0
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
                bsf     KBSTAT, KBEMPTY         ; yes: indicate status
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
