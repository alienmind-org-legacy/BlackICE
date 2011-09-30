#!/bin/bash
# ICEDroid - setup.sh
# Custom kitchen to build the ROM given a CM nightly build / KANG build
# Read config
. conf/sources.ini
. conf/icedroid.ini
. tools/util_sh

KANG_DIR=$1
KERNEL_DIR=$2

DATE=`date +%Y%m%d`
TIMESTAMP=`date +%Y%m%d`
HELP="Usage: $0 [-v] <kang.zip> [kernel.zip]"

TOOLS_DIR=$ROOT_DIR/tools/
WORK_DIR=$ROOT_DIR/work/
DOWN_DIR=$ROOT_DIR/download/
OUT_DIR="$ROOT_DIR/out/icedroid-$DATE"
OUT_ZIP="${OUT_DIR}.zip"
OUT_SIGNED="${OUT_DIR}-signed.zip"

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
  ShowMessage "* Cleaning..."
  rm -rf $OUT_DIR $WORK_DIR
  exit
fi

# No args
if [ "$#" -lt "1" ]; then
  ShowMessage "$HELP"
  exit 1
fi

###
cat <<EOF
     ProjectX introducing...
           _  __ ___ __         __  
          | |/ _| __|  \ _  _ ()  \ 
          | ( (_| _|| o )_|/o\|| o )
          |_|\__|___|__/L| \_/L|__/ 

EOF


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
# If not, we download them from the base url in sources.ini
if [ -f "$1" ]; then
  ROMFILE=$1
elif [ -f "$DOWN_DIR/$1" ]; then
  ROMFILE=$DOWN_DIR/$1
else
  cd $DOWN_DIR
  ShowMessage "* Downloading $ROMBASE/$1"
  wget "$ROMBASE/$1" >> $LOG
  ROMFILE=$DOWN_DIR/$1
  cd - &>/dev/null
fi

# Fix relative path
ROMFILE=`FixPath $ROMFILE`

if [ -f "$2" ]; then
  KERNELFILE=$2
  KERNELFILE=`FixPath $KERNELFILE`
  ShowMessage "* Unpacking KERNEL ..."
  KERNEL_DIR=$WORK_DIR/`basename "$KERNELFILE" .zip`
  rm -rf $KERNEL_DIR
  mkdir $KERNEL_DIR ; cd $KERNEL_DIR
  unzip -x $KERNELFILE >> $LOG
  cd - &>/dev/null
else
  KERNELFILE=""
  KERNEL_DIR=$ROOT_DIR/kernel/ # Local copy
  #cd $DOWN_DIR
  #ShowMessage "* Downloading $KERNELBASE/$2"
  #wget "$KERNELBASE/$2" >> $LOG
  #KERNELFILE=$DOWN_DIR/$2
  #cd - &>/dev/null
fi

# From there we are in work dir
cd $WORK_DIR

# Unpack ROM
ShowMessage "* Unpacking ROM ..."
KANG_DIR=$WORK_DIR/`basename "$ROMFILE" .zip`
rm -rf $KANG_DIR
mkdir $KANG_DIR ; cd $KANG_DIR
unzip -x $ROMFILE >> $LOG

# Extract relevant identification strings from kernel
if [ -f "$KERNEL_DIR/META-INF/com/google/android/updater-script" ]; then
  KERNEL_ID=`cat $KERNEL_DIR/META-INF/com/google/android/updater-script | \
           grep -e Lord -e High`
fi

# Mixup everything
cd $ROOT_DIR
ShowMessage "* Copying KANG files..."
for i in $ROM_DIR_LIST; do
   cp -av $KANG_DIR/$i   $OUT_DIR/  >> $LOG 2>&1
done
ShowMessage "* Copying KERNEL files..."
for i in $KERNEL_DIR_LIST; do
  cp -av $KERNEL_DIR/$i $OUT_DIR/  >> $LOG 2>&1
