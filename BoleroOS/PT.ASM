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
;!      Purpose: Portuguese keyboard layout map            !
;!      History: 13/08/2008 - Created                      !
;!                                                         !
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


VK2UNI_normal:
		;dw	"\\1234567890'«"
		;dw	"qwertyuiop+'~"
		;dw	"asdfghjklçº"
		;dw	"zxcvbnm,.-"
		;dw	

VK2UNI_shift:
		;db	"|!\"#$%&/()=?»"
		;db	"qwertyuiop*`^"
		;db	"asdfghjklç"

VK2UNI_altgr:

DEAD_KEYS:
		dd	"~", .tidle_deads
		dd	0, 0

	.tidle_deads:
		dd	"a", "ã"
		dd	0, 0


