REFRESH_DOWNLOAD_DIR=refresh_download

rm -rf ${REFRESH_DOWNLOAD_DIR}
mkdir ${REFRESH_DOWNLOAD_DIR}

echo ""
echo "Extracting files from phone..."
echo ""
for i in *.apk; do
  N=`echo $i | sed 's/-[0-9]*.apk//g' | sed 's/.apk//g'`
  LOCAL=`ls $N*.apk | tr '\n' ' ' | tr '\r' ' '`
  REMOTO=`adb shell basename /data/app/$N*.apk | tr '\n' ' ' | tr '\r' ' ' | sed 's/\ $//g'`

  TEST_FILE=`adb shell ls /data/app/${REMOTO} | grep -o "No such file"`
  if [ "${TEST_FILE}" != "No such file" ]; then
    # Pull all the matching .apks into the download dir
    echo "adb pull /data/app/${REMOTO} ${REFRESH_DOWNLOAD_DIR}/${LOCAL}"
    adb pull /data/app/${REMOTO} ${REFRESH_DOWNLOAD_DIR}/${LOCAL}
  fi
done

echo ""
echo "Comparing files for differences..."
echo "  - New extracted files will be copied"
echo "  - Identical extracted files will be deleted"
echo ""

for i in ${REFRESH_DOWNLOAD_DIR}/*.apk; do
  oldi=`basename ${i}`

  echo "diff -s ${i} ${oldi}"
#  diff -s ${i} ${oldi}
  DIFF_FILE=`diff -s ${i} ${oldi} | grep -o "identical"`
  if [ "${DIFF_FILE}" == "identical" ]; then
    echo "  identical: rm ${i}"
    rm ${i}
  else
    echo "  different: cp ${i} ${oldi}"
    cp ${i} ${oldi}
  fi
done

echo ""
echo "  New files that should be uploaded to server"
echo ""
ls -al ${REFRESH_DOWNLOAD_DIR}
