#!/usr/bin/env bash
GYB_SRC_DIRECTORY=$HOME/src/gyb
GYB_SRC_URL=https://github.com/carlosonunez/gyb-docker

usage() {
  cat <<-USAGE
gyb.sh [email_address]
Runs a Dockerized instance of gyb.

ARGUMENTS:

  email_address       The email address to run gyb against.
USAGE
}

clone_gyb_repo_if_not_present() {
  if ! test -d "$GYB_SRC_DIRECTORY"
  then
    >&2 echo "INFO: gyb source dir not found; cloning."
    pushd "$HOME/src"
    git clone "$GYB_SRC_URL"
    mv gyb-docker gyb
    popd
  fi
}

run_gyb_command() {
  email_address="${1?Please provide an email address.}"
  export LOCAL_FOLDER="$HOME/.gyb/${email_address}"
  mkdir -p "$LOCAL_FOLDER" 2>/dev/null
  docker-compose -f "${GYB_SRC_DIRECTORY}/docker-compose.yml" run --rm gyb \
    --email "${email_address}" \
    $*
}

if test -z "$1"
then
  usage
  exit 1
fi
set -x
clone_gyb_repo_if_not_present &&
run_gyb_command $*
set +x
