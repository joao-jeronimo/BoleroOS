
; ===== Initialization

function InitConsole, EAX_REG or EBX_REG or GetDisplay_rmask or UpDisplay_rmask
		mov		eax, DISPLAY_BUFFER
		callfun	GetDisplay, 0
		
		clear	eax
		mov		ebx, 80*25
		callfun	UpDisplay, 0
		
		ret


; ===== Output

; Prints a string to screen. Scrolls if necessary.
;  In: ESI - pointer to string
;      EAX - VGA attribute shl 8
function PrintString, EAX_REG or EBX_REG or ESI_REG or PrintChar_rmask or UpDisplay_rmask
		cld
	.loop:
		lodsb
		test    al, al
		jz		.ret
		callfun	PrintChar, EAX_REG or ESI_REG   ; Need to save EAX because of the attribute...
		jmp		.loop
	.ret:
		clear	eax
		mov		ebx, 80*25
		callfun	UpDisplay, 0
		
		ret

; Prints a character and advances cursor (buffer offset).
; Scrolls if necessary.
;  In: EAX - char to print with attribute byte
function PrintChar, ECX_REG or EBX_REG or ScrollScreen_rmask or CurUp_rmask or CurRight_rmask or CurLeft_rmask or NewLine_rmask
		cmp		al, 32          ; Space
		jb		.control_char
		cmp		al, 126         ; '~'
		ja		.control_char
		
		mov		ecx, [TELETYPE_INFO.buffer_offset]
		cmp		ecx, 80*25*2
		jne		.no_scroll
		
		mov		ebx, 1
		callfun	ScrollScreen, EAX_REG
		callfun	CurUp, EAX_REG
		mov		ecx, [TELETYPE_INFO.buffer_offset]
	.no_scroll:
		mov		[DISPLAY_BUFFER+ecx], ax    ; Place the char.
		callfun	CurRight, 0
		
		ret
		
	.control_char:
		cmp		al, 08h		; Backspace
		jne		.not_bkspc
		callfun	CurLeft, 0
		ret
	.not_bkspc:
		cmp		al, 0Ah		; Line Feed
		jne		.not_lf
		callfun	NewLine, 0
		ret
	.not_lf:
		ret

; Opens a new line, scrolls if necessary.
function NewLine, EDX_REG or ScrollScreen_rmask or CurUp_rmask
		mov		edx, [TELETYPE_INFO.remaining_chars]
		cmp		edx, 80
		je		.start_of_line
		
		mov		[TELETYPE_INFO.remaining_chars], 80
		shl		edx, 1					; *2
		add		[TELETYPE_INFO.buffer_offset], edx
		
		jmp		.continue
	.start_of_line:
		add		[TELETYPE_INFO.buffer_offset], 80*2
		
	.continue:
		cmp		[TELETYPE_INFO.buffer_offset], 80*25*2
		je		.do_scroll
		ret
		
	.do_scroll:
		mov		ebx, 1
		callfun	ScrollScreen, 0
		callfun	CurUp, 0
		ret

; Pulls cursor up
function CurUp, 0
		sub		[TELETYPE_INFO.buffer_offset], 80*2
		
		ret

; Pulls cursor left
function CurLeft, 0
		sub		[TELETYPE_INFO.buffer_offset], 2
		inc		[TELETYPE_INFO.remaining_chars]
		cmp		[TELETYPE_INFO.remaining_chars], 80
		ja		.prevline
		ret
	.prevline:
		sub		[TELETYPE_INFO.remaining_chars], 80
		ret

; Pushes cursor right
function CurRight, ScrollScreen_rmask or CurUp_rmask
		add		[TELETYPE_INFO.buffer_offset], 2
		dec		[TELETYPE_INFO.remaining_chars]
		jz		.nextline
		ret
	.nextline:
		mov		[TELETYPE_INFO.remaining_chars], 80
		cmp		[TELETYPE_INFO.buffer_offset], 80*25*2
		je		.scroll
		ret
	.scroll:
		mov		ebx, 1
		callfun	ScrollScreen, 0
		callfun	CurUp, 0
		ret

; Scrools the VGA buffer.
;  In: EBX - number of lines to scroll
function ScrollScreen, EAX_REG or EBX_REG or ECX_REG or ESI_REG or EDI_REG
		mov		edi, DISPLAY_BUFFER
		
		mov		esi, edi
		shl		ebx, 5		; ebx <- ebx*80*2 = ebx*160
		add		esi, ebx	; (160 = 128+32 = (1<<5)+(1<<7))
		shl		ebx, 2		; 7-5 = 2 (only shift 2 this time)
		add		esi, ebx
		
		mov		ecx, DISPLAY_BUFFER+80*25*2
		sub		ecx, esi
		shr		ecx, 2		; /4
		cld
		rep		movsd
		
		clear	eax
		mov		ecx, 80/2
		rep		stosd
		
		ret


; ===== Input

; Reads a line (at most EBX chars) from keyboard to buffer, with line editing.
; EDI - buffer pointer
; ECX - buffer size
function ReadLine, EAX_REG or ECX_REG or EDI_REG or EBP_REG or WaitForEvent_rmask or GetKey_rmask
        mov     ebp, edi    ; No not overwrite EBP so that we can know the start of the buffer...

    .more_chars:
        ; Updating cursor
        mov     eax, [TELETYPE_INFO.buffer_offset]
        shr     eax, 1
        mov     ebx, eax
        callfun UpDisplay, ECX_REG or EDI_REG or EBP_REG
        
        callfun WaitForEvent, EDI_REG or ECX_REG or EBP_REG
        callfun GetKey, EDI_REG or ECX_REG or EBP_REG
        cmp     ebx, -1     ; Test for special keys
        je      .special_key
        
        ; Save in buffer
        mov     [edi], ebx
        inc     edi
        dec     ecx
        
        ; Print to screen
        mov     eax, 0700h
        or      eax, ebx
        callfun PrintChar, EBX_REG or ECX_REG or EDI_REG or EBP_REG
        mov     eax, 0
        push    ebx
        ;mov     ebx, [TELETYPE_INFO.buffer_offset]
        ;shr     ebx, 1          ; /2 (because each char takes 2 bytes)
        mov     ebx, 80*25
        callfun UpDisplay, ECX_REG or EDI_REG or EBP_REG
        pop     ebx
        
        ; Detect termination (no more space in buffer or LF)
        cmp     ebx, 0Ah
        je      .ret
        cmp     ecx, 0
        jz      .ret
        jmp     .more_chars
        
    .ret:
        dec     edi
        mov     [edi], byte 0
        ret


    .special_key:
        cmp     eax, 1024+34    ; Baskspace
        jne      .not_bkspc
        
        ; Handle backspace
        cmp     edi, ebp
        je      .more_chars     ; Backspace are invalid at the start of the buffer...
        
        callfun CurLeft, EDI_REG or ECX_REG or EBP_REG
        mov     eax, 0700h or ' '
        callfun PrintChar, EDI_REG or ECX_REG
        callfun CurLeft, EDI_REG or ECX_REG or EBP_REG
        mov     eax, 0
        push    ebx
        mov     ebx, 80*25
        callfun UpDisplay, ECX_REG or EDI_REG or EBP_REG
        pop     ebx
        
        inc     ecx
        dec     edi
        
    .not_bkspc:
        jmp     .more_chars





align 4
TELETYPE_INFO:
 .buffer_offset		dd	0		; Current offset inside VGA buffer (i.e. cursor)
 .remaining_chars	dd	80		; Remaining number of characters in current line





