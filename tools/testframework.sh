FRAMEWORKAPK=$1
adb shell stop
adb remount
adb push $FRAMEWORKAPK /system/framework/
adb shell chmod 644 /system/framework/framework-res.apk
adb shell start
