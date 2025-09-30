#!/usr/bin/env bash
soft_exit() {
  # Courtesy of
  # https://stackoverflow.com/questions/11141120/exit-function-stack-without-exiting-shell;w
  return "${1:-1}"
}

get_os_type() {
  case "$(uname)" in
    "Darwin")
      echo "Darwin"
      ;;
    "Linux")
      lsb_release -is
      ;;
    *)
      echo "Unsupported"
      ;;
  esac
}

ensure_bash_profile_is_symlinked_or_die() {
  [ -L "$HOME/.bash_profile" ] && return 0

  echo "ERROR: .bash_profile must be a symlink to your GitHub clone to use this." >&2
  soft_exit 1
}

set_path() {
  path=$(cat <<-DIRECTORIES
/opt/homebrew/opt/coreutils/libexec/gnubin
/opt/homebrew/opt/make/libexec/gnubin
/opt/homebrew/bin
/opt/homebrew/sbin
/usr/local/opt/coreutils/libexec/gnubin
/Users/$USER/.gems
/Users/$USER/.gems/bin
/Users/$USER/.local/bin
/usr/local/opt/curl/bin
/usr/local/bin
/opt/X11/bin
/Users/$USER/src/go/bin
/Users/$USER/bin/gyb
/Users/$USER/.cargo/bin
/usr/bin
/usr/sbin
/bin
/sbin
$PATH
DIRECTORIES
)
  cat <<-EXPORTS
export PATH=$(echo "$path" | tr ':' '\n' | uniq | tr '\n' ':' | sed 's/.$//')
export HOMEBREW_PREFIX=/opt/homebrew
export HOMEBREW_CELLAR=/opt/homebrew/Cellar
export HOMEBREW_REPOSITORY=/opt/homebrew
export MANPATH=$(sed -E 's/:\+$//' <<< /opt/homebrew/share/man${MANPATH+:$MANPATH}:)
export INFOPATH=$(sed -E 's/:\+$//' <<< /opt/homebrew/share/info:${INFOPATH:-})
EXPORTS
}

source_tmux_stuff() {
  if ! source "$HOME/.bash_tmux_specific"
  then
    log_error "Failed to load Bash functions. Ensure that they are in your repo."
    return 1
  fi
}

ensure_setup_directory_is_present_or_die() {
  [ -d "$BASH_PROFILE_REPO" ] && return 0

  echo "ERROR: Please install your setup scripts to $BASH_PROFILE_LOCATION first." >&2
  soft_exit 1
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

install_homebrew_if_on_mac_or_die() {
  { test "$(get_os_type)" != "Darwin" || &>/dev/null which brew; } && return 0

  echo "Installing homebrew, GNU coreutils, sops and yq"
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" && \
    brew install coreutils sops yq &&
    return 0

  soft_exit 1
}

invoked_by_ai() {
  for env_var in CLAUDECODE
  do test -n "${!env_var}" && return 0
  done
  return 1
}

export $(set_path | grep -E '^export' | xargs -0)
if invoked_by_ai
then
  >&2 echo "[INFO] AI agent detected; skipping dotfile initialization"
  return 0
fi
set HISTCONTROL="ignorespace"
export_LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
export LANG="en_US.UTF-8"
set_terminal_keybinding
ensure_bash_profile_is_symlinked_or_die
ensure_setup_directory_is_present_or_die
install_homebrew_if_on_mac_or_die
source_tmux_stuff

export HOMEBREW_NO_AUTO_UPDATE=1 # This is incredibly annoying.

if test "$(echo "$BASH_VERSION" | cut -f1 -d '.')" -ge 4
then
  >&2 echo "PREFLIGHT: Enabling Bash 4+ extensions"
  export PROMPT_DIRTRIM=3
  shopt -s autocd
fi

source $HOME/.bash_functions
source $HOME/.bash_aliases
source $HOME/.bash_colors

test -f "$HOME/.bash_exports" && source $HOME/.bash_exports
test -f "$HOME/.bash_secret_exports" && source $HOME/.bash_secret_exports

if tmux_is_supported && ! in_tmux_session && ! tmux_is_disabled
then
  if ! tmux_is_installed
  then
    if ! install_tmux_and_tpm
    then
      log_error "Failed to install tmux."
      return 1
    fi
  fi
  start_tmux
elif tmux_session_is_present && ! in_tmux_session
then
  configure_client_or_company_specific_settings
  configure_secret_settings
  join_tmux_session
else
  PROMPT_COMMAND='e=$?; history -a; history -c; history -r; set_bash_prompt $e'
    configure_machine_pre
    configure_machine
    configure_client_or_company_specific_settings
    configure_secret_settings
    configure_bash_session
    add_keys_to_ssh_agent
    start_gpg_agent
    PROMPT_COMMAND='e=$?; history -a; history -c; history -r; trap - SIGINT SIGHUP EXIT; git_config_hook; aws_prompt_command_hook; set_bash_prompt $e'
fi

[ -f "$HOME/src/setup/fzf.bash" ] && source "$HOME/src/setup/fzf.bash"

# We need to do this again becasue some scripts trample over the PATH and cause
# duplicate/errant entries.
export $(set_path | grep -E '^export' | xargs -0)
source "$(brew --prefix asdf)/etc/bash_completion.d/asdf.bash"
log_info "Shell ready; enjoy! 🎉"
