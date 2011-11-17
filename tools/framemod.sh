#!/bin/bash

ICE_DIR=~/android/blackice/ICEDroid

. $ICE_DIR/tools/util_sh

if [ "$#" -lt "2" ]; then
  echo
  echo "Usage: $0 <fdir> <pdir>"
  echo "       fdir = directory containing the framework-res.apk to update"
  echo "       pdir = directory with new .png files to be added to framework-res.apk/res/drawable-hdpi"
  echo
  exit 1
fi

APK_BASE=framework-res
APK=$APK_BASE.apk
APK_DIR=$1
PNG_DIR=$2
OUT_DIR=$ICE_DIR/work/$APK_BASE
PNG_ARCHIVE_PATH=res/drawable-hdpi

: ${LOG:=/dev/null}

# Set this to non-empty (e.g. "1") for some extra debug messages
VERBOSE="1"

if [ "$VERBOSE" != "" ]; then
  ShowMessage ""
  ShowMessage "Directories:"
  ShowMessage "  APK_NAME    = $APK"
  ShowMessage "  APK_DIR     = $APK_DIR"
  ShowMessage "  PNG_DIR     = $PNG_DIR"
  ShowMessage "  OUT_DIR     = $OUT_DIR"
  ShowMessage "  APKTOOL     = $APKTOOL"
  ShowMessage ""
fi

if [ ! -d "$APK_DIR" ]; then
  ShowMessage ""
  ShowMessage " '$APK_DIR' does not exist (this is where framework-res.apk is supposed to be)"
  ShowMessage ""
  exit 1
fi
if [ ! -f "$APK_DIR/$APK" ]; then
  ShowMessage ""
  ShowMessage " $APK does not exist in '$APK_DIR'"
  ShowMessage ""
  exit 1
fi
if [ ! -d "$PNG_DIR" ]; then
  ShowMessage ""
  ShowMessage " '$PNG_DIR' does not exist (this is where the new .png files are supposed to be)"
  ShowMessage ""
  exit 1
fi

# First see if there are any .png files to process
PNGS=`ls $PNG_DIR | grep .png`
if [ "$PNGS" = "" ]; then
  ShowMessage ""
  ShowMessage " No .png files found in '$PNG_DIR', nothing to do"
  ShowMessage ""
  exit 1
fi

# Get rid of any old files
rm -rf $OUT_DIR

# Recreate the ouput directory plus a structure to match the path in the framework-res.apk archive
mkdir -p $OUT_DIR/$PNG_ARCHIVE_PATH  &>> $LOG || exit 1

# Copy the new .png files so we can use that path to update the archive
ShowMessage "cp -a $PNG_DIR/*.png $OUT_DIR/$PNG_ARCHIVE_PATH"
cp -a $PNG_DIR/*.png $OUT_DIR/$PNG_ARCHIVE_PATH  &>> $LOG || exit 1

ShowMessage "cp -a $APK_DIR/$APK $OUT_DIR/$APK"
cp -a $APK_DIR/$APK $OUT_DIR/$APK_BASE.zip  &>> $LOG || exit 1
chmod 666 $OUT_DIR/$APK_BASE.zip  &>> $LOG || exit 1

ORG_DIR=$PWD
cd $OUT_DIR  &>> $LOG || exit 1

ShowMessage "7za u $OUTDIR/$APK $PNG_ARCHIVE_PATH/*.png"
7za u $APK_BASE.zip $PNG_ARCHIVE_PATH/*.png  &>> $LOG || exit 1

ShowMessage "mv $APK_BASE.zip $APK"
mv $APK_BASE.zip $APK  &>> $LOG || exit 1

cd $ORG_DIR

ShowMessage ""
ShowMessage "  Updated framework-res.apk is in $OUT_DIR/$APK"
ShowMessage ""

exit 0
