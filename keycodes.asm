; vim:ft=pic:sts=8:sw=8:et:

                title    "PS/2 IR adapter"
                subtitle "IR key scancode map"

                include "common.inc"
                include "keycodes.inc"

; This scancode table maps the codes used by the @sat satellite receiver.
; The One For All remote direct setup code for this device is 1300 (SAT).
;
                DEFSYM  IRDEVADR, h'0820'       ; IR device address

cdata           code

; IR command to keyboard scancode lookup table.
; Must have exactly 128 entries. Unused positions should be set to 0.
;
keycodemap:     dw      KEYPOWER                ; 00: Power
                dw      KEYTAB                  ; 01: Aspect ratio
                dw      KEYVOLUP                ; 02: Volume up
                dw      KEYVOLDOWN              ; 03: Volume down
                dw      KEYMUTE                 ; 04: Mute
                dw      0                       ; 05
                dw      KEYPAGEUP               ; 06: Channel up
                dw      KEYPAGEDOWN             ; 07: Channel down
                dw      KEYMEDIA                ; 08: AV
                dw      0                       ; 09
                dw      0                       ; 0A
                dw      0                       ; 0B
                dw      KEYBACKSPACE            ; 0C: Back
                dw      KEYLSUPER               ; 0D: Guide
                dw      0                       ; 0E
                dw      KEYFAV                  ; 0F: Favorites
                dw      KEYESCAPE               ; 10: Exit
                dw      KEYMENU                 ; 11: Menu
                dw      KEYUP                   ; 12: Up
                dw      KEYDOWN                 ; 13: Down
                dw      KEYLEFT                 ; 14: Left
                dw      KEYENTER                ; 15: OK
                dw      KEYRIGHT                ; 16: Right
                dw      0                       ; 17
                dw      KEYMYCOMP               ; 18: Red
                dw      KEYWEB                  ; 19: Green
                dw      KEYMAIL                 ; 1A: Yellow
                dw      KEYSEARCH               ; 1B: Blue/Info
                dw      KEY1                    ; 1C: 1
                dw      KEY2                    ; 1D: 2
                dw      KEY3                    ; 1E: 3
                dw      0                       ; 1F
                dw      0                       ; 20
                dw      0                       ; 21
                dw      0                       ; 22
                dw      0                       ; 23
                dw      0                       ; 24
                dw      0                       ; 25
                dw      0                       ; 26
                dw      0                       ; 27
                dw      0                       ; 28
                dw      0                       ; 29
                dw      0                       ; 2A
                dw      0                       ; 2B
                dw      0                       ; 2C
                dw      0                       ; 2D
                dw      0                       ; 2E
                dw      0                       ; 2F
                dw      0                       ; 30
                dw      0                       ; 31
                dw      0                       ; 32
                dw      0                       ; 33
                dw      0                       ; 34
                dw      0                       ; 35
                dw      0                       ; 36
                dw      0                       ; 37
                dw      0                       ; 38
                dw      0                       ; 39
                dw      0                       ; 3A
                dw      0                       ; 3B
                dw      0                       ; 3C
                dw      0                       ; 3D
                dw      0                       ; 3E
                dw      0                       ; 3F
                dw      KEY4                    ; 40: 4
                dw      KEY5                    ; 41: 5
                dw      KEY6                    ; 42: 6
                dw      KEYSPACE                ; 43: Pause
                dw      KEY7                    ; 44: 7
                dw      KEY8                    ; 45: 8
                dw      KEY9                    ; 46: 9
                dw      KEY0                    ; 47: 0
                dw      KEYPREVTRACK            ; 48: Previous track
                dw      KEYBACK                 ; 49: Rewind
                dw      KEYFORWARD              ; 4A: Forward
                dw      KEYNEXTTRACK            ; 4B: Next track
                dw      KEYSTOP                 ; 4C: Record
                dw      KEYSTOPTRACK            ; 4D: Stop
                dw      KEYPLAYPAUSE            ; 4E: Play
                dw      0                       ; 4F
                dw      0                       ; 50
                dw      0                       ; 51
                dw      0                       ; 52
                dw      0                       ; 53
                dw      0                       ; 54
                dw      0                       ; 55
                dw      0                       ; 56
                dw      0                       ; 57
                dw      0                       ; 58
                dw      0                       ; 59
                dw      0                       ; 5A
                dw      0                       ; 5B
                dw      0                       ; 5C
                dw      0                       ; 5D
                dw      0                       ; 5E
                dw      0                       ; 5F
                dw      0                       ; 60
                dw      0                       ; 61
                dw      0                       ; 62
                dw      0                       ; 63
                dw      0                       ; 64
                dw      0                       ; 65
                dw      0                       ; 66
                dw      0                       ; 67
                dw      0                       ; 68
                dw      0                       ; 69
                dw      0                       ; 6A
                dw      0                       ; 6B
                dw      0                       ; 6C
                dw      0                       ; 6D
                dw      0                       ; 6E
                dw      0                       ; 6F
                dw      0                       ; 70
                dw      0                       ; 71
                dw      0                       ; 72
                dw      0                       ; 73
                dw      0                       ; 74
                dw      0                       ; 75
                dw      0                       ; 76
                dw      0                       ; 77
                dw      0                       ; 78
                dw      0                       ; 79
                dw      0                       ; 7A
                dw      0                       ; 7B
                dw      0                       ; 7C
                dw      0                       ; 7D
                dw      0                       ; 7E
                dw      0                       ; 7F

                global  keycodemap

                end
