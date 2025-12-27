#!/bin/bash
# env MAPPING_PATH: yaml(s) path
# env WARNINGS:
#   print more visible notice if "notice"
#   fail if "error"
#   skip if "skip"
# env WARNING_NO_CID
# env WARNING_NO_CONNECTORS
# env WARNING_NO_IMAGE
# env WARNING_NO_PINS
# env WARNING_DUPE
# env WARNING_PARSE
#   same options as WARNINGS

if [ "$DEBUG" = "true" ]; then
  echo "WARNINGS: $WARNINGS"
  echo "WARNING_NO_CID: $WARNING_NO_CID"
  echo "WARNING_NO_CONNECTORS: $WARNING_NO_CONNECTORS"
  echo "WARNING_NO_IMAGE: $WARNING_NO_IMAGE"
  echo "WARNING_NO_PINS: $WARNING_NO_PINS"
  echo "WARNING_DUPE: $WARNING_DUPE"
  echo "WARNING_PARSE: $WARNING_PARSE"
fi

SCRIPTDIR=$(dirname "$0")

handle_warning ()
{
  if [ "$WARNINGS" = "error" ] && [ "$1" = "unset" ] || [ "$1" = "error" ]; then
    echo "::error:: $2"
    exit 1;
  elif [ "$WARNINGS" = "notice" ] && [ "$1" = "unset" ] || [ "$1" = "notice" ]; then
    echo "::notice:: $2"
  elif [ "$WARNINGS" = "skip" ] && [ "$1" = "unset" ] || [ "$1" = "skip" ]; then
    echo "$2"
    return 1
  else
    echo "$2"
  fi
  return 0
}

# Sort all the yaml files by the order field they may contain.
CONNECTORS=$(echo "$MAPPING_PATH" | while read p; do find . -path "./$p"; done)

if [ "$DEBUG" = "true" ]; then
  echo "Search Path: $MAPPING_PATH"
  echo "Found YAMLs: $CONNECTORS"
fi

if [ $(echo "$CONNECTORS" | grep -v ^$ | wc -l) -eq 0 ]; then
  handle_warning "$WARNING_NO_CONNECTORS" "WARNING: No connectors found"
  exit
fi

FILES=$(for f in $CONNECTORS; do
          ORDER=$(yq e '.info.order' "$f")
          [ $? -eq 0 ] || handle_warning "$WARNING_PARSE" "WARNING: parse error in definition $f"
          echo "$f $ORDER"
done)
CONNECTORS=$(echo "$FILES" | sort -k2 | cut -d ' ' -f 1)

# Make a temp directory for symlinks to actual files.
mkdir -p pinoutstmp


