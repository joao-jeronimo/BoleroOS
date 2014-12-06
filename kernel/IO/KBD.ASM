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
;!      Purpose: Keyboard driver                           !
;!      History: 28/07/2008 - created                      !
;!                                                         !
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!



function KbdInit, EAX_REG
		; Disabling on-board scancode translation
		callfun	kbd_wait_before_out, 0
		mov		al, 0x60		; Write Command Byte
		out		0x64, al
		callfun	kbd_wait_before_out, 0
		mov		al, 00000101b	;  Clarify keyboard's configuration
		out		0x60, al		; (scancode convertion off, INT1 on)
		
		
		callfun	kbd_wait_before_out, 0
		mov		al, 0xED		; Set LEDs
		out		0x60, al
		callfun	kbd_wait_before_out, 0
		mov		al, 0x00		; Turn off all LEDs
		out		0x60, al
		
		; Enabling keyboard IRQ
		in		al, PIC1_BASE+1
		and		al, not(1 shl 1)	; Unsetting bit 0
		out		PIC1_BASE+1, al
		
		ret



function kbd_wait_before_out, EAX_REG
	@@:	
		in		al, 0x64
		test	al, 1 shl 1		; Test InBF flag until empty
		jnz		@b
		ret
	
function kbd_wait_before_in, EAX_REG
	@@:	
		in		al, 0x64
		test	al, 1 shl 0		; Test OutBF flag until full
		jz		@b
		ret



; PS/2 Keyboard support
interrupt KBD_ISR
		pushad
		
		in		al, 0x60
		movzx	eax, al
		
		cmp		eax, 0xFA			; See if it's ACK
		je		.ret
		
		cmp		eax, 0xF0			; See if reading a break
		jne		.not_break
		or		[.state], 1 shl 0	; Mark bit 0
		jmp		.ret
	.not_break:
		
		cmp		eax, 0xE0
		jne		.not_escaped
		or		[.state], 1 shl 1	; Mark bit 1
		jmp		.ret
	.not_escaped:
		
		mov		ebx, SimpleSC2VK
		test	[.state], 1 shl 1
		jz		@f
		; If reading an escaped one, use the other look-up table instead
		mov		ebx, EscapedSC2VK
	@@:
		movzx	ecx, word [ebx+eax*2]
		
		; Virtual key code now in ecx.
		;  Now:
		;   - See whether it's a break and just
		;     report it in that case.
		;   - Unmark .state bits.
		;   - If NOT a break, see if it is a
		;     * Lock, and update the flags
		;     accordingly.
		;   - Update the leds.
		;   - Add the flags to the VK code.
		test	[.state], 1 shl 0
		jz		.wasnt_a_break
		
		; Test for shifts, alts and controls
		;  and unmark the respective bit.
		cmp		ecx, KEY_L_Shift
		jne		@f
		and		[.flags], not(1 shl 22)
	@@:	cmp		ecx, KEY_R_Shift
		jne		@f
		and		[.flags], not(1 shl 23)
	@@:	cmp		ecx, KEY_L_Control
		jne		@f
		and		[.flags], not(1 shl 24)
	@@:	cmp		ecx, KEY_R_Control
		jne		@f
		and		[.flags], not(1 shl 25)
	@@:	cmp		ecx, KEY_L_Alt
		jne		@f
		and		[.flags], not(1 shl 26)
	@@:	cmp		ecx, KEY_R_Alt
		jne		@f
		and		[.flags], not(1 shl 27)
		
	@@:	or		ecx, 1 shl 31
		jmp		.deliver_key
	.wasnt_a_break:
		
		; Test for shifts, alts and controls
		;  and mark the respective bit.
		cmp		ecx, KEY_L_Shift
		jne		@f
		or		[.flags], 1 shl 22
	@@:	cmp		ecx, KEY_R_Shift
		jne		@f
		or		[.flags], 1 shl 23
	@@:	cmp		ecx, KEY_L_Control
		jne		@f
		or		[.flags], 1 shl 24
	@@:	cmp		ecx, KEY_R_Control
		jne		@f
		or		[.flags], 1 shl 25
	@@:	cmp		ecx, KEY_L_Alt
		jne		@f
		or		[.flags], 1 shl 26
	@@:	cmp		ecx, KEY_R_Alt
		jne		@f
		or		[.flags], 1 shl 27
	@@:	
		
		; Test for *lock and invert the respective bit
		cmp		ecx, KEY_ScrollLock
		jne		@f
		xor		[.flags], 1 shl 28
	@@:	cmp		ecx, KEY_NumLock
		jne		@f
		xor		[.flags], 1 shl 29
	@@:	cmp		ecx, KEY_CapsLock
		jne		@f
		xor		[.flags], 1 shl 30
	@@:	
		
		; Final virtual key code must be now in ecx.
	.deliver_key:
		mov		[.state], 0
		
		; Compute Upper flag
		mov		eax, [.flags]
		mov		ebx, eax
		mov		edx, eax
		mov		esi, eax
		shr		ebx, 22		; Get L shift
		shr		edx, 23		; Get R shift
		shr		esi, 30		; Get Caps
		and		eax, not(1 shl 21)	; Set Upper bit to 0
		and		ebx, 1
		and		edx, 1		; Mask other bits
		and		esi, 1
		or		ebx, edx	; OR the shifts
		xor		ebx, esi	; XOR the result with caps
		shl		ebx, 21		; Put the final flag in bit 21
		or		eax, ebx
		mov		[.flags], eax
		
		or		ecx, eax	; Apply the flags to the final value
		
		;shr		eax, 28		; Adapt the flags to be sent to the keyboard
		;mov		ebx, eax
		
		; TODO: Set up somthing to get the LEDs updated...
		
		callfun	DeliverKey, 0
		
		
	.ret:
		; Sending EOI to the PIC
		mov		al, PIC_EOI
		out		PIC1_BASE, al
		
		popad
		iret
		
	.state	dd	0		; Bit 0 means "reading a break"
						; Bit 1 means "reading an escaped scancode"
	align 4
	.flags	dd	0		; Bits 21 to 30:
						;  21 - Upper
						;  22 - L Shift
						;  23 - R Shift
						;  24 - L Ctrl
						;  25 - R Ctrl
						;  26 - L Alt
						;  27 - R Alt
						;  28 - Scroll Lock
						;  29 - Num Lock
						;  30 - Caps Lock


