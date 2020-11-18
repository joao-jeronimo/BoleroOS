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
;!      Purpose: Basic CPU Initialization, phase 2         !
;!      History: ??/06/2008 - created                      !
;!                                                         !
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


higher_half_entry:
		mov		ebp, KERNEL_MESSAGES.init_paging
		callfun	puts, 0
		
		mov		eax, [BOOTUP_DATA.mem_map_addr]
		xor		ebx, ebx
		
  .mem_map_lp:
		cmp		[eax], dword FREE_MEMORY_DESC
		je		.found_free_mem
		cmp		[eax], dword EOM_DESC
		je		.mem_map_lp_end
		add		ebx, [eax+4]
		jc		.mem_map_lp_end
		cmp		[eax+8], dword 0
		jnz		.mem_map_lp_end
		add		eax, 4+8
		jmp		.mem_map_lp
  .found_free_mem:
		
		; Now we need to mark as free every page refered to by this block
		; Computing the block end
		mov		ebp, [eax+4]
		add		ebp, ebx
		jc		.above_32_bit			; See if memory is too big
		
		and		ebp, not (PAGE_SIZE-1)	; Round it DOWN
		
		cmp		[eax+8], dword 0		; Test high dword
		jz		.in_32bit_mem			; See if memory is too big
		
  .above_32_bit:
		mov		ebp, 4*GIBI-PAGE_SIZE	; Alloc everything but very last
										;  page in that case.
		
  .in_32bit_mem:
		dec		ebx						; Force EBX page-aligned
		or		ebx, PAGE_SIZE-1
		inc		ebx
		
  .mark_pages_lp:
		cmp		ebx, ebp
		jnb		.mark_pages_lp_end
		callfun	MarkAsFree, EBP_REG
		add		ebx, PAGE_SIZE
		
		jmp		.mark_pages_lp
  .mark_pages_lp_end:
		
		add		eax, 4+8
		jmp		.mem_map_lp
		
  .mem_map_lp_end:
		
		mov		ebp, KERNEL_MESSAGES.init_pageframe_allocator
		callfun	puts, 0
		
		mov		eax, SYSTEM_TSS
		ltr		ax
		
		mov		ebp, KERNEL_MESSAGES.init_tss
		callfun	puts, 0
		
		; A bit of env cleanup now
		; The pages taken by the memory map
		mov		edx, [BOOTUP_DATA.mem_map_addr-LOAD_ADDRESS+HIGH_ADDRESS]
		mov		ecx, edx
	@@:	add		ecx, 8+4
		cmp		[ecx], dword EOM_DESC
		jne		@b
		
		and		edx, not (PAGE_SIZE-1)	; Page align the begin of memory map
		and		ecx, not (PAGE_SIZE-1)	;  and the same for the end of it.
		
		mov		ebx, edx
	@@:	callfun	MarkAsFree, EBX_REG or ECX_REG
		add		ebx, PAGE_SIZE
		cmp		ebx, ecx
		jbe		@b
		
		; Discard the first page table
		mov		ecx, PGDIR_ADDRESS
		mov		ebx, [ecx]
		mov		[ecx], dword 0
		callfun	MarkAsFree, 0
		mov		eax, cr3
		mov		cr3, eax				; Reloand CR3 to avoid problems...
		
		; IDT
		push	dword IDT
		push	word IDT.limit
		lidt	[esp]
		add		esp, 4+2
		
		
		mov		[klog.dbg_to_screen], 1	; Configure klog to write debug info to the screen
		
		
		jmp		init_kernel
		jmp		$









RUNTIME_ERROR_EXC:
		callfun	load_kmode_selectors, 0
		
		mov		ebp, KERNEL_MESSAGES.runtime_error
		callfun	klog, 0
		
		cli
		hlt
		jmp $

DOUBLE_FAULT_EXC:
		callfun	load_kmode_selectors, 0
		
		mov		ebp, KERNEL_MESSAGES.double_fault
		callfun	klog, 0
		
		cli
		hlt
		jmp $

GPF_EXC:
		callfun	load_kmode_selectors, 0
		
		mov		ebp, KERNEL_MESSAGES.gen_prot_fault
		callfun	klog, 0
		
		cli
		hlt
		jmp $




