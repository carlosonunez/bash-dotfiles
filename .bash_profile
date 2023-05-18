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
  soft_exit
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
/usr/local/opt/curl/bin
/usr/local/bin
/opt/X11/bin
/Users/$USER/src/go/bin
/Users/$USER/bin/gyb
/usr/bin
/usr/sbin
/bin
/sbin
DIRECTORIES
)
  export PATH=$(echo "$path" | tr '\n' ':' | sed 's/.$//')
  export HOMEBREW_PREFIX="/opt/homebrew";
  export HOMEBREW_CELLAR="/opt/homebrew/Cellar";
  export HOMEBREW_REPOSITORY="/opt/homebrew";
  export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:";
  export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}";
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
  soft_exit
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

  echo "Installing homebrew and GNU coreutils"
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" && \
    brew install coreutils &&
    return 0

  soft_exit
}

set HISTCONTROL="ignorespace"
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
export LANG="en_US.UTF-8"
set_path
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
  configure_client_or_company_specific_settings &&
  configure_secret_settings &&
  join_tmux_session
else
  PROMPT_COMMAND='e=$?; history -a; history -c; history -r; set_bash_prompt $e'
    configure_machine_pre &&
    configure_machine &&
    PROMPT_COMMAND='e=$?; history -a; history -c; history -r; gvm_hook; cscope_hook; ctags_hook; set_bash_prompt $e'
    configure_client_or_company_specific_settings &&
    configure_secret_settings &&
    configure_bash_session &&
    add_keys_to_ssh_agent &&
    start_gpg_agent &&
    log_info "Shell ready; enjoy! 🎉"
fi

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
[ -f "$HOME/src/setup/fzf.bash" ] && source "$HOME/src/setup/fzf.bash"

[[ -s "/Users/cn/.gvm/scripts/gvm" ]] && source "/Users/cn/.gvm/scripts/gvm"
source "$HOME/src/setup/.bash_go_specific"
