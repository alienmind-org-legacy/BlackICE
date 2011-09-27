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

if [ -f "$APK" ]; then
  mkdir -p $OUT_DIR
  cd $OUT_DIR
  unzip -x $APK &> /dev/null
  cp -a $MOD_DIR/* .
  zip -r9 $NEWAPK . &>/dev/null
  mv $APK $APK.orig
  sign.sh $NEWAPK $APK
  #mv $NEWAPK $APK
  cd - &> /dev/null
fi
