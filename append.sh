#!/usr/bin/env bash

DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)"/"
JSON="$(echo $1 | sed 's/\\/\\\\\\\\/g')"
TEXT=$(sed -e "/\/\/\/DATA\/\/\//{a \ \`$(echo ${JSON//\//\\/} | tr -d '\n')\ \`,\n///DATA///" -e "d}" $2)
if [ $? -ne 0 ]; then
  echo "Error in append.sh"
  exit 1;
fi
echo "$TEXT" > $2
