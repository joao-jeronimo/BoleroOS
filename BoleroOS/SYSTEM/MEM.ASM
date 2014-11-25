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
;!      Purpose: Paging and memory management              !
;!      History: 21/06/2008 - Page frame allocator         !
;!               06/07/2008 - Allocate pages for user      !
;!                            mode stack.                  !
;!                                                         !
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


; ======================= Memory Pool Manager ========================
align 4
INITIAL_TOM		equ	((IMAGE_END+HIGH_ADDRESS-1) or ((8)-1))  +1
TOM_LIMIT		equ	HIGH_ADDRESS+512*MEBI
TOM				dd	INITIAL_TOM

function PoolInit, 0
		ret

; Allocate memory
;  In:	 ECX - number of q-words
;  Out:  EDI - address of allocated block
function PoolAlloc, expand_heap_rmask
		callfun	expand_heap, 0
		
		ret
		
function PoolFree, 0
		ret



; Helper routine
;  In:	 ECX - number of q-words
;  Out:  EDI - address of allocated block
function expand_heap, EAX_REG or EBX_REG or ECX_REG or EDX_REG or ESI_REG or EDI_REG or MakeMemAt_rmask
		mov		esi, [TOM]
		mov		edi, esi
		
		mov		eax, esi	; page being analised for presence
		shl		ecx, 3		; *8
		add		eax, ecx	; last page
		mov		edx, eax
		
		cmp		edx, TOM_LIMIT		; see if we are growing above the oficial limit...
		ja		.no_enough_space
		
		dec		eax
		shr		eax, PAGE_SIZE_LOG			; get page number of LAST needed page
		shr		esi, PAGE_SIZE_LOG			; get page number
		
		mov		ecx, PTENTRY_PRESENT or PTENTRY_RW or PTENTRY_SUPER
		; esi - index of page being analysed
		; eax - index of last page
		; ecx - used to pass permission mask to MakeMemAt
		; ebx - free for temps
		; edx - end address in case of success
		
	.loop:
		mov		ebx, esi
		shr		ebx, 10						; gets table number
		
		test	[PGDIR_ADDRESS+ebx*4], dword PTENTRY_PRESENT
		jz		.make_page
		
		test	[PGMAP_ADDRESS+esi*4], dword PTENTRY_PRESENT
		jz		.make_page
	.turn_back:
		
		inc		esi							; next page
		cmp		esi, eax
		jbe		.loop
		
		mov		[TOM], edx
		
		ret
		
  .make_page:
		shl		esi, PAGE_SIZE_LOG
		callfun	MakeMemAt, EDI_REG or ESI_REG or ECX_REG or EAX_REG or EDX_REG		; ecx - permission; esi - address
		shr		esi, PAGE_SIZE_LOG
		
		jmp		.turn_back
		
  .no_enough_space:
		mov		ebp, KERNEL_MESSAGES.no_space_for_heap
		callfun	klog, 0
		
		cli
		hlt
		jmp $



; ======================= Page Frame Allocator =======================
align 4
free_page_sp	dd	PGMAP_ADDRESS

; Put a page frame in the stack, thus marking it as free for allocation.
;  Input: EBX - page address (assumed to be aligned)
function MarkAsFree, EBP_REG
		
		mov		ebp, [free_page_sp]
		test	ebp, PAGE_SIZE-1	; Test if address is page aligned
		jz		.sp_page_aligned	; Forward jumps are predicted NOT to be taken.
									;  and most times the address will not be page aligned.
		
		sub		ebp, 4
  .page_present:					; Return here if found to be present when page aligned.
		mov		[ebp], ebx
		mov		[free_page_sp], ebp
		
		ret
		
		; Handles the case of when the pointer is page-aligned.
  .sp_page_aligned:
		push	eax ecx edi
		
		sub		ebp, 4
		mov		edi, ebp
		shr		edi, (PAGE_SIZE_LOG)							; Index into PGMAP
		mov		ecx, edi
		shr		ecx, 10											; Index into PGDIR
		test	[PGDIR_ADDRESS+ecx*4], dword PTENTRY_PRESENT	; See if page table is present
		jz		.put_in_pd
		
		test	[PGMAP_ADDRESS+edi*4], dword PTENTRY_PRESENT	; See if the page is present
		jz		.put_in_pt
		
		pop		edi ecx eax
		jmp		.page_present
		
  .put_in_pd:
		mov		eax, ebx
		or		eax, PTENTRY_PRESENT or PTENTRY_RW
		mov		[PGDIR_ADDRESS+ecx*4], eax
		
		xor		eax, eax
		lea		edi, [PGMAP_ADDRESS+edi*4]
		invlpg	[edi]
		and		edi, not (PAGE_SIZE-1)		; Round down
		mov		ecx, PAGE_SIZE/4
		cld									; Up
		rep		stosd
		
		pop		edi ecx eax
		ret
		
  .put_in_pt:
		mov		eax, ebx
		or		eax, PTENTRY_PRESENT or PTENTRY_RW
		mov		[PGMAP_ADDRESS+edi*4], eax
		invlpg	[ebp]
		
		pop		edi ecx eax
		ret

