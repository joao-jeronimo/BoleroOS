#! /bin/sh

echo "Compiling"

../support/fasm/fasm TESTS/PROG1.ASM TESTS/PROG1.EXE
if [ $? != 0 ]; then
 exit
fi

../support/fasm/fasm TESTS/SHELL.ASM TESTS/SHELL.EXE
if [ $? != 0 ]; then
 exit
fi

../support/fasm/fasm BOLERO.ASM BOLERO.IMG
if [ $? != 0 ]; then
 exit
fi


echo "Building floppy.img"

export MTOOLSRC=./mtools.conf

dd if=/dev/zero of=floppy.img count=2880 2> /dev/null
mformat -t 80 -h 2 -n 18 f: > /dev/null



#./insboot -o floppy.img BOOTSECT.IMG > /dev/null
dd if=BOOTSECT.IMG of=floppy.img conv=notrunc

mcopy -o BOOTER.IMG f: > /dev/null
mcopy -o BOOTER.CFG f: > /dev/null
mcopy -o BOLERO.IMG f: > /dev/null




