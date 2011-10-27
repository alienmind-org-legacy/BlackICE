#!/bin/sh
# Remove older version of my data apps
cd /data/app/
rm -f \
      dev.sci.systune-*.apk \
      com.android.vending*.apk \
      com.keramidas.TitaniumBackup-*.apk \
      LordModUV*.apk \
      org.alienmod*.apk \
     > /sdcard/blackice/pre.log 2>&1
cd -