; Get page frame from stack.
;  Output: EBX - page address
function GetFreePage, EBP_REG
		mov		ebp, [free_page_sp]
		cmp		ebp, PGMAP_ADDRESS
		je		.no_memory_left
		
		mov		ebx, [ebp]
		add		ebp, 4
		mov		[free_page_sp], ebp
		
		ret
		
; For now, just hang...
.no_memory_left:
		mov		ebp, KERNEL_MESSAGES.no_memory_left
		callfun	klog, 0
		
		cli
		hlt
		jmp		$


; Maps some free page frame at address [ESI], so that it can be used to store things.
;  Input: ESI - address to make alive
;         ECX - permission (please set PRESENT-bit)
function MakeMemAt, EBX_REG or EDI_REG or EAX_REG or ECX_REG or GetFreePage_rmask
display "TODO: collect modifications to the page directory in a dedicated", FASM_NL
display "      buffer, so that we can work around kernel mode page faults.", FASM_NL
		
		shr		esi, PAGE_SIZE_LOG
		mov		eax, esi
		shr		eax, 10
		
		test	[PGDIR_ADDRESS+eax*4], dword PTENTRY_PRESENT
		jnz		.has_ptbl
		
		push	ecx
		
		callfun	GetFreePage, EAX_REG or ESI_REG		; ECX already saved above...
		or		ebx, PTENTRY_PRESENT or PTENTRY_RW or PTENTRY_USER		; Most permissive, cause most
		mov		[PGDIR_ADDRESS+eax*4], ebx								;  conservative overwride these.
		
		lea		edi, [PGMAP_ADDRESS+esi*4]
		invlpg	[edi]
		and		edi, not(PAGE_SIZE-1)
		mov		ecx, 1024
		clear	eax
		cld
		rep		stosd								; Zero that page...
		
		pop		ecx
		
	.has_ptbl:
		test	[PGMAP_ADDRESS+esi*4], dword PTENTRY_PRESENT
		jnz		.panic
		
		callfun	GetFreePage, ESI_REG
		or		ebx, ecx							; Merge requested permissions...
		mov		[PGMAP_ADDRESS+esi*4], ebx
		
		ret
		
  ; There is something wrong, cause we were asked to allocate a page
  ;  where there was already something maped.
  .panic:
		mov		ebp, KERNEL_MESSAGES.page_already_present
		callfun	klog, 0
		
		cli
		hlt
		jmp $

; Sees if there is anything mapped at some range.
;  Input: ESI - first (virtual) address to verify
;         EDI - last (virtual) address to verify
;  Output: CF set if non-existent page found. Unset otherwise.
function MemoryExistsAt, ESI_REG or EDI_REG or ECX_REG or EDX_REG		
		and		esi, not(PAGE_SIZE-1)		; Round down
		and		edi, not(PAGE_SIZE-1)		; Round down
		
		shr		edi, PAGE_SIZE_LOG
		shr		esi, PAGE_SIZE_LOG
		mov		edx, edi
		mov		ecx, esi
		shr		edi, 10
		shr		esi, 10
		
		lea		edi, [PGDIR_ADDRESS+edi*4]
		lea		esi, [PGDIR_ADDRESS+esi*4]
	.pd_loop:
		test	[esi], dword PTENTRY_PRESENT
		jz		.negative
		
		add		esi, 4
		cmp		esi, edi
		jbe		.pd_loop
		
		lea		edi, [PGMAP_ADDRESS+edx*4]
		lea		esi, [PGMAP_ADDRESS+ecx*4]
	.pm_loop:
		test	[esi], dword PTENTRY_PRESENT
		jz		.negative
		
		add		esi, 4
		cmp		esi, edi
		jbe		.pm_loop
		
		clc
		ret
		
	.negative:
		stc
		ret

