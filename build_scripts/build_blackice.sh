#!/bin/bash

#
# build_blackice.sh
#
# Custom kitchen to build the ROM given a CM nightly build / KANG build.
#
# This script is intended to be invoked from ../build.sh and requires various
# script variables to already be initialized. It is not intended to be invoked
# as a standalone script.
#

# Read config

source ${SCRIPT_DIR}/../conf/sources.ini || ExitError "Sourcing 'conf/sources.ini'"
source ${SCRIPT_DIR}/../conf/blackice.ini  || ExitError "Sourcing 'conf/blackice.ini'"

# Base name for CM7 KANG that we build BlackICE on top of.
# If this doesn't exist we will try to download it from
# the base url in sources.ini
#${CM7_BASE_NAME}

#
# We use another variable here because we don't want to change the global
# TIMESTAMP variable
TIMESTAMP_OR_OFFICIAL=${TIMESTAMP}
if [ "$OFFICIAL" = "yes" ]; then
  TIMESTAMP_OR_OFFICIAL="OFFICIAL"
fi

# Kernel to use
# If this doesn't exist we will try to download it from
# the base url in sources.ini
KERNELFILE=${BLACKICE_KERNEL_NAME}

# Custom param LANGUAGE for GPS conf
# If the value is empty, our default system/etc/gps.conf will be included
GPS_REGION=${BLACKICE_GPS_NAME}

# Custom param for ril version
# If the value is empty, the original CM RIL will get included
RIL_VER=${BLACKICE_RIL_NAME}

TOOLS_DIR=${BLACKICE_DIR}/tools
WORK_DIR=${BLACKICE_DIR}/work/
DOWN_DIR=${BLACKICE_DIR}/download/
MOD_DIR=${BLACKICE_DIR}/mod

# Unzip stuff into OUT_DIR
OUT_DIR_BASE="${BLACKICE_DIR}/out"
OUT_DIR="${OUT_DIR_BASE}/${BLACKICE_VERSION}-${TIMESTAMP_OR_OFFICIAL}"
OUT_EXTRAAPPS="${OUT_DIR_BASE}/${BLACKICE_VERSION}-extraapps-${TIMESTAMP_OR_OFFICIAL}"

# RELEASE_DIR gets the final files built from the stuff in OUT_DIR
RELEASE_DIR_BASE=$OUT_DIR_BASE/release
RELEASE_DIR=${RELEASE_DIR_BASE}/${BLACKICE_VERSION}-${TIMESTAMP_OR_OFFICIAL}
RELEASE_ZIP="${RELEASE_DIR}/${BLACKICE_VERSION}-${TIMESTAMP_OR_OFFICIAL}.zip"
RELEASE_SIGNED="${RELEASE_DIR}/${BLACKICE_VERSION}-${TIMESTAMP_OR_OFFICIAL}-signed.zip"
RELEASE_EXTRAAPPS_ZIP="${RELEASE_DIR}/${BLACKICE_VERSION}-extraapps-${TIMESTAMP_OR_OFFICIAL}.zip"
RELEASE_EXTRAAPPS_SIGNED="${RELEASE_DIR}/${BLACKICE_VERSION}-extraapps-${TIMESTAMP_OR_OFFICIAL}-signed.zip"


# User requested clean of all temporary content
if [ "$CLEAN_ONLY" = "1" ]; then
  ShowMessage "* Removing $WORK_DIR"
  rm -rf $WORK_DIR

  ShowMessage "* Removing $OUT_DIR_BASE"
  rm -rf $OUT_DIR_BASE

  ShowMessage "* Removing build-*.log"
  rm -rf build-*.log
  return 0
fi


### Show version and banner
ShowMessage "$BLACKICE_VERSION"
cat ${SCRIPT_DIR}/../artwork/logo.txt

# Remove previous build stuff
ShowMessage "* Removing $WORK_DIR"
rm -rf $WORK_DIR

