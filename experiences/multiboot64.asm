
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

hellomsg db "Hello...                                                                       ", 0
hallomsg db "  LONG MODE???                                                                 ", 0


Kernel_Start:
        mov     esp, Kernel_Stack
        
        ; Clear screen...
        mov     edi, 0xB8000
        mov     eax, 0
        mov     ecx, 80*25
        rep stosw

        mov     eax, 'PCMC'
        mov     [0xB8000], eax
        
        mov     esi, hellomsg
        call    print
        ; INIT DONE!!!!!
        
        
        ; Trying to enter long mode.....
        ; Testing CPUID...
        pushfd
        pop     eax
        mov     ecx, eax
        xor     eax, (1 shl 21)
        push    eax
        popfd
        pushfd
        pop     eax
        cmp     eax, ecx
        je      .nolongmode
        
        ; CPUID ok...
        mov     eax, '1'
        mov     [hallomsg+30], al
        mov     esi, hallomsg
        call    print
        
        ; See if long-mode is available:
        mov eax, 0x80000000
        cpuid
        cmp eax, 0x80000001     ; See if function 0x80000001 exists...
        jb .nolongmode
        mov eax, 0x80000001
        cpuid
        test edx, 1 shl 29       ; See if processor has long mode...
        jz .nolongmode
        
        ; LongMode ok
        mov     eax, '2'
        mov     [hallomsg+30], al
        mov     esi, hallomsg
        call    print
        
        ; If we had paging enabled in 32-bit Protected Mode,
        ; we would have to disable it here...
        ;mov eax, cr0
        ;and eax, not (1 shl 31)
        ;mov cr0, eax
        
        ; Setting up paging...
        


;use64
;        mov     rax, 'LCMCLCMC'
;        mov     [0xB8000+80*7*2], rax


        jmp $

  .nolongmode:
        mov     eax, 'F'
        mov     [hallomsg+30], al
        mov     esi, hallomsg
        call    print
        jmp $





; Print ESI contents
print:
        mov     edi, [.cursor_ptr]
        mov     eax, 0x00000700
        cld
 .lp:
        mov     al, byte [esi]
        inc     esi
        stosw
    
        cmp     al, 0x0A
        jne     @f
  @@:
        
        cmp     al, 0
        jne     .lp
        
        mov     [.cursor_ptr], edi
    
        ret
.cursor_ptr dd 0xB8000+(80)*2


_end_data:


rb 32768        ; our own stack 
Kernel_Stack: 

_end: