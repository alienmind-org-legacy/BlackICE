#!/bin/bash
# BlackICE - setup.sh
# Custom kitchen to build the ROM given a CM nightly build / KANG build
# Read config
. conf/sources.ini
. conf/blackice.ini
. tools/util_sh

KANG_ZIP=$1
KERNEL_ZIP=$2

DATE=`date +%Y%m%d`
TIMESTAMP=`date +%Y%m%d`
HELP="Usage: $0 [-v] <kang.zip> <kernel.zip>"

TOOLS_DIR=${ROOT_DIR}/tools/
WORK_DIR=${ROOT_DIR}/work/
DOWN_DIR=${ROOT_DIR}/download/
OUT_DIR="${ROOT_DIR}/out/${BLACKICE_VERSION}-${DATE}"
OUT_ZIP="${OUT_DIR}.zip"
OUT_SIGNED="${OUT_DIR}-signed.zip"
OUT_EXTRAAPPS="${ROOT_DIR}/out/${BLACKICE_VERSION}-extraapps-${DATE}"
OUT_EXTRAAPPS_ZIP="${OUT_EXTRAAPPS}.zip"
OUT_EXTRAAPPS_SIGNED="${OUT_EXTRAAPPS}-signed.zip"

if [ "$1" = "-v" ]; then
  VERBOSE=1
  LOG=/dev/stdout
  shift
else
  VERBOSE=0
  LOG=${ROOT_DIR}/build-${TIMESTAMP}.log
fi


# Reset log
echo "" > $LOG

# User requested clean
if [ "$1" = "clean" ]; then
  ShowMessage "* Cleaning..."
  rm -rf $WORK_DIR $OUT_DIR $OUT_ZIP $OUT_SIGNED $OUT_EXTRAAPPS $OUT_EXTRAPPS_ZIP $OUT_EXTRAPPS_SIGNED *.log
  exit
fi

# Bad args
if [ "$#" -lt "2" ]; then
  ShowMessage "$HELP"
  exit 1
fi

### Show version and banner
echo "$BLACKICE_VERSION"
cat artwork/logo.txt

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
  ROMSRC=$ROMBASE/`basename $1`
  ShowMessage "* Downloading $ROMSRC"
  CheckDownloadZip "$ROMSRC" || ExitError "Can't download $ROMSRC"
  ROMFILE=$DOWN_DIR/$1
  cd - &>/dev/null
fi
if [ -f "$2" ]; then
  KERNELFILE=$2
elif [ -f "$DOWN_DIR/$2" ]; then
  KERNELFILE=$DOWN_DIR/$2
else
  cd $DOWN_DIR
  KERNELSRC=$KERNELBASE/`basename $2`
  ShowMessage "* Downloading $KERNELSRC"
  CheckDownloadZip "$KERNELSRC" || ExitError "Can't download $KERNELSRC"
  KERNELFILE=$DOWN_DIR/$2
  cd - &>/dev/null
fi

# Fix relative path
ROMFILE=`FixPath $ROMFILE`

# Unpack ROM
ShowMessage "* Unpacking ROM ..."
KANG_DIR=$WORK_DIR/`basename "$ROMFILE" .zip`
rm -rf $KANG_DIR
mkdir $KANG_DIR ; cd $KANG_DIR
unzip -x $ROMFILE >> $LOG
cd - &>/dev/null

# Unpack kernel zip and convert zImage to boot.img 
KERNELFILE=`FixPath $KERNELFILE`
ShowMessage "* Unpacking KERNEL ..."
KERNEL_DIR=$WORK_DIR/`basename "$KERNELFILE" .zip`
rm -rf $KERNEL_DIR
mkdir $KERNEL_DIR
cd $KERNEL_DIR
unzip -x $KERNELFILE >> $LOG
mkbootimg.sh $KANG_DIR/boot.img $KERNEL_DIR/kernel/zImage $KERNEL_DIR/boot.img >> $LOG 2>&1
cd - &>/dev/null

