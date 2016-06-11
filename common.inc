; vim:ft=pic:sts=8:sw=8:et:

                include <p16f1xxx.inc>

                radix   dec

                errorlevel -305         ; "Using default destination of 1 (file)"

; Machine definition
FREQ_OSC        equ     4000000         ; CPU clock frequency in Hz

; Pin assignments
IRDET           equ     RA4             ; IR detector input pin
PS2CLK          equ     RA1             ; PS/2 clock pin
PS2DAT          equ     RA0             ; PS/2 data pin

; KBSTAT bits
                cblock  0
KBIOABORT                               ; transfer aborted by host
KBIOERROR                               ; framing or parity error
KBQUEUED                                ; output bytes queued
KBOVERFLOW                              ; output buffer overflow
KBEXPECTARG                             ; waiting for command argument
KBDISABLE                               ; disable scanning
KBKEYHELD                               ; a key is currently being held down
                endc

; IRSTAT bits
                cblock  0
IRACTIVE                                ; start pulse detected, decoding
IRPENDING                               ; decoded IR datagram pending
IRRELEASE                               ; any held key should be released
                endc

; Key code flags
KEYEXTBIT       equ     7               ; extended scancode flag bit
