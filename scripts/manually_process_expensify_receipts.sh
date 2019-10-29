#!/usr/bin/env bash
trap 'stop_simple_server_for_known_adtech_hosts && exit $?' HUP INT

KNOWN_ADTECH_HOSTS=$(cat <<-HOSTS
d\.liadm\.com
p\.liadm\.com
liadm\.com
li\.americanexpress\.com
cits-tracking-prod\.americanexpress\.com
HOSTS
)
usage() {
  cat <<-USAGE_DOC
$(basename $0)
Converts receipts in EML format to PDF for submitting to Expensify.

This script takes no options.

NOTES

- You will need to place your EML files in this directory: $HOME/emails
- You will also need Docker for this to work.
USAGE_DOC
}

get_script_version() {
  version=$(GIT_DIR=$HOME/src/setup/.git git log -1 HEAD --format=%h)
  echo "version: $version"
}

start_simple_server_for_known_adtech_hosts() {
  echo 'this is the future of adtech' | nc -l 80 &
  echo 'this is the future of adtech' | nc -l 443 &
  >&2 echo "INFO: We started up a simple webserver for simple email tracking \
servers to prevent email conversions from failing." 
}

redirect_adtech_to_simple_server() {
  cp /etc/hosts /tmp/etc_hosts.backup
  for host in $KNOWN_ADTECH_HOSTS
  do
    >&2 echo "INFO: Redirecting ${host} to webserver (password may be required)"
    sudo sed -i '' "s/0.0.0.0 ${host}$/127.0.0.1 ${host}/" /etc/hosts
  done
}

stop_simple_server_for_known_adtech_hosts() {
  >&2 echo "INFO: Stopping the webserver (password may be required)."
  kill -SIGHUP %1
  kill -SIGHUP %2
  sudo cp /tmp/etc_hosts.backup /etc/hosts
}

if [ "$1" == "--help" ] || [ "$1" == '-h' ]
then
  usage
  exit 0
fi

if [ "$1" == "--version" ] || [ "$1" == '-v' ]
then
  get_script_version
  exit 0
fi

start_simple_server_for_known_adtech_hosts && \
  redirect_adtech_to_simple_server
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
    -v /tmp:/tmp \
    -e DISABLE_IMAGES=true \
    carlosnunez/email-to-pdf "$new_filename_sans_path" > "$new_filename_as_pdf"
done
stop_simple_server_for_known_adtech_hosts
