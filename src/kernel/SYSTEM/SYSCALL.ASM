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
;!      Purpose: System Call ISR and trampoline            !
;!      History: 23/06/2008 - Sentinel symbol for server   !
;!                                                         !
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

INT_SYSCALL:
		pushad
		
		callfun	load_kmode_selectors, 0		
		
		mov		ebx, [esp+4*2]		; Get system call number
		mov		ebp, esp			; Passing stack frame in EBP so that the system call
									;  routine can access user mode state.
		call	dword [SYSTEM_TRAMPOLINE+ebx*4]
		
		callfun	load_umode_selectors, 0
		
		popa
		iret





