PHONE_WIFI_NETWORKS_REGEX="atoi|Carlos's Pixel|sandy"
source "$(brew --prefix)/etc/profile.d/bash_completion.sh"
source "$HOME/.bash_completion.d/complete_alias"

check_for_git_repository() {
  which git &>/dev/null || return 1
  if ! 2>/dev/null git rev-parse --show-toplevel
  then
    log_error "$PWD is not a Git repository."
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
    log_info "Fetching Dockerized Got-Your-Back..."
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
alias git='git'
alias git='hub'
alias googler='googler -n 5 --url-handler w3m'
alias killmatch='kill_all_matching_pids'
alias tuir='TUIR_BROWSER=w3m DISPLAY=$DISPLAY tuir --enable-media'
alias find='find -E'
if ! which todo.sh &>/dev/null
then
  log_warn "todo.sh is not installed. Install it to keep track of stuff\!"
else
  alias todo="todo.sh -d $TODO_DIR/.todo.cfg"
  alias t="todo a"
  alias tl="todo ls"
  alias tdone="todo do"
  alias ptodo="check_for_git_repository && todo.sh -d $PROJECT_SPECIFIC_TODO_DIR/.todo.cfg"
  alias pt="ptodo a"
  alias ptl="ptodo ls"
  alias ptdone="ptodo do"
fi

alias dc=docker-compose
complete -F _complete_alias dc
alias speed=run_speed_test
alias git=git

case "$(get_os_type)" in
  "Darwin")
    alias tmux='tmux -u'
    alias ls='ls --color -l'
    alias clip=pbcopy
    alias upcase='tr [:lower:] [:upper:]'
    alias downcase='tr [:upper:] [:lower:]'
    alias ctags="`brew --prefix`/bin/ctags"
    ;;
  "Ubuntu|Debian")
    alias tmux=tmux-next
    alias ls='ls -Gla'
    alias clip=xclip
    alias upcase='tr [:lower:] [:upper:]'
    alias downcase='tr [:upper:] [:lower:]'
    ;;
esac

