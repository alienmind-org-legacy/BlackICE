#!/bin/sh
# ICEDroid - clean.sh
# Custom kitchen cleanup script
# Removes all the crap from the original KANG
# Intended to be called from setup.sh
. conf/clean.ini
OUT_DIR=$1
LOG_FILE=$2

if [ "$#" -lt "2" ]; then
  echo "Usage: $0 <out_dir> <log_file>"
  exit 1
fi

for i in $CLEAN_LIST; do
   echo "[RM] $i"
   rm -rf $OUT_DIR/$i >> $LOG_FILE
done