#!/usr/bin/env bash

DEFAULT_CONFIGURATION_DIRECTORY="$HOME/src"
DEFAULT_SETUP_DIRECTORY="${DEFAULT_CONFIGURATION_DIRECTORY}/setup"

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
for managed_file in '.bash_' '.tmux' '.vim'
do
  find "${DEFAULT_SETUP_DIRECTORY}"/"${managed_file}"* -maxdepth 0 | \
    while read found_config_file
    do
      destination_for_config_file=$(echo "$found_config_file" | \
          sed "s#${DEFAULT_SETUP_DIRECTORY}#$HOME#")
      if [ ! -L "$destination_for_config_file" ] || \
        [ ! -f "$destination_for_config_file" ]
      then
        /usr/bin/env ln -s "$found_config_file" "$destination_for_config_file"
      else
        >&2 echo "INFO: Symlink already exists: $destination_for_config_file"
      fi
    done
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
  if cat /proc/version | grep -q 'Microsoft'
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

copy_ssh_keys_from_onedrive() {
  copy_from_onedrive_if_within_lxss_for_windows "ssh_keys" "$HOME/.ssh"
  grep -rlH 'RSA' $HOME/.ssh | xargs chmod 600
}

copy_aws_keys_from_onedrive() {
  copy_from_onedrive_if_within_lxss_for_windows "aws_keys" "$HOME/.aws"
}

if {
  check_for_required_directories &&
  create_symlinks_for_config_files &&
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
