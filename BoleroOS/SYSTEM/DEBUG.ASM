


function Dbg_init, ESI_REG or EDI_REG or MapPhysicalRange_rmask
		mov		esi, 0xB8000
		mov		edi, 0xB8000+80*25*2-1
		callfun	MapPhysicalRange, 0
		
		mov		[VGA_TXT_ADDR], ebp
		mov		eax, [puts.vga_offset-LOAD_ADDRESS+HIGH_ADDRESS]
		mov		[klog.vga_offset], eax
		
		ret


; Input: EBP - address of string
function klog, EAX_REG or EBP_REG or EDI_REG
		cmp		[.dbg_to_screen], 0
		jz		.ret
		
		mov		edi, [.vga_offset]
		mov		eax, 0x0700
		add		edi, [VGA_TXT_ADDR]
		
		; Write chars to screen
	@@:	mov		al, [ebp]
		test	al, al
		jz		.updt_cur
		
		stosw
		inc		ebp
		
		jmp		@b
		
 .updt_cur:
		sub		edi, [VGA_TXT_ADDR]
		
		; Advance to next line (add 80 chars each time
		;  until we land after the line just written)
	@@:	add		[.vga_offset], dword 80*2	; Advance 80 chars (attr+ASCII code)
		cmp		[.vga_offset], edi
		jb		@b
		
	.ret:
		ret

align 4
    .vga_offset		dd	?
    .dbg_to_screen	dd	?



