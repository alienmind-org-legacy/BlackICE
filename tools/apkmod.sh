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

if [ -f "$APK" ]; then
#  mkdir -p $OUT_DIR
#  cd $OUT_DIR
  #unzip -ox $APK &> /dev/null
  java -jar $APKTOOL d $APK $OUT_DIR
  cp -a $MOD_DIR/* .
  #zip -r9 $NEWAPK . &>/dev/null
  java -jar $APKTOOL b $OUT_DIR $NEWAPK
  #mv $APK $APK.orig # if we want to preserve
  sign.sh $NEWAPK $APK
  cd - &> /dev/null
fi
