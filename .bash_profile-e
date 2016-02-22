export TERM="xterm-color"
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

# ==================================================================
# Most of this was taken from the example .bash_profile on tldp.org.
# ==================================================================
# =================
# COLORS
# =================

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

# ================================
# EXTRAS
# ================================

source ~/.bash_functions
source ~/.bash_extras
find ~ -type f -name bash_*_specific -maxdepth 1 | while read file; do
    source $file
done

# =================
# SET PROMPT
# =================
set_bash_prompt() {
  # ==========================================
  # Check if I'm root or someone else.
  # ==========================================
  my_username="carlosnunez"
  fmtd_username=$my_username

  if [ $USER != $my_username ]; then
    fmtd_username="\[$On_Purple\]\[$BWhite\]$my_username\[$NC\]"
  elif [ $EUID -eq 0 ]; then
    fmtd_username="\[$ALERT\]$my_username\[$NC\]"
  else
    fmtd_username="\[$On_Green\]\[$BBlack\]$my_username\[$NC\]"
  fi

  # ===================
  # Machine name
  # ===================
  hostname_fmtd="\[$On_Yellow\]\[$BBlack\]localhost\[$NC\]"
  if [ ! -z "$SSH_CLIENT" ]; then
    hostname_fmtd="\[$On_Yellow\]\[$BBlack\]$HOSTNAME\[$NC\]"
  fi
  if [ "`git branch >/dev/null 2>/dev/null; echo $?`" -ne "0" ]; then
    PS1="\[$BCyan\][$(date "+%Y-%m-%d %H:%M:%S")\[$NC\] $fmtd_username@$hostname_fmtd \[$BCyan\]\W]\[$NC\]\[$Yellow\]\$\[$NC\]: "
  elif [ `git status --porcelain 2>/dev/null | wc -l | tr -d ' '` -eq 0 ]; then
    PS1="\[$BCyan\][$(date "+%Y-%m-%d %H:%M:%S")\[$NC\] $fmtd_username@$hostname_fmtd \[$BCyan\]\W]\[$NC\]\[$Green\]<<\$(get_git_branch)>>\[$NC\]\[$Yellow\]\$\[$NC\]: "
  else
    PS1="\[$BCyan\][$(date "+%Y-%m-%d %H:%M:%S")\[$NC\] $fmtd_username@$hostname_fmtd \[$BCyan\]\W]\[$NC\]\[$Red\]<<\$(get_git_branch)>>\[$NC\]\[$Yellow\]\$\[$NC\]: "
  fi
}

# =================
# ALIASES
# =================
alias killmatch='kill_all_matching_pids'
[[ "`uname`" == "Darwin" ]] && {
    alias clip='pbcopy'
    alias ls='ls -Gla'
} || {
    alias clip='xclip'
    alias ls='ls --color -la'
}

# =====================
# ATTACH TMUX
# =====================
which tmux > /dev/null || brew install tmux
[ -z $TMUX ] && { tmux attach-session -t 0 || true; }

# ===========================================
# Display last error code, when applicable
# ===========================================
PROMPT_COMMAND='e=$?; if [ $e -ne 0 ]; then printf "${On_Red}${BWhite}ERROR CODE $e${NC}\n"; fi; set_bash_prompt'
