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
;!      Purpose: VGA driver                                !
;!      History: 28/07/2008 - provisory display            !
;!                            syscalls written             !
;!               21/02/2012 - cursor updating              !
;!                                                         !
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


VGA_TXT_ADDR	dd	?

DISPLAY_OWNER	dd	?
BUFFER_ADDRESS	dd	-1    ; Address of buffer that user mode app is using to manipulate display.


syscall GetDisplay
		cmp		[BUFFER_ADDRESS], -1
		je		.not_defined
		
		; If its already defined, report error
		or		[ebp+UM_EFLAGS_ON_STACK], dword (1 shl 0)		; Set carry flag
		mov		[ebp+UM_EAX_ON_STACK], dword 1					; Error code (conflictuous request)
		ret
		
	.not_defined:
		mov		ebx, [ebp+UM_EAX_ON_STACK]		; Get address for buffer
		mov		edi, ebx
		mov		esi, ebx
		add		edi, 80*25*2-1
		callfun	MemoryExistsAt, EBX_REG
		jc		.invalid_address
		
		cmp		ebx, HIGH_ADDRESS
		jae		.invalid_address
		
		mov		eax, [current_thread]
		mov		ecx, [eax+THREAD.process]
		mov		[BUFFER_ADDRESS], ebx
		mov		eax, [ecx+PROC.pid]
		mov		[DISPLAY_OWNER], eax
		
		and		[ebp+UM_EFLAGS_ON_STACK], dword not(1 shl 0)	; Unset carry flag
		ret
		
	.invalid_address:
		or		[ebp+UM_EFLAGS_ON_STACK], dword (1 shl 0)		; Set carry flag
		mov		[ebp+UM_EAX_ON_STACK], dword 2					; Error code (invalid address)
		ret


syscall UpDisplay
		mov		eax, [current_thread]
		mov		ebx, [eax+THREAD.process]
		mov		ecx, [ebx+PROC.pid]
		cmp		[DISPLAY_OWNER], ecx
		jne		.reterr						; No efect if current process isn't owning the display
		
		mov		esi, [ebp+UM_EAX_ON_STACK]
		mov		edi, [VGA_TXT_ADDR]
		
		mov		ecx, [ebp+UM_EBX_ON_STACK]
		
		; Some safety tests
		cmp		esi, ecx
		ja		.reterr		; Start must be <= end
		cmp		ecx, 80*25
		ja		.reterr		; End must be <= 80*25
		
		mov     ebx, ecx
		sub		ecx, esi
		
		shl		esi, 1						; *2
		add		edi, esi
		add		esi, [BUFFER_ADDRESS]
		;push ebx
		cld
		rep		movsw   ; Do copy...
		;pop ebx
		
	.cursor:
		; Setting cursor position
		;mov     edx, 0x3CC   ; Determining offset of CRTC register...
		;in      al, dx
		;and     eax, 1
		;shl     eax, 1
		mov		eax, 0
		mov     edx, 0x3D4
		sub     edx, eax
		
		mov     al, 0x0E    ; Setting the low  byte of cursor
		out     dx, al
		movzx   ax, bh;byte [ebp+UM_EBX_ON_STACK+1]
		inc     dx
		out     dx, al
		dec     dx
		mov     al, 0x0F    ; Setting the high byte of cursor
		out     dx, al
		movzx   ax, bl;byte [ebp+UM_EBX_ON_STACK+0]
		inc     dx
		out     dx, al
		
	.ret:
		and		[ebp+UM_EFLAGS_ON_STACK], not(1 shl 0)	; Clear carry flag to signal success
		ret

	.reterr:
		or		[ebp+UM_EFLAGS_ON_STACK], 1 shl 0	; Set carry flag to signal error
		ret

