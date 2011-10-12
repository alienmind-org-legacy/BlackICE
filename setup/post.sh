#!/system/xbin/bash
(
set -x
# Copy default market (older) to sdcard/market
# So icetool finds there
cp /system/app/Vending.apk /sdcard/blackice/market/Vending-2.3.6.apk
) > /sdcard/blackice/post.log 2>&1
