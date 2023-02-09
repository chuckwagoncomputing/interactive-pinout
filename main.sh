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

mkdir -p pinoutstmp

for c in $CONNECTORS; do
  echo "Processing: "$c
  DIRECTORY=$(yq e '.info.directory' $c)
  DIR="pinoutstmp/"$(dirname $c | sed -e 's/^\.\///' -e 's/^\///')
  if [ "$DIRECTORY" != "null" ]; then
    echo "Connector Directory: $DIRECTORY"
    if [ ! -d "pinouts/$DIRECTORY" ]; then
      mkdir -p "pinouts/$DIRECTORY"
      if [ -d "$DIR" ]; then
        mv "$DIR"* "pinouts/$DIRECTORY"
        rmdir "$DIR"
      fi
      mkdir -p $(dirname "$DIR")
      ln -rs "pinouts/$DIRECTORY" "$DIR"
    fi
  else
    echo "WARNING: Missing yaml directory field in info section of $c"
    if [ "$WARNINGS" = "error" ]; then
      exit 1;
    elif [ "$WARNINGS" = "skip" ]; then
      continue
    fi
    mkdir -p "$DIR"
  fi
  echo "Target Directory: "$DIR
  NAME=$(basename $c .yaml)
  echo "File Name: "$NAME
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

find pinoutstmp -type l -delete
find pinoutstmp -type d -empty -delete
cp -r pinoutstmp/* pinouts/

echo "Completed processing $(echo -n "$CONNECTORS" | wc -l) mappings"
