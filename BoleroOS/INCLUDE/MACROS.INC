
macro printhexdigit num {
	if num < 10
		display (num)+'0'
	else
		display (num)-10+'A'
	end if
}

macro printaddr addr {
	display "0x"
	printhexdigit ((addr) shr 28) and 0xF
	printhexdigit ((addr) shr 24) and 0xF
	printhexdigit ((addr) shr 20) and 0xF
	printhexdigit ((addr) shr 16) and 0xF
	printhexdigit ((addr) shr 12) and 0xF
	printhexdigit ((addr) shr 08) and 0xF
	printhexdigit ((addr) shr 04) and 0xF
	printhexdigit ((addr) shr 00) and 0xF
}

; Stack layout after pushad at system call entry
virtual at 0
	UM_EDI_ON_STACK		dd	?
	UM_ESI_ON_STACK		dd	?
	UM_EBP_ON_STACK		dd	?
						dd	?	; User Mode ESP is NOT at here
	UM_EBX_ON_STACK		dd	?
	UM_EDX_ON_STACK		dd	?
	UM_ECX_ON_STACK		dd	?
	UM_EAX_ON_STACK		dd	?
	
	UM_EIP_ON_STACK		dd	?
	UM_CS_ON_STACK		dd	?
	UM_EFLAGS_ON_STACK	dd	?
	UM_ESP_ON_STACK		dd	?
	UM_SS_ON_STACK		dd	?
end virtual






EAX_REG	equ	(1 shl 0)
EBX_REG	equ	(1 shl 1)
ECX_REG	equ	(1 shl 2)
EDX_REG	equ	(1 shl 3)
ESI_REG	equ	(1 shl 4)
EDI_REG	equ	(1 shl 5)
EBP_REG	equ	(1 shl 6)	; EBP may be used for any purpose. It must be saved even if the purpose is
						;  marking the stack frame.
						; The callee must always save ESP by itself in some way if using it for
						;  any "nonstandard" (i.e. not a stack pointer) purpose...

macro function label, mask {
align 4
	label#_rmask = mask
	label:
	
	display "Symbol "
	display `label
	display " at address: "
	printaddr label
	display 0x0A, 0x0D
}

macro callfun label, mask  {
	
	local thissavemask
	thissavemask	equ	(label#_rmask and mask)
	
	if thissavemask and EAX_REG
		push eax
	end if
	if thissavemask and EBX_REG
		push ebx
	end if
	if thissavemask and ECX_REG
		push ecx
	end if
	if thissavemask and EDX_REG
		push edx
	end if
	if thissavemask and ESI_REG
		push esi
	end if
	if thissavemask and EDI_REG
		push edi
	end if
	if thissavemask and EBP_REG
		push ebp
	end if
	
	call label
	
	if thissavemask and EBP_REG
		pop ebp
	end if
	if thissavemask and EDI_REG
		pop edi
	end if
	if thissavemask and ESI_REG
		pop esi
	end if
	if thissavemask and EDX_REG
		pop edx
	end if
	if thissavemask and ECX_REG
		pop ecx
	end if
	if thissavemask and EBX_REG
		pop ebx
	end if
	if thissavemask and EAX_REG
		pop eax
	end if
	
}

macro syscall label  {
	display "System Call "
	display `label
	display " entry at address: "
	printaddr label
	display 0x0A, 0x0D

align 4
	label:
}

macro interrupt label  {
	display "Interrupt handler "
	display `label
	display " entry at address: "
	printaddr label
	display 0x0A, 0x0D

align 4
	label:
}



macro clear reg  {
	xor reg, reg
}








