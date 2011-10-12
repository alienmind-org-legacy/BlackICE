#!/system/xbin/bash
(
set -x
# Remove older version of my data apps
cd /data/app/
rm -f \
      dev.sci.systune-*.apk \
      com.android.vending*.apk \
      com.keramidas.TitaniumBackup-*.apk \
      LordModUV*.apk \
      org.alienmod*.apk
cd -
) > /sdcard/blackice/pre.log 2>&1
