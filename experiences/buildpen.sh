PATH=$PATH:/sbin:../support/fasm

# 128MB pendrive image with empty partition table:
dd if=/dev/zero of=pendrv.img bs=$((1024*1024)) count=128
#echo -n -e "\x55\xAA" | dd of=pendrv.img bs=1 seek=510 conv=notrunc
fakeroot parted pendrv.img mklabel msdos

# Create pendrive partition
parted -s pendrv.img mkpart primary 16 100%

export MTOOLSRC="../mtools.conf"

# Format pendrive partition...
mformat p:

# Now we are supposed to run some commands to install grub in the pen drive...
grub-mkimage -c myconf.grub -o mygrub.img -O i386-pc normal fat configfile biosdisk part_msdos multiboot cat
dd if=/boot/grub/i386-pc/boot.img of=pendrv.img bs=1 count=446 conv=notrunc
#grub-install.real pendrv.img
dd if=mygrub.img of=pendrv.img bs=1 seek=512 conv=notrunc

#Compile kernel and copy it to pendrive...
fasm multiboot64.asm multiboot64.bin
mcopy multiboot64.bin p:

# Run the beast!
qemu-system-i386 -usbdevice disk:format=raw:pendrv.img
