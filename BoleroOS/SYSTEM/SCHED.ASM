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
;!      Purpose: Process and thread management             !
;!      History: 01/07/2008 - Created                      !
;!                                                         !
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

TYPEAHEAD_SIZE		equ	8	; Keys are queued and delivered in a special "virtual key" format,
							;  aiming for keyboard interoperability. Each virtual key occupies 1 dword.

THREAD_RUNNING		equ	0
THREAD_IO_WAIT		equ	1
THREAD_EVENT_WAIT	equ	2


virtual at 0
	PROC:
	 .pid				dd	?
	 .first_exec_thread	dd	?	; Thread that appears first in the list of running processes
	 .stack_bottom		dd	?	; Address of stack for next thread of this process to be created
	 .cr3				dd	?	; CR3 for this process
	 .threads			dd	?	; List that links together all threads of the process
	 
	 .exit_requests		dd	?	; Number of exit requests
	 .exit_wait_thread	dd	?	; Thread that is monitoring the exit event
	 
	 .kbd_queue:		times 8 dd ?
	 .kbd_oldest		dd	?	; Queue for keyboard data
	 .kbd_newest		dd	?
	 .kbd_wait_thread	dd	?	; Thread that is monitoring the kbd event
	 
	 .next				dd	?

  .size = (($-1)or(8-1))+1		; q-word aligned
end virtual

virtual at 0
	THREAD:
	 .process		dd	?
	 .stack			dd	?		; Suspended stack saved here when yielding
	 .kmstack		dd	?		; To patch the TSS when awaikening
	 .state			dd	?		; Running, waiting for i/o or waiting for event
	 
	 ; Links to the various linked-lists the thread may be on.
	 .proc_next		dd	?		; List of threads of the process (every thread is in one)
	 .sleep_next	dd	?		; List for some semaphore-guarded resource
	 .exec_previous	dd	?		; Circular doubly-linked list of
	 .exec_next		dd	?		;   processes waiting to be ran.

  .size = (($-1)or(8-1))+1		; q-word aligned
end virtual

align 4
; Size of process hash table
HASH_SIZE		equ		11
HASH_MOD		dd		HASH_SIZE
; Process (hashed) table
PROC_TABLE:
	times HASH_SIZE	dd 0

running_threads	dd	0
current_thread	dd	0		; this value is ignored when there are no threads running
current_cr3		dd	?		; we have to initialize this
last_PID		dd	0		; last used PID number

fore_thread		dd	?		; Current foreground thread


function SchedInit, EAX_REG
		mov		eax, cr3
		mov		[current_cr3], eax
		
		ret

; Hashes ECX according to (4*n) mod HASH_MOD
;   Input: ECX - PID to hash
;  Output: ECX - result of applying hash function
function PROC_hash, EAX_REG or EDX_REG or ECX_REG
		shl		ecx, 2
		mov		eax, ecx
		clear	edx
		div		[HASH_MOD]
		
		mov		ecx, edx
		
		ret


INITIAL_USER_STACK		equ	HIGH_ADDRESS		; Start creating user stacks just below the kernel
DEFAULT_UMSTACK_SIZE	equ	PAGE_SIZE			; Just one page for now...
DEFAULT_KMSTACK_SIZE	equ	PAGE_SIZE			; Just one page for now...

