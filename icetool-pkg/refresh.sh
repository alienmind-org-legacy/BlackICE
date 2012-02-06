mkdir -p system/bin system/etc system/app
cp -p ../system/bin/icetool system/bin/
cp -p ../system/etc/icetool.conf system/etc/
cp -p ../src/ICETool/bin/ICETool.apk system/app/
tar -czvf icetool.tgz system/
grep ICETOOL_VERSION system/bin/icetool | head -n 1 | \
      awk '{ print $1 }' | cut -c17- | sed 's/\"//g' \
    > icetool.version
