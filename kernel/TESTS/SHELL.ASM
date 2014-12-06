use32
jmp start

include "../INCLUDE/MACROS.INC"

; Int 48 to call kernel

greeting	db	"Welcome to BoleroOS shell . . .", 0Ah, 0Ah, 0
prompt      db  " / # ", 0
comm_buffer: times 256 db 0
notfound    db  ": command not found!", 0Ah, 0

start:
		callfun	InitConsole, 0

		mov		eax, 1		; Set
		mov		ebx, 010b
		callfun	ConfigEvents, 0
		
		mov		eax, 0x0700
		mov		esi, greeting
		callfun	PrintString, 0


    .reprompt:
        mov     eax, 0x0700
        mov     esi, prompt
        callfun PrintString, 0
        
        mov edi, comm_buffer
        mov ecx, 256
        callfun ReadLine, 0
        
        
        mov     eax, 0x0700
        mov     esi, comm_buffer
        callfun PrintString, 0
        
        mov     eax, 0x0700
        mov     esi, notfound
        callfun PrintString, 0
        
        
        jmp     .reprompt
        

		jmp $





include "CONSOLE.ASM"
include "SYS.ASM"
include "../LIB.ASM"

display "Symbol DISPLAY_BUFFER at address: "
printaddr DISPLAY_BUFFER
DISPLAY_BUFFER:
times 80*25 dw 0700h



