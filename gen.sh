#!/usr/bin/env bash

DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)"/"
JSON="$(echo $1 | sed 's/\\/\\\\\\\\/g')"

CSS=""
for C in $COLORS; do
  CT=$(echo "$C" | cut -sd ':' -f 1)
  CC=$(echo "$C" | cut -sd ':' -f 2 | cut -d ',' -f 1)
  if [ -n "$CT" ] && [ -n "$CC" ]; then
    CSS+=$(echo -e "[data-type*=\"$CT\"] {\nborder-color: $CC;\n}\n\n")
  fi
done
CSS+=$(cat $DIR/style.css)

TEXT=$(sed -e "/###JS###/{r ${DIR}script.js" -e 'd}' ${DIR}pinout.html | sed -e "s/\/\/\/DATA\/\/\//\`$(echo ${JSON//\//\\/} | tr -d '\n')\`,\n\/\/\/DATA\/\/\//" | perl -0pe "s/###CSS###/${CSS}/" | perl -0pe "s/\/\/\/COLS\/\/\//${COLS}/" | perl -0pe "s/\/\/\/PRINT_COLS\/\/\//${PRINT_COLS}/")
if [ $? -ne 0 ]; then
  echo "Error in gen.sh"
  exit 1;
fi
echo "$TEXT" > $2
