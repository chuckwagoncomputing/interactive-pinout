#!/bin/bash
# env MAPPING_PATH: yaml(s) path
# env WARNINGS:
#   fail if "error"
#   skip if "skip"

CONNECTORS=$(find -path "$MAPPING_PATH")
FILES=$(for f in $CONNECTORS; do
  ORDER=$(yq e '.info.order' $f)
  echo "$f $ORDER"
done)
CONNECTORS=$(echo "$FILES" | sort -k2 | cut -d ' ' -f 1)

for c in $CONNECTORS; do
  echo "Processing: "$c
  DIR="pinouts/"$(echo $c | tr '/' '\n' | tail -n +5 | head -n -2 | tr '\n' '/')
  echo "Target Directory: "$DIR
  NAME=$(basename $c .yaml)
  echo "File Name: "$NAME
  mkdir -p $DIR
  if [ "$(yq e '.info.id' $c)" == "null" ]; then
    echo "WARNING: Missing yaml id field in info section of $c"
    if [ "$WARNINGS" = "error" ]; then
      exit 1;
    elif [ "$WARNINGS" = "skip" ]; then
      continue
    fi
  fi
  if [ -f $DIR/index.html ]; then
    bash /append.sh "$(yq -o=json e $c)" $DIR/index.html
  else
    bash /gen.sh "$(yq -o=json e $c)" $DIR/index.html
  fi
  if [ $? -ne 0 ]; then
    echo "WARNING: Failed to generate or append to pinout"
    if [ "$WARNINGS" = "error" ]; then
      exit 1;
    elif [ "$WARNINGS" = "skip" ]; then
      continue
    fi
  fi
  IMG=$(yq e '.info.image.file' $c)
  if [ $? -ne 0 ] || [ "$IMG" = "null" ]; then
    echo "WARNING: Missing image"
    if [ "$WARNINGS" = "error" ]; then
      exit 1;
    elif [ "$WARNINGS" = "skip" ]; then
      continue
    fi
  else
    echo "Image: "$IMG
    cp $(dirname $c)/$IMG $DIR
  fi
done

echo "Completed processing $(echo -n "$CONNECTORS" | wc -l) mappings"
