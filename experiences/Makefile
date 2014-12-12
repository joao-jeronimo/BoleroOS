PATH      := $(PATH):/sbin:../support/fasm
MTOOLSRC  := ../mtools.conf

export MTOOLSRC PATH


all:	multiboot64.bin

multiboot64.bin:	multiboot64.asm
	@echo [FASM] "$@"
	@#Compile kernel and copy it to pendrive...
	@fasm multiboot64.asm multiboot64.bin





.PHONY:run
run:	pen
	@echo "Running the beast!..."
	@qemu-system-x86_64 -usbdevice disk:format=raw:pendrv.img


mygrub.img:myconf.grub
	@echo [GRUB-MKIMAGE] "$@"
	@# Now we are supposed to run some commands to install grub in the pen drive...
	@grub-mkimage -c myconf.grub -o mygrub.img -O i386-pc normal fat configfile biosdisk part_msdos multiboot cat

.PHONY:pen
pen:pendrv.img

pendrv.img:	mygrub.img multiboot64.bin rebuild_pen
	@echo "Updating $@..."
	@dd if=/boot/grub/i386-pc/boot.img of=pendrv.img bs=1 count=446 conv=notrunc   2> /dev/null
	@#grub-install.real pendrv.img
	@dd if=mygrub.img of=pendrv.img bs=1 seek=512 conv=notrunc   2> /dev/null
	@mcopy -o multiboot64.bin p:


rebuild_pen:	Makefile
	@echo "Rebuilding pendrv.img"
	@# 128MB pendrive image with empty partition table:
	@dd if=/dev/zero of=pendrv.img bs=$(shell echo $$((1024*1024)) ) count=128   2> /dev/null
	@#echo -n -e "\x55\xAA" | dd of=pendrv.img bs=1 seek=510 conv=notrunc
	@fakeroot parted pendrv.img mklabel msdos
	@# Create pendrive partition
	@parted -s pendrv.img mkpart primary 16 100%
	@# Format pendrive partition...
	@mformat p:
	@touch $@



.PHONY:clean
clean:
	rm -rf *.img *.bin rebuild_pen