done
ShowMessage "* Copying custom extra directories..."
for i in $EXTRA_DIRS ; do 
  if [ ! -d $i ]; then
    ShowMessage "Error: $i does not exists - skipping"
  fi
  ShowMessage "[CP] $i/ => "`basename "$OUT_DIR"`"/$i"
  cp -av $i/* $OUT_DIR/$i/ >> $LOG 2>&1
done

# Special .prepend files are prepended to original ones
ShowMessage "* Looking for *.prepend files..."
for i in `find $OUT_DIR/ -name '*.prepend'`; do
   BASE=`dirname $i`/`basename "$i" .prepend`
   ShowMessage "[PREPEND] $i"
   cat $i $BASE >> $BASE.new
   rm -f $i ; mv $BASE.new $BASE
done

# Special .prop.append files must be appended to original ones
# removing the older params
ShowMessage "* Looking for *.prop.append files..."
for i in `find $OUT_DIR/ -name '*.prop.append'`; do
   BASE=`dirname $i`/`basename "$i" .append`
   ShowMessage "[PROP] " `basename "$i"`
   $TOOLS_DIR/propreplace.awk $i $BASE > $BASE.new
   mv $BASE.new $BASE ; rm -f $i
done

# Remaining .append files are simply appended to original ones
ShowMessage "* Looking for *.append files..."
for i in `find $OUT_DIR/ -name '*.append'`; do
   BASE=`dirname $i`/`basename "$i" .append`
   ShowMessage "[APPEND] " `basename "$i"`
   cat $i >> $BASE
   rm -f $i
done

# Mod files
if [ "$MODAPKS" = "1" ]; then
for i in app/* ; do
   BASE=`basename "$i"`
   ORIG=`find $OUT_DIR/ -name "$BASE.apk"`
   if [ -f $ORIG ]; then
     ShowMessage "[MOD] $i.apk "
     tools/apkmod.sh $ORIG $i
   fi
done
fi

# Bootanimation
if [ -f $ROOT_DIR/artwork/bootanimation.zip ]; then
  ShowMessage "[CP] bootanimation.zip"
  cp "$ROOT_DIR/artwork/bootanimation.zip" $OUT_DIR/system/media/ >> $LOG
else
  ShowMessage "[ZIP] bootanimation.zip"
  cd artwork/bootanimation/
  zip -r $ROOT_DIR/work/bootanimation.zip desc.txt part0/* part1/* >> $LOG
  ShowMessage "[CP] bootanimation.zip"
  cp -av $ROOT_DIR/work/bootanimation.zip $OUT_DIR/system/media/ >> $LOG
  cd - &> /dev/null
fi

# META-INF files
# updater-script is built from the prepared logo, extracted kernel-id and patches
for i in CERT.RSA CERT.SF MANIFEST.MF; do
   cp $ROOT_DIR/meta/$i $OUT_DIR/META-INF/
done
cd $OUT_DIR/META-INF/com/google/android/
patch -p0 < $ROOT_DIR/meta/updater-script.patch
( cat $ROOT_DIR/meta/updater-script.logo ;
  echo $KERNEL_ID ;
  cat updater-script ) \
  > updater-script.new
mv updater-script.new updater-script
cd - &>/dev/null

# TODO mkbootimg-remote.sh when kernel is not the included one

# TODO source build ICETool

# Copy bin/ICETool.apk and whatever is built under src
for i in src/*/bin/*.apk; do
   ShowMessage "[APK] "`basename $i`
   cp $i $OUT_DIR/system/app/
done

# zipalign
if [ "$ZIPALIGN" = "1" ]; then
  printf "[ZIPALIGN] " 
  for i in `find $OUT_DIR/ -name '*.apk'`; do
     printf "`basename $i` "
     tools/zipalign -f 4 $i $i.new 
     mv $i.new $i
  done
  printf "\n"
fi

# Call the clean script
ShowMessage "* Cleaning up..."
$TOOLS_DIR/clean.sh $OUT_DIR $LOG

# zip and sign
ShowMessage "[ZIP] $OUT_ZIP"
cd $OUT_DIR
zip $ZIPFLAGS $OUT_ZIP \
  $ROM_DIR_LIST >> $LOG
if [ "$SIGN_ZIP" = "1" ]; then
  ShowMessage "[SIGN] $OUT_SIGNED"
  sign.sh $OUT_ZIP $OUT_SIGNED >> $LOG
fi
cd - &>/dev/null

ShowMessage "* Done!!!"
