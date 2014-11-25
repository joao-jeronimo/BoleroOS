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
;!      Purpose: Generic I/O routines                      !
;!      History: 01/07/2008 - PIC initialization           !
;!                                                         !
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


PIC1_BASE	equ		020h
PIC2_BASE	equ		0A0h

PIC_ICW1	equ		00010001b	; Cascaded mode, sending ICW4
PIC1_ICW2	equ		32			; Remap PIC1 to INT32
PIC2_ICW2	equ		40			; Remap PIC2 to INT40
PIC1_ICW3	equ		1 shl 2		; This means that IR2 comes from slave
PIC2_ICW3	equ		2			; This means that PIC2 is wired to master's IR2
PIC_ICW4	equ		00000001b	; This means we are an 8086 (which is a lie!)

PIC_EOI		equ		0x20		; OCW2 aka EndOfInterrupt

; 0 = int allowed
; 1 = int masked
PIC1_MASK	equ		11111011b	; IRQs[0:7]    (IRQ2 is allowed because of PIC2)
PIC2_MASK	equ		11111111b	; IRQs[8:15]

function PicInit, EAX_REG
		
		; Remapping PIC1
		mov		al, PIC_ICW1
		out		PIC1_BASE+0, al
		mov		al, PIC1_ICW2
		out		PIC1_BASE+1, al
		mov		al, PIC1_ICW3
		out		PIC1_BASE+1, al
		mov		al, PIC_ICW4
		out		PIC1_BASE+1, al
		
		; Remapping PIC2
		mov		al, PIC_ICW1
		out		PIC2_BASE+0, al
		mov		al, PIC2_ICW2
		out		PIC2_BASE+1, al
		mov		al, PIC2_ICW3
		out		PIC2_BASE+1, al
		mov		al, PIC_ICW4
		out		PIC2_BASE+1, al
		
		; Now INT masks
		mov		al, PIC1_MASK
		out		PIC1_BASE+1, al
		mov		al, PIC2_MASK
		out		PIC2_BASE+1, al
		
		ret