# From there we are in work dir
cd $WORK_DIR

# Kernel ID will be added to updater-script
KERNEL_ID=`basename $KERNEL_DIR`

# Mixup everything
cd ${ROOT_DIR}
ShowMessage "* Copying KANG files..."
for i in $ROM_DIR_LIST; do
   cp -av $KANG_DIR/$i   $OUT_DIR/  >> $LOG 2>&1
done
ShowMessage "* Copying KERNEL files..."
for i in $KERNEL_DIR_LIST; do
  cp -av $KERNEL_DIR/$i $OUT_DIR/  >> $LOG 2>&1
done
ShowMessage "* Downloading data APKs..."
mkdir -p $OUT_DIR/data/app/
cd $DOWN_DIR/
for i in $DATA_APKS ; do 
  APK=`basename "$i"`
  CheckDownloadZip "$i" || ExitError "Can't download $i"
  cp $APK $OUT_DIR/data/app/
done
ShowMessage "* Downloading extra APKs..."
mkdir -p $OUT_EXTRAAPPS/data/app/
for i in $EXTRA_APKS ; do 
  APK=`basename "$i"`
  CheckDownloadZip "$i" || ExitError "Can't download $i"
  cp $APK $OUT_EXTRAAPPS/data/app/
done
cd - &>/dev/null

