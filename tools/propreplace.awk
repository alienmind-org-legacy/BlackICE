#!/usr/bin/gawk -f
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
{
  key="";
  n=split($0,a,"=");
  if (n >= 2) {
    key=a[1];
    if (key in KEYS) {
      print key "=" KEYS[key];
      next;
    }
  }
  print;
}