; Temporary routine. Copies memory buffer into user mode process
; space and creates default thread.
; Note: please provide an address space which has nothing mapped
;       below 3GB (i.e. user space). This routine does it's job
;       in the address space currently on CPU.
;  Inputs: EDI - buffer start
;          EDX - buffer size
; Outputs: Nothing
function TempRun, EBX_REG or ECX_REG or ESI_REG or EDI_REG or MakeMemAt_rmask or PoolAlloc_rmask or PROC_hash_rmask
		; First, make memory at user space
		mov		ebx, edx
		dec		ebx
		and		ebx, not(PAGE_SIZE-1)
		
		clear	esi
	.loop:
		mov		ecx, PTENTRY_PRESENT or PTENTRY_USER or PTENTRY_RW
		callfun	MakeMemAt, ESI_REG or EDI_REG or EDX_REG or EBX_REG
		
		add		esi, PAGE_SIZE
		cmp		esi, ebx
		jbe		.loop
		
		; Now, copy image
		mov		ecx, edx
		mov		esi, edi
		clear	edi
		cld
		rep		movsb
		
		; ****************************************
		; Create process structure
		; This is complicated:
		;  - Allocate memory for process structure
		;  - Fill it in
		;  - Get next free PID
		;  - Increment it. If carry out, hang (latter, we'll have
		;    to handle this better)
		;  - Save updated number back, hash it, add structure to
		;    the start of the linked list
		mov		ecx, PROC.size/8
		callfun	PoolAlloc, 0
		
		mov		[edi+PROC.stack_bottom], INITIAL_USER_STACK - DEFAULT_UMSTACK_SIZE - DEFAULT_KMSTACK_SIZE
		mov		esi, cr3					; We are loading the address space currently
		mov		[edi+PROC.cr3], esi			;  on CPU, not that of the currently running thread.
		
		mov		[edi+PROC.exit_requests], 0
		mov		[edi+PROC.exit_wait_thread], 0
		
		mov		[edi+PROC.kbd_queue+0*4], dword 0
		mov		[edi+PROC.kbd_queue+1*4], dword 0
		mov		[edi+PROC.kbd_queue+2*4], dword 0
		mov		[edi+PROC.kbd_queue+3*4], dword 0
		mov		[edi+PROC.kbd_queue+4*4], dword 0
		mov		[edi+PROC.kbd_queue+5*4], dword 0
		mov		[edi+PROC.kbd_queue+6*4], dword 0
		mov		[edi+PROC.kbd_queue+7*4], dword 0
		mov		[edi+PROC.kbd_oldest], 0
		mov		[edi+PROC.kbd_newest], 0
		mov		[edi+PROC.kbd_wait_thread], 0
		
		; Note: .first_exec_thread and .threads are filled shortly latter
		
		mov		ecx, [last_PID]
		inc		ecx
		jc		.carry_out_panic
		mov		[edi+PROC.pid], ecx
		mov		[last_PID], ecx
		
		; Apply hash
		callfun	PROC_hash, EDI_REG
		
		; Add it to table
		mov		ebx, [PROC_TABLE+ecx*4]
		mov		[edi+PROC.next], ebx
		mov		[PROC_TABLE+ecx*4], edi
		
		; ****************************************
		; Create thread
		mov		esi, edi
		mov		ecx, THREAD.size/8
		callfun	PoolAlloc, ESI_REG
		
		mov		[esi+PROC.first_exec_thread], edi
		mov		[esi+PROC.threads], edi
		
		mov		[edi+THREAD.process], esi
		; .stack is to be setup a bit later...
		mov		[edi+THREAD.kmstack], INITIAL_USER_STACK - DEFAULT_UMSTACK_SIZE
		mov		[edi+THREAD.state], THREAD_RUNNING
		
		mov		[edi+THREAD.proc_next], 0
		
		
		mov		ebx, [running_threads]
		test	ebx, ebx				; Don't smash EBX, please...
		jz		.no_thread_running
		
		; Get first running thread of current process
		; (just a place to allocate our new thread, nothing more)
		mov		ecx, [current_thread]
		mov		esi, [ecx+THREAD.process]
		mov		ecx, [esi+PROC.first_exec_thread]
		; Context (not now, but 2 lines later):
		;  EDI - thread being added
		;  ESI - thread that will be linked before the new one
		;  ECX - thread that will be linked after the new one
		mov		[edi+THREAD.exec_next], ecx		; setup .next field for new thread
		mov 	esi, [ecx+THREAD.exec_previous]	; get "former" previous
		mov		[ecx+THREAD.exec_previous], edi	; setup .previous field for next thread
		mov		[edi+THREAD.exec_previous], esi	; .previour field of new thread
		mov		[esi+THREAD.exec_next], edi		; .next filed of former previous
		
		jmp		.continue
		
	.no_thread_running:
		mov		[edi+THREAD.exec_previous], edi
		mov		[edi+THREAD.exec_next], edi
		
		mov		[current_thread], edi			; Next thread becomes new running thread
		
		;jmp		.continue
		
	.continue:
		inc		ebx
		mov		[running_threads], ebx			; save back updated number of threads
		
		; Make pages for UM stack
		mov		esi, INITIAL_USER_STACK - DEFAULT_UMSTACK_SIZE - PAGE_SIZE
		mov		ecx, PTENTRY_PRESENT or PTENTRY_SUPER or PTENTRY_RW
		callfun	MakeMemAt, EDI_REG
		
		; Set ESI to the start of the kernel-mode stack
		mov		esi, INITIAL_USER_STACK - DEFAULT_UMSTACK_SIZE
		; Construct Ring-switch stack layout to enable going to user mode
		sub		esi, 4
		mov		[esi], dword UDATASEG					; SS
		sub		esi, 4
		mov		[esi], dword INITIAL_USER_STACK			; ESP - Stay at same place when doing the stack "switch"
		sub		esi, 4
		mov		[esi], dword 0x00000202					; EFLAGS - IF=1, IOPL=0, VM=0
		sub		esi, 4
		mov		[esi], dword UCODESEG					; CS
		sub		esi, 4
		mov		[esi], dword 0							; EIP - start executing at 0 (will be altered in the future)
		sub		esi, 4
		mov		[esi], dword new_thread_stub			; Address of stub for new threads
		mov		[edi+THREAD.stack], esi
		
		ret
		
  .carry_out_panic:
		mov		ebp, KERNEL_MESSAGES.pid_carry_out
		callfun	klog, 0
		
		cli
		hlt
		jmp $



