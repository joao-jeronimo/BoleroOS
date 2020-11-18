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
;!      Purpose: Basic CPU Initialization, phase 1         !
;!      History: ??/06/2008 - created                      !
;!                                                         !
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


BOOTUP_DATA:
 .welcome_msg		db	"Welcome to BoleroOS", 0
 .mem_map_addr		dd	0
 .page_directory	dd	0

BOOTUP_ERRORS:
 .magic_error_msg		db	"BoleroOS: Magic number is wrong!", 0
 .no_enought_space_msg	db	"BoleroOS: No enought space for basic system initialization!", 0
 .MAGIC_ERROR:
		mov		eax, 0x07000700
		mov		edi, 0xB8000
		mov		ecx, (80*25*2)/4
		rep		stosd
		mov		ebp, .magic_error_msg
		callfun	puts, 0
		jmp		$
 .ALLOC_ERROR:
		mov		ebp, .no_enought_space_msg
		callfun	puts, 0
		jmp		$


display "Start at: "
printaddr start
display 10, 13

start:
		cmp		ebx, 0x534F5A49
		jne		BOOTUP_ERRORS.MAGIC_ERROR
		
		; This may seem stupid, but for some
		;  reason the Nested Task flag may be set on entry, so...
		pushfd
		pop		eax
		and		eax, not(1 shl 14)
		push	eax
		popfd
		
		mov		ecx, [ecx]
		mov		[BOOTUP_DATA.mem_map_addr], ecx
		
		mov		eax, 0x07000700
		mov		edi, 0xB8000
		mov		ecx, (80*25*2)/4
		rep		stosd
		
		mov		ebp, BOOTUP_DATA.welcome_msg
		callfun	puts, ECX_REG
		
		; Map kernel high
		mov		esi, LOAD_ADDRESS
		mov		edi, HIGH_ADDRESS
		mov		ebp, IMAGE_END-IMAGE_START
		dec		ebp					; Aligning kernel end address
		shr		ebp, PAGE_SIZE_LOG
		inc		ebp
	.map_kernel_lp:
		callfun	MAP_PAGE_4KB, EBP_REG or ESI_REG or EDI_REG
		add		esi, PAGE_SIZE
		add		edi, PAGE_SIZE
		dec		ebp
		jnz		.map_kernel_lp
		
		; Identity map this page
		mov		esi, LOAD_ADDRESS
		mov		edi, esi
		callfun	MAP_PAGE_4KB, 0
		
		; Find end of memory map
		mov		eax, [BOOTUP_DATA.mem_map_addr]
		mov		esi, eax
		mov		edi, eax
	.memory_map_end_lp:
		add		eax, 4+8
		cmp		[eax-4-8], dword EOM_DESC
		jne		.memory_map_end_lp
		
		; Identity map it
	.map_memmap_lp:
		callfun	MAP_PAGE_4KB, EAX_REG or ESI_REG or EDI_REG
		add		esi, PAGE_SIZE
		add		edi, PAGE_SIZE
		cmp		esi, eax
		jb		.map_memmap_lp
		
		; Map VGA so that we can talk to the user
		mov		esi, 0xB8000
		mov		edi, esi
		callfun	MAP_PAGE_4KB, 0
		
		; Make last page directory entry point to the PD itself
		mov		eax, [BOOTUP_DATA.page_directory]
		mov		[eax+(1024-1)*4], dword eax
		or		[eax+(1024-1)*4], dword 111b		; Present, supervisor, read/write
		
		; Load cr3
		mov		eax, [BOOTUP_DATA.page_directory]
		mov		cr3, eax
		
		; Now enable paging
		mov		eax, cr0
		or		eax, 1 shl 31
		mov		cr0, eax
		
		; We are barely ready. Let's just configure
		;  the stack and the GDT.
		mov		esp, KERNEL_STACKTOP
		
		; Now, the GDT
		push	dword GDT
		push	word GDT.limit
		lgdt	[esp]
		add		esp, 4+2
		
		mov		ax, KDATASEG
		mov		ds, ax
		mov		es, ax
		mov		fs, ax
		mov		gs, ax
		mov		ss, ax
		
		jmp		KCODESEG:higher_half_entry
		
		jmp		$




; EBP - String
function puts, EAX_REG or EBP_REG or EDI_REG
   .VGA_TXT	equ 0xB8000
			
			mov		edi, [.vga_offset]
			add		edi, .VGA_TXT
			mov		eax, 0x0700
			
			; Write chars to screen
		@@:	mov		al, [ebp]
			test	al, al
			jz		.updt_cur
			
			stosw
			inc		ebp
			
			jmp		@b
			
 .updt_cur:	sub		edi, .VGA_TXT
			
			; Advance to next line (add 80 chars each time
			;  until we land after the line just written)
		@@:	add		[.vga_offset], dword 160	; Advance 80 chars (attr+ASCII code)
			cmp		[.vga_offset], edi
			jb		@b
			
			ret

 .vga_offset	dd  0










