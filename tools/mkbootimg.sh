#!/bin/bash
#
# All the tools we reference should be in the ICEDroid/tools directory,
# which is the same directory this script is supposed to be running from.
#
OUR_ABS_PATH=$(cd "$(dirname "$0")"; pwd)
export PATH=$PATH:${OUR_ABS_PATH}

if [ "$#" != "3" ]; then
  echo "Usage: $0 <original_boot.img> <kernel_zImage> <output_boot.img>"
  exit 1
fi
T=$PWD/.mkbootimgtmp
mkdir -p $T
ORIBOOTIMG=$1
ZIMAGE=$2
BOOT=$3
TMPBOOT=`basename $3`
dd if=$ORIBOOTIMG of=$TMPBOOT.tmp
unpackbootimg -i $TMPBOOT.tmp -o $T
mkbootimg --kernel $ZIMAGE --ramdisk $T/$TMPBOOT.tmp-ramdisk.gz --cmdline `cat $T/$TMPBOOT.tmp-cmdline` \
                            --base `cat $T/$TMPBOOT.tmp-base` --output $BOOT
rm -rf $TMPBOOT.tmp $T
