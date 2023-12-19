#!/usr/bin/env bash
MARCUS_DIR="$HOME/src/marcus-stack"
MARCUS_REMOTE_DIR=stacks/marcus
BASH_DOTFILES_URL=https://github.com/carlosonunez/bash-dotfiles

_marcus_exists() {
  test -d "$MARCUS_DIR"
}

_log() {
  >&2 printf '===> %s\n' "$1"
}


fetch_marcus_stack() {
  _marcus_exists && return 0

  _log 'Downloading Marcus stack'
  test -d /tmp/bash-dotfiles && rm -rf /tmp/bash-dotfiles
  git clone -n --depth=1 --filter=tree:0 "$BASH_DOTFILES_URL" /tmp/bash-dotfiles || return 0
  pushd /tmp/bash-dotfiles &&
    git sparse-checkout set --no-cone "$MARCUS_REMOTE_DIR" &&
    git checkout &&
    cp -r "$MARCUS_REMOTE_DIR" "$MARCUS_DIR" &&
    popd &&
    rm -rf /tmp/bash-dotfiles
}

ensure_alpine() {
  test -f /etc/alpine-release && return 0

  >&2 echo "ERROR: This only works on Alpine. Sorry!"
  exit 1
}

start_marcus_stack_on_boot() {
  test -f /etc/local.d/marcus.start && return 0

  _log 'Configuring Marcus to start on boot'
  echo "docker-compose --project-directory '$MARCUS_DIR' up -d" > /etc/local.d/marcus.start &&
    chmod +x /etc/local.d/marcus.start
}

install_docker_and_compose() {
  &>/dev/null which docker docker-compose && return 0

  _log 'Installing Docker and Compose'
  apk update && apk add docker docker-compose
}

start_marcus() {
  _log 'Starting Marcus'
  sudo /etc/local.d/marcus.start
}

ensure_sudo() {
  if ! &>/dev/null which sudo
  then
    >&2 echo "ERROR: sudo not installed"
    exit 1
  fi
  test "$(sudo whoami)" == "root"
}

ensure_sudo &&
  ensure_alpine &&
  fetch_marcus_stack &&
  install_docker_and_compose &&
  start_marcus_stack_on_boot &&
  start_marcus
