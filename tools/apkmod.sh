#!/bin/bash
. tools/util_sh

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

# Package containing compiled sources should be decompiled first
RES=`ls $MOD_DIR/res/ | grep -v drawable`

if [ -f "$APK" ]; then
  rm -rf $OUT_DIR
  #mkdir -p $OUT_DIR

  # Decompile
  if [ "$RES" != "" ]; then
    ShowMessage "  [MOD|apkd] " `basename $APK` " => " `basename "$OUT_DIR"`
    java -jar $APKTOOL d $APK $OUT_DIR &>> $LOG
  # just unzip
  else 
    ShowMessage "  [MOD|7zax] " `basename $APK` " => " `basename "$OUT_DIR"`
    7za x -o"$OUT_DIR" $APK &>> $LOG
  fi

  # Copy content
  ShowMessage "  [MOD|cp] " `basename $MOD_DIR` " => " `basename "$OUT_DIR"`
  cp -av $MOD_DIR/* $OUT_DIR &>> $LOG

  # Optimize png?
	#find "$OUT_DIR/res" -name *.png | while read PNG_FILE ;
	#do
	#	if [ `echo "$PNG_FILE" | grep -c "\.9\.png$"` -eq 0 ] ; then
	#		optipng -o99 "$PNG_FILE"
	#	fi
	#done

  # Remove meta-inf on regular apk's
  if [ "$RMMETA" = "1" ]; then
    ShowMessage "  [MOD|rm] META-INF"
    rm -rf $OUT_DIR/META-INF/ &>> $LOG
  fi

  # Recompile
  if [ "$RES" != "" ]; then
    ShowMessage "  [MOD|apkb] " `basename $MOD_DIR` " => " `basename "$OUT_DIR"`
    java -jar $APKTOOL b $OUT_DIR $NEWAPK &>> $LOG
  # just rezip
  else
    ShowMessage "  [MOD|7zaa] " `basename $MOD_DIR` " => " `basename "$OUT_DIR"`
    7za a -tzip $NEWAPK $OUT_DIR/* -mx9 &>> $LOG
  fi

  # Sign
  if [ "$SIGN" = "1" ]; then
    ShowMessage "  [MOD|sign] " `basename $NEWAPK`  " => " `basename "$APK"`
    sign.sh $NEWAPK $APK &>> $LOG
  else
    ShowMessage "  [MOD|mv] " `basename $NEWAPK`  " => " `basename "$APK"`
    mv $NEWAPK $APK &>> $LOG
  fi

  cd - &> /dev/null
fi