ShowMessage "* Copying custom extra directories..."
for i in $EXTRA_DIRS ; do 
  if [ ! -d $i ]; then
    ShowMessage "Warning: $i does not exists - skipping"
  fi
  ShowMessage "  [CP] $i/ => "`basename "$OUT_DIR"`"/$i"
  mkdir -p $OUT_DIR/$i/
  cp -av $i/* $OUT_DIR/$i/ >> $LOG 2>&1
done

# Special .prepend files are prepended to original ones
ShowMessage "* Looking for *.prepend files..."
for i in `find $OUT_DIR/ -name '*.prepend'`; do
   BASE=`dirname $i`/`basename "$i" .prepend`
   ShowMessage "  [PREPEND] $i"
   cat $i $BASE >> $BASE.new
   rm -f $i ; mv $BASE.new $BASE
done

# Special .prop.append files must be appended to original ones
# removing the older params
ShowMessage "* Looking for *.prop.append files..."
for i in `find $OUT_DIR/ -name '*.prop.append'`; do
   BASE=`dirname $i`/`basename "$i" .append`
   ShowMessage "  [PROP] " `basename "$i"`
   $TOOLS_DIR/propreplace.awk $i $BASE > $BASE.new
   # Customize versioning from blackice.ini
   cat $BASE.new | sed "s/BLACKICE_VERSION/$BLACKICE_VERSION/g" \
        > $BASE ; rm -f $i $BASE.new
done

# Remaining .append files are simply appended to original ones
ShowMessage "* Looking for *.append files..."
for i in `find $OUT_DIR/ -name '*.append'`; do
   BASE=`dirname $i`/`basename "$i" .append`
   ShowMessage "  [APPEND] " `basename "$i"`
   cat $i >> $BASE
   rm -f $i
done

# Mod files
if [ "$MODAPKS" = "1" ]; then
for i in app/* ; do
   BASE=`basename "$i"`
   BASE=${BASE%\.*} # We allow several mods for 1 apk
   if [ -f "app/${BASE}.exclude" ]; then
     continue ; # dirty hack to exclude framework-res modding
   fi
   ORIG=`find $OUT_DIR/system -name "$BASE.apk"`
   if [ -f "$ORIG" ]; then
     ShowMessage "  [MOD] $BASE.apk ($i)"
     tools/apkmod.sh $ORIG $i
   fi
done
fi

# Bootanimation
if [ -f ${ROOT_DIR}/artwork/bootanimation.zip ]; then
  ShowMessage "  [CP] bootanimation.zip"
  cp "${ROOT_DIR}/artwork/bootanimation.zip" $OUT_DIR/system/media/ >> $LOG
else
  ShowMessage "  [ZIP] bootanimation.zip"
  cd artwork/bootanimation/
  zip -r0 ${ROOT_DIR}/work/bootanimation.zip desc.txt part0/* part1/* >> $LOG
  ShowMessage "  [CP] bootanimation.zip"
  cp -av ${ROOT_DIR}/work/bootanimation.zip $OUT_DIR/system/media/ >> $LOG
  cd - &> /dev/null
fi

# META-INF files
# updater-script is built from the prepared logo, extracted kernel-id and patches
ShowMessage "  [META] " $BLACKICE_VERSION "-" $KERNEL_ID
for i in CERT.RSA CERT.SF MANIFEST.MF; do
   cp ${ROOT_DIR}/meta/$i $OUT_DIR/META-INF/ >> $LOG
done
cd $OUT_DIR/META-INF/com/google/android/
patch -p0 < ${ROOT_DIR}/meta/updater-script.patch >> $LOG
( ( cat ${ROOT_DIR}/artwork/logo.txt ; echo $BLACKICE_VERSION "-" $KERNEL_ID ) |
  awk '{ print "ui_print(\"" $0 "\");" }' ;
  cat updater-script ) \
  > updater-script.new
mv updater-script.new updater-script
cd - &>/dev/null

# TODO source build ICETool

# Copy bin/ICETool.apk and whatever is built under src
for i in src/*/bin/*.apk; do
   ShowMessage "  [APK] "`basename $i`
   cp $i $OUT_DIR/system/app/
done

# Move possible packages to extraapps
for i in $EXTRAAPPS_APK; do
   # It could have a :* part with destinatino
   SRC=${i%\:*}
   DST=${i##*:}
   DST=$OUT_EXTRAAPPS/$DST
   if [ -f $OUT_DIR/$SRC ]; then
     mkdir -p `dirname $DST`
     ShowMessage "  [MV] " $i " => $DST"
     mv $OUT_DIR/$SRC $DST
   fi
done

# zipalign
if [ "$ZIPALIGN" = "1" ]; then
  printf "  [ZIPALIGN] " 
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
ShowMessage "  [ZIP] $OUT_ZIP"
cd $OUT_DIR
zip $ZIPFLAGS $OUT_ZIP \
  $ROM_DIR_LIST >> $LOG
if [ "$SIGN_ZIP" = "1" ]; then
  ShowMessage "  [SIGN] $OUT_SIGNED"
  sign.sh $OUT_ZIP $OUT_SIGNED >> $LOG
fi
cd - &>/dev/null

# Extraapps
if [ "$EXTRA_APPS" = "1" ] ; then
  ShowMessage "  [CP] $EXTRAAPPS_DIR"
  cp -av $ROOT_DIR/$EXTRAAPPS_DIR/* $OUT_EXTRAAPPS/ >> $LOG
  cd $OUT_EXTRAAPPS/META-INF/com/google/android/
  ( ( cat ${ROOT_DIR}/artwork/logo.txt ; echo $BLACKICE_VERSION "-extrapps" ) |
    awk '{ print "ui_print(\"" $0 "\");" }' ;
    cat updater-script ) \
    > updater-script.new
  mv updater-script.new updater-script
  cd - &>/dev/null

  ShowMessage "  [ZIP] $OUT_EXTRAAPPS_ZIP"
  cd $OUT_EXTRAAPPS
  zip $ZIPFLAGS $OUT_EXTRAAPPS_ZIP . >> $LOG
  if [ "$SIGN_ZIP" = "1" ]; then
    ShowMessage "  [SIGN] $OUT_EXTRAAPPS_SIGNED"
    sign.sh $OUT_EXTRAAPPS_ZIP $OUT_EXTRAPPS_SIGNED >> $LOG
  fi
fi
cd - &>/dev/null
 
ShowMessage "* Done!!!"
