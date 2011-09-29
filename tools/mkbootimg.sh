KERNELDIR=$1
BOOT=$2
dd if=$KERNELDIR/zImage of=$BOOT.tmp
unpackbootimg $BOOT.tmp $KERNELDIR
mkbootimg --kernel $KERNELDIR/zImage --ramdisk $KERNELDIR/boot.img-ramdisk.gz --cmdline `cat $KERNELDIR/boot.img-cmdline` \
                            --base `cat $KERNELDIR/boot.img-base` --output $2
