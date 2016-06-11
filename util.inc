; vim:ft=pic:sts=8:sw=8:et:

                extern  waitcycles3n5, waitcycles3n4, waitcycles3n3, waitcycles4

; Single-instruction two-cycle NOP.
;
NOPNOP          macro
                bra     $+1
                endm

; Busy-wait for a specified number of instruction cycles.
; Note: The inserted code clobbers WREG for counts above 6.
;
WAITIC          macro   COUNT
        if (COUNT) < 0
                error   "Negative cycle count"
        endif
        if (COUNT) == 0
                exitm
        endif
        if (COUNT) == 1
                nop
                exitm
        endif
        if (COUNT) == 2
                NOPNOP
                exitm
        endif
        if (COUNT) == 3
                NOPNOP
                nop
                exitm
        endif
        if (COUNT) == 4
                call    waitcycles4
                exitm
        endif
        if (COUNT) == 5
                call    waitcycles4
                nop
                exitm
        endif
        if (COUNT) == 6
                call    waitcycles4
                NOPNOP
                exitm
        endif
        if (COUNT) > 3 * h'100' + 6
                error   "Cycle count too large for 8-bit loop counter"
        endif
                movlw   low(((COUNT) - 4) / 3)
        if (COUNT) % 3 == 1
                call    waitcycles3n3
                exitm
        endif
        if (COUNT) % 3 == 2
                call    waitcycles3n4
                exitm
        endif
                call    waitcycles3n5
                endm

; Wait for a specified time in microseconds, while compensating
; for a number of instruction cycles spent in the surrounding code.
; Note: The generated code may clobber WREG.
;
WAITUS          macro   USECS, COMPCYCLES
                local   IDLECYCLES = (USECS) * (FREQ_OSC / d'1000') / d'4000'
        if IDLECYCLES < (COMPCYCLES)
                error   "Context instructions delay exceeds requested wait time"
        endif
                WAITIC  IDLECYCLES - (COMPCYCLES)
                endm
