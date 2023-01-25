#!/usr/bin/env bash

DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)"/"
JSON="$(echo $1 | sed 's/\\/\\\\\\\\/g')"
TEXT=$(sed -e "/###CSS###/{r ${DIR}style.css" -e 'd}' -e "/###JS###/{r ${DIR}script.js" -e 'd}' ${DIR}pinout.html | sed -e "s/\/\/\/DATA\/\/\//\`$(echo ${JSON//\//\\/} | tr -d '\n')\`,\n\/\/\/DATA\/\/\//")
if [ $? -ne 0 ]; then
  echo "Error in gen.sh"
  exit 1;
fi
echo "$TEXT" > $2