IDT:
	int_gate	KCODESEG, RUNTIME_ERROR_EXC, 3		;  0 - Divide by zero
	dd			0,0									;  1 - Single Step
	dd			0,0									;  2 - NMI (ABORT)
	dd			0,0									;  3 - Breakpoint
	dd			0,0									;  4 - Overflow
	dd			0,0									;  5 - BOUND
	int_gate	KCODESEG, RUNTIME_ERROR_EXC, 3		;  6 - Invalid opcode
	dd			0,0									;  7 - x86 not available
	int_gate	KCODESEG, DOUBLE_FAULT_EXC, 3		;  8 - Double fault (ABORT)
	dd			0,0									;  9 - Coprocessor segment overrun (ABORT)
	dd			0,0									; 10 - Invalid TSS
	dd			0,0									; 11 - Segment not present
	dd			0,0									; 12 - Stack exception
	int_gate	KCODESEG, GPF_EXC, 3				; 13 - General Protection Fault
	int_gate	KCODESEG, PAGE_FAULT_EXC, 3			; 14 - Page Fault
	dd			0,0									; 15 -  reserved
	dd			0,0									; 16 - x87 exception pending (???)
	dd			0,0									; 17 - Alignement error (only if enabled)
	dd			0,0									; 18 - MCE (only if enabled)
	dd			0,0									; 19 - SIMD
	dd			0,0									; 20 -  reserved
	dd			0,0									; 21 -  reserved
	dd			0,0									; 22 -  reserved
	dd			0,0									; 23 -  reserved
	dd			0,0									; 24 -  reserved
	dd			0,0									; 25 -  reserved
	dd			0,0									; 26 -  reserved
	dd			0,0									; 27 -  reserved
	dd			0,0									; 28 -  reserved
	dd			0,0									; 29 -  reserved
	dd			0,0									; 30 - Security
	dd			0,0									; 31 -  reserved

	;IRQs from 1st PIC
	dd			0,0									; 32 - 
	int_gate	KCODESEG, KBD_ISR, 3				; 33 - IRQ1: Keyboard
	dd			0,0									; 34 - 
	dd			0,0									; 35 - 
	dd			0,0									; 36 - 
	dd			0,0									; 37 - 
	dd			0,0									; 38 - 
	dd			0,0									; 39 - 
	;IRQs from 2nd PIC
	dd			0,0									; 40 - 
	dd			0,0									; 41 - 
	dd			0,0									; 42 - 
	dd			0,0									; 43 - 
	dd			0,0									; 44 - 
	dd			0,0									; 45 - 
	dd			0,0									; 46 - 
	dd			0,0									; 47 - 

	int_gate	KCODESEG, INT_SYSCALL, 3			; 48 - Kernel Mode entry point for system calls

	.limit = $-IDT-1


GDT:
	dd 0,0												;NULL entry
	
	; Supervisor segments
	gdt_entry   0x00000000,	0xFFFFF,	10011010b,	0xC0	; Ring 0, code, non-conforming, readable
	gdt_entry   0x00000000,	0xFFFFF,	10010010b,	0xC0	; Ring 0, data, expand-up, r/w
	
	; User segments
	gdt_entry   0x00000000,	0xFFFFF,	11111010b,	0xC0	; Ring 3, code, non-conforming, readable
	gdt_entry   0x00000000,	0xFFFFF,	11110010b,	0xC0	; Ring 3, data, expand-up, r/w
	
	; TSS
	gdt_entry   TSS,		TSS.limit,	10001001b,	0x00	; Granularity is 1 byte
	
	.limit = $-GDT-1


TSS:
 .backlink:	dw	0			; Back link not needed for sure...
			dw	0			; reserved
			
			; Ring 0
	 .esp0:	dd	?
	  .ss0:	dw	KDATASEG
			dw	0			; reserved
			; Ring 1
	 .esp1:	dd	0
	  .ss1:	dw	0
			dw	0
			; Ring 2
	 .esp2:	dd	0
	  .ss2:	dw	0
			dw	0
			
	  .cr3:	dd	0			; INITIALIZE AT RUNTIME...
			
			; EIP, EFLAGS, GPR, Segment and LDT registers
   times 17	dd	0
			
			dw	0			; reserved
			dw	.limit+1	; IOPB offset

	.limit = $-TSS-1








