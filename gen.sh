#!/usr/bin/env bash

DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)"/"
export JSON="$(echo $1 | minify --type json | sed 's/\\/\\\\/g')"

CSS=$(cat $DIR/style.css)
for C in $COLORS; do
  CT=$(echo "$C" | cut -sd ':' -f 1)
  CC=$(echo "$C" | cut -sd ':' -f 2 | cut -d ',' -f 1 | cut -d '"' -f 2)
  if [ -n "$CT" ] && [ -n "$CC" ]; then
    CSS+=$(echo -e "\n[data-type*=$CT] {\nborder-color: $CC;\n}")
  fi
done
export CSS

export JS=$(perl -0pe 's/\/\*DATA\*\//\`$ENV{JSON}\`,/;' -pe 's/\/\/\/COLS\/\/\//$ENV{COLS}/;' -pe 's/\/\/\/PRINT_COLS\/\/\//$ENV{PRINT_COLS}/;' $DIR/script.js)

TEXT=$(perl -0pe 's/###JS###/$ENV{JS}/;' -pe 's/###CSS###/$ENV{CSS}/;' $DIR/pinout.html | minify --type html | perl -0pe 's/}`]/}`,\/\*DATA\*\/]/;')
if [ $? -ne 0 ]; then
  echo "Error in gen.sh"
  exit 1;
fi
echo "$TEXT" > $2
