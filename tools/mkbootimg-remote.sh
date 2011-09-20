adb shell mkdir /data/kernel/
for i in kernel/* ; do
adb push $i /data/kernel/
done
adb shell chmod 777 /data/kernel/*
adb shell /data/kernel/dd if=/dev/block/mmcblk0p22 of=/data/kernel/boot.img
adb shell /data/kernel/unpackbootimg /data/kernel/boot.img /data/kernel/
adb shell /data/kernel/mkbootimg --kernel /data/kernel/zImage --ramdisk /data/kernel/boot.img-ramdisk.gz --cmdline \"$(adb shell cat /data/kernel/boot.img-cmdline)\" \
                            --base $(adb shell cat /data/kernel/boot.img-base) --output /data/kernel/newboot.img
adb pull /data/kernel/newboot.img
