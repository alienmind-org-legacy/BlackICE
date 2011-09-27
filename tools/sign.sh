if [ "$ROOT_DIR" = "" ]; then
  echo "Error: ROOT_DIR env var must be set"
  exit 1
fi
if [ "$#" != "2" ]; then
 echo "Usage: sign.sh <rom.zip> <rom-signed.zip>"
 exit 1
fi
java -jar $ROOT_DIR/tools/signapk.jar -w $ROOT_DIR/tools/testkey.x509.pem $ROOT_DIR/tools/testkey.pk8 $1 $2
