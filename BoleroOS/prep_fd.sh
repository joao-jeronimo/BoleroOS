# !/bin/sh

dd if=/dev/zero of=floppy.img count=2880 2> /dev/null
mformat -t 80 -h 2 -n 18 m: > /dev/null



./insboot -o floppy.img BOOTSECT.IMG > /dev/null

mcopy -o BOOTER.IMG m: > /dev/null
mcopy -o BOOTER.CFG m: > /dev/null
mcopy -o KERNEL.IMG m: > /dev/null