align 4
DemandMappedTop		dd	TOM_LIMIT

; Maps requested physical range somewhere, so that we can access it.
;  Input: ESI - first needed (physical) address
;         EDI - last needed (physical) address
; Output: EBP - start (virtual) address of mapped range
function MapPhysicalRange, EAX_REG or EBX_REG or ECX_REG or EDX_REG or ESI_REG or EDI_REG or EBP_REG or GetFreePage_rmask
		mov		ebp, esi
		and		ebp, PAGE_SIZE-1
		
		and		esi, not (PAGE_SIZE-1)
		and		edi, not (PAGE_SIZE-1)
		
		mov		ecx, [DemandMappedTop]
		
		mov		edx, edi
		sub		edx, esi
		shr		edx, PAGE_SIZE_LOG+10		; Amount of page tables to map in EDX now
		
		add		ebp, ecx					; This gets final return value into EBP
		mov		eax, ecx
		shr		eax, PAGE_SIZE_LOG+10
		add		edx, eax
		
		; Context:
		;  EAX - index of first page table
		;  EDX - index of last page table
		;  ECX - copy of [DemandMappedTop]
		;  EBX - reserved to receive return from GetFreePage
		;  ESI and EDI - start and end physical addresses
		
	.pd_loop:
		test	[PGDIR_ADDRESS+eax*4], dword PTENTRY_PRESENT
		jnz		@f
		
		callfun	GetFreePage, EAX_REG or EDX_REG or ECX_REG or ESI_REG or EDI_REG or EBP_REG
		or		ebx, PTENTRY_PRESENT or PTENTRY_RW or PTENTRY_SUPER
		mov		[PGDIR_ADDRESS+eax*4], ebx
		shl		eax, PAGE_SIZE_LOG
		invlpg	[PGMAP_ADDRESS+eax]
		shr		eax, PAGE_SIZE_LOG
		
	@@:	inc		eax
		cmp		eax, edx
		jbe		.pd_loop
		
		
		
		or		esi, PTENTRY_PRESENT or PTENTRY_RW or PTENTRY_SUPER
		shr		ecx, PAGE_SIZE_LOG
		
	.pm_loop:
		mov		[PGMAP_ADDRESS+ecx*4], esi
		
		inc		ecx
		add		esi, PAGE_SIZE
		cmp		esi, edi
		jbe		.pm_loop
		
		
		; Update DemandMappedTop
		shl		ecx, PAGE_SIZE_LOG
		mov		[DemandMappedTop], ecx
		
		ret
display "WARNING: MapPhysicalRange lacks error checking and its code is really ugly!", FASM_NL



; ****************************
; Page fault exception handler
;  Implemented:
;   Allocate pages for user mode stack.
PAGE_FAULT_EXC:
		pushad
		
		callfun	load_kmode_selectors, 0
		
		; See whether the page fault occured in a present page
		test	[esp+8*4], dword (1 shl 0)
		jnz		.fatal
		
		; Get faulty address
		mov		eax, cr2
		
		; See if it is is the range of the app stack
		mov		ebx, [current_thread]
		cmp		eax, INITIAL_USER_STACK
		ja		.fatal
		mov		ecx, [ebx+THREAD.process]
		mov		ebx, [ecx+PROC.stack_bottom]
		cmp		eax, ebx
		jb		.fatal
		
		mov		esi, eax
		mov		ecx, PTENTRY_PRESENT or PTENTRY_USER or PTENTRY_RW
		callfun	MakeMemAt, 0
		
		popad					; Pop registers
		add		esp, 4			; Pop error code
		
		iret
		
	.fatal:
		mov		ebp, KERNEL_MESSAGES.page_fault
		callfun	klog, 0
		
		cli
		hlt
		jmp $






