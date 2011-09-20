set -x
if [ "$#" != "2" ]; then
 echo "Uso: sign.sh <rom.zip> <rom-signed.zip>"
 exit 1
fi
java -jar bin/signapk.jar -w bin/testkey.x509.pem bin/testkey.pk8 $1 $2
