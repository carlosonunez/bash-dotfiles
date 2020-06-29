#!/usr/bin/env bash
source ~/.bash_colors
export TMUX_SESSION_NAME='tmux_session'

set_path() {
  path=$(cat <<-DIRECTORIES
/Users/$USER/.gems/bin
/Users/$USER/.gems
/usr/local/opt/coreutils/libexec/gnubin
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

configure_bash_session() {
  # Load bash submodules, unless the submodule already indicated that it's been
  # fully loaded.
  # ===========================================================================
  for file in $(find $HOME -maxdepth 1 | \
    egrep '.*\/.bash' | \
    egrep -v 'bash_(aliases|exports|profile|install|custom_profile|company|history|sessions)' | \
    egrep -v '.bashrc' | \
    sort -u)
  do
    printf "${BYellow}INFO${NC}: Loading ${BYellow}$file${NC}\n"
    source $file
    printf "\n"
  done
  for file in aliases exports
  do
    printf "${BYellow}INFO${NC}: Loading ${BYellow}$file${NC}\n"
    source $HOME/.bash_$file
    printf "\n"
  done
}

add_keys_to_ssh_agent() {
  killall ssh-agent
  eval $(ssh-agent -s) > /dev/null
  grep -HR "RSA" $HOME/.ssh | cut -f1 -d: | sort -u | xargs ssh-add
}

# Installs tmux
install_tmux_and_tpm() {
  install_tmux() {
    case "$(get_os_type)" in
      "Darwin")
        brew install tmux
        ;;
      "Ubuntu"|"Debian")
        sudo add-apt-repository -y ppa:pi-rho/dev sudo apt-get update
        install_application tmux python-software-properties software-properties-common tmux-next
        ;;
      *)
        >&2 echo "INFO: tmux not supported by this operating system."
        return 0
        ;;
    esac
  }
  install_tpm() {
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm;
  }
  install_tmux_yank() {
    if [ ! -d "$HOME/.tmux.d" ]
    then
      git clone https://github.com/tmux-plugins/tmux-yank ~/.tmux.d
    fi
  }
  install_tmux && install_tpm && install_tmux_yank
}

install_bash_completion() {
  if [ "$(get_os_type)" == "Darwin" ]
  then
    [ -f $(brew --prefix)/etc/bash_completion ] && . $(brew --prefix)/etc/bash_completion
  else
    [ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion
  fi
}

# Is tmux installed?
tmux_is_installed() {
  test "$(which tmux &>/dev/null)" != ""
}

# Are we in an SSH session?
in_ssh_session() {
  ! test -z "$SSH_CLIENT"
}

# Are we in a TMUX shell already?
in_tmux_sesion() {
  ! test -z "$TMUX_SESSION_NAME"
}

# Is tmux supported by this OS?
tmux_is_supported() {
  os=$(get_os_type)
  case "$os" in
    Darwin|Ubuntu|Debian)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}


# Starts a new tmux session with my usual window configuration.
start_tmux() {
  cd $HOME
  if tmux ls &> /dev/null
  then
    tmux attach -t "$TMUX_SESSION_NAME" 2>/dev/null
  else
    tmux new-session -d -s "$TMUX_SESSION_NAME" && \
      tmux new-window -t "$TMUX_SESSION_NAME:1" -n "reddit" && \
      tmux select-window -t "$TMUX_SESSION_NAME:0" && \
      tmux split-window -v && \
      tmux select-pane -t 0 && \
      tmux attach-session -t "$TMUX_SESSION_NAME"
  fi
}
# Check that homebrew is installed.
# ==================================
[ "$(uname)" == "Darwin" ] && {
  which brew > /dev/null || {
    echo "Installing homebrew."
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" && \
      brew install coreutils
  };
  export PATH="/usr/local/opt/coreutils/libexec/gnubin:/usr/local/bin:$PATH"
}

# =================
# Prerequisites
# ================

bash_profile_location=$(readlink "$HOME/.bash_profile")
bash_profile_repo=$(dirname "$bash_profile_location")
pre_push_hook_location="${bash_profile_repo}/.git/hooks/pre-push"

# Ensure that our mandatory hooks are in place.
# ---------------------------------------------
if [ ! -d "$bash_profile_repo" ]
then
  echo "ERROR: Please install your setup scripts to \
$bash_profile_location_directory first." >&2
  return 1
fi

if [ ! -f "$pre_push_hook_location" ]
then
  cp "$bash_profile_repo/githooks/pre-push" \
    "$pre_push_hook_location"
  chmod +x "$pre_push_hook_location"
fi

if ! source "$HOME/.bash_functions"
then
  >&2 echo "ERROR: Failed to load Bash functions. Ensure that they are in your repo."
  return 1
fi

if [ ! -L "$HOME/.bash_profile" ]
then
  echo "ERROR: .bash_profile must be a symlink to your GitHub clone to use this." >&2
  return 1
fi

source "$HOME/.bash_install"

# ============
# emacs keybindings
# ==============
set -o emacs

# Load any company specific bash submodules first.
ls $HOME/.bash_company_* 2>/dev/null && {
  for file in $HOME/.bash_company_*
  do
    printf "${BYellow}INFO${NC}: Loading company submodule ${file}\n"
    source $file
  done
}

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
    add_keys_to_ssh_agent

  PROMPT_COMMAND='e=$?; set_bash_prompt $e'
fi

