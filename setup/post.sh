#!/sbin/sh

# Install default market
if [ ! -f /system/app/Vending.apk ]; then
  cp -p /sdcard/blackice/market/Vending-3.5.16.apk /system/app/Vending.apk
  chmod 644 /system/app/Vending.apk
fi

# Run icetool autoinstall
/system/bin/icetool autoinstall
