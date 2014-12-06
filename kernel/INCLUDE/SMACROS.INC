
macro gdt_entry base, limit, flags, flags2  {
	dw	limit and 0xFFFF
	dw	base  and 0xFFFF
	db	(base shr 16)  and 0xFF
	db	flags
	db	((limit shr 16) and 0xF) or flags2
	db	(base shr 24)  and 0xFF
}

macro int_gate selector, offset, DPL  {
	dw	(offset) and 0xFFFF
	dw	selector
	db	0
	db	((DPL) shl 5) or 10001110b		; Present (bit 7) and gate descriptor
	dw	((offset) shr 16) and 0xFFFF
}

KCODESEG		equ		(1 shl 3)
KDATASEG		equ		(2 shl 3)
UCODESEG		equ		((3 shl 3) or 011b)	; RPL must be 3
UDATASEG		equ		((4 shl 3) or 011b)	; RPL must be 3
SYSTEM_TSS		equ		(5 shl 3)

KMODE_STACKBASE	equ		KERNEL_STACKTOP



PTENTRY_PRESENT	equ		(1 shl 0)
PTENTRY_RW		equ		(1 shl 1)
PTENTRY_RO		equ		0			; If we need to stress the fact of being readonly (the default)
PTENTRY_USER	equ		(1 shl 2)
PTENTRY_SUPER	equ		0			; Something for supervisor pages (the default)


