PHONE_WIFI_NETWORKS_REGEX="atoi|Carlos's Pixel|sandy"

check_for_git_repository() {
  which git &>/dev/null || return 1
  if ! 2>/dev/null git rev-parse --show-toplevel
  then
    >&2 printf "${BRed}ERROR${NC}: $PWD is not a Git repository.\n"
    return 1
  fi
}

run_travis() {
  docker run --rm \
    --interactive \
    --tty \
    --volume $PWD:/app \
    --volume $HOME/.travis:/root/.travis \
    --workdir /app \
    skandyla/travis-cli \
    $@
}

connect_to_phone() {
  # adb always lists phones connected over serial/USB before those
  # connected over the network.
  # pick the first entry in the list if that's the case, or 
  # attempt to connect to the phone over the network otherwise.
  connected_phone=$(adb devices | \
    grep -v 'no devices found' | \
    head -2 | \
    tail -1 | \
    awk '{print $1}'
  )
  if test -z "$connected_phone"
  then
    if ! $(/Sy*/L*/Priv*/Apple8*/V*/C*/R*/airport -I | \
      grep -E ' SSID:' | \
      sed 's/^.*SSID: //' | \
      grep -Eq "^$PHONE_WIFI_NETWORKS_REGEX$")
    then
      >&2 cat <<-ERROR_MESSAGE
Please connect to your phone's Wi-Fi hotspot first.
Ensure that it is named "Carlos's Pixel"
ERROR_MESSAGE
      return 1
    else
      phone_hotspot_gateway="$(netstat -f inet -nr | \
        grep default | \
        awk '{print $2}' | \
        tr -d ' ')"
      adb connect "${phone_hotspot_gateway}:5555"
    fi
    &>/dev/null scrcpy --bit-rate "${1:-1M}" &
  else
    &>/dev/null scrcpy --bit-rate "${1:-8M}" -s "$connected_phone" &
  fi
}

run_gyb() {
  email_address=$1
  if ! test -d "$HOME/src/gyb"
  then
    >&2 echo "INFO: Fetching Dockerized Got-Your-Back..."
    mkdir -p "$HOME/src/gyb" && \
      git clone https://github.com/carlosonunez/gyb "$HOME/src/gyb"
  fi
  $HOME/src/gyb/gyb.sh $email_address ${@:2}
}

alias w3m="w3m -cookie"
alias lynx="lynx -accept_all_cookies -vikeys -use_mouse"
alias phone='connect_to_phone'
alias phone_slow='connect_to_phone 1M'
alias xq='docker run --rm -i carlosnunez/xq'
alias travis=run_travis
alias authy='docker run --rm --env AUTHY_KEY carlosnunez/authy-cli-docker:latest'
alias git='git'
alias git='hub'
alias googler='googler -n 5 --url-handler w3m'
alias killmatch='kill_all_matching_pids'
alias tuir='TUIR_BROWSER=w3m DISPLAY=:0 tuir --enable-media'
alias find='find -E'
alias gybp='run_gyb carlos@carlosnunez.me ${@:1}'
alias gybw='run_gyb carlos.nunez@contino.io ${@:1}'
if ! which todo.sh &>/dev/null
then
  >&2 printf "${BYellow}WARN${NC}: todo.sh is not installed. Install it to keep track of stuff\!\n"
else
  alias todo="todo.sh -d $TODO_DIR/.todo.cfg"
  alias t="todo a"
  alias tl="todo ls"
  alias tdone="todo do"
  alias ptodo="check_for_git_repository && todo.sh -d $PROJECT_SPECIFIC_TODO_DIR/.todo.cfg"
  alias pt="ptodo a"
  alias ptl="ptodo ls"
  alias ptdone="ptodo do"
  if test -z "$CLIENT_NAME"
  then
    >&2 printf "${BYellow}WARN${NC}: \$CLIENT_NAME is not defined. \
Do so in .bash_exports to track client-specific to-dos, then \
source this file again.\n"
  else
    alias ctodo="todo.sh -d $CLIENT_TODO_DIR/$CLIENT_NAME/.todo.cfg"
    alias ct="ctodo a"
    alias ctl="ctodo ls"
    alias ctdone="ctodo do"
  fi
fi

alias dc=docker-compose

if which hub &>/dev/null
then
  alias git=hub
else
  >&2 printf "${BYellow}WARN${NC}: 'hub' is not installed; install it for GitHub extensions.\n"
  alias git=git
fi

case "$(get_os_type)" in
  "Darwin")
    alias tmux='tmux -u'
    alias ls='ls --color -l'
    alias clip=pbcopy
    ;;
  "Ubuntu|Debian")
    alias tmux=tmux-next
    alias ls='ls -Gla'
    alias clip=xclip
    ;;
esac
