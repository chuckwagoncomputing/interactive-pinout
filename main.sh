#!/bin/bash
# $1: yaml(s) path
# env WERROR: fail on warning if "true"
# env WSKIP: skip on warning if "true"

CONNECTORS=$(find -path "$1")
FILES=$(for f in $CONNECTORS; do
  ORDER=$(yqdir/yq e '.info.order' $f)
  echo "$f $ORDER"
done)
CONNECTORS=$(echo "$FILES" | sort -k2 | cut -d ' ' -f 1)

for c in $CONNECTORS; do
  echo "Processing "$c
  DIR="pinouts/"$(echo $c | tr '/' '\n' | tail -n +5 | head -n -2 | tr '\n' '/')
  echo "Target Directory "$DIR
  NAME=$(basename $c .yaml)
  echo "File Name "$NAME
  mkdir -p $DIR
  if [ "$(yqdir/yq e '.info.id' $c)" == "null" ]; then
    echo "WARNING: Missing yaml id field in info section of $c"
    if [ "$WERROR" = "true" ]; then
      exit 1;
    elif [ "$WSKIP" = "true" ]; then
      continue
    fi
  fi
  if [ -f $DIR/index.html ]; then
    bash misc/pinout-gen/append.sh "$(yqdir/yq -o=json e $c)" $DIR/index.html
  else
    bash misc/pinout-gen/gen.sh "$(yqdir/yq -o=json e $c)" $DIR/index.html
  fi
  if [ $? -ne 0 ]; then
    echo "Failed to generate or append to pinout"
    if [ "$WERROR" = "true" ]; then
      exit 1;
    elif [ "$WSKIP" = "true" ]; then
      continue
    fi
  fi
  file $DIR/index.html
  IMG=$(yqdir/yq e '.info.image.file' $c)
  if [ $? -ne 0 ]; then
    echo "Missing image"
    if [ "$WERROR" = "true" ]; then
      exit 1;
    elif [ "$WSKIP" = "true" ]; then
      continue
    fi
  fi
  echo "IMG "$IMG
  if [ "$IMG" != "null" ]; then
    cp $(dirname $c)/$IMG $DIR
  fi
  ls $DIR
done
