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
;!      This is the main kernel source file,               !
;!      who just source-level includes every               !
;!      other source file with kernel-land                 !
;!      code & data (and some user-mode code               !
;!      & data too, at least for now).                     !
;!                                                         !
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


display 13, 10      ; This is a newline!

IMAGE_START:
include "INCLUDE/MACROS.INC"
include "INCLUDE/SMACROS.INC"
include "INCLUDE/CONST.INC"
include "INCLUDE/KEYS.INC"

LOAD_ADDRESS	equ	1*MEBI
HIGH_ADDRESS	equ	3*GIBI			; Last 1 GB are for kernel

PGMAP_ADDRESS	equ	4*GIBI-4*MEBI	; Page map for this address space
PGDIR_ADDRESS	equ	4*GIBI-4*KIBI	; Page directory for this address space
PAGE_SIZE		equ	4*KIBI
PAGE_SIZE_LOG	equ	12				; Base2 logarithm of page size

use32

; Kernel header
KERNEL_HEADER:
	dd	0x4E484F20      ; Magic number
	dd	0               ; Don't remember!!!
	dd	start           ; <-- Entry point if kernel...

if KERNEL_HEADER <> 0x00000000
	display "---------------> WARNING: Somehow the kernel header landed in wrong place..."
end if

org $+LOAD_ADDRESS
include "CPUINIT1.ASM"			; Basic CPU configuration for paging and kernel entry point
org $-LOAD_ADDRESS
; Here begins high kernel
org $+HIGH_ADDRESS
include "INCLUDE/MESSAGES.INC"
include "CPUINIT2.ASM"			; Rest of paging initialization and higher-half entry point

; System Stuff
include "SYSTEM/KMAIN.ASM"		; Main kernel initialization routine. Initializes important stuff
include "SYSTEM/SCHED.ASM"		; Process and Thread management
include "SYSTEM/MEM.ASM"		; Physical memory manager
include "SYSTEM/SYSCALL.ASM"	; System Call Interface Entry
include "SYSTEM/TRAMP.ASM"		; System Trampoline
include "SYSTEM/DEBUG.ASM"		; Debug routines (including klog)
include "SYSTEM/HID.ASM"		; Helper routines for Human Interface Devices

; I/O Stuff
include "IO/GENERIC.ASM"		; Generic I/O routines
include "IO/DISPLAY.ASM"		; Display routines
include "IO/KBD.ASM"			; Keyboard driver

; I18N stuff
;include "PT.ASM"				; Keyboard maps for PT keyboards
include "US.ASM"				; Keyboard maps for US keyboards

; Runtime library
include "LIB.ASM"

; Temporary tests
;include "TESTS/MATEST.ASM"
prog1:
;file "TESTS/SHELL.EXE"
file "TESTS/PROG1.EXE"
 .size = $-prog1



times 128 dd ?		; Stack size for system initialization: 128 dwords
KERNEL_STACKTOP:

org $-HIGH_ADDRESS
IMAGE_END:

