#!/bin/bash
# env MAPPING_PATH: yaml(s) path
# env WARNINGS:
#   fail if "error"
#   skip if "skip"

# Sort all the yaml files by the order field they may contain.
CONNECTORS=$(find . -path "$MAPPING_PATH")
FILES=$(for f in $CONNECTORS; do
  ORDER=$(yq e '.info.order' "$f")
  echo "$f $ORDER"
done)
CONNECTORS=$(echo "$FILES" | sort -k2 | cut -d ' ' -f 1)

# Make a temp directory for symlinks to actual files.
mkdir -p pinoutstmp

for c in $CONNECTORS; do
  echo "Processing: $c"
  # Get the directory and title, if they exist
  DIRECTORY=$(yq e '.info.directory' "$c")
  TITLE=$(yq e '.info.title' "$c")
  # Build the temp path, removing leading ./ and /
  DIR="pinoutstmp/"$(dirname "$c" | sed -e 's/^\.\///' -e 's/^\///')
  # If we have a directory field
  if [ "$DIRECTORY" != "null" ]; then
    # If temp dir exists
    if [ -d "$DIR" ]; then
      # If temp dir isn't symbolic link
      if [ ! -L "$DIR" ]; then
        # It must be a real directory, move it to the final dir and link it
        mkdir -p "pinouts/$DIRECTORY"
        mv "$DIR"/* "pinouts/$DIRECTORY"
        rmdir "$DIR"
        ln -rs "pinouts/$DIRECTORY" "$DIR"
      # If temp dir is a link, but not to the specified directory
      elif TARGET=$(readlink "$DIR") && [ "$TARGET" != "pinouts/$DIRECTORY" ]; then
        # Make specified directory
        mkdir -p "pinouts/$DIRECTORY"
        # Move the contents of the directory the link points to, and remove that directory
        mv "$(readlink -f "$DIR")"/* "pinouts/$DIRECTORY"
        rmdir "$(readlink -f "$DIR")"
        # Link to specified directory
        rm "$DIR"
        ln -rs "pinouts/$DIRECTORY" "$DIR"
      fi
    # If it doesn't exist, create specified directory and link it
    else
      mkdir -p "pinouts/$DIRECTORY"
      mkdir -p "$(dirname "$DIR")"
      ln -rs "pinouts/$DIRECTORY" "$DIR"
    fi
  # If we have a title field but not directory
  elif [ "$TITLE" != "null" ]; then
    # If temp dir exists
    if [ -d "$DIR" ]; then
      # If temp dir isn't symbolic link
      # If it is a symbolic link, we just assume that it points to the directory field
      if [ ! -L "$DIR" ]; then
        # It must be a real directory, move it to the final dir and link it
        mkdir -p "pinouts/$TITLE"
        mv "$DIR"/* "pinouts/$TITLE"
        rmdir "$DIR"
        ln -rs "pinouts/$TITLE" "$DIR"
      fi
    # If it doesn't exist, create it at title field and link it
    else
      mkdir -p "pinouts/$TITLE"
      mkdir -p "$(dirname "$DIR")"
      ln -rs "pinouts/$TITLE" "$DIR"
    fi
  else
    # Fallback to creating normal directory
    mkdir -p "$DIR"
  fi
  echo "Target Directory: $DIR"
  NAME=$(basename "$c" .yaml)
  echo "File Name: $NAME"
  if [ "$(yq e '.info.cid' "$c")" == "null" ]; then
    echo "WARNING: Missing yaml cid field in info section of $c"
    if [ "$WARNINGS" = "error" ]; then
      exit 1;
    elif [ "$WARNINGS" = "skip" ]; then
      continue
    fi
  fi
  if [ -f "$DIR/index.html" ]; then
    bash /append.sh "$(yq -o=json e "$c")" "$DIR/index.html"
  else
    bash /gen.sh "$(yq -o=json e "$c")" "$DIR/index.html"
  fi
  if [ $? -ne 0 ]; then
    echo "WARNING: Failed to generate or append to pinout"
    if [ "$WARNINGS" = "error" ]; then
      exit 1;
    elif [ "$WARNINGS" = "skip" ]; then
      continue
    fi
  fi
  IMG=$(yq e '.info.image.file' "$c")
  if [ $? -ne 0 ] || [ "$IMG" = "null" ]; then
    echo "WARNING: Missing image"
    if [ "$WARNINGS" = "error" ]; then
      exit 1;
    elif [ "$WARNINGS" = "skip" ]; then
      continue
    fi
  else
    echo "Image: $IMG"
    cp "$(dirname "$c")/$IMG" "$DIR"
  fi
done

# Delete all symbolic links and empty directories from the temp dir.
find pinoutstmp -type l -delete
find pinoutstmp -type d -empty -delete
# Copy everything left over in the temp dir.
# This will get everything that didn't have a directory or title specified.
cp -r pinoutstmp/* pinouts/

rm -r pinoutstmp

echo "Completed processing $(echo -n "$CONNECTORS" | wc -l) mappings"
