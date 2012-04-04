REFRESH_DOWNLOAD_DIR=refresh_download
rm -rf ${REFRESH_DOWNLOAD_DIR}
mkdir ${REFRESH_DOWNLOAD_DIR}

echo ""
DOTS="Extracting matching *.apk files from phone "
for i in *.apk; do
  # -n = no newline
  # -e = interpret escape characters
  # \r = carriage return, but no newline
  DOTS="${DOTS}."
  echo -n -e "\r${DOTS}"
  N=`echo $i | sed 's/-[0-9]*.apk//g' | sed 's/.apk//g'`
  LOCAL=`ls $N*.apk | tr '\n' ' ' | tr '\r' ' '`
  REMOTO=`adb shell basename /data/app/$N*.apk | tr '\n' ' ' | tr '\r' ' ' | sed 's/\ $//g'`

  TEST_FILE=`adb shell ls /data/app/${REMOTO} | grep -o "No such file"`
  if [ "${TEST_FILE}" != "No such file" ]; then
    # Pull all the matching .apks into the download dir
##    echo "adb pull /data/app/${REMOTO} ${REFRESH_DOWNLOAD_DIR}/${LOCAL}"
    adb pull /data/app/${REMOTO} ${REFRESH_DOWNLOAD_DIR}/${LOCAL} &>/dev/null
  fi
done
echo ""

NEW_FILES=0
for i in ${REFRESH_DOWNLOAD_DIR}/*.apk; do
  oldi=`basename ${i}`
  DIFF_FILE=`diff -s ${i} ${oldi} | grep -o "identical"`
  if [ "${DIFF_FILE}" == "identical" ]; then
    rm ${i}
  else
    NEW_FILES=1
  fi
done

echo ""
if [ "$NEW_FILES" == "1" ]; then
  echo "The following are different and should be uploaded to the server"
  for i in ${REFRESH_DOWNLOAD_DIR}/*.apk; do
    echo "  ${i}"
  done
else
  echo "  No new files"
fi
echo ""
