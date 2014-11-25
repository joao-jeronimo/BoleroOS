use32
jmp start

include "../INCLUDE/MACROS.INC"

; Int 48 to call kernel

greeting	db	     "Ola", 0Ah, 0Ah, 0
pressed		db	0Ah, "A key was pressed: ", 0
vk			db	"code - "
numbuff		db	"0x        ", 0
letter		db	"; character - "

start:
		callfun	InitConsole, 0

		;mov [0xdeadbeef], dword 0xb0af0da
		
		mov		eax, 1		; Set
		mov		ebx, 010b
		callfun	ConfigEvents, 0
		
		mov		eax, 0x0700
		mov		esi, greeting
		callfun	PrintString, 0
		
		mov		eax, 'B' or 0x0700
		callfun	PrintChar, 0
		
		clear	eax
		mov		ebx, 80*25
		callfun	UpDisplay, 0
		
	@@:	callfun	WaitForEvent, 0
		
		mov		eax, 0x0700
		mov		esi, pressed
		callfun	PrintString, 0
		
		callfun	GetKey, 0
		
		mov		ebp, numbuff+2
		callfun	WriteHex, EBX_REG
		mov		esi, vk
		mov		eax, 0x0700
		callfun	PrintString, EBX_REG
		
		cmp		ebx, -1
		je		@b
		
		mov		esi, letter
		mov		eax, 0x0700
		callfun	PrintString, EBX_REG
		
		mov		eax, ebx
		or		eax, 0x0700
		callfun	PrintChar, 0
		clear	eax
		mov		ebx, 80*25
		callfun	UpDisplay, 0
		
		jmp		@b
		
		
		jmp $




include "CONSOLE.ASM"
include "SYS.ASM"
include "../LIB.ASM"

display "Symbol DISPLAY_BUFFER ot address: "
printaddr DISPLAY_BUFFER
DISPLAY_BUFFER:
times 80*25*2 db 0



