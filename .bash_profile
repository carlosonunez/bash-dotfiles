#!/usr/bin/env bash
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
export LANG="en_US.UTF-8"
source ~/.bash_colors
source ~/.bash_exports
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

set_path() {
  path=$(cat <<-DIRECTORIES
/Users/$USER/.gems
/Users/$USER/.gems/bin
/usr/local/opt/coreutils/libexec/gnubin
/usr/local/opt/make/libexec/gnubin
/usr/local/bin
/usr/bin
/bin
/usr/sbin
/sbin
/opt/X11/bin
/Users/$USER/src/go/bin
/Users/$USER/bin/gyb
DIRECTORIES
)
  export PATH=$(echo "$path" | tr '\n' ':' | sed 's/.$//')
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

set_path &&
  set_terminal_keybinding &&
  ensure_setup_directory_is_present &&
  ensure_bash_profile_is_symlinked &&
  source_tmux_stuff &&
  source_functions

if tmux_is_supported && ! in_tmux_session && ! tmux_is_disabled
then
  if ! tmux_is_installed
  then
    if ! install_tmux_and_tpm
    then
      >&2 echo "ERROR: Failed to install tmux."
      return 1
    fi
  fi
  start_tmux
elif tmux_session_is_present && ! in_tmux_session
then
  join_tmux_session
else
  PROMPT_COMMAND='e=$?; set_bash_prompt $e'
    install_bash_completion &&
    configure_client_or_company_specific_settings &&
    configure_bash_session &&
    configure_machine &&
    add_keys_to_ssh_agent
fi


[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
