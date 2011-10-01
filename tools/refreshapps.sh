for i in *.apk; do
  N=`echo $i | sed 's/-[0-9]*.apk//g' | sed 's/.apk//g'` 
  LOCAL=`ls $N*.apk | tr '\n' ' ' | tr '\r' ' '`
  REMOTO=`adb shell basename /data/app/$N*.apk | tr '\n' ' ' | tr '\r' ' ' | sed 's/\ $//g'`
  if [ "$LOCAL" != "$REMOTO" ]; then
    echo "LOCAL: $LOCAL" 
    echo "REMOTO: $REMOTO" 
    echo "SYNC: rm -f $LOCAL ; adb pull /data/app/$REMOTO"
    echo "---------------------"
  fi
done
