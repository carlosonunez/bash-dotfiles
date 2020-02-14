#!/usr/bin/env bash
export TMUX_SESSION_NAME='tmux_session'

# Starts a new tmux session with my usual window configuration.
start_tmux() {
  tmux new-session -d -s "$TMUX_SESSION_NAME" && \
    tmux new-window -t "$TMUX_SESSION_NAME:1" -n "reddit" && \
    tmux select-window -t "$TMUX_SESSION_NAME:0" && \
    tmux split-window -v && \
    tmux select-pane -t 0 && \
    tmux attach-session -t "$TMUX_SESSION_NAME"
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

# =================
# COLORS
# =================
# Enable terminal color support.
export TERM="xterm-256color"
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

# Normal Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

# Background
On_Black='\033[40m'       # Black
On_Red='\033[41m'         # Red
On_Green='\033[42m'       # Green
On_Yellow='\033[43m'      # Yellow
On_Blue='\033[44m'        # Blue
On_Purple='\033[45m'      # Purple
On_Cyan='\033[46m'        # Cyan
On_White='\033[47m'       # White

NC="\033[m"               # Color Reset
ALERT=${BWhite}${On_Red} # Bold White on red background

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

# ===========================================================================
# Start up tmux before doing anything else.
# We will only load our profile within a TMUX pane to save on loading time.
# ===========================================================================
if test -z "$TMUX"
then
  if [ "$(which tmux)" == "" ]
  then
    case "$(get_os_type)" in
      "Darwin")
        if ! {
          brew install tmux reattach-to-user-namespace && \
          git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm;
        }
        then
          >&2 echo "ERROR: Failed to install tmux."
          exit 1
        fi
        ;;
      "Ubuntu"|"Debian")
        printf "${BYellow}INFO${NC}: Preparing to install tmux\n"
        sudo add-apt-repository -y ppa:pi-rho/dev
        sudo apt-get update
        install_application  "python-software-properties software-properties-common"
        install_application  "tmux-next"
        ;;
      *)
        printf "${BYellow}WARN${NC}: No subroutine written for OS $(get_os_type). \
Assuming package name of 'tmux'.\n"
        install_application "tmux"
        ;;
    esac
  fi
  if [ ! -d "$HOME/.tmux.d" ]
  then
    git clone https://github.com/tmux-plugins/tmux-yank ~/.tmux.d
  fi
  # Bash completion for Git.
  # ========================
  if [ "$(get_os_type)" == "Darwin" ]
  then
    [ -f $(brew --prefix)/etc/bash_completion ] && . $(brew --prefix)/etc/bash_completion
  else
    [ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion
  fi
  cd $HOME
  if tmux ls &> /dev/null
  then
    tmux attach -t "$TMUX_SESSION_NAME" 2>/dev/null
  else
    start_tmux
  fi
else
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


  # Load SSH keys into ssh-agent
  # ============================
  killall ssh-agent
  eval $(ssh-agent -s) > /dev/null
  grep -HR "RSA" $HOME/.ssh | cut -f1 -d: | sort -u | while read file; do
  ssh-add $file
  done

  [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
  # ===========================================
  # Display last error code, when applicable
  # ===========================================
  PROMPT_COMMAND='e=$?; set_bash_prompt $e'
fi

if [ -f $(brew --prefix)/etc/bash_completion ]; then
. $(brew --prefix)/etc/bash_completion
else
  brew install bash-completion
fi

export PATH=/Users/carlos/.gems/bin:/Users/carlos/.gems::/usr/local/opt/coreutils/libexec/gnubin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin:/Users/carlos/src/go/bin:/Users/carlos/bin/gyb

export PATH=/Users/carlos/.gems/bin:/Users/carlos/.gems::/usr/local/opt/coreutils/libexec/gnubin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin:/Users/carlos/src/go/bin:/Users/carlos/bin/gyb:/Users/cn/bin/gyb
