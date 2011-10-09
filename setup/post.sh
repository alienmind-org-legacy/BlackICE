#!/system/bin/sh

# Copy default market from sdcard/market
# Default is older
cp /sdcard/market/Vending-2.3.6.apk /system/app/Vending.apk
chmod 644 /system/app/Vending.apk