new_thread_stub:
		callfun	load_umode_selectors, 0
		
		iret

; Temporary implementations.
function Yield, 0
		ret
function SleepYield, 0
		mov		[.is_sleeping], 1
		sti
	@@:	cmp		[.is_sleeping], 0
		jne		@b
		cli
		ret
align 4
 .is_sleeping dd 0

; Wakes a thread up.
;  Input: EAX - pointer to thread to wake up.
function WakeUp, 0
		mov		[SleepYield.is_sleeping], 0
		ret




syscall ConfigEvents
		mov		eax, [current_thread]
		mov		ebx, [eax+THREAD.process]
		
		cmp		[ebp+UM_EAX_ON_STACK], 0
		je		.Get
		
 .Set:	
		mov		ecx, [ebp+UM_EBX_ON_STACK]
		
		test	ecx, (1 shl 0)
		jz		.unset_exit
		; Exit = 1
		; If there's someone already on that event, ignore the request
		cmp		[ebx+PROC.exit_wait_thread], 0
		jne		@f
		mov		[ebx+PROC.exit_wait_thread], eax
		jmp		@f
	.unset_exit:
		; Exit = 0
		cmp		[ebx+PROC.exit_wait_thread], eax
		jne		@f
		mov		[ebx+PROC.exit_wait_thread], 0
		@@:
		
		
		test	ecx, (1 shl 1)
		jz		.unset_kbd
		; KBD = 1
		; If there's someone already on that event, ignore the request
		cmp		[ebx+PROC.kbd_wait_thread], 0
		jnz		@f
		mov		[ebx+PROC.kbd_wait_thread], eax
		jmp		@f
	.unset_kbd:
		; KBD = 0
		cmp		[ebx+PROC.kbd_wait_thread], eax
		jne		@f
		mov		[ebx+PROC.kbd_wait_thread], 0
		@@:
		
		ret
		
 .Get:
		clear	ebx
		cmp		[ebx+PROC.exit_wait_thread], eax
		jne		@f
		or		ebx, (1 shl 0)
	@@:	cmp		[ebx+PROC.kbd_wait_thread], eax
		jne		@f
		or		ebx, (1 shl 1)
	@@:	mov		[ebp+UM_EBX_ON_STACK], ebx
		ret


syscall WaitForEvent
		mov		eax, [current_thread]
		mov		ebx, [eax+THREAD.process]
		
		; Is there any pending exit event?
		cmp		[ebx+PROC.exit_wait_thread], eax
		jne		@f
		cmp		[ebx+PROC.exit_requests], 0
		jnz		.return_exit
	@@:	
		
		; Is there any pending keyboard event?
		cmp		[ebx+PROC.kbd_wait_thread], eax
		jne		@f
		mov		ecx, [ebx+PROC.kbd_newest]
		cmp		[ebx+PROC.kbd_oldest], ecx
		jne		.return_kbd
	@@:	
		
		mov		[eax+THREAD.state], THREAD_EVENT_WAIT
		
		
		callfun	SleepYield, 0					; Sleep & Yield
		
		
		; See if it was an exit event.
		cmp		[ebx+PROC.exit_wait_thread], eax
		jne		@f
		cmp		[ebx+PROC.exit_requests], 0
		jnz		.return_exit
	@@:	
		
		; See if it was a keyboard event.
		cmp		[ebx+PROC.kbd_wait_thread], eax
		jne		@f
		mov		ecx, [ebx+PROC.kbd_newest]
		cmp		[ebx+PROC.kbd_oldest], ecx
		jne		.return_kbd
	@@:	
		
		mov		ebp, KERNEL_MESSAGES.event_delivery_bug
		callfun	klog, 0
		cli
		hlt
		jmp $
		
	.return_exit:
		dec		[ebx+PROC.exit_requests]
		mov		[ebp+UM_EAX_ON_STACK], 0
		ret
		
	.return_kbd:
		mov		[ebp+UM_EAX_ON_STACK], 1
		ret













function load_kmode_selectors, EAX_REG
		mov		eax, KDATASEG
		mov		ds, ax
		mov		es, ax
		mov		fs, ax
		mov		gs, ax
		
		ret

function load_umode_selectors, EAX_REG
		mov		eax, UDATASEG
		mov		ds, ax
		mov		es, ax
		mov		fs, ax
		mov		gs, ax
		
		ret











