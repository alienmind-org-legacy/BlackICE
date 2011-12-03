diff -r framework-res.orig/ framework-res.new/ | grep -e diff -e Only | sort | awk '/Only/ { print $3 "/" $4 } /diff/ { print $4 }' | sed 's/://g'
