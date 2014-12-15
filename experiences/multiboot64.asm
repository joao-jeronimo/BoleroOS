
format binary  
org 0x100000
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
        cli
        
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
        ; == Testing CPUID...
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
        
        ; == CPUID ok...
        mov     eax, '1'
        mov     [hallomsg+30], al
        mov     esi, hallomsg
        call    print
        
        ; == See if long-mode is available:
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
        
        ; == If we had paging enabled in 32-bit Protected Mode,
        ; ==  we would have to disable it here...
        ;mov eax, cr0
        ;and eax, not (1 shl 31)
        ;mov cr0, eax
        
        ; == Setting up page tables (already declared!)...
        mov     eax, Paging.PML4T
        mov     cr3, eax
        ; == Enable PAE
        mov     eax, cr4
        or      eax, 1 shl 5
        mov     cr4, eax
        
        ; Paging ok
        mov     eax, '3'
        mov     [hallomsg+30], al
        mov     esi, hallomsg
        call    print
        
        ; == Enabling 32-bit Long Mode...
        mov     ecx, 0xC0000080
        rdmsr
        or      eax, 1 shl 8     ; This sets LM bit.
        wrmsr
        ; == Re-enable paging
        mov     eax, cr0
        or      eax, 1 shl 31
        mov     cr0, eax
        
        ; Now in long mode (32-bit)!
        mov     eax, 'LM32'
        mov     dword [hallomsg+30], eax
        mov     esi, hallomsg
        call    print
        
        ; == Setting up 64-bit GDT...
        lgdt    [GDT64_Ptr]
        jmp     GDT64.Code:.KingdomOf64  ; Long-Jump-Long!

use64
  .KingdomOf64:
        mov     ax, GDT64.Data
        mov     ds, ax
        mov     es, ax
        mov     fs, ax
        mov     gs, ax
        mov     ss, ax
        
        
        ; Now in 64-bit Long Mode . . .
        mov     rax, 'LCMC6C4C'
        mov     [0xB8000+80*7*2], rax


        ;hlt
        jmp $

use32
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

; == DATA ==
; Paging stuff...
align 4096
Paging:
 .PML4T:  ; Maps 256 TB
         dq .PDPT               or (000000000011b)    ; Present, R/W, Supervisor
         times 512-1 dq 0
 .PDPT:  ; Maps 512 GB
         dq .PDT                or (000000000011b)    ; Present, R/W, Supervisor
         times 512-1 dq 0
 .PDT:   ; Maps   1 GB
         dq .PT                 or (000000000011b)    ; Present, R/W, Supervisor
         times 512-1 dq 0
 .PT:    ; Maps   2 MB (4 KB per entry)
         repeat 512
                dq ((%-1)*4096) or (000000000011b)    ; Present, R/W, Supervisor
         end repeat


; This code was lazily and mercilessly stolen from OSDEV Wiki page: :-)
;  http://wiki.osdev.org/User:Stephanvanschaik/Setting_Up_Long_Mode#Entering_the_64-bit_Submode
align 8
GDT64:
 .Null = $ - GDT64  ; Selector for Null.
    dw 0
    dw 0
    db 0
    db 0
    db 0
    db 0
 .Code = $ - GDT64  ; Selector for Code.
    dw 0         ; Limit (low).
    dw 0         ; Base (low).
    db 0         ; Base (middle)
    db 10011000b ; Access.
    db 00100000b ; Bit 5 means "64-bit mode", Bit 6 Has no meaning in 64-bit mode . . .
    db 0         ; Base (high).
 .Data = $ - GDT64  ; Selector for Data.
    dw 0         ; Limit (low).
    dw 0         ; Base (low).
    db 0         ; Base (middle)
    db 10010010b ; Access.
    db 00000000b ; Granularity.
    db 0         ; Base (high).

GDT64_Ptr:
    dw $ - GDT64 - 1             ; Limit.
    dd GDT64                     ; Base.






_end_data:
        
rb 32768        ; our own stack 
Kernel_Stack:


; == Paging stuff... ==
;Paging:
; .PML4T:        rq 512  ; Maps 256 TB
; .PDPT:         rq 512  ; Maps 512 GB
; .PDT:          rq 512  ; Maps   1 GB
; .PT:           rq 512  ; Maps   2 MB (4 KB per entry)

_end:



