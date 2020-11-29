#!/bin/bash
# used by the ci to rename files to upload to github
# sets FILENAME and optionally UPLOAD_URL for releases
# renames the file to [original name][SUFFIX].[original extension]
# where SUFFIX is either available in the environment or as the first arg
# if MAKE_ZIP is set instead a zip is made
# will fetch the github upload url using curl and jq and add the release name
# expected to be run in the project root directory

if [[ $1 ]]; then
  SUFFIX="$1"
fi

# check env
for var in GITHUB_REF GITHUB_REPOSITORY SUFFIX; do
  [[ ${!var} ]] || missing+=" $var"
done
if [[ $missing ]]; then
  echo "::error file=$0::environment missing:$missing"
  exit 2
fi

set -e

# on release only
release_regex='^refs/tags/'
if [[ $GITHUB_REF =~ $release_regex ]]; then
  tag="${GITHUB_REF##*/}"
  api_url="https://api.github.com/repos/$GITHUB_REPOSITORY/releases/tags/$tag"
  json="$(curl "$api_url")"

  # set UPLOAD_URL
  UPLOAD_URL="$(jq -r '.upload_url' <<<"$json")"
  if [[ ! $UPLOAD_URL || $UPLOAD_URL == null ]]; then
    echo "::error file=$0::failed to fetch upload url from $api_url"
    exit 1
  fi
  echo "::set-output name=upload_url::$UPLOAD_URL"

  # add pretty name to SUFFIX
  release_name="$(jq -r '.name' <<<"$json")"
  if [[ $release_name && $release_name != null ]]; then
    name_regex='^Cockatrice .*: '
    if [[ $release_name =~ $name_regex ]]; then
      pretty_name="${release_name#$BASH_REMATCH}"
      SUFFIX="-${pretty_name//[^[:alnum:]]/_}$SUFFIX"
    fi
  fi
fi

# find file
found="$(find build -maxdepth 1 -type f -name "Cockatrice-*.*" -print -quit)"
path="${found%/*}"
file="${found##*/}"
if [[ ! $file ]]; then
  echo "::error file=$0::could not find package"
  exit 1
fi

# set FILENAME
name="${file%.*}"
new_name="$path/$name$SUFFIX."
if [[ $MAKE_ZIP ]]; then
  FILENAME="${new_name}zip"
  zip "$FILENAME" "$path/$file"
else
  extension="${file##*.}"
  FILENAME="$new_name$extension"
  mv "$path/$file" "$FILENAME"
fi
echo "::set-output name=file::$FILENAME"
echo "::set-output name=name::${FILENAME##*/}"
