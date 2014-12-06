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
;!      Purpose: Main kernel initialization procedure      !
;!      History: 01/07/2008 - init_kernel                  !
;!                                                         !
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


init_kernel:
		callfun	Dbg_init, 0
		
		mov		ebp, KERNEL_MESSAGES.cpu_init_done
		callfun	klog, 0
		
		callfun	SchedInit, 0
		callfun	PicInit, 0
		
		; Initializing drivers
		callfun	KbdInit, 0
		
		mov		edi, prog1
		mov		edx, prog1.size
		callfun	TempRun, 0
		
		;mov		[klog.dbg_to_screen], 0	; Stop debugging to the screen
		
		mov		eax, [current_thread]
		mov		[fore_thread], eax
		mov		ebx, [eax+THREAD.kmstack]
		mov		[TSS.esp0], ebx				; Fix the kernel mode stack place
		mov		esp, [eax+THREAD.stack]
		ret
		
		jmp $




