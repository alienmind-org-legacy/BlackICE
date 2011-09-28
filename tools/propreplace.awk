#!/usr/bin/gawk -f
# Store the keys and values of the append files
BEGIN {
}
(FILENAME ~ ".append") {
  key="";
  n=split($0,a,"=");
  if (n >= 2) {
    key=a[1];
    val=substr($0,index($0,"=")+1); # So we get the rest of the args
    KEYS[key]=val;
  }
  next;
}
# Original file, if we find the key we replace the rightmost value
{
  key="";
  n=split($0,a,"=");
  if (n >= 2) {
    key=a[1];
    if (key in KEYS) {
      print key "=" KEYS[key];
      KEYS[key] = "DONE";
      next;
    }
  }
  print;
}
# The rest of the keys should be flushed (new entries)
END {
  for (key in KEYS) {
     if (KEYS[key] != "DONE") {
       print key "=" KEYS[key];
     }
  }
}
