#!/usr/bin/env bash

DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)"/"
export JSON="$(echo $1 | minify --type json | sed 's/\\/\\\\/g')"
TEXT=$(perl -0pe 's/\/\*DATA\*\//\`$ENV{JSON}\`,\/\*DATA\*\//;' $2)
if [ $? -ne 0 ]; then
  echo "Error in append.sh"
  exit 1;
fi
echo "$TEXT" > $2
