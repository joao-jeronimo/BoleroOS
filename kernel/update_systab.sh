#! /bin/sh

./prep_syscalls.py GEN_TRAMP SYSCALLS.LST SYSTEM/TRAMP.ASM
./prep_syscalls.py GEN_HEADER SYSCALLS.LST TESTS/SYS.ASM


