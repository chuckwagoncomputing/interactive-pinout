#!/usr/bin/env bash

DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)"/"
#if [ "$DEBUG" = "true" ]; then
#  export JSON="$(echo "$1" | sed 's/\\/\\\\/g')"
#else
  export JSON="$(echo $1 | minify --type json | sed 's/\\/\\\\/g')"
#fi

if [ "$DEBUG" = "true" ]; then
  TEXT=$(perl -0pe 's/\/\*DATA\*\//\`$ENV{JSON}\`,\n\/\*DATA\*\//;' $2)
else
  TEXT=$(perl -0pe 's/\/\*DATA\*\//\`$ENV{JSON}\`,\/\*DATA\*\//;' $2)
fi

if [ $? -ne 0 ]; then
  echo "Error in append.sh"
  exit 1;
fi
echo "$TEXT" > $2
