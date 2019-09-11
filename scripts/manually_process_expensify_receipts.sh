#!/usr/bin/env bash
EMAILS_DIRECTORY="${EMAILS_DIRECTORY:-$HOME/emails}"
MHONARC_FILE_PATH="${MHONARC_FILE_PATH:-$HOME/src/setup/mhonarc.rc}"
if ! (test -d "$EMAILS_DIRECTORY" ||  test -f "$MHONARC_FILE_PATH")
then
  >&2 echo "ERROR: Couldn't find $EMAILS_DIRECTORY or $MHONARC_FILE_PATH"
  exit 1
fi
mkdir -p "${EMAILS_DIRECTORY}/pdf"
for file in ${EMAILS_DIRECTORY}/*.eml
do
  new_filename_without_spaces="$(echo "$file" | \
    sed 's/ /_/g' | \
    tr '[:upper:]' '[:lower:]')"
  new_filename_sans_path=$(basename "$new_filename_without_spaces")
  new_filename_as_pdf=$(echo "${EMAILS_DIRECTORY}/pdf/$new_filename_sans_path" | \
    sed 's/.eml/.pdf/'
  )
  if [ "$file" != "$(echo "$new_filename_without_spaces" | tr '[:upper:]' '[:lower:]')" ]
  then
    mv "$file" "$new_filename_without_spaces"
  fi
  echo "INFO: Processing '$new_filename_without_spaces'..."
  docker run --rm -v "$MHONARC_FILE_PATH:/mhonarc.rc" \
    -v "$EMAILS_DIRECTORY":/vol \
    gerco/email-to-pdf "$new_filename_sans_path" > "$new_filename_as_pdf"
done
