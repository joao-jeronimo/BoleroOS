
# 128MB pendrive image with empty partition table:
dd if=/dev/zero of=pendrv.img bs=$((1024*1024)) count=128
#echo -n -e "\x55\xAA" | dd of=pendrv.img bs=1 seek=510 conv=notrunc
fakeroot parted pendrv.img mklabel msdos

# Create pendrive partition
parted -s pendrv.img mkpart primary 0% 100%

export MTOOLSRC="../mtools.conf"

# Format pendrive partition...
mformat p:

