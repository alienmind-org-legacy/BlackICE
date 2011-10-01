#!/bin/bash
export PATH=$PATH:tools
if [ "$#" != "3" ]; then
  echo "Usage: $0 <original_boot.img> <kernel_zImage> <output_boot.img>"
  exit 1
fi
T=$PWD/.mkbootimgtmp
mkdir -p $T
ORIBOOTIMG=$1
ZIMAGE=$2
BOOT=$3
dd if=$ORIBOOTIMG of=$BOOT.tmp
unpackbootimg -i $BOOT.tmp -o $T
mkbootimg --kernel $ZIMAGE --ramdisk $T/boot.img.tmp-ramdisk.gz --cmdline `cat $T/boot.img.tmp-cmdline` \
                            --base `cat $T/boot.img.tmp-base` --output $BOOT
rm -rf $BOOT.tmp $T
