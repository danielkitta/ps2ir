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
KBEMPTY                                 ; output buffer is empty
KBOVERFLOW                              ; output buffer overflow
KBEXPECTARG                             ; waiting for command argument
KBDISABLE                               ; disable scanning
KBKEYHELD                               ; a key is currently being held down
                endc

; IRSTAT bits
                cblock  0
IRACTIVE                                ; start pulse detected, decoding
IRPENDING                               ; decoded IR datagram pending
IRREPEAT                                ; held key repeat interval tick
IRRELEASE                               ; any held key should be released
                endc

; Key modifier flags
                cblock  0
MODEXT                                  ; extended code, needs E0 prefix
MODONCE                                 ; disable auto-repeat of key
MODSHIFT                                ; combine key with Shift modifier
MODCTRL                                 ; combine key with Control modifier
MODALT                                  ; combine key with Alt modifier
MODSUPER                                ; combine key with Super modifier
                endc
