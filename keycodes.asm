; vim:ft=pic:sts=8:sw=8:et:

                title    "PS/2 IR adapter"
                subtitle "IR key scancode map"

                include "common.inc"

; This scancode table maps the codes used by the @sat satellite receiver.
; The One For All remote direct setup code for this device is 1300 (SAT).
;
DEVICEADR       equ     h'0820'                 ; IR device address

cdata           code

; IR command to keyboard scancode lookup table.
; Must begin with the 16 bit device address, followed by exactly
; 128 scancode entries. Unused positions should be set to zero.
;
keycodemap:     dt      low DEVICEADR
                dt      high DEVICEADR

                dt      KEYPOWER                ; 00: Power
                dt      KEYDELETE               ; 01: Aspect ratio
                dt      KEYVOLUP                ; 02: Volume up
                dt      KEYVOLDOWN              ; 03: Volume down
                dt      KEYMUTE                 ; 04: Mute
                dt      0                       ; 05
                dt      KEYPAGEUP               ; 06: Channel up
                dt      KEYPAGEDOWN             ; 07: Channel down
                dt      KEYMEDIA                ; 08: AV
                dt      0                       ; 09
                dt      0                       ; 0A
                dt      0                       ; 0B
                dt      KEYBACKSPACE            ; 0C: Back
                dt      KEYLSUPER               ; 0D: Guide
                dt      0                       ; 0E
                dt      KEYFAV                  ; 0F: Favorites
                dt      KEYESCAPE               ; 10: Exit
                dt      KEYMENU                 ; 11: Menu
                dt      KEYUP                   ; 12: Up
                dt      KEYDOWN                 ; 13: Down
                dt      KEYLEFT                 ; 14: Left
                dt      KEYENTER                ; 15: OK
                dt      KEYRIGHT                ; 16: Right
                dt      0                       ; 17
                dt      KEYF1                   ; 18: Red
                dt      KEYF2                   ; 19: Green
                dt      KEYF3                   ; 1A: Yellow
                dt      KEYF4                   ; 1B: Blue/Info
                dt      KEY1                    ; 1C: 1
                dt      KEY2                    ; 1D: 2
                dt      KEY3                    ; 1E: 3
                dt      0                       ; 1F
                dt      0                       ; 20
                dt      0                       ; 21
                dt      0                       ; 22
                dt      0                       ; 23
                dt      0                       ; 24
                dt      0                       ; 25
                dt      0                       ; 26
                dt      0                       ; 27
                dt      0                       ; 28
                dt      0                       ; 29
                dt      0                       ; 2A
                dt      0                       ; 2B
                dt      0                       ; 2C
                dt      0                       ; 2D
                dt      0                       ; 2E
                dt      0                       ; 2F
                dt      0                       ; 30
                dt      0                       ; 31
                dt      0                       ; 32
                dt      0                       ; 33
                dt      0                       ; 34
                dt      0                       ; 35
                dt      0                       ; 36
                dt      0                       ; 37
                dt      0                       ; 38
                dt      0                       ; 39
                dt      0                       ; 3A
                dt      0                       ; 3B
                dt      0                       ; 3C
                dt      0                       ; 3D
                dt      0                       ; 3E
                dt      0                       ; 3F
                dt      KEY4                    ; 40: 4
                dt      KEY5                    ; 41: 5
                dt      KEY6                    ; 42: 6
                dt      KEYPLAYPAUSE            ; 43: Pause
                dt      KEY7                    ; 44: 7
                dt      KEY8                    ; 45: 8
                dt      KEY9                    ; 46: 9
                dt      KEY0                    ; 47: 0
                dt      KEYPREVTRACK            ; 48: Previous track
                dt      KEYBACK                 ; 49: Rewind
                dt      KEYFORWARD              ; 4A: Forward
                dt      KEYNEXTTRACK            ; 4B: Next track
                dt      KEYRECORD               ; 4C: Record
                dt      KEYSTOP                 ; 4D: Stop
                dt      KEYPLAYPAUSE            ; 4E: Play
                dt      0                       ; 4F
                dt      0                       ; 50
                dt      0                       ; 51
                dt      0                       ; 52
                dt      0                       ; 53
                dt      0                       ; 54
                dt      0                       ; 55
                dt      0                       ; 56
                dt      0                       ; 57
                dt      0                       ; 58
                dt      0                       ; 59
                dt      0                       ; 5A
                dt      0                       ; 5B
                dt      0                       ; 5C
                dt      0                       ; 5D
                dt      0                       ; 5E
                dt      0                       ; 5F
                dt      0                       ; 60
                dt      0                       ; 61
                dt      0                       ; 62
                dt      0                       ; 63
                dt      0                       ; 64
                dt      0                       ; 65
                dt      0                       ; 66
                dt      0                       ; 67
                dt      0                       ; 68
                dt      0                       ; 69
                dt      0                       ; 6A
                dt      0                       ; 6B
                dt      0                       ; 6C
                dt      0                       ; 6D
                dt      0                       ; 6E
                dt      0                       ; 6F
                dt      0                       ; 70
                dt      0                       ; 71
                dt      0                       ; 72
                dt      0                       ; 73
                dt      0                       ; 74
                dt      0                       ; 75
                dt      0                       ; 76
                dt      0                       ; 77
                dt      0                       ; 78
                dt      0                       ; 79
                dt      0                       ; 7A
                dt      0                       ; 7B
                dt      0                       ; 7C
                dt      0                       ; 7D
                dt      0                       ; 7E
                dt      0                       ; 7F

                global  keycodemap

                end
