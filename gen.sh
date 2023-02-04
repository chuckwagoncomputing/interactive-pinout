#!/usr/bin/env bash

DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)"/"
JSON="$(echo $1 | sed 's/\\/\\\\\\\\/g')"

CSS=""
CSS+=$(sed 's/@/\\@/g' $DIR/style.css)
for C in $COLORS; do
  CT=$(echo "$C" | cut -sd ':' -f 1)
  CC=$(echo "$C" | cut -sd ':' -f 2 | cut -d ',' -f 1 | cut -d '"' -f 2)
  if [ -n "$CT" ] && [ -n "$CC" ]; then
    CSS+=$(echo -e "\n[data-type*=$CT] {\nborder-color: $CC;\n}")
  fi
done
CSS=$(echo "$CSS" | minify --type css)
HTML=$(minify $DIR/pinout.html)
JS=$(minify $DIR/script.js)
TEXT=$(echo "$HTML" | perl -0pe "s/###JS###/${JS}/" | sed -e "s/\/\/\/DATA\/\/\//\`$(echo ${JSON//\//\\/} | tr -d '\n')\`,\n\/\/\/DATA\/\/\//" | perl -0pe "s/###CSS###/${CSS}/" | perl -0pe "s/\/\/\/COLS\/\/\//${COLS}/" | perl -0pe "s/\/\/\/PRINT_COLS\/\/\//${PRINT_COLS}/")
if [ $? -ne 0 ]; then
  echo "Error in gen.sh"
  exit 1;
fi
echo "$TEXT" > $2
