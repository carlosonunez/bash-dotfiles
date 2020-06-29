#!/usr/bin/env bash
source ~/.bash_colors
export TMUX_SESSION_NAME='tmux_session'
export BASH_PROFILE_LOCATION=$(readlink "$HOME/.bash_profile")
export BASH_PROFILE_REPO=$(dirname "$BASH_PROFILE_LOCATION")
ensure_bash_profile_is_symlinked() {
  if [ ! -L "$HOME/.bash_profile" ]
  then
    echo "ERROR: .bash_profile must be a symlink to your GitHub clone to use this." >&2
    return 1
  fi
}

source_functions() {
  if ! source "$HOME/.bash_functions"
  then
    >&2 echo "ERROR: Failed to load Bash functions. Ensure that they are in your repo."
    return 1
  fi
}

source_tmux_stuff() {
  if ! source "$HOME/.bash_tmux_specific"
  then
    >&2 echo "ERROR: Failed to load Bash functions. Ensure that they are in your repo."
    return 1
  fi
}

ensure_setup_directory_is_present() {
  if [ ! -d "$BASH_PROFILE_REPO" ]
  then
    echo "ERROR: Please install your setup scripts to $BASH_PROFILE_LOCATION first." >&2
    return 1
  fi
}

configure_git_hooks() {
  pre_push_hook_location="${bash_profile_repo}/.git/hooks/pre-push"

  # Ensure that our mandatory hooks are in place.
  # ---------------------------------------------
  if [ ! -f "$pre_push_hook_location" ]
  then
    cp "$BASH_PROFILE_REPO/githooks/pre-push" \
      "$pre_push_hook_location"
    chmod +x "$pre_push_hook_location"
  fi
}

set_terminal_keybinding() {
  set -o emacs
}

set_terminal_keybinding &&
  ensure_setup_directory_is_present &&
  ensure_bash_profile_is_symlinked &&
  source_tmux_stuff &&
  source_functions

if tmux_is_supported && ! in_tmux_sesion && ! in_ssh_session
then
  if ! tmux_is_installed
  then
    if ! install_tmux
    then
      >&2 echo "ERROR: Failed to install tmux."
      exit 1
    fi
  fi
  start_tmux
else
  set_path &&
    install_bash_completion &&
    configure_bash_session &&
    configure_machine &&
    add_keys_to_ssh_agent

  PROMPT_COMMAND='e=$?; set_bash_prompt $e'
fi

