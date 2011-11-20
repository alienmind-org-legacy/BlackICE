#!/bin/bash
. tools/util_sh

function FindResources() {
  local MOD_DIR=$1
  local RES_PATTERN=$2
  cd $MOD_DIR
  for f in `find . -type f -name $RES_PATTERN`; do
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

APK=`FixPath $1`
MOD_DIR=`FixPath $2`
OUT_DIR=work/`basename $APK .apk`
OUT_DIR=`FixPath $OUT_DIR`
NEWAPK=work/`basename $APK`
NEWAPK=`FixPath $NEWAPK`
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
XML=`FindResources $MOD_DIR '*.xml'`
PNG=`FindResources $MOD_DIR '*.png'`

if [ -f "$APK" ]; then

  # If there are resources, we just decrypt / cp / encrypt
  # prior to copying the images, as they may be broken (9.png...)

  # $APK => $NEWAPK
  if [ "$XML" != "" ]; then
    # Decompile
    ShowMessage "  [MOD|apkd] " `basename $APK`
    rm -rf $OUT_DIR
    java -jar $APKTOOL d $APK $OUT_DIR &>> $LOG || exit 1
    # Copy resources
    ShowMessage "  [MOD|cp] " `basename $MOD_DIR`
    for i in $XML; do
       cp -av $MOD_DIR/$i $OUT_DIR &>> $LOG
    done
    # Recompile
    ShowMessage "  [MOD|apkb] " `basename $MOD_DIR`
    java -jar $APKTOOL b $OUT_DIR $NEWAPK &>> $LOG || exit 1
    mv $OUT_DIR $OUT_DIR.decompile # preserve temp dir
  else
    ShowMessage "  [MOD|cp] " `basename $APK`
    cp -p $APK $NEWAPK
  fi

  # Now we 7za u (update) the images
  if [ "$PNG" != "" ]; then
    ShowMessage "  [MOD|7zau] " `basename $APK`

    # Optimize png?
 		#find "$OUT_DIR/res" -name *.png | while read PNG_FILE ;
 		#do
 		#	if [ `echo "$PNG_FILE" | grep -c "\.9\.png$"` -eq 0 ] ; then
 		#		optipng -o99 "$PNG_FILE"
 		#	fi
 		#done

    cd "$MOD_DIR"
    set -x
    7za -tzip u $NEWAPK $PNG &>> $LOG || exit 1
    set +x
    cd - >> $LOG 2>&1

  fi

  # Sign $NEWAPK => $APK
  if [ "$SIGN" = "1" ]; then
    ShowMessage "  [MOD|sign] " `basename $NEWAPK`
    sign.sh $NEWAPK $APK &>> $LOG || exit 1
  else
    ShowMessage "  [MOD|mv] " `basename $NEWAPK`
    mv $NEWAPK $APK &>> $LOG || exit 1
  fi

  cd - &> /dev/null
fi
exit 0