# Make tmp directories
if [ ! -d "$OUT_DIR" ]; then
  mkdir -p $OUT_DIR
fi
if [ ! -d "$RELEASE_DIR" ]; then
  mkdir -p $RELEASE_DIR
fi
if [ ! -d "$WORK_DIR" ]; then
  mkdir -p $WORK_DIR
fi
if [ ! -d "$DOWN_DIR" ]; then
  mkdir -p $DOWN_DIR
fi

# If provided files exist, we use them
# If not, we download them from the base url in sources.ini
if [ ! -f $CM7_BASE_NAME ]; then
  if [ -f ${DOWN_DIR}/${CM7_BASE_NAME} ]; then
    CM7_BASE_NAME=${DOWN_DIR}/${CM7_BASE_NAME}
  else
    cd $DOWN_DIR
    ROMSRC=${ROMBASE}/`basename ${CM7_BASE_NAME}`
    ShowMessage "* Downloading $ROMSRC"
    CheckDownloadZip "$ROMSRC" || ExitError "Can't download $ROMSRC"
    CM7_BASE_NAME=${DOWN_DIR}/${CM7_BASE_NAME}
    cd - &>/dev/null
  fi
fi

if [ ! -f $KERNELFILE ]; then
  if [ -f ${DOWN_DIR}/${KERNELFILE} ]; then
    KERNELFILE=${DOWN_DIR}/${KERNELFILE}
  else
    cd $DOWN_DIR
    KERNELSRC=${KERNELBASE}/`basename ${KERNELFILE}`
    ShowMessage "* Downloading $KERNELSRC"
    CheckDownloadZip "$KERNELSRC" || ExitError "Can't download $KERNELSRC"
    KERNELFILE=${DOWN_DIR}/${KERNELFILE}
    cd - &>/dev/null
  fi
fi

# Fix relative path
CM7_BASE_NAME=`FixPath $CM7_BASE_NAME`

# Unpack ROM
ShowMessage "* Unpacking ROM ..."
KANG_DIR=$WORK_DIR/`basename "$CM7_BASE_NAME" .zip`
rm -rf $KANG_DIR
mkdir $KANG_DIR ; cd $KANG_DIR
unzip -x $CM7_BASE_NAME >> $LOG
cd - &>/dev/null

# Unpack kernel zip and convert zImage to boot.img
KERNELFILE=`FixPath $KERNELFILE`
ShowMessage "* Unpacking KERNEL ... '${KERNELFILE}'"
KERNEL_DIR=$WORK_DIR/`basename "$KERNELFILE" .zip`
rm -rf $KERNEL_DIR
mkdir $KERNEL_DIR
cd $KERNEL_DIR
unzip -x $KERNELFILE >> $LOG || ExitError "Can't unzip $KERNELFILE"

${TOOLS_DIR}/mkbootimg.sh $KANG_DIR/boot.img $KERNEL_DIR/kernel/zImage $KERNEL_DIR/boot.img >> $LOG 2>&1 || ExitError "Can't run mkbootimg.sh"
cd - &>/dev/null

# From there we are in work dir
cd $WORK_DIR

# Kernel ID will be added to updater-script
KERNEL_ID=`basename $KERNEL_DIR`

# Mixup everything
cd ${BLACKICE_DIR}
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
  ShowMessage "  [CP]        $i/ => "`basename "$OUT_DIR"`"/$i"
  mkdir -p $OUT_DIR/$i/
  cp -av $i/* $OUT_DIR/$i/ >> $LOG 2>&1
done

# Special .prepend files are prepended to original ones
ShowMessage "* Looking for *.prepend files..."
for i in `find $OUT_DIR/ -name '*.prepend'`; do
   BASE=`dirname $i`/`basename "$i" .prepend`
   ShowMessage "  [PREPEND]   $i"
   cat $i $BASE >> $BASE.new
   rm -f $i ; mv $BASE.new $BASE
done

# Special .prop.append files must be appended to original ones
# removing the older params
ShowMessage "* Looking for *.prop.append files..."
for i in `find $OUT_DIR/ -name '*.prop.append'`; do
   BASE=`dirname $i`/`basename "$i" .append`
   ShowMessage "  [PROP]     " `basename "$i"`
   ${TOOLS_DIR}/propreplace.awk $i $BASE > $BASE.new
   # Customize versioning from blackice.ini
   cat $BASE.new | sed "s/BLACKICE_VERSION/$BLACKICE_VERSION/g" \
        > $BASE ; rm -f $i $BASE.new
done

# Remaining .append files are simply appended to original ones
ShowMessage "* Looking for *.append files..."
for i in `find $OUT_DIR/ -name '*.append'`; do
   BASE=`dirname $i`/`basename "$i" .append`
   ShowMessage "  [APPEND]   " `basename "$i"`
   cat $i >> $BASE
   rm -f $i
done

# Mod files
if [ "$MODAPKS" = "1" ]; then
   MODS=`for i in $MOD_DIR/*.apk; do echo $i ; done | sort -n`
   for i in $MODS ; do
     BASE=`basename "$i" .apk`
     if [ -f "mod/${BASE}.exclude" ]; then
       continue ; # dirty hack to exclude framework-res modding
     fi
     # Read specific options
     if [ -f "mod/${BASE}.options" ]; then
       . mod/${BASE}.options
       export APKMOD_METHOD=$method
       export APKMOD_PATCH=$patch
     else
       unset APKMOD_METHOD
       unset APKMOD_PATCH
     fi

     # We allow several mods for 1 apk
     BASE=${BASE%\.*}
     ORIG=`find $OUT_DIR/system -name "$BASE.apk"`
     if [ -f "$ORIG" ]; then
       ShowMessage "  [MOD]       $BASE.apk ($i)"
       ${TOOLS_DIR}/apkmod.sh $ORIG $i || ExitError "Cannot mod $ORIG. See $LOG for details"
     fi
   done
fi

# Bootanimation
if [ -f ${BLACKICE_DIR}/artwork/bootanimation.zip ]; then
  ShowMessage "  [CP]        bootanimation.zip"
  cp "${BLACKICE_DIR}/artwork/bootanimation.zip" $OUT_DIR/system/media/ >> $LOG
else
  ShowMessage "  [ZIP]       bootanimation.zip"
  cd artwork/bootanimation/
  zip -r0 ${BLACKICE_DIR}/work/bootanimation.zip desc.txt part0/* part1/* >> $LOG
  ShowMessage "  [CP]        bootanimation.zip"
  cp -av ${BLACKICE_DIR}/work/bootanimation.zip $OUT_DIR/system/media/ >> $LOG
  cd - &> /dev/null
fi

# GPS and RIL
if [ "$RIL_VER" != "" -a -d ${BLACKICE_DIR}/sdcard/blackice/ril/HTC-RIL_$RIL_VER ]; then
  ShowMessage "  [CP]        HTC-RIL $RIL_VER"
  cp -a "${BLACKICE_DIR}/sdcard/blackice/ril/HTC-RIL_$RIL_VER/system/bin/rild" $OUT_DIR/system/bin/rild >> $LOG
  cp -a "${BLACKICE_DIR}/sdcard/blackice/ril/HTC-RIL_$RIL_VER/system/lib/libhtc_ril.so" $OUT_DIR/system/lib/libhtc_ril.so >> $LOG
  cp -a "${BLACKICE_DIR}/sdcard/blackice/ril/HTC-RIL_$RIL_VER/system/lib/libril.so" $OUT_DIR/system/lib/libril.so >> $LOG
fi
if [ "$GPS_REGION" != "" -a -d ${BLACKICE_DIR}/sdcard/blackice/gpsconf/$GPS_REGION ]; then
  ShowMessage "  [CP]        GPS for $GPS_REGION"
  cp -a "${BLACKICE_DIR}/sdcard/blackice/gpsconf/$GPS_REGION/gps.conf" $OUT_DIR/system/etc/ >> $LOG
fi

# META-INF files
# updater-script is built from the prepared logo, extracted kernel-id and patches
ShowMessage "  [META]     " $BLACKICE_VERSION "-" $KERNEL_ID
for i in CERT.RSA CERT.SF MANIFEST.MF; do
   cp ${BLACKICE_DIR}/meta/$i $OUT_DIR/META-INF/ >> $LOG
done
cd $OUT_DIR/META-INF/com/google/android/
patch -p0 < ${BLACKICE_DIR}/meta/updater-script.patch >> $LOG
( ( cat ${BLACKICE_DIR}/artwork/logo.txt ; echo $BLACKICE_VERSION "-" $KERNEL_ID ) |
  awk '{ print "ui_print(\"" $0 "\");" }' ;
  cat updater-script ) \
  > updater-script.new
mv updater-script.new updater-script
cd - &>/dev/null

# TODO source build ICETool

# Copy bin/ICETool.apk and whatever is built under src
for i in src/*/bin/*.apk; do
   ShowMessage "  [APK]      " `basename $i`
   cp $i $OUT_DIR/system/app/
done

# Move possible packages to extraapps
for i in $EXTRAAPPS_APK; do
   # It could have a :* part with destination
   SRC=${i%\:*}
   DST=${i##*:}
   DST=$OUT_EXTRAAPPS/$DST
   if [ -f $OUT_DIR/$SRC ]; then
     mkdir -p `dirname $DST`
     ShowMessage "  [MV]       " $i " => $DST"
     mv $OUT_DIR/$SRC $DST
   fi
done

# zipalign
if [ "$ZIPALIGN" = "1" ]; then
  printf "  [ZIPALIGN]  "
  for i in `find $OUT_DIR/ -name '*.apk'`; do
     printf "`basename $i` "
     tools/zipalign -f 4 $i $i.new
     mv $i.new $i
  done
  printf "\n"
fi

# Call the clean script
ShowMessage "* Cleaning up..."
${TOOLS_DIR}/clean.sh $OUT_DIR $LOG

# zip and sign
ShowMessage "  [ZIP]       $RELEASE_ZIP"
cd $OUT_DIR
zip $ZIPFLAGS $RELEASE_ZIP \
  $ROM_DIR_LIST >> $LOG

if [ "$SIGN_ZIP" = "1" ]; then
  ShowMessage "  [SIGN]      $RELEASE_SIGNED"
  ${TOOLS_DIR}/sign.sh $RELEASE_ZIP $RELEASE_SIGNED >> $LOG
fi

cd - &>/dev/null

# Extraapps
if [ "$EXTRA_APPS" = "1" ] ; then
  ShowMessage "  [CP]        $EXTRAAPPS_DIR"
  cp -av $BLACKICE_DIR/$EXTRAAPPS_DIR/* $OUT_EXTRAAPPS/ >> $LOG
  cd $OUT_EXTRAAPPS/META-INF/com/google/android/
  ( ( cat ${BLACKICE_DIR}/artwork/logo.txt ; echo "$BLACKICE_VERSION-extraapps" ) |
    awk '{ print "ui_print(\"" $0 "\");" }' ;
    cat updater-script ) \
    > updater-script.new
  mv updater-script.new updater-script
  cd - &>/dev/null

  ShowMessage "  [ZIP]       $RELEASE_EXTRAAPPS_ZIP"
  cd $OUT_EXTRAAPPS
  zip $ZIPFLAGS $RELEASE_EXTRAAPPS_ZIP . >> $LOG

  if [ "$SIGN_ZIP" = "1" ]; then
    ShowMessage "  [SIGN]      $RELEASE_EXTRAAPPS_SIGNED"
    ${TOOLS_DIR}/sign.sh $RELEASE_EXTRAAPPS_ZIP $RELEASE_EXTRAAPPS_SIGNED_ >> $LOG
  fi
fi
cd - &>/dev/null
