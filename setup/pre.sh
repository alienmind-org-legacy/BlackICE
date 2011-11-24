#!/sbin/sh
# Remove older version of my data apps
cd /data/app/
rm -f \
      dev.sci.systune-[0-9].apk \
      com.android.vending-[0-9]*.apk \
      com.keramidas.TitaniumBackup-[0-9]*.apk \
      eu.chainfire.cf3d-[0-9]*apk \
      com.FREE.android.lvh-[0-9]*apk \
      LordModUV*.apk \
      org.alienmod*.apk \
     > /sdcard/blackice/pre.log 2>&1
cd - > /dev/null 2>&1
