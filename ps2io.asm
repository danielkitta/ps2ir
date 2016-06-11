; vim:ft=pic:sts=8:sw=8:et:

                title    "PS/2 IR adapter"
                subtitle "PS/2 I/O routines"

                include "common.inc"
                include "util.inc"

                extern  KBSTAT                  ; bank 0

PS2PERIOD       equ     d'40'                   ; clock period in microseconds

BANK0           udata

PS2IODATA:      res     1                       ; byte to send or received
BITCOUNT:       res     1                       ; bit loop counter
PARITYSUM:      res     1                       ; parity accumulator

                global  PS2IODATA

PROG0           code

; Send byte to PS/2 host.
; Pre    : bank 0 active
; Post   : bank 0 active
; Input  : PS2IODATA
; Output : KBSTAT
; Scratch: WREG, STATUS, FSR1, PS2IODATA
;
ps2sendbyte:    clrf    FSR1H
                movlw   TRISA                   ; access TRISA via FSR1
                movwf   FSR1L                   ; to avoid bank switching

                bcf     KBSTAT, KBIOERROR
                movlw   8
                movwf   BITCOUNT
                bcf     INTCON, GIE             ; block interrupts

                bcf     STATUS, C               ; send start bit
                call    transferbit

                bcf     KBSTAT, KBIOABORT
                movlw   1
                movwf   PARITYSUM

sendloop:       WAITUS  PS2PERIOD/2, d'11'
                movf    PS2IODATA, w
                xorwf   PARITYSUM               ; compute parity
                rrf     PS2IODATA               ; send data bit
                call    transferbit

                decfsz  BITCOUNT
                bra     sendloop

                WAITUS  PS2PERIOD/2, 8
                rrf     PARITYSUM, w            ; send parity bit
                call    transferbit

                WAITUS  PS2PERIOD/2, 6
                call    transferbit1            ; send stop bit

                WAITUS  PS2PERIOD/2, 3
                bsf     INDF1, PS2CLK           ; release clock line

                bsf     INTCON, GIE             ; re-enable interrupts
                return

                global  ps2sendbyte

; Receive byte from PS/2 host.
; Pre    : bank 0 active
; Post   : bank 0 active
; Output : KBSTAT, PS2IODATA
; Scratch: WREG, STATUS, FSR1, PS2IODATA
;
ps2recvbyte:    clrf    FSR1H
                movlw   TRISA                   ; access TRISA via FSR1
                movwf   FSR1L                   ; to avoid bank switching

                bcf     KBSTAT, KBIOERROR
                bcf     INTCON, GIE             ; block interrupts

                call    transferbit1            ; receive start bit

                bcf     KBSTAT, KBIOABORT
                movlw   8
                movwf   BITCOUNT
                clrf    PARITYSUM
                WAITUS  PS2PERIOD/2, d'10'

recvloop:       call    transferbit1            ; receive data bit

                rrf     PS2IODATA, w            ; shift in data bit
                movwf   PS2IODATA
                xorwf   PARITYSUM               ; compute parity (in MSB)

                WAITUS  PS2PERIOD/2, d'12'
                decfsz  BITCOUNT
                bra     recvloop

                nop                             ; match cycles with loop
                call    transferbit1            ; receive parity bit

                rrf     WREG, w
                xorwf   PARITYSUM               ; validate parity

waitforstop:    WAITUS  PS2PERIOD/2, 5
                bsf     INDF1, PS2CLK           ; release clock line
                WAITUS  PS2PERIOD/4, 5

                movlw   1<<PS2DAT
                btfss   PORTA, PS2CLK           ; clock line pulled low?
                goto    abortxfer               ; yes: abort transfer

                andwf   PORTA, w                ; sample data line
                xorwf   INDF1                   ; acknowledge stop bit

                btfss   WREG, PS2DAT            ; stop bit was received?
                bsf     KBSTAT, KBIOERROR       ; no: indicate framing error
                WAITUS  PS2PERIOD/4, 3

                bcf     INDF1, PS2CLK           ; pull clock line low
                nop                             ; match cycles with prologue

                btfsc   INDF1, PS2DAT           ; acknowlege sent?
                bra     waitforstop             ; no: do another cycle

                btfss   PARITYSUM, 7            ; parity matches?
                bsf     KBSTAT, KBIOERROR       ; no: indicate error status

                WAITUS  PS2PERIOD/2, 6
                bsf     INDF1, PS2CLK           ; release clock line
                WAITUS  PS2PERIOD/4, 1
                bsf     INDF1, PS2DAT           ; release data line

                bsf     INTCON, GIE             ; re-enable interrupts
                return

                global  ps2recvbyte

; Send/receive a bit to/from the PS/2 host.
; Instruction cycles (including call)   until positive clock edge: 3 (4)
; Instruction cycles (including return) after negative clock edge: 2
; Pre    : bank 0 active, FSR1 points to TRISA
; Post   : bank 0 active, FSR1 points to TRISA
; Input  : STATUS.C, FSR1
; Output : STATUS.C, KBSTAT
; Scratch: WREG, STATUS
;
transferbit1:   bsf     STATUS, C               ; entry with constant argument
transferbit:    bsf     INDF1, PS2CLK           ; release clock line
                WAITUS  PS2PERIOD/4, 5

                btfsc   STATUS, C
                bra     send1bit
                nop                             ; compensate branch cycle

                movf    PORTA, w                ; sample data and clock
                bcf     INDF1, PS2DAT           ; pull data line low
                bra     cycleclk

send1bit:       movf    PORTA, w                ; sample data and clock
                bsf     INDF1, PS2DAT           ; release data line
                bra     cycleclk                ; nop: match branch cycles

cycleclk:       btfss   WREG, PS2CLK            ; clock pulled low?
                bra     unwindabort             ; if so, abort transfer

                andlw   1<<PS2DAT
                addlw   -(1<<PS2DAT)            ; copy received bit to carry

                WAITUS  PS2PERIOD/4, 7
                bcf     INDF1, PS2CLK           ; pull clock line low
                return

unwindabort:    banksel STKPTR                  ; bank 31
                decf    STKPTR                  ; unwind: return to caller's caller
                banksel KBSTAT                  ; bank 0

abortxfer:      bsf     INDF1, PS2DAT           ; release data line
                bsf     INTCON, GIE             ; re-enable interrupts

                bsf     KBSTAT, KBIOABORT       ; indicate abort status
                return

                end