; Maps page frame at address ESI to virtual page at address EDI...
; Only for supporting 4KB pages... (fairly portable thing...)
function MAP_PAGE_4KB, EAX_REG or EBX_REG or ECX_REG or EDX_REG		; EBX and EDX for CALLOC_PAGE
	.PAGE_PRESENT_BIT	equ	(1 shl 0)
		
		cmp		[BOOTUP_DATA.page_directory], dword 0
		jnz		.pd_present								; Jump if page directory already present
		callfun	CALLOC_PAGE, EDI_REG or ESI_REG
		mov		[BOOTUP_DATA.page_directory], eax
		
	.pd_present:
		mov		eax, [BOOTUP_DATA.page_directory]
		mov		ebx, edi
		shr		ebx, 22-2								; Byte offset into PD...
		and		ebx, (1111111111b shl 2)
		add		ebx, eax
		test	[ebx], dword .PAGE_PRESENT_BIT
		jnz		.pt_present								; Jump if page table already present
		callfun	CALLOC_PAGE, EBX_REG or EDI_REG or ESI_REG
		mov		[ebx], eax
		or		[ebx], dword 011b						; Present, supervisor, read/write
		
	.pt_present:
		mov		eax, [ebx]
		and		eax, not 0x0FFF
		mov		ebx, edi
		shr		ebx, 12-2							 	; Byte offset into PT...
		and		ebx, 1111111111b shl 2
		add		ebx, eax								; EBX now points to the place where we have to put the page frame address...
		
		mov		[ebx], esi
		or		[ebx], dword 011b						; Present, supervisor, read/write
		
		ret

; Return:
;     EAX - page start address (initialized to zero)
function CALLOC_PAGE, EAX_REG or EBX_REG or ECX_REG or EDX_REG or EDI_REG
		
		callfun	ALLOC_PAGE, 0
		mov		ebx, eax
		
		mov		ecx, 1024
		xor		eax, eax
		mov		edi, ebx
		cld
		rep
		stosd
		
		mov		eax, ebx
		
		ret

; Return:
;     EAX - page start address
function ALLOC_PAGE, EAX_REG or EBX_REG or ECX_REG or EDX_REG
		
		xor		eax, eax
		mov		ebx, [BOOTUP_DATA.mem_map_addr]
		
		; Now:
		;   EAX - current address in memory
		;   EBX - map pointer
		
		;     Notes:
		; 1 - Read the block type and add 4. If not free, go to 4
		; 2 - See whether it has enought space for a page. If not, go to 4
		; 3 - Otherwise, See whether the start address is page aligned. If not, add
		;     the appropriate amount to the second previous descriptor (the
		;     descriptor before the OTHER_DATA one), add it to EAX, and subtract it
		;     from the free one, then go to 2. (do a add/sub with carry to keep the high
		;     dword consistent).
		;     If it's aligned, subtract the page size from the free block and add
		;     it to the OTHER_DATA block. (do a add/sub with carry to keep the high dword
		;     consistent) Then return the current address.
		; 4 - Update the current address var (eax). If it carries out or the high word on
		;     the map is not 0, report error.
		; 5 - Add 8 to the pointer and go to 1
		;        OH NAO! ESQUECI-ME COMPLETAMENTE! O END-OF-MAP!
		
		
   .alloc_loop:
		mov		ecx, [ebx]
		add		ebx, 4
		cmp		ecx, FREE_MEMORY_DESC
		jne		.next_iter
		
   .test_page_fit:
		cmp		[ebx+4], dword 0			; High dword
		jnz		@f
		cmp		[ebx+0], dword PAGE_SIZE
		jb		.next_iter
		
	@@:
		test	eax, PAGE_SIZE-1
		jnz		@f
		
		; if page aligned:
		sub		[ebx],			dword PAGE_SIZE	; Subtract low dword
		sbb		[ebx+4],		dword 0				; take borrow into account just in case
		add		[ebx-(4+8)],	dword PAGE_SIZE	; Add low dword
		adc		[ebx-(4+8)+4],	dword 0				; take carry into account just in case
		
		ret
		
	@@:	; if not:
		mov		edx, eax
		and		edx, PAGE_SIZE-1
		sub		edx, PAGE_SIZE
		neg		edx
		add		eax, edx
		
		sub		[ebx], edx
		sbb		[ebx+4], dword 0
		
		add		[ebx-(4+8)*2], edx
		adc		[ebx-(4+8)*2+4], dword 0
		
		jmp		.test_page_fit
			
		
		
   .next_iter:
		cmp		[ebx+4], dword 0
		jnz		BOOTUP_ERRORS.ALLOC_ERROR
		add		eax, [ebx+0]
		jc		BOOTUP_ERRORS.ALLOC_ERROR
		
		add		ebx, 8
		jmp		.alloc_loop
		
  .ret:	ret


















