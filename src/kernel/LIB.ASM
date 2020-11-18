;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;!                                                         !
;!  BoleroOS                                               !
;!  By Joao Jeronimo - j_j_b_o_j@yahoo.com.br              !
;!                                                         !
;!  BoleroOS comes with NO WARANTY. Use at your own risk.  !
;!  In case of problem caused by Bolero, you can           !
;!  you can always contact Jeronimo for help, but no       !
;!  solution or assistance is warrantied.                  !
;!                                                         !
;!      Purpose: Runtime library                           !
;!      History: 21/06/2008 - Decimal ASCII convertion     !
;!                                                         !
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


; Write as unsigned decimal, in memory
;  Ins:  EAX - number
;        EBP - expected a buffer with 11 bytes, to
;              receive the result. This may be modified,
;              however, to point to the most significative
;              character written. A 0 is put in ebp+10.
;  Out:  EBP - start of string, with number converted
function WriteDecU, EDX_REG or EBX_REG or EAX_REG or EBP_REG
		add		ebp, 10
		mov		[ebp], byte 0
		mov		ebx, 10
		
	.loop:
		dec		ebp
		clear	edx
		div		ebx
		
		add		edx, '0'
		mov		[ebp], dl
		test	eax, eax
		jnz		.loop
		
		ret



; Write as hexadecimal, in memory
;  Ins:  EAX - number
;        EBP - expected a buffer with 9 bytes, to
;              receive the result.
function WriteHex, EDX_REG or EBX_REG
		add		ebp, 8
		mov		[ebp], byte 0
		mov		ebx, 8
		
	.loop:
		dec		ebp
		
		mov		edx, eax
		and		edx, 0xF
		mov		edx, dword [.hexstr+edx]
		mov		[ebp], dl
		
		ror		eax, 4
		dec		ebx
		jnz		.loop
		
		ret

.hexstr	db "0123456789ABCDEF"



