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
;!      Purpose: Support routines for Human                !
;!               Interface Devices                         !
;!      History: 13/08/2008 - Key delivery to processes    !
;!                                                         !
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!



; Delivers one key to the current foreground process.
;  Input: ECX - char received
function DeliverKey, EAX_REG or EBP_REG or ESI_REG or EDI_REG or WakeUp_rmask or WriteDecU_rmask or klog_rmask
		;mov		eax, ecx
		;and		eax, (1 shl 21)-1
		;mov		ebp, .charbuff
		;callfun	WriteDecU, ECX_REG
		;
		;callfun	klog, ECX_REG
		
		mov		eax, [fore_thread]
		mov		ebx, [eax+THREAD.process]
		
		; Discard key if the foreground thread isn't waiting for chars
		cmp		[ebx+PROC.kbd_wait_thread], eax
		jne		.ret
		
		mov		esi, [ebx+PROC.kbd_oldest]
		mov		edi, [ebx+PROC.kbd_newest]
		mov		ebp, esi
		sub		ebp, edi			; If (ESI-EDI)=-1, then the buffer is full
		inc		ebp					;  (not -1 == 0)
		jz		.ret
		
		dec		edi
		jns		.not_wrapped_arround	; Jump if not sign (i.e. not negative)
		add		edi, TYPEAHEAD_SIZE
		cmp		edi, esi			; If the queue wrapped arround, we need to see
		je		.ret				;  if it is full, cause the previous test
	.not_wrapped_arround:			;  doesn't work for this corner case.
		
		lea		ebp, [ebx+PROC.kbd_queue]
		mov		[ebp+edi*4], ecx
		mov		[ebx+PROC.kbd_newest], edi
		
		cmp		[eax+THREAD.state], THREAD_EVENT_WAIT
		jne		.ret
		
		callfun	WakeUp, 0
		
	.ret:
		ret
		
	;.charbuff	db	"           "

; Returns last virtual key code in EAX and corresponding char code in EBX.
syscall GetKey
		mov		[ebp+UM_EAX_ON_STACK], -1
		mov		[ebp+UM_EBX_ON_STACK], -1
		
		mov		eax, [fore_thread]			; Get foreground thread
		
		mov		ebx, [eax+THREAD.process]	; Get corresponding process
		cmp		eax, [ebx+PROC.kbd_wait_thread]
		jne		.ret
		
		mov		ecx, [ebx+PROC.kbd_oldest]
		cmp		[ebx+PROC.kbd_newest], ecx
		je		.ret						; Return if the queue is empty
		
		dec		ecx
		jns		.not_wrapped_arround		; Jump if not sign (i.e. not negative)
		add		ecx, TYPEAHEAD_SIZE
	.not_wrapped_arround:
		
		mov		[ebx+PROC.kbd_oldest], ecx
		lea		edx, [ebx+PROC.kbd_queue]
		mov		esi, [edx+ecx*4]
		
		; Key code now in ESI
		mov		[ebp+UM_EAX_ON_STACK], esi
		
		; Ignore translation for break codes
		test	esi, 1 shl 31
		jnz		.ret
		
		mov		edi, esi
		and		edi, (1 shl 21)-1
		cmp		edi, N_TRANS_KEYS
		jae		.ret
		callfun	TranslateVK2UNIC, 0
		
		mov		[ebp+UM_EBX_ON_STACK], edi
		
	.ret:
		ret


; Input:  ESI - virtual key code
; Output: EDI - Unicode character number
function TranslateVK2UNIC, ESI_REG or EDI_REG or EDX_REG
		; Algorithm:
		;  - Get the char from the correct look-up table.
		;  - If it's a letter, apply the Upper bit.
		;  - If it's among the dead key table, save it and return -1.
		;  - If there's a dead key awaiting, search the last char
		;    in the corresponding sub-table:
		;     . If not found, return -1 (i.e. discard the latter).
		;     . If found, return the resulting gliph.
		;     . (note: before returning, reset the dead-await variable)
		
		test	esi, (11b shl 22)			; See if any shift down
		jz		.no_shift_down
		mov		edi, VK2UNI_shift
		jmp		.do_trans
	.no_shift_down:
		test	esi, (1b shl 27)			; See if AltGr down
		jz		.not_altgr
		mov		edi, VK2UNI_altgr
		jmp		.do_trans
	.not_altgr:
		mov		edi, VK2UNI_normal
		;jmp		.do_trans
	.do_trans:
		
		mov		edx, esi
		and		esi, (1 shl 21)-1			; Mask out the flags
		movzx	edi, word [edi+esi*2]
		
		; Char code now in EDI (lower case if letter)
		cmp		edi, 'z'
		ja		.not_a_letter
		cmp		edi, 'a'
		jb		.not_a_letter
		and		edx, (1 shl 21)				; Get Upper bit
		shr		edx, 21-5					; The idea now is unsetting bit 5, so
		not		edx							;  that the letter becomes upper case.
		and		edi, edx
	.not_a_letter:
		
		; See whether we have a pending dead key
		cmp		[.last_dead], 0
		jnz		.dead_pending
		
		; See whether this key is dead
		mov		esi, DEAD_KEYS
	.search_in_dead_tbl:
		cmp		[esi], dword 0
		jz		@f
		cmp		[esi], edi					; See if this char is here...
		je		.save_deadkey
		add		esi, 4+4
		jmp		.search_in_dead_tbl
	@@:	
		
		ret
		
  .dead_pending:
		mov		[.last_dead], 0
		
		mov		esi, [.dead_subtbl]
	.search_in_dead_subtbl:
		cmp		[esi], dword 0
		jz		@f
		cmp		[esi], edi					; See if this char is here...
		je		.found_deadtrans
		add		esi, 4+4
		jmp		.search_in_dead_subtbl
	@@:	
		mov		edi, -1
		ret
		
	; pre: ESI point to the character found...
	.found_deadtrans:
		mov		edi, [esi+4]
		ret
		
  .save_deadkey:
		mov		[.last_dead], edi
		mov		esi, [esi+4]
		mov		[.dead_subtbl], esi
		mov		edi, -1						; The thread doesn't see the dead key...
		ret

align 4
.last_dead		dd	0
.dead_subtbl	dd	?