; Table for converting scancodes into VKs
SimpleSC2VK:
		dw	?		; 00 - 
		dw	1024+9	; 01 - f9
		dw	?		; 02 - 
		dw	1024+5	; 03 - f5
		dw	1024+3	; 04 - f3
		dw	1024+1	; 05 - f1
		dw	1024+2	; 06 - f2
		dw	1024+12	; 07 - f12
		dw	?		; 08 - 
		dw	1024+10	; 09 - f10
		dw	1024+8	; 0a - f8
		dw	1024+6	; 0b - f6
		dw	1024+4	; 0c - f4
		dw	48		; 0d - Tab
		dw	0		; 0e - grave accent
		dw	?		; 0f - 
		dw	?		; 10 - 
		dw	1024+28	; 11 - left Alt
		dw	1024+24	; 12 - left Shift
		dw	?		; 13 - 
		dw	1024+26	; 14 - left Control
		dw	13		; 15 - Q
		dw	1		; 16 - 1
		dw	?		; 17 - 
		dw	?		; 18 - 
		dw	?		; 19 - 
		dw	37		; 1a - Z
		dw	27		; 1b - S
		dw	26		; 1c - A
		dw	14		; 1d - W
		dw	2		; 1e - 2
		dw	?		; 1f - 
		dw	?		; 20 - 
		dw	39		; 21 - C
		dw	38		; 22 - X
		dw	28		; 23 - D
		dw	15		; 24 - E
		dw	4		; 25 - 4
		dw	3		; 26 - 3
		dw	?		; 27 - 
		dw	?		; 28 - 
		dw	47		; 29 - Space
		dw	40		; 2a - V
		dw	29		; 2b - F
		dw	17		; 2c - T
		dw	16		; 2d - R
		dw	5		; 2e - 5
		dw	?		; 2f - 
		dw	?		; 30 - 
		dw	42		; 31 - N
		dw	41		; 32 - B
		dw	31		; 33 - H
		dw	30		; 34 - G
		dw	18		; 35 - Y
		dw	6		; 36 - 6
		dw	?		; 37 - 
		dw	?		; 38 - 
		dw	?		; 39 - 
		dw	43		; 3a - M
		dw	32		; 3b - J
		dw	19		; 3c - U
		dw	7		; 3d - 7
		dw	8		; 3e - 8
		dw	?		; 3f - 
		dw	?		; 40 - 
		dw	44		; 41 - ,	(comma)
		dw	33		; 42 - K
		dw	20		; 43 - I
		dw	21		; 44 - O
		dw	10		; 45 - 0	(Zero)
		dw	9		; 46 - 9
		dw	?		; 47 - 
		dw	?		; 48 - 
		dw	45		; 49 - .	(Period)
		dw	46		; 4a - /	(Forward Slash)
		dw	34		; 4b - L
		dw	35		; 4c - ;	(Semicolon)
		dw	22		; 4d - P
		dw	11		; 4e - -	(Dash)
		dw	?		; 4f - 
		dw	?		; 50 - 
		dw	?		; 51 - 
		dw	36		; 52 - '	(Apostrophe)
		dw	?		; 53 - 
		dw	23		; 54 - [	(left Square Bracket)
		dw	12		; 55 - =	(Equals Sign)
		dw	?		; 56 - 
		dw	?		; 57 - 
		dw	1024+23	; 58 - Caps Lock
		dw	1024+25	; 59 - right Shift
		dw	49		; 5a - Enter
		dw	24		; 5b - ]	(right Square Bracket)
		dw	?		; 5c - 
		dw	25		; 5d - \	(Back Slash)
		dw	?		; 5e - 
		dw	?		; 5f - 
		dw	?		; 60 - 
		dw	?		; 61 - 
		dw	?		; 62 - 
		dw	?		; 63 - 
		dw	?		; 64 - 
		dw	?		; 65 - 
		dw	1024+34	; 66 - Backspace
		dw	?		; 67 - 
		dw	?		; 68 - 
		dw	56		; 69 - keypad 1
		dw	?		; 6a - 
		dw	53		; 6b - keypad 4
		dw	50		; 6c - keypad 7
		dw	?		; 6d - 
		dw	?		; 6e - 
		dw	?		; 6f - 
		dw	59		; 70 - keypad 0
		dw	60		; 71 - keypad .
		dw	57		; 72 - keypad 2
		dw	54		; 73 - keypad 5
		dw	55		; 74 - keypad 6
		dw	51		; 75 - keypad 8
		dw	1024+0	; 76 - Escape
		dw	1024+22	; 77 - Number Lock
		dw	1024+11	; 78 - f11
		dw	62		; 79 - keypad +
		dw	58		; 7a - keypad 3
		dw	63		; 7b - keypad -
		dw	64		; 7c - keypad *
		dw	52		; 7d - keypad 9
		dw	1024+14	; 7e - Scroll Lock
		dw	?		; 7f - 
		dw	?		; 80 - 
		dw	?		; 81 - 
		dw	?		; 82 - 
		dw	1024+7	; 83 - f7


