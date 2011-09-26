#!/bin/bash
# ICEDroid - setup.sh
# Custom kitchen to build the ROM given a CM nightly build / KANG build
KANG_DIR=$1
KERNEL_DIR=$2
EXTRA_DIRS="system data sdcard"
DATE=`date +%Y%m%d`
TIMESTAMP=`date +%Y%m%d`
HELP="Usage: $0 [-v] <kang.zip> <kernel.zip>"

ROOT_DIR=`pwd`
TOOLS_DIR=$ROOT_DIR/tools/
WORK_DIR=$ROOT_DIR/work/
DOWN_DIR=$ROOT_DIR/download/
OUT_DIR="$ROOT_DIR/out/icedroid-$DATE"

# Read config
. conf/sources.ini

if [ "$1" = "-v" ]; then
  VERBOSE=1
  LOG=/dev/stdout
  shift
else
  VERBOSE=0
  LOG=$ROOT_DIR/build-$TIMESTAMP.log
fi

# Reset log
echo "" > $LOG

# User requested clean
if [ "$1" = "clean" ]; then
  echo "Cleaning..."
  rm -rf $OUT_DIR $WORK_DIR
  exit
fi

# No args
if [ "$#" -lt "2" ]; then
  echo "$HELP"
  exit 1
fi

# Make tmp directories
if [ ! -d "$OUT_DIR" ]; then
  mkdir -p $OUT_DIR
fi
if [ ! -d "$WORK_DIR" ]; then
  mkdir -p $WORK_DIR
fi
if [ ! -d "$DOWN_DIR" ]; then
  mkdir -p $DOWN_DIR
fi

# If provided files exist, we use them
# If not, we download them from sources.ini
if [ -f "$1" ]; then
  ROMFILE=$1
else
  cd $DOWN_DIR
  echo "Downloading $ROMBASE/$1"
  wget "$ROMBASE/$1" >> $LOG
  ROMFILE=$DOWN_DIR/$1
  cd - &>/dev/null
fi

if [ -f "$2" ]; then
  KERNELFILE=$2
else
  cd $DOWN_DIR
  echo "Downloading $KERNELBASE/$1"
  wget "$KERNELBASE/$2" >> $LOG
  KERNELFILE=$DOWN_DIR/$2
  cd - &>/dev/null
fi

# Fix relative path
P=${ROMFILE:0:1}
if [ "$P" != "/" ]; then
  ROMFILE=$ROOT_DIR/$ROMFILE
fi
P=${KERNELFILE:0:1}
if [ "$P" != "/" ]; then
  KERNELFILE=$ROOT_DIR/$KERNELFILE
fi

# From there we are in work dir
cd $WORK_DIR

# Unpack
echo "Unpacking ROM ..."
KANG_DIR=$WORK_DIR/`basename $ROMFILE .zip`
rm -rf $KANG_DIR
mkdir $KANG_DIR ; cd $KANG_DIR
unzip -x $ROMFILE >> $LOG

echo "Unpacking KERNEL ..."
KERNEL_DIR=$WORK_DIR/`basename $KERNELFILE .zip`
rm -rf $KERNEL_DIR
mkdir $KERNEL_DIR ; cd $KERNEL_DIR
unzip -x $KERNELFILE >> $LOG

# Mixup everything
cd $ROOT_DIR
echo "Copying KANG files..."
cp -av $KANG_DIR/*   $OUT_DIR/  >> $LOG 2>&1
echo "Copying KERNEL files..."
cp -av $KERNEL_DIR/* $OUT_DIR/  >> $LOG 2>&1
echo "Copying custom extra directories..."
for i in $EXTRA_DIRS ; do 
  if [ ! -d $i ]; then
    echo "Error: $i does not exists - skipping"
  fi
  echo "[CP] $i/ => "`basename $OUT_DIR`"/$i"
  cp -av $i/* $OUT_DIR/$i/ >> $LOG 2>&1
done

# Special .prop.append files must be appended to original ones
# removing the older params
echo "Looking for *.prop.append files..."
for i in `find $OUT_DIR/ -name '*.prop.append'`; do
   BASE=`dirname $i`/`basename $i .append`
   echo "[PROP] $i"
   $TOOLS_DIR/propreplace.awk $i $BASE > $BASE.new
   mv $BASE.new $BASE ; rm -f $i
done
# Special .append files are simply appended to original ones
echo "Looking for *.append files..."
for i in `find $OUT_DIR/ -name '*.append'`; do
   BASE=`dirname $i`/`basename $i .append`
   echo "[APPEND] $i"
   cat $i >> $BASE
   rm -f $i
done

# Call the clean script
echo "Cleaning up..."
$TOOLS_DIR/clean.sh $OUT_DIR $LOG

## Timestamp
# cat $OUT_DIR/META-INF/com/google/android/updater-script | sed "s/%DATE%/$DATE/g" > $OUT_DIR/META-INF/com/google/android/updater-script.new 
#mv $OUT_DIR/META-INF/com/google/android/updater-script.new $OUT_DIR/META-INF/com/google/android/updater-script
#cat $OUT_DIR/system/build.prop | sed "s/%DATE%/$DATE/g" | sed "s/%TIMESTAMP%/$TIMESTAMP/g" > $OUT_DIR/system/build.prop.new
#mv $OUT_DIR/system/build.prop.new $OUT_DIR/system/build.prop
#
## Missing elements
#gvim -d $OUT_DIR/META-INF/com/google/android/updater-script \
#        $KANG_DIR/META-INF/com/google/android/updater-script \
#        $KERNEL_DIR/META-INF/com/google/android/updater-script
#
#cat <<EOF
#cd $OUT_DIR/ ; zip -r9 ../out-$DATE.zip . ; cd ../ ; ./sign.sh out-$DATE.zip out-$DATE-signed.zip 
#EOF

echo "Done!!!"
