#!/usr/bin/env bash

DEFAULT_CONFIGURATION_DIRECTORY="$HOME/src"
DEFAULT_SETUP_DIRECTORY="${DEFAULT_CONFIGURATION_DIRECTORY}/setup"

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

copy_from_onedrive_if_within_lxss_for_windows() {
  dir_to_copy_from="${1?Please provide a source directory.}"
  dir_to_copy_to="${2?Please provide the directory to copy to.}"
  if test -f "/proc/version" && (cat /proc/version | grep -q 'Microsoft')
  then
    cmd.exe /c 'echo %USERNAME%' > /tmp/windows_username
    windows_username=$(cat -v '/tmp/windows_username' | tr -d '^M')
    windows_onedrive_directory="/mnt/c/Users/${windows_username}/OneDrive"
    if [ -d "$windows_onedrive_directory" ]
    then
      >&2 echo "INFO: Copying from $dir_to_copy_from within OneDrive to $dir_to_copy_to"
      mkdir -p "$dir_to_copy_to" 2>/dev/null
      cp -v "${windows_onedrive_directory}/${dir_to_copy_from}"/* "$dir_to_copy_to"
    fi
  fi
}

create_symlinks_for_tuir() {
  mkdir -p ~/.config/tuir &&
    ln -s "${DEFAULT_SETUP_DIRECTORY}/tuir_configs/tuir.cfg" ~/.config/tuir/tuir.cfg || true &&
    ln -s "${DEFAULT_SETUP_DIRECTORY}/tuir_configs/.mailcap" ~/.mailcap || true
}

copy_ssh_keys_from_onedrive() {
  copy_from_onedrive_if_within_lxss_for_windows "ssh_keys" "$HOME/.ssh"
  grep -rlH 'RSA' $HOME/.ssh | xargs chmod 600
}

copy_aws_keys_from_onedrive() {
  copy_from_onedrive_if_within_lxss_for_windows "aws_keys" "$HOME/.aws"
}

if {
  install_homebrew &&
  check_for_required_directories &&
  create_symlinks_for_config_files &&
  create_symlinks_for_tuir &&
  create_vim_directories &&
  copy_ssh_keys_from_onedrive &&
  copy_aws_keys_from_onedrive;
}
then
  tell_user_what_to_do_next
else
  >&2 echo "ERROR: Something went wrong. Fix that thing, then try again."
  exit 1
fi