for c in $CONNECTORS; do
  echo "Processing: $c"
	PINCNT=$(yq e '.pins.[].pin' "$c" | wc -c)
	[ $? -eq 0 ] || handle_warning "$WARNING_PARSE" "WARNING: parse error in definition $c" || continue
  [ "$PINCNT" -gt 0 ] || handle_warning "$WARNING_NO_PINS" "WARNING: No pins found in definition $c" || continue
  DUPES=$(yq e '.pins.[].pin' "$c" | grep -v "null" | sort | uniq -d | tr -d '\n')
	[ $? -eq 0 ] || handle_warning "$WARNING_PARSE" "WARNING: parse error in definition $c" || continue
  [ -z "$DUPES" ] || handle_warning "$WARNING_DUPE" "WARNING: Duplicate pins in $c: $DUPES" || continue
  POSDUPES=$(yq e '.info.pins.[].pin' "$c" | grep -v "null" | sort | uniq -d | tr -d '\n')
	[ $? -eq 0 ] || handle_warning "$WARNING_PARSE" "WARNING: parse error in definition $c" || continue
  POSDUPES+=$(yq e '.info.image.pins.[].pin' "$c" | grep -v "null" | sort | uniq -d | tr -d '\n')
	[ $? -eq 0 ] || handle_warning "$WARNING_PARSE" "WARNING: parse error in definition $c" || continue
  [ -z "$POSDUPES" ] || handle_warning "$WARNING_DUPE" "WARNING: Duplicate pin positions in $c: $POSDUPES" || continue
  # Get the directory and title, if they exist
  DIRECTORY=$(yq e '.info.directory' "$c")
	[ $? -eq 0 ] || handle_warning "$WARNING_PARSE" "WARNING: parse error in definition $c" || continue
  TITLE=$(yq e '.info.title' "$c")
	[ $? -eq 0 ] || handle_warning "$WARNING_PARSE" "WARNING: parse error in definition $c" || continue
  # Build the temp path, removing leading ./ and /
  DIR="pinoutstmp/"$(dirname "$c" | sed -e 's/^\.\///' -e 's/^\///')
  # If we have a directory field
  if [ "$DIRECTORY" != "null" ]; then
    if [ "$DEBUG" = "true" ]; then
      echo "Found Directory: $DIRECTORY"
    fi
    # If temp dir exists
    if [ -d "$DIR" ]; then
      # If temp dir isn't symbolic link
      if [ ! -L "$DIR" ]; then
        if [ "$DEBUG" = "true" ]; then
          echo "Found Directory is normal directory"
        fi
        # It must be a real directory, move it to the final dir and link it
        mkdir -p "pinouts/$DIRECTORY"
        mv "$DIR"/* "pinouts/$DIRECTORY"
        rmdir "$DIR"
        ln -rs "pinouts/$DIRECTORY" "$DIR"
      # If temp dir is a link, but not to the specified directory
      elif TARGET=$(readlink -f "$DIR") && [ "$TARGET" != "$(realpath "pinouts/$DIRECTORY")" ]; then
        if [ "$DEBUG" = "true" ]; then
          echo "Found Directory is link to another directory: $TARGET vs $(realpath "pinouts/$DIRECTORY")"
        fi
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
    if [ "$DEBUG" = "true" ]; then
      echo "Found Title: $TITLE"
    fi
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
  if [ "$DEBUG" = "true" ]; then
    echo "Target Directory: $DIR"
  fi
  NAME=$(basename "$c" .yaml)
  if [ "$DEBUG" = "true" ]; then
    echo "File Name: $NAME"
  fi
	CID=$(yq e '.info.cid' "$c")
	[ $? -eq 0 ] || handle_warning "$WARNING_PARSE" "WARNING: parse error in definition $c" || continue
  [ "$CID" != "null" ] || handle_warning "$WARNING_NO_CID" "WARNING: Missing yaml cid field in info section of $c" || continue
  IMG=$(yq e '.info.image.file' "$c")
	[ $? -eq 0 ] || handle_warning "$WARNING_PARSE" "WARNING: parse error in definition $c" || continue
  if [ "$IMG" = "null" ]; then
    IMP=$(yq e '.info.image.import' "$c")
		[ $? -eq 0 ] || handle_warning "$WARNING_PARSE" "WARNING: parse error in definition $c" || continue
    if [ "$IMP" = "null" ]; then
      handle_warning "$WARNING_NO_IMAGE" "WARNING: $c missing image" || continue
    else
      IMG=$(yq e '.image.file' "$(dirname "$c")/$IMP")
			[ $? -eq 0 ] || handle_warning "$WARNING_PARSE" "WARNING: parse error in definition $c" || continue
      echo "Image: $IMG"
      cp "$(dirname $(dirname "$c")/$IMP)/$IMG" "$DIR"
      yq --inplace ea '.info.image = .image | select(fi == 0)' "$c" "$(dirname "$c")/$IMP"
			[ $? -eq 0 ] || handle_warning "$WARNING_PARSE" "WARNING: parse error in definition $c" || continue
    fi
  else
    echo "Image: $IMG"
    cp "$(dirname "$c")/$IMG" "$DIR"
    # Patch legacy YAMLs for backwards compatability by moving .info.pins to .info.image.pins
    yq --inplace e '.info.image.pins = .info.pins' "$c"
		[ $? -eq 0 ] || handle_warning "$WARNING_PARSE" "WARNING: parse error in definition $c" || continue
    yq --inplace e 'del(.info.pins)' "$c"
		[ $? -eq 0 ] || handle_warning "$WARNING_PARSE" "WARNING: parse error in definition $c" || continue
  fi
	JSON=$(yq -o=json e "$c")
	[ $? -eq 0 ] || handle_warning "$WARNING_PARSE" "WARNING: parse error in definition $c" || continue
  if [ -f "$DIR/index.html" ]; then
    bash "$SCRIPTDIR"/append.sh "$JSON" "$DIR/index.html"
  else
    bash "$SCRIPTDIR"/gen.sh "$JSON" "$DIR/index.html"
  fi
  [ $? -eq 0 ] || handle_warning "unset" "WARNING: Failed to generate or append to pinout" || continue
done

# Delete all symbolic links and empty directories from the temp dir.
find pinoutstmp -type l -delete
find pinoutstmp -type d -empty -delete
# Copy everything left over in the temp dir.
# This will get everything that didn't have a directory or title specified.
[ -d pinoutstmp ] && cp -r pinoutstmp/* pinouts/ && rm -r pinoutstmp

find pinouts/ -type f -name 'index.html' -print0 | while IFS= read -r -d '' f; do
  DUPES=$(grep "cid\": " "$f" | uniq -d | tr -d '\n')
  if [ -n "$DUPES" ]; then
    handle_warning "$WARNING_DUPE" "WARNING: Duplicate cids in $f: $DUPES" || continue
  fi
done

echo "Completed processing $(echo "$CONNECTORS" | grep -v ^$ | wc -l) mappings"
