#!/usr/bin/env bash

DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)"/"
if [ "$DEBUG" = "true" ]; then
  export JSON="$(echo "$1" | sed 's/\\/\\\\/g')"
else
  export JSON="$(echo $1 | minify --type json | sed 's/\\/\\\\/g')"
fi

CSS=$(cat $DIR/style.css)
CSS+=$'\n'
CSS+=$(echo "$COLORS" | jq -r 'keys[] as $k | "[data-type*=\"\($k)\"] {\nborder-color: \(.[$k]);\n}"')
export CSS

if [ -z "$TEMPLATES" ]; then
  export TEMPLATES="{}"
fi

export JS=$(perl -0pe 's/\/\*DATA\*\//\`$ENV{JSON}\`,/;' -pe 's/\/\/\/COLS\/\/\//$ENV{COLS}/;' -pe 's/\/\/\/PRINT_COLS\/\/\//$ENV{PRINT_COLS}/;' -pe 's/\/\/\/INFO_COL\/\/\//$ENV{INFO_COL}/;' -pe 's/\/\/\/TEMPLATES\/\/\//$ENV{TEMPLATES}/;' $DIR/script.js)

if [ "$DEBUG" = "true" ]; then
  export JS=$'var debug = true;\n'"$JS"
else
  export JS=$(echo '(function() {'"$JS"'})()' | perl -0pe 's/\/\/ \@ifdef DEBUG.*?\/\/ \@endif//s;')
fi

if [ "$DEBUG" = "true" ]; then
  TEXT=$(perl -0pe 's/###JS###/$ENV{JS}/;' -pe 's/###CSS###/$ENV{CSS}/;' $DIR/pinout.html | perl -0pe 's/}`,\n]/}`,\n\/\*DATA\*\/\n]/;')
else
  TEXT=$(perl -0pe 's/###JS###/$ENV{JS}/;' -pe 's/###CSS###/$ENV{CSS}/;' $DIR/pinout.html | minify --type html | perl -0pe 's/}`]/}`,\/\*DATA\*\/]/;')
fi

if [ $? -ne 0 ]; then
  echo "Error in gen.sh"
  exit 1;
fi
echo "$TEXT" > $2
