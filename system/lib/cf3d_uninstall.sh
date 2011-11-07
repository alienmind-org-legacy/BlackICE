#!/system/bin/sh
mount -o rw -o remount /dev/block/mmcblk0p25 /system
stop
cat /system/lib/libGLESv1_CM_ORG_CF3D.so > /system/lib/libGLESv1_CM.so
chown 1000.1000 /system/lib/libGLESv1_CM.so
chown 1000:1000 /system/lib/libGLESv1_CM.so
chown system.system /system/lib/libGLESv1_CM.so
chown system:system /system/lib/libGLESv1_CM.so
chmod 644 /system/lib/libGLESv1_CM.so

cat /system/lib/libGLESv2_ORG_CF3D.so > /system/lib/libGLESv2.so
chown 1000.1000 /system/lib/libGLESv2.so
chown 1000:1000 /system/lib/libGLESv2.so
chown system.system /system/lib/libGLESv2.so
chown system:system /system/lib/libGLESv2.so
chmod 644 /system/lib/libGLESv2.so

#rm /system/lib/libGLESv1_CM_ORG_CF3D.so
#rm /system/lib/libGLESv2_ORG_CF3D.so
rm /system/lib/cf3d_uninstall.sh
rm /system/lib/cf3d_sh

reboot -f
reboot
reboot normal
toolbox reboot
busybox reboot -f
busybox reboot
busybox reboot normal
