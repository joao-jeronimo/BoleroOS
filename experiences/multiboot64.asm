
format binary  
org 0x220000
use32

MBFLAGS=0x03 or (1 shl 16)          ; 4kb page aligment for modules, supply memory info 

_start:
; Multiboot header
        dd 0x1BADB002               ; multiboot signature 
        dd MBFLAGS              
        dd -0x1BADB002-MBFLAGS      ; checksum = -(FLAGS+0x1BADB002) 

        dd _start                   ; header_addr 
        dd _start                   ; load_addr 
        dd _end_data                ; load_end_addr 
        dd _end                     ; bss_end_addr 
        dd Kernel_Start             ; entry 

Kernel_Start:
    mov     eax, 'BBBB'
    mov     [0xB8000], eax

    jmp $



_end_data:


rb 32768        ; our own stack 
Kernel_Stack: 

_end: