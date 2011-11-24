#!/bin/bash
. tools/util_sh

# Finds resources
# in mod_dir, print them with rel path fixed
function FindResources() {
  local MOD_DIR=$1
  shift 1
  local RES_PATTERN=$@
  cd $MOD_DIR
  for f in `find $RES_PATTERN`; do
     n=`FixRelPath $f`
     echo $n
  done
  cd - &>/dev/null
}

# Updates metafiles with specific files
# Prevents broken builds of framework-res
# with apktool b
# FIXME - dirty as 7za u does not work
function UpdateMeta() {
  local APK_FILE=$1
  local META_DIR=$2
  local TMP_DIR=$1.tmp

  ShowMessage "  [MOD|7zu] " $APK_FILE

  # Temp dir
  CUR_DIR=`pwd`
  rm -rf $TMP_DIR
  mkdir -p $TMP_DIR

  # Extract
  7za x -tzip -o$TMP_DIR $APK_FILE  &>> $LOG || exit 1
  rm -f $APK_FILE

  # Copy resources
  cd $META_DIR
  cp -av META-INF AndroidManifest.xml $TMP_DIR &>> $LOG || exit 1

  # Repack
  cd $TMP_DIR
  7za a -tzip -mx9  $APK_FILE *     &>> $LOG || exit 1

  cd $CUR_DIR
  return 0
}

HELP="Usage: $0 <file.apk> <mod.dir>"
if [ "$#" -lt "2" ]; then
  echo "$HELP"
  exit 1
fi

CUR_DIR=`pwd`
APK=`FixPath $1`
MOD_DIR=`FixPath $2`
OUT_DIR=$CUR_DIR/work/`basename $MOD_DIR`
OUT_DIR=`FixPath $OUT_DIR`
TMP_APK=$OUT_DIR.tmp
APKTOOL=$PWD/tools/apktool.jar 
: ${LOG:=/dev/null}

## SystemUI / framework-res shouldn't have their meta-inf removed
#SYS=`echo $MOD_DIR | grep -e SystemUI -e framework-res`
SYS="true"
if [ "$SYS" != "" ]; then
  SYS=1
  RMMETA=0
  SIGN=0
else
  SYS=0
  RMMETA=1
  SIGN=1
fi

# Package containing compiled sources should be recompiled afterwards
# We convert them to rel path similar to the one in the apk
XML=`FindResources $MOD_DIR -name '*.xml'`
IMG=`FindResources $MOD_DIR -name '*.png' -o -name '*.jpg'`

if [ "$APKMOD_METHOD" = "" -a "$XML" != "" ]; then
  APKMOD_METHOD=apktool
elif [ "$APKMOD_METHOD" = "" -a "$IMG" != "" ]; then
  APKMOD_METHOD=7z
fi

if [ -f "$APK" ]; then

  # Preserve the original file and META's (META-INF, AndroidManifest.xml)
  cp -p $APK $TMP_APK.orig.apk
  ShowMessage "  [MOD|7zx] " `basename $APK`
  rm -rf "$OUT_DIR.orig"
  7za x -o"$OUT_DIR.orig" ${TMP_APK}.orig.apk &>> $LOG || exit 1

  # apktool method
  # We decrypt and rebuild using apktool
  # Not suitable when 9.png images are broken
  # $APK => $APK.step1
  if [ "$APKMOD_METHOD" = "apktool" ]; then
    # Decompile
    ShowMessage "  [MOD|apkd] " `basename $APK`
    rm -rf $OUT_DIR
    java -jar $APKTOOL d $APK $OUT_DIR &>> $LOG || exit 1
    # Copy resources
    ShowMessage "  [MOD|cp] " `basename $MOD_DIR` " => " `basename "$OUT_DIR"`
    for i in $XML $IMG; do
       cp -av $MOD_DIR/$i $OUT_DIR/$i &>> $LOG
    done
    # Patch
    if [ "$APKMOD_PATCH" != "" -a -f "$MOD_DIR/../$APKMOD_PATCH" ]; then
      ShowMessage "  [MOD|patch] $APKMOD_PATCH"
      cd $OUT_DIR
      patch -p0 < $MOD_DIR/../$APKMOD_PATCH &>> $LOG || exit 1
      cd - &>> $LOG
    fi

    # Recompile
    ShowMessage "  [MOD|apkb] " `basename $MOD_DIR`
    java -jar $APKTOOL b $OUT_DIR ${TMP_APK}.step1.apk &>> $LOG || exit 1

    # Fix broken meta and AndroidManifest.xml
    UpdateMeta ${TMP_APK}.step1.apk ${OUT_DIR}.orig || exit 1

    # Move away and preserve intermediary directory
    mv $OUT_DIR $OUT_DIR.step1

  else

    # Copy and follow
    ShowMessage "  [MOD|cp] " `basename $APK`
    cp -p $APK ${TMP_APK}.step1.apk

  fi

  # 7z method
  # We just rebuild the zip with new resources
  # We could use 7za -u but for some reasons android refuses
  # to load this way, so we repack the whole dir
  # $APK.step1 => $APK.step2
  if [ "$APKMOD_METHOD" = "7z" ]; then

    ShowMessage "  [MOD|7zx] " `basename ${TMP_APK}.step1.apk`
    7za x -o"$OUT_DIR" ${TMP_APK}.step1.apk &>> $LOG || exit 1

    # Copy
    for i in $XML $IMG; do
       cp -av $MOD_DIR/$i $OUT_DIR/$i &>> $LOG
    done

    # Optimize png?
 		#find "$OUT_DIR/res" -name *.png | while read PNG_FILE ;
 		#do
 		#	if [ `echo "$PNG_FILE" | grep -c "\.9\.png$"` -eq 0 ] ; then
 		#		optipng -o99 "$PNG_FILE"
 		#	fi
 		#done

    # Repack the whole dir
    ShowMessage "  [MOD|7za] " `basename ${TMP_APK}.step2.apk`
    cd $OUT_DIR
    7za a -tzip ${TMP_APK}.step2.apk * -mx9 &>> $LOG || exit 1
    cd - >> $LOG 2>&1
    mv $OUT_DIR $OUT_DIR.step2

  else

    # Copy and follow
    ShowMessage "  [MOD|cp] " `basename ${TMP_APK}.step1.apk` " => " `basename ${TMP_APK}.step2.apk`
    cp -p ${TMP_APK}.step1.apk ${TMP_APK}.step2.apk

  fi

  # Sign $APK.step2 => $APK.step3
  if [ "$SIGN" = "1" ]; then
    ShowMessage "  [MOD|sign] " `basename $APK`
    sign.sh ${TMP_APK}.step2.apk ${TMP_APK}.step3.apk &>> $LOG || exit 1
  else
    # Overwrite original metas
    ShowMessage "  [MOD|meta] " `basename ${TMP_APK}.step2.apk` " => " `basename ${TMP_APK}.step3.apk`
    cp -p ${TMP_APK}.step2.apk ${TMP_APK}.step3.apk
    UpdateMeta ${TMP_APK}.step3.apk ${OUT_DIR}.orig || exit 1
  fi

  # Last step overwrites original apk
  ShowMessage "  [MOD|cp] " `basename ${TMP_APK}.step3.apk` " => " `basename $APK`
  cp -p ${TMP_APK}.step3.apk $APK

  cd - &> /dev/null

fi

exit 0
