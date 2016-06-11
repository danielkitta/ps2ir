; vim:ft=pic:sts=8:sw=8:et:

                title    "PS/2 IR adapter"
                subtitle "Utility routines"

                include "common.inc"

PROG0           code

; Wait a precise number of instruction cycles.
; The instruction cycle counts include call and return.
; If WREG is zero, the delay will be 3*256 + k cycles.
; Input  : WREG
; Scratch: WREG
;
waitcycles3n5:  nop                             ; 3*WREG + 5 cycles
waitcycles3n4:  nop                             ; 3*WREG + 4 cycles
waitcycles3n3:  decfsz  WREG, w                 ; 3*WREG + 3 cycles
                bra     waitcycles3n3
waitcycles4:    return                          ; 4 cycles

                global  waitcycles3n5, waitcycles3n4, waitcycles3n3, waitcycles4

                end