EscapedSC2VK:
		dw	?		; 00 - 
		dw	?		; 01 - 
		dw	?		; 02 - 
		dw	?		; 03 - 
		dw	?		; 04 - 
		dw	?		; 05 - 
		dw	?		; 06 - 
		dw	?		; 07 - 
		dw	?		; 08 - 
		dw	?		; 09 - 
		dw	?		; 0a - 
		dw	?		; 0b - 
		dw	?		; 0c - 
		dw	?		; 0d - 
		dw	?		; 0e - 
		dw	?		; 0f - 
		dw	?		; 10 - 
		dw	1024+29	; 11 - right Alt
		dw	?		; 12 - 
		dw	?		; 13 - 
		dw	1024+27	; 14 - right Control
		dw	?		; 15 - 
		dw	?		; 16 - 
		dw	?		; 17 - 
		dw	?		; 18 - 
		dw	?		; 19 - 
		dw	?		; 1a - 
		dw	?		; 1b - 
		dw	?		; 1c - 
		dw	?		; 1d - 
		dw	?		; 1e - 
		dw	?		; 1f - left Gui		(????? Win key ?????)
		dw	?		; 20 - 
		dw	?		; 21 - 
		dw	?		; 22 - 
		dw	?		; 23 - 
		dw	?		; 24 - 
		dw	?		; 25 - 
		dw	?		; 26 - 
		dw	?		; 27 - right Gui	(????? Win key ?????)
		dw	?		; 28 - 
		dw	?		; 29 - 
		dw	?		; 2a - 
		dw	?		; 2b - 
		dw	?		; 2c - 
		dw	?		; 2d - 
		dw	?		; 2e - 
		dw	?		; 2f - Apps			(????? No Guess ?????)
		dw	?		; 30 - 
		dw	?		; 31 - 
		dw	?		; 32 - 
		dw	?		; 33 - 
		dw	?		; 34 - 
		dw	?		; 35 - 
		dw	?		; 36 - 
		dw	?		; 37 - 
		dw	?		; 38 - 
		dw	?		; 39 - 
		dw	?		; 3a - 
		dw	?		; 3b - 
		dw	?		; 3c - 
		dw	?		; 3d - 
		dw	?		; 3e - 
		dw	?		; 3f - 
		dw	?		; 40 - 
		dw	?		; 41 - 
		dw	?		; 42 - 
		dw	?		; 43 - 
		dw	?		; 44 - 
		dw	?		; 45 - 
		dw	?		; 46 - 
		dw	?		; 47 - 
		dw	?		; 48 - 
		dw	?		; 49 - 
		dw	65		; 4a - keypad /
		dw	?		; 4b - 
		dw	?		; 4c - 
		dw	?		; 4d - 
		dw	?		; 4e - 
		dw	?		; 4f - 
		dw	?		; 50 - 
		dw	?		; 51 - 
		dw	?		; 52 - 
		dw	?		; 53 - 
		dw	?		; 54 - 
		dw	?		; 55 - 
		dw	?		; 56 - 
		dw	?		; 57 - 
		dw	?		; 58 - 
		dw	?		; 59 - 
		dw	61		; 5a - keypad Enter
		dw	?		; 5b - 
		dw	?		; 5c - 
		dw	?		; 5d - 
		dw	?		; 5e - 
		dw	?		; 5f - 
		dw	?		; 60 - 
		dw	?		; 61 - 
		dw	?		; 62 - 
		dw	?		; 63 - 
		dw	?		; 64 - 
		dw	?		; 65 - 
		dw	?		; 66 - 
		dw	?		; 67 - 
		dw	?		; 68 - 
		dw	1024+20	; 69 - End
		dw	?		; 6a - 
		dw	1024+30	; 6b - Left Arrow
		dw	1024+17	; 6c - Home
		dw	?		; 6d - 
		dw	?		; 6e - 
		dw	?		; 6f - 
		dw	1024+16	; 70 - Insert
		dw	1024+19	; 71 - Delete
		dw	1024+31	; 72 - Down Arrow
		dw	?		; 73 - 
		dw	1024+32	; 74 - Right Arrow
		dw	1024+33	; 75 - Up Arrow
		dw	?		; 76 - 
		dw	?		; 77 - 
		dw	?		; 78 - 
		dw	?		; 79 - 
		dw	1024+21	; 7a - Page Down
		dw	?		; 7b - 
		dw	?		; 7c - 
		dw	1024+18	; 7d - Page Up
		dw	?		; 7e - 
		dw	?		; 7f - 










