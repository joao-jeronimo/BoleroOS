;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;!                                                         !
;!  BoleroOS                                               !
;!  By Joao Jeronimo - j_j_b_o_j@yahoo.com.br              !
;!                                                         !
;!  BoleroOS comes with NO WARANTY. Use at your own risk.  !
;!  In case of problem caused by Bolero, you can always    !
;!  contact Jeronimo for help, but no solution or          !
;!  assistance is warrantied.                              !
;!                                                         !
;!      Purpose: United States keyboard layout map         !
;!      History: 13/08/2008 - Created                      !
;!                                                         !
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


align 2
VK2UNI_normal:
		dw	"`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "="
		dw	"q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "[", "]", "\\"
		dw	"a", "s", "d", "f", "g", "h", "j", "k", "l", ";", "'"
		dw	"z", "x", "c", "v", "b", "n", "m", ",", ".", "/"
		dw	" ", 0x09, 0x0A		; Space, TAB and LF
		times 20 dw -1

align 2
VK2UNI_shift:
		dw	"~", "!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "_", "+"
		dw	"q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "{", "}", "|"
		dw	"a", "s", "d", "f", "g", "h", "j", "k", "l", ":", 0x22	; Inverted commas
		dw	"z", "x", "c", "v", "b", "n", "m", "<", ">", "?"
		dw	" ", 0x09, 0x0A		; Space, TAB and LF
		times 20 dw -1

align 2
VK2UNI_altgr:
		times N_TRANS_KEYS dw -1

align 4
DEAD_KEYS:
		dd	0, 0