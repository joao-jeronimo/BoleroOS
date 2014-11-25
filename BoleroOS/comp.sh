#! /bin/sh

echo "A compilar"

fasm TESTS/PROG1.ASM TESTS/PROG1.EXE
if [ $? != 0 ]; then
 exit
fi

fasm TESTS/SHELL.ASM TESTS/SHELL.EXE
if [ $? != 0 ]; then
 exit
fi

fasm BOLERO.ASM BOLERO.IMG
if [ $? != 0 ]; then
 exit
fi




echo "A construir floppy"

dd if=/dev/zero of=floppy.img count=2880 2> /dev/null
mformat -t 80 -h 2 -n 18 m: > /dev/null



#./insboot -o floppy.img BOOTSECT.IMG > /dev/null
dd if=BOOTSECT.IMG of=floppy.img conv=notrunc

mcopy -o BOOTER.IMG m: > /dev/null
mcopy -o BOOTER.CFG m: > /dev/null
mcopy -o BOLERO.IMG m: > /dev/null




