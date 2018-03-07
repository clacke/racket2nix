#! /usr/bin/env bash
make test | awk '
  BEGIN {
    current_scope=""
  }
  /^building \x27\/nix\/store\/.*[.]drv\x27/ {
    if(current_scope != "") {
      print "travis_fold:end:" current_scope "\r"
    }
    current_scope=$0
    sub("building \x27/nix/store/", "", current_scope)
    sub("\x27.*", "", current_scope)
    print "travis_fold:start:" current_scope "\r"
  }
  { print }
'
