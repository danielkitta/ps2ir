; vim:ft=pic:sts=8:sw=8:et:

; Key modifier masks. To be combined with a base scancode byte into
; a single code word describing a key's scancode and any modifiers.
;
EXTMASK         equ     h'100' << MODEXT
SHIFTMASK       equ     h'100' << MODSHIFT
CTRLMASK        equ     h'100' << MODCTRL
ALTMASK         equ     h'100' << MODALT
SUPERMASK       equ     h'100' << MODSUPER

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
KEYRALT         equ     h'11' | EXTMASK
KEYRCTRL        equ     h'14' | EXTMASK
KEYINSERT       equ     h'70' | EXTMASK
KEYDELETE       equ     h'71' | EXTMASK
KEYHOME         equ     h'6C' | EXTMASK
KEYEND          equ     h'69' | EXTMASK
KEYPAGEUP       equ     h'7D' | EXTMASK
KEYPAGEDOWN     equ     h'7A' | EXTMASK
KEYLEFT         equ     h'6B' | EXTMASK
KEYUP           equ     h'75' | EXTMASK
KEYDOWN         equ     h'72' | EXTMASK
KEYRIGHT        equ     h'74' | EXTMASK
KEYESCAPE       equ     h'76'
KEYF1           equ     h'05'
KEYF2           equ     h'06'
KEYF3           equ     h'04'
KEYF4           equ     h'0C'
KEYF5           equ     h'03'
KEYF6           equ     h'0B'
KEYF7           equ     h'83'
KEYF8           equ     h'0A'
KEYF9           equ     h'01'
KEYF10          equ     h'09'
KEYF11          equ     h'78'
KEYF12          equ     h'07'
KEYSCRLOCK      equ     h'7E'
KEYLSUPER       equ     h'1F' | EXTMASK
KEYRSUPER       equ     h'27' | EXTMASK
KEYMENU         equ     h'2F' | EXTMASK
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
KEYKPDIV        equ     h'4A' | EXTMASK
KEYKPENTER      equ     h'5A' | EXTMASK
; ACPI keys:
KEYSLEEP        equ     h'3F' | EXTMASK
KEYPOWER        equ     h'37' | EXTMASK
KEYWAKE         equ     h'5E' | EXTMASK
; Microsoft internet/office keys:
KEYSEARCH       equ     h'10' | EXTMASK
KEYFORWARD      equ     h'30' | EXTMASK
KEYBACK         equ     h'38' | EXTMASK
KEYSTOP         equ     h'28' | EXTMASK
KEYREFRESH      equ     h'20' | EXTMASK
KEYFAV          equ     h'18' | EXTMASK
KEYWEB          equ     h'3A' | EXTMASK
KEYMAIL         equ     h'48' | EXTMASK
KEYMYCOMP       equ     h'40' | EXTMASK
KEYCALC         equ     h'2B' | EXTMASK
; Microsoft multimedia keys:
KEYMEDIA        equ     h'50' | EXTMASK
KEYPLAYPAUSE    equ     h'34' | EXTMASK
KEYNEXTTRACK    equ     h'4D' | EXTMASK
KEYPREVTRACK    equ     h'15' | EXTMASK
KEYSTOPTRACK    equ     h'3B' | EXTMASK
KEYVOLUP        equ     h'32' | EXTMASK
KEYVOLDOWN      equ     h'21' | EXTMASK
KEYMUTE         equ     h'23' | EXTMASK

; Define and export a constant as relocatable symbol.
;
DEFSYM          macro   NAME, VALUE
NAME            udata_ovr VALUE
NAME:
                global  NAME
                endm
