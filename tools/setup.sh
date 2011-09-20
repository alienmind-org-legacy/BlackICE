#!/bin/sh
# ICEDroid - setup.sh
# Custom kitchen to build the ROM given a CM nightly build / KANG build
KANG_DIR=$1
KERNEL_DIR=$2
EXTRA_DIRS="system data sdcard"
DATE=`date +%Y%m%d`
TOOLS_DIR=tools/
TIMESTAMP=`date +%Y%m%d%H%M%s`
OUT_DIR="out/icedroid-$DATE"

if [ "$2" = "-v" ]; then
  VERBOSE=1
  LOG=/dev/stdout
  shift
else
  VERBOSE=0
  LOG=build-$TIMESTAMP.log
fi

if [ "$#" -lt "2" ]; then
  echo "Usage: $0 [-v] <kang_dir> <kernel_dir>"
  exit 1
fi

if [ -d "$OUT_DIR" ]; then
  echo "Error: $OUT_DIR already exists - doing nothing"
  exit 2
fi

if [ ! -d "$KANG_DIR" -o ! -d "$KERNEL_DIR" ]; then
  echo "Error: At least one of the provided directories does not exists"
  exit 3
fi

mkdir -p $OUT_DIR

# Mixup everything
echo "Copying KANG files..."
cp -av $KANG_DIR/*   $OUT_DIR/  > $LOG 2>&1
echo "Copying KERNEL files..."
cp -av $KERNEL_DIR/* $OUT_DIR/  > $LOG 2>&1
echo "Copying custom extra directories..."
for i in $EXTRA_DIRS ; do 
  if [ ! -d $i ]; then
    echo "Error: $i does not exists - aborting"
  fi
  echo "[$i]"
  cp -av $i/* $OUT_DIR/ > $LOG 2>&1
done

# .append files must be appended to original ones
echo "Looking for .append files..."
for i in `find $OUT_DIR/ -name '*.append'`; do
   BASE=`basename $i`
   echo "* $i"
   cat $i >> $BASE
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
