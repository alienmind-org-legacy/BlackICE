#!/bin/bash
. tools/util_sh

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

HELP="Usage: $0 <file.apk> <mod.dir>"
if [ "$#" -lt "2" ]; then
  echo "$HELP"
  exit 1
fi

CUR_DIR=`pwd`
APK=`FixPath $1`
MOD_DIR=`FixPath $2`
OUT_DIR=$CUR_DIR/work/`basename $APK .apk`
TMPAPK=$OUT_DIR.apk.step
OUT_DIR=`FixPath $OUT_DIR`
APKTOOL=$PWD/tools/apktool.jar 
: ${LOG:=/dev/null}

# Both sys and regular apk's should be signed
SIGN=1

# SystemUI / framework-res shouldn't have their meta-inf removed
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

  # Preserve the original file
  cp -p $APK $APK.orig

  # If there are resources, we just decrypt / cp / encrypt
  # prior to copying the images, as they may be broken (9.png...)

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
    ShowMessage "  [MOD|cp] " `basename $MOD_DIR`
    for i in $XML $IMG; do
       cp -av $MOD_DIR/$i $OUT_DIR/$i &>> $LOG
    done
    # Recompile
    ShowMessage "  [MOD|apkb] " `basename $MOD_DIR`
    java -jar $APKTOOL b $OUT_DIR ${TMPAPK}1 &>> $LOG || exit 1

    # Move away and preserve intermediary directory
    mv $OUT_DIR $OUT_DIR.step1
    
  else

    # Copy and follow
    ShowMessage "  [MOD|cp] " `basename $APK`
    cp -p $APK ${TMPAPK}1

  fi

  # 7z method
  # We just rebuild the zip with new resources
  # We could use 7za -u but for some reasons android refuses
  # to load this way, so we repack the whole dir
  # $APK.step1 => $APK.step2
  if [ "$APKMOD_METHOD" = "7z" ]; then

    ShowMessage "  [MOD|7zax] " `basename $APK`
    7za x -o"$OUT_DIR" ${TMPAPK}1 &>> $LOG || exit 1

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
    cd $OUT_DIR
    7za a -tzip ${TMPAPK}2 * -mx9 &>> $LOG || exit 1
    cd - >> $LOG 2>&1
    mv $OUT_DIR $OUT_DIR.step2

  else

    # Copy and follow
    ShowMessage "  [MOD|cp] " `basename $APK`
    cp -p ${TMPAPK}1 ${TMPAPK}2

  fi

  # Sign $APK.step2 => $APK.step3
  if [ "$SIGN" = "1" ]; then
    ShowMessage "  [MOD|sign] " `basename $APK`
    sign.sh ${TMPAPK}2 ${TMPAPK}3 &>> $LOG || exit 1
  else
    ShowMessage "  [MOD|mv] " `basename $NEWAPK`
    cp -p ${TMPAPK}2 ${TMPAPK}3 &>> $LOG || exit 1
  fi

  # Last step overwrites original apk
  cp -p ${TMPAPK}3 $APK

  cd - &> /dev/null

fi
exit 0
