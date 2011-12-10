#!/sbin/sh

# Remove older version of my data apps
cd /data/app/
rm -f \
      LordModUV*.apk \
      org.alienmod*.apk \
      dev.sci.systune-[0-9].apk \
      com.android.vending-[0-9]*.apk \
      com.keramidas.TitaniumBackup-[0-9]*.apk \
      eu.chainfire.cf3d-[0-9]*apk \
      com.namakerorin.audiofxwidget-[0-9]*apk \
      com.leppie.dhd-[0-9]*apk \
      com.adobe.flashplayer-[0-9]*apk \
      com.FREE.android.lvh-[0-9]*apk \
     > /sdcard/blackice/pre.log 2>&1
cd - > /dev/null 2>&1
