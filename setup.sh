#!/usr/bin/env bash

DEFAULT_CONFIGURATION_DIRECTORY="$HOME/src"
DEFAULT_SETUP_DIRECTORY="${DEFAULT_CONFIGURATION_DIRECTORY}/setup"

clone_dotfiles() {
  if test -d "$DEFAULT_SETUP_DIRECTORY"
  then
    >&2 echo "ERROR: Setup directory already exists at $DEFAULT_SETUP_DIRECTORY. Add \
OVERWRITE=true to the beginning of this command to fix that."
    return 1
  fi
  git clone https://github.com/carlosonunez/bash-dotfiles $DEFAULT_SETUP_DIRECTORY
}

set_context() {
  pushd $DEFAULT_SETUP_DIRECTORY
}

leave_context() {
  popd
}

install_homebrew() {
  if ! which brew &>/dev/null
  then
    "$(dirname $0)/install_homebrew.sh"
  fi
}

check_for_required_directories() {
for required_directory in "$DEFAULT_CONFIGURATION_DIRECTORY" "$DEFAULT_SETUP_DIRECTORY"
do
  if [ ! -d "$required_directory" ]
  then
    >&2 echo "ERROR: Configuration directory not present: $required_directory"
    return 1
  fi
done
}

create_symlinks_for_config_files() {
  all_bash_files=$(find $(dirname $0) -maxdepth 1 -type f -name ".bash_*" -exec basename {} \;)
  for managed_file in $all_bash_files '.vim' '.tmux.conf' '.vimrc'
  do
    symlink_path="${HOME}/$managed_file"
    target_path="${DEFAULT_SETUP_DIRECTORY}/$managed_file"
    if test -L "$symlink_path"
    then
      >&2 echo "INFO: Symlink exists: $symlink_path"
    else
      /usr/bin/env ln -s "$target_path" "$symlink_path" || true
    fi
  done
}

tell_user_what_to_do_next() {
  if [ "$?" == "0" ]
  then
    echo 'Setup complete! Run this to get started: source $HOME/.bash_profile'
  fi
}

create_vim_directories() {
  for vim_directory in 'swap' 'backup'
  do
    mkdir -pv "${DEFAULT_SETUP_DIRECTORY}/.vim/$vim_directory"
  done
}

create_symlinks_for_tuir() {
  mkdir -p ~/.config/tuir &&
    ln -s "${DEFAULT_SETUP_DIRECTORY}/tuir_configs/tuir.cfg" ~/.config/tuir/tuir.cfg || true &&
    ln -s "${DEFAULT_SETUP_DIRECTORY}/tuir_configs/.mailcap" ~/.mailcap || true
}

if {
  clone_dotfiles &&
  set_context &&
  install_homebrew &&
  check_for_required_directories &&
  create_symlinks_for_config_files &&
  create_symlinks_for_tuir &&
  create_vim_directories &&
  leave_context
}
then
  tell_user_what_to_do_next
else
  >&2 echo "ERROR: Something went wrong. Fix that thing, then try again."
  exit 1
fi
