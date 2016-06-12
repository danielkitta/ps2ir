; vim:ft=pic:sts=8:sw=8:et:

; Partial list of AT MF2 untranslated set 2 scancodes.
; Source: http://www.win.tue.nl/~aeb/linux/kbd/scancodes-10.html
;         http://wiki.osdev.org/PS/2_Keyboard#Scan_Code_Set_2
;         National Semiconductors AN-0734
; Abuse bit 7 to flag scancodes that require an E0 prefix. Only a small
; number of keys have scancodes above 7F, and we can do without those.
;
KEY1            equ     h'16'
KEY2            equ     h'1E'
KEY3            equ     h'26'
KEY4            equ     h'25'
KEY5            equ     h'2E'
KEY6            equ     h'36'
KEY7            equ     h'3D'
KEY8            equ     h'3E'
KEY9            equ     h'46'
KEY0            equ     h'45'
KEYBACKSPACE    equ     h'66'
KEYTAB          equ     h'0D'
KEYCAPSLOCK     equ     h'58'
KEYENTER        equ     h'5A'
KEYLSHIFT       equ     h'12'
KEYRSHIFT       equ     h'59'
KEYLCTRL        equ     h'14'
KEYLALT         equ     h'11'
KEYSPACE        equ     h'29'
KEYRALT         equ     h'11' | 1<<KEYEXTBIT
KEYRCTRL        equ     h'14' | 1<<KEYEXTBIT
KEYINSERT       equ     h'70' | 1<<KEYEXTBIT
KEYDELETE       equ     h'71' | 1<<KEYEXTBIT
KEYHOME         equ     h'6C' | 1<<KEYEXTBIT
KEYEND          equ     h'69' | 1<<KEYEXTBIT
KEYPAGEUP       equ     h'7D' | 1<<KEYEXTBIT
KEYPAGEDOWN     equ     h'7A' | 1<<KEYEXTBIT
KEYLEFT         equ     h'6B' | 1<<KEYEXTBIT
KEYUP           equ     h'75' | 1<<KEYEXTBIT
KEYDOWN         equ     h'72' | 1<<KEYEXTBIT
KEYRIGHT        equ     h'74' | 1<<KEYEXTBIT
KEYESCAPE       equ     h'76'
KEYF1           equ     h'05'
KEYF2           equ     h'06'
KEYF3           equ     h'04'
KEYF4           equ     h'0C'
KEYF5           equ     h'03'
KEYF6           equ     h'0B'
KEYF7           equ     h'02'   ; actually 83, but either translates to 41...
KEYF8           equ     h'0A'
KEYF9           equ     h'01'
KEYF10          equ     h'09'
KEYF11          equ     h'78'
KEYF12          equ     h'07'
KEYSCRLOCK      equ     h'7E'
KEYLSUPER       equ     h'1F' | 1<<KEYEXTBIT
KEYRSUPER       equ     h'27' | 1<<KEYEXTBIT
KEYMENU         equ     h'2F' | 1<<KEYEXTBIT
; Numeric keypad:
KEYNUMLOCK      equ     h'77'
KEYKP1          equ     h'69'
KEYKP2          equ     h'72'
KEYKP3          equ     h'7A'
KEYKP4          equ     h'6B'
KEYKP5          equ     h'73'
KEYKP6          equ     h'74'
KEYKP7          equ     h'6C'
KEYKP8          equ     h'75'
KEYKP9          equ     h'7D'
KEYKP0          equ     h'70'
KEYKPDEL        equ     h'71'
KEYKPADD        equ     h'79'
KEYKPSUB        equ     h'7B'
KEYKPMUL        equ     h'7C'
KEYKPDIV        equ     h'4A' | 1<<KEYEXTBIT
KEYKPENTER      equ     h'5A' | 1<<KEYEXTBIT
; ACPI keys:
KEYSLEEP        equ     h'3F' | 1<<KEYEXTBIT
KEYPOWER        equ     h'37' | 1<<KEYEXTBIT
KEYWAKE         equ     h'5E' | 1<<KEYEXTBIT
; Microsoft internet/office keys:
KEYSEARCH       equ     h'10' | 1<<KEYEXTBIT
KEYFORWARD      equ     h'30' | 1<<KEYEXTBIT
KEYBACK         equ     h'38' | 1<<KEYEXTBIT
KEYSTOP         equ     h'28' | 1<<KEYEXTBIT
KEYREFRESH      equ     h'20' | 1<<KEYEXTBIT
KEYFAV          equ     h'18' | 1<<KEYEXTBIT
KEYWEB          equ     h'3A' | 1<<KEYEXTBIT
KEYMAIL         equ     h'48' | 1<<KEYEXTBIT
KEYMYCOMP       equ     h'40' | 1<<KEYEXTBIT
KEYCALC         equ     h'2B' | 1<<KEYEXTBIT
; Microsoft multimedia keys:
KEYMEDIA        equ     h'50' | 1<<KEYEXTBIT
KEYPLAYPAUSE    equ     h'34' | 1<<KEYEXTBIT
KEYNEXTTRACK    equ     h'4D' | 1<<KEYEXTBIT
KEYPREVTRACK    equ     h'15' | 1<<KEYEXTBIT
KEYSTOPTRACK    equ     h'3B' | 1<<KEYEXTBIT
KEYVOLUP        equ     h'32' | 1<<KEYEXTBIT
KEYVOLDOWN      equ     h'21' | 1<<KEYEXTBIT
KEYMUTE         equ     h'23' | 1<<KEYEXTBIT