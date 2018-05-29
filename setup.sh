#!/usr/bin/env bash
DEFAULT_CONFIGURATION_DIRECTORY="$HOME/src"
DEFAULT_SETUP_DIRECTORY="${DEFAULT_SETUP_DIRECTORY}/setup"

for required_directory in "$DEFAULT_CONFIGURATION_DIRECTORY" "$DEFAULT_SETUP_DIRECTORY"
do
  if [ ! -d "$required_directory" ]
  then
    >&2 echo "ERROR: Configuration directory not present: $required_directory"
    exit 1
  fi

for managed_file in '.bash_' '.tmux' '.vim'
do
  find "${DEFAULT_SETUP_DIRECTORY}/${managed_file}*" | \
    while read found_config_file
    do
      ln -sv "$found_config_file" "$(echo "$found_config_file" | sed "s#${DEFAULT_SETUP_DIRECTORY}#$HOME#")"
    done
done

if [ "$?" == "0" ]
then
  echo 'Setup complete! Run this to get started: source $HOME/.bash_profile'
fi
