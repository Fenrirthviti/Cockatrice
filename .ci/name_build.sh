#!/bin/bash
# used by the ci to rename build artifacts
# renames the file to [original name][SUFFIX].[original extension]
# where SUFFIX is either available in the environment or as the first arg
# if MAKE_ZIP is set instead a zip is made
# expected to be run in the build directory
buildddir="."

if [[ $1 ]]; then
  SUFFIX="$1"
fi

# check env
if [[ ! $SUFFIX ]]; then
  echo "::error file=$0::SUFFIX is missing"
  exit 2
fi

set -e

# find file
found="$(find "$builddir" -maxdepth 1 -type f -name "Cockatrice-*.*" -print -quit)"
path="${found%/*}"
file="${found##*/}"
if [[ ! $file ]]; then
  echo "::error file=$0::could not find package"
  exit 1
fi

# set filename
name="${file%.*}"
new_name="$path/$name$SUFFIX."
if [[ $MAKE_ZIP ]]; then
  filename="${new_name}zip"
  zip "$filename" "$path/$file"
else
  extension="${file##*.}"
  filename="$new_name$extension"
  mv "$path/$file" "$filename"
fi
echo "::set-output name=path::$filename"
echo "::set-output name=name::${filename##*/}"
