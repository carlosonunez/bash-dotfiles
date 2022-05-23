#!/usr/bin/env bash
HIDDEN_BASH_PROMPT_FILE="/tmp/use_hidden_bash_prompt"
ONE_GIGABYTE="$(numfmt --from=iec '1G')"
ONE_MEGABYTE="$(numfmt --from=iec '1M')"
ONE_KILOBYTE="$(numfmt --from=iec '1K')"

# shellcheck disable=SC2154
log_init() {
  >&2 echo -ne "${BCyan}INIT${NC}: $1\n"
}

log_info() {
  >&2 echo -ne "${BGreen}INFO${NC}: $1\n"
}

log_info_sudo() {
  >&2 echo -ne "${BGreen}INFO${NC}: $1 (Enter password when prompted)\n"
}

log_warning() {
  >&2 echo -ne "${BYellow}WARNING${NC}: $1\n"
}

log_warning() {
  >&2 echo -ne "${BYellow}WARNING${NC}: $1 (Enter password when prompted)\n"
}

log_error() {
  >&2 echo -ne "${BRed}ERROR${NC}: $1 (Enter password when prompted)\n"
}

log_error() {
  >&2 echo -ne "${BRed}ERROR${NC}: $1 (Enter password when prompted)\n"
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


jumpbox() {
  get_jumpbox_details_from_op() {
    details=$(sudo security find-generic-password -a "$USER" -s "jumpbox" -w 2>/dev/null)
    if test -z "$details"
    then
      if ! remote_details=$(op --vault "$ONEPASSWORD_VAULT" get item "Carlos's Jumpbox Details" | \
        jq -r '.details.notesPlain' | tr '\n' ';' )
      then
        log_error "Can't get jumpbox details."
        return 1
      fi
      sudo security add-generic-password -a "$USER" -s "jumpbox" -w "$remote_details" -U
      echo "$remote_details"
      return
    fi
    echo "$details"
  }
  if ! details=$(get_jumpbox_details_from_op | tr ';' '\n')
  then
    log_error "Can't get jumpbox details."
    return 1
  fi
  host=$(echo "$details" | head -1)
  port=$(echo "$details" | tail -2 | tail -1)
  username=$(echo "$details" | tail -2 | head -1)
  if test -z "$host" || test -z "$port" || test -z "$username"
  then
    log_error "Host or port is empty."
    return 1
  fi
  cmd="ssh -o ServerAliveInterval=30 -o ServerAliveCountMax=10 -A"
  for arg in "$@"
  do
    cmd="$cmd $arg"
  done
  cmd="$cmd -p $port $username@$host"
  if ! test -z "$JUMPBOX_SSH_COMMAND"
  then
    cmd="$cmd $JUMPBOX_SSH_COMMAND"
  fi
  printf "${BGreen}-->${NC} $cmd\n"
  $cmd
}

pushd () {
  command pushd "$@" > /dev/null
}

popd () {
  command popd "$@" > /dev/null
}

get_csp_login_status() {
  AZURE_PROFILES_LOCATION="$HOME/.azure/azureProfile.json"
  AWS_STS_LOCATION="$HOME/.config/aws/sts_info"
  _azure_status() {
    if test -f "$AZURE_PROFILES_LOCATION"
    then
      logged_in_user_guids=$(jq -r '.subscriptions[].user.name' $AZURE_PROFILES_LOCATION | \
        sort -u | \
        tr '\n' ',' | \
        sed 's/,$//'
      )
      if ! test -z "$logged_in_user_guids"
      then
        printf "%s" "$logged_in_user_guids"
      else
        printf "not logged in"
      fi
    fi
  }

  _aws_status() {
    access_key_loaded="$(echo "$AWS_ACCESS_KEY_ID")"
    if test -z "$access_key_loaded"
    then
      echo -ne "${BRed}no access key loaded; run log_into_aws to fix${NC}"
      return 0
    fi
    if test -e "$AWS_STS_LOCATION"
    then
      sts_arn=$(jq -r .arn "$AWS_STS_LOCATION" | sed 's/arn:aws:sts:://')
      expiration=$(jq -r .expiration "$AWS_STS_LOCATION")
      now=$(date +%s)
      minutes_til_expiration=$(((expiration-now)/60))
      if test "$minutes_til_expiration" -lt 0
      then
        printf "${BRed}%s ~> !! refresh needed !!${NC}" "$access_key_loaded"
      else
        printf "%s ~> %s [%d minutes left]" "$access_key_loaded" "$sts_arn" "$minutes_til_expiration"
      fi
    else
      printf "%s" "$access_key_loaded"
    fi
  }

  printf "${BYellow}[AWS${NC}: ${Yellow}%s${NC}\n" "$(_aws_status)]"
  printf "${BCyan}[Azure${NC}: ${Cyan}%s${NC}" "$(_azure_status)]"
}


configure_machine() {
  install_homebrew_if_on_mac() {
    if test "$(get_os_type)" == "Darwin" && ! which brew &>/dev/null
    then
      echo "Installing homebrew and GNU coreutils"
      /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" && \
        brew install coreutils
    fi
  }

  install_homebrew_if_on_mac && source "$HOME/.bash_install"
}


configure_client_or_company_specific_settings() {
  # Load any company specific bash submodules first.
  for file in $(find $HOME -type l -name ".bash_company_*" -maxdepth 1)
  do
    log_init "Loading company submodule ${BYellow}${file}${NC}"
    source $file
  done
}

configure_secret_settings() {
  for file in $(find $HOME -type f -name ".bash_secret_*" -maxdepth 1 | grep -v ".bash_secret_exports")
  do
    log_init "Loading company submodule ${BYellow}${file}${NC}"
    source $file
  done
}

configure_bash_session() {
  source_file() {
    log_init "Loading ${BYellow}$1${NC}"
    source $1
    printf ""
  }
  # Aliases and exports need to come first to prevent it breaking configuration
  # happening in other files.
  for file in aliases exports
  do
    source_file "$HOME/.bash_$file"
  done
  excludes_re='bash_(aliases|exports|profile|install|custom_profile|company|history|sessions)'
  for file in $(find $HOME -type l -maxdepth 1 -name "*.bash_*" | \
    egrep -v "$excludes_re" | \
    sort -u)
  do
    source_file "$file"
  done
}

add_keys_to_ssh_agent() {
  SSH_AGENT_ENV_FILE="$HOME/.ssh/agent_env"
  apply_ssh_askpass_hack() {
    export OLD_DISPLAY=$DISPLAY
    unset DISPLAY
  }

  unapply_ssh_askpass_hack() {
    export DISPLAY=$OLD_DISPLAY
    unset OLD_DISPLAY
  }

  is_ssh_agent_running() {
    pgrep -q ssh-agent
  }

  delete_stale_ssh_agent_env() {
    test -f "$SSH_AGENT_ENV_FILE" && rm -f "$SSH_AGENT_ENV_FILE" || true
  }

  start_ssh_agent() {
    ssh-agent -s > "$SSH_AGENT_ENV_FILE"
    chmod 600 "$SSH_AGENT_ENV_FILE"
  }

  add_ssh_agent_to_environment() {
    unset SSH_AGENT_PID
    unset SSH_AUTH_SOCK
    &>/dev/null eval $(cat $SSH_AGENT_ENV_FILE) 
  }

  add_keys() {
    grep -ElR "BEGIN (RSA|OPENSSH)" $HOME/.ssh | sort -u | xargs ssh-add
  }

  if ! is_ssh_agent_running
  then
    delete_stale_ssh_agent_env &&
      apply_ssh_askpass_hack &&
      start_ssh_agent &&
      add_ssh_agent_to_environment &&
      add_keys &&
      unapply_ssh_askpass_hack
  else
    add_ssh_agent_to_environment
  fi
}

restart_ssh_agent() {
  killall ssh-agent && add_keys_to_ssh_agent
}

restart_gpg_agent() {
  gpg-connect-agent reloadagent /bye
}

start_gpg_agent() {
  pgrep -q gpg-agent || gpg-connect-agent /bye
}


review_wifi_networks() {
  while read -u 3 network
    do
      printf "Are you sure you want to remove '$network'? [yes|NO]: "
      read -s choice
      if [ "$(echo $choice | tr '[:upper:]' '[:lower:]')" == "yes" ]
      then
        &>/dev/null sudo networksetup -removepreferredwirelessnetwork en0 "$network" && \
          printf "...removed!\n"
      else
        printf "...okay.\n"
      fi
    done 3< <(networksetup -listpreferredwirelessnetworks en0 | \
        tr -d '\t' | \
        grep -v "Preferred networks on en0:")
}

calculate_speed_from_curl() {
  speed_iec="$1"
  if ! &>/dev/null which numfmt
  then
    log_warn "numfmt not installed; returning input"
    return "$speed_iec"
  fi
  result_bytes="$(echo "$speed_iec" | tr '[:lower:]' '[:upper:]' | numfmt --from=iec)"
  test "$result_bytes" -gt "$ONE_GIGABYTE" && { echo "$(((result_bytes/ONE_GIGABYTE)*8)) Gbps"; return; }
  test "$result_bytes" -gt "$ONE_MEGABYTE" && { echo "$(((result_bytes/ONE_MEGABYTE)*8)) Mbps"; return; }
  test "$result_bytes" -gt "$ONE_KILOBYTE" && { echo "$(((result_bytes/ONE_KILOBYTE)*8)) Kbps"; return; }
  echo "$((result_bytes*8)) bps"
}

run_speed_test_cloudflare() {
  # Runs a quick speed test using Cloudflare's Speed.
  # Exponentially ramps to produce the most accurate result.
  SPEED_TEST_URI="https://speed.cloudflare.com/__down?measId=12345"
  payload_size_bytes=1000
  cutoff_seconds=3
  iterations=0
  log_info "Running download speed test via Cloudflare"
  while true
  do
    printf '.'
    uri="${SPEED_TEST_URI}&bytes=${payload_size_bytes}"
    start_time=$(date +%s)
    result=$(2>&1 curl -L -o /dev/null "$uri" | tail -1 | awk '{print $NF}')
    end_time=$(date +%s)
    if test "$((end_time-start_time))" -gt "$cutoff_seconds"
    then
      result_str=$(calculate_speed_from_curl "$result")
      printf "\n${BGreen}INFO${NC}: Download speed: ~%s (final payload: %s)\n" \
        "$result_str" \
        "$((payload_size_bytes/ONE_MEGABYTE)) MB"
      return
    fi
    payload_size_bytes="$((payload_size_bytes*2))"
  done
}

run_speed_test() {
  if ! check_for_internet_access
  then
    log_error "No internet access. Speed test unavailable."
    return 1
  fi
  run_speed_test_cloudflare
}

kill_all_matching_pids() {
  pgrep $@ | while read pid; do sudo kill -9 $pid; done
}

generate_random_string() {
  length=$1
  lower=$2
  [[ "$length" == "" ]] && length=16
  if [[ "$(uname)" == "Darwin" ]]; then
    if grep -Eiq '^true$' <<< "$lower"
    then
      LC_CTYPE=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c $length | tr '[:upper:]' '[:lower:]'
    else
      LC_CTYPE=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c $length
    fi
  else
    if grep -Eiq '^true$' <<< "$lower"
    then
      tr -dc 'a-zA-Z0-9' < /dev/urandom | tr '[:upper:]' '[:lower:]' | head -c $length
    else
      tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c $length
    fi
  fi
}

generate_lcase_random_string() {
  generate_random_string "$1" "true"
}

generate_password() {
  if [[ $# -ne 2 ]]; then
    echo "generate_password [email_address] [domain_for_account]"
    return
  fi
  email_address=$1
  domain=$2
  password=`echo "$email_address $domain" | md5 | shasum | cut -f1 -d '-' | head -c 12`
  echo $password | pbcopy
  echo "Password: $password. It has been copied into your clipboard."
}

get_git_branch() {
  ! test -d ".git" && return 0

  if ! branch=$(git branch 2>/dev/null | egrep "^\*" | sed 's/* //' | tr -d '\n')
  then
    echo no_branch_yet
  else
    printf "$branch"
  fi
}

get_upstream() {
  ! test -d '.git' && return 0

  2>/dev/null git rev-parse --abbrev-ref $(get_git_branch)@{upstream} | tr -d '\n'
}

summarize_commits_ahead_and_behind_of_upstream() {
  status=$(2>/dev/null git rev-list --left-right --count $(get_upstream)..$(get_git_branch) | \
    tr '\t' ',')
  behind_upstream=$(echo "$status" | cut -f1 -d ',')
  ahead_of_upstream=$(echo "$status" | cut -f2 -d ',')
  if [ "$behind_upstream" != '0' ]
  then
    printf "\[${BRed}\][!!]\[${NC}\]"
  fi

  if [ "$ahead_of_upstream" != '0' ]
  then
    printf "\[${BGreen}\][!!]\[${NC}\]"
  fi
}



install_homebrew_if_missing() {
  if [ "$(get_os_type)" -ne "Darwin" ]
  then
    # Check not required for non-Darwin operating systems.
    return 0
  fi

  if [ "$(which brew)" -eq "" ]
  then
    log_info "Installing homebrew"
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi
}

install_application() {
  if [ $# -eq 0 ]
  then
    printf "${BRed}ERROR${NC}: install_application requires some arguments.\n"
    return 1
  fi
  package_manager_command_to_run=""
  os_type=$(get_os_type)
  echo "OS Type: $os_type"
  case $os_type in
    "Darwin")
      package_manager_command_to_run="brew install"
      ;;
    "Ubuntu"|"Debian")
      package_manager_command_to_run="sudo apt-get -y install"
      ;;
    "Red Hat"|"Fedora")
      package_manager_command_to_run="sudo yum -y install"
      ;;
    "SuSE")
      package_manager_command_to_run="sudo zypper install"
      ;;
    *)
      log_error "OS [$os_type] is unsupported"
      return 1
      ;;
  esac
  log_info "Running ${BGreen}${package_manager_command_to_run} $@${NC}"
  eval "$package_manager_command_to_run $@"
}

get_next_thing_to_do() {
  todo_dir="${1?Please provide a todo.sh-compatible directory.}"
  color_code="${2:-false}"
  ! test -d "$todo_dir" && return 0

  next_up_to_do="$(head -1 "${todo_dir}/todo.txt" 2>/dev/null)"
  if [ ! -z "$next_up_to_do" ]
  then
    number_of_next_ups=$(wc -l ${todo_dir}/todo.txt | awk '{print $1}' )
    case "$color_code" in
      sensitive)
        printf "\[$BRed\][$next_up_to_do (1/$number_of_next_ups)]\[$NC\]\n "
        ;;
      project)
        printf "\[$BBlue\][$next_up_to_do (1/$number_of_next_ups)]\[$NC\]\n "
        ;;
      *)
        printf "\[$BYellow\][$next_up_to_do (1/$number_of_next_ups)]\[$NC\]\n "
        ;;
    esac
  fi
}

get_cwd() {
  max_dir_length=20
  directory=$(printf "$PWD")
  length=$(printf "$directory" | wc -c)
  if test "$length" -gt "$max_dir_length"
  then
    printf "${PWD%/*}" | sed -e "s;\(/.\)[^/]*;\1;g" | tr -d '\n'; printf "/${PWD##*/}"
  else
    printf "$directory"
  fi
}

update_dotfiles() {
  pushd $HOME/src/setup
  if test -z "$(git status --porcelain)"
  then
    log_warning "Changed files have been detected. Stashing them."
    git stash
  fi
  git pull --rebase
  popd
}

dirstack_count() {
  raw_count="${#DIRSTACK[@]}" # this will always be 1 if dirstack is empty.
  echo $((raw_count-1))
}

# =================
# SET PROMPT
# =================
set_bash_prompt() {
  if ! test -f "$HIDDEN_BASH_PROMPT_FILE"
  then
    set_full_bash_prompt "$1"
  else
    set_hidden_bash_prompt "$1"
  fi
}

set_full_bash_prompt() {
  if test "$1" -ne 0 && test "$1" -ne 130
  then
    error_code_str="\[$On_Red\]\[$BWhite\]<<$1>>\[$NC\]"
  else
    error_code_str=""
  fi
  account_type_indicator="\$"
  if [ "$(id -u)" -eq 0 ]
  then
    account_type_indicator="\#"
  fi
  git_branch="$(get_git_branch)"
  next_up_to_dos="$(get_next_thing_to_do "$TODO_DIR" "personal")\
$(get_next_thing_to_do "$CLIENT_TODO_DIR/$CLIENT_NAME" "sensitive")\
$(get_next_thing_to_do "$PWD/.todos" "project")"
  if [ ! -z "$next_up_to_dos" ]
  then
    next_up_to_dos="$(printf "${next_up_to_dos}" | \
      sed "s/^ //g")\n"
  fi
  if [ $EUID -eq 0 ]; then
    fmtd_username="\[$ALERT\]$USER\[$NC\]"
  else
    fmtd_username="\[$BGreen\]$USER\[$NC\]"
  fi

  if ! test -z "$VIRTUAL_ENV"
  then
    python_version="$(grep -E "^version" "${VIRTUAL_ENV}/pyvenv.cfg" |
      awk -F'=' '{print $2}' |
      tr -d ' ')"
    virtualenv="\[$BGreen\][python-${python_version}]\[$NC\]"
  else
    virtualenv=""
  fi
  ruby_version=""
  if ! test -z "$MY_RUBY_HOME"
  then
    ruby_version="\[$BRed\][$(basename "$MY_RUBY_HOME")]\[$NC\]"
  fi
  local_go_version=""
  if ! test -z "$LOCAL_GVM_VERSION"
  then
    local_go_version="\[$BGreen\][gvm $LOCAL_GVM_VERSION]\[$NC\]"
  elif ! test -z "$GOROOT"
  then
    local_go_version="\[$BGreen\][$(basename "$GOROOT")]\[$NC\]"
  fi

  print_dirstack_count() {
    count=$(dirstack_count)
    if test "$count" -ge 1
    then
      dirs_deep="dir(s) deep"
      if test "$count" -eq 1
      then
        dirs_deep="dir deep"
      fi
      printf "\[%s\] [%d %s] \[%s\]" "$BCyan" "$count" "$dirs_deep" "$NC"
    fi
  }

  hostname_name=$(echo "$HOSTNAME" | sed 's/.local$//')
  hostname_fmtd="\[$BBlue\]$hostname_name\[$NC\]"
  if ! $(test -d '.git' && 2>/dev/null git rev-parse --is-inside-work-tree 2>/dev/null)
  then
    PS1="${next_up_to_dos}$error_code_str\[$BCyan\][$(date "+%Y-%m-%d %H:%M:%S")\[$NC\] $fmtd_username@$hostname_fmtd \[$BCyan\]$(get_cwd)]\[$NC\]${virtualenv}${ruby_version}${local_go_version}$(print_dirstack_count)\n$(get_csp_login_status)\n\[$Yellow\]$account_type_indicator\[$NC\]: "
  elif [ "$(2>/dev/null git --no-pager branch --list)" == "" ]
  then
    PS1="${next_up_to_dos}$error_code_str\[$BCyan\][$(date "+%Y-%m-%d %H:%M:%S")\[$NC\] $fmtd_username@$hostname_fmtd \[$BCyan\]$(get_cwd)]\[$NC\] \[$Red\](NO BRANCH?)\[$NC\] ${virtualenv}${ruby_version}${local_go_version}$(print_dirstack_count) \n$(get_csp_login_status)\n\[$Yellow\]$account_type_indicator\[$NC\]: "
  elif ! $(2>/dev/null git diff-index --quiet HEAD)
  then
    PS1="${next_up_to_dos}$error_code_str\[$BCyan\][$(date "+%Y-%m-%d %H:%M:%S")\[$NC\] $fmtd_username@$hostname_fmtd \[$BCyan\]$(get_cwd)]\[$NC\] \[$Red\]($git_branch)\[$NC\] ${virtualenv}${ruby_version}${local_go_version}$(print_dirstack_count) $(summarize_commits_ahead_and_behind_of_upstream)\n$(get_csp_login_status)\n\[$Yellow\]$account_type_indicator\[$NC\]: "
  else
    PS1="${next_up_to_dos}$error_code_str\[$BCyan\][$(date "+%Y-%m-%d %H:%M:%S")\[$NC\] $fmtd_username@$hostname_fmtd \[$BCyan\]$(get_cwd)]\[$NC\] \[$Green\]($git_branch)\[$NC\] ${virtualenv}${ruby_version}${local_go_version}$(print_dirstack_count) $(summarize_commits_ahead_and_behind_of_upstream)\n$(get_csp_login_status)\n\[$Yellow\]$account_type_indicator\[$NC\]: "
  fi
}

set_hidden_bash_prompt() {
  if test "$1" -ne 0 && test "$1" -ne 130
  then
    error_code_str="\[$On_Red\]\[$BWhite\]<<$1>>\[$NC\]"
  else
    error_code_str=""
  fi

  account_type_indicator="\$"
  if [ "$(id -u)" -eq 0 ]
  then
    account_type_indicator="\#"
  fi
  PS1="$error_code_str\[$BCyan\]$(get_cwd)\[$NC\]\[$BYellow\] $account_type_indicator\[$NC\]: "
}

toggle_bash_prompt() {
  if test -f "$HIDDEN_BASH_PROMPT_FILE"
  then
    rm -f "$HIDDEN_BASH_PROMPT_FILE"
  else
    touch "$HIDDEN_BASH_PROMPT_FILE"
  fi
}

preview_markdown() {
  log_info "Visit http://localhost:6419 to view your stuff."
  docker run -it --rm -v $PWD:/data -p 6419:3080 thomsch98/markserv
}

disable_sleep() {
  if ! test -d "/Applications/Fermata.app"
  then
    log_error "Fermata is not installed. Please install it."
    return 1
  fi
  if ! pgrep -i fermata
  then
    log_info "Fermata isn't running. Starting it now."
    open /Applications/Fermata.app
  fi
  brightness 0
  open -a "${HOME}/src/setup/PreventSleep.app"
}

enable_sleep() {
  if ! test -d "/Applications/Fermata.app"
  then
    log_error "Fermata is not installed. Please install it."
    return 1
  fi
  brightness 0.5
  pkill -9 "PreventSleep" && sudo pkill -9 "Fermata"
}

reload_tmux(){ 
  tmux source-file "$HOME/.tmux.conf"
}

update_dotfiles() {
  if ! {
    pushd "$HOME/src/setup" &&
      current_version=$(git log --format="%h") &&
      git pull --rebase --autostash &&
      new_version=$(git log --format="%h") &&
      if test "$current_version" != "$new_version"
      then
        log_info "$current_version -> $new_version"
      fi &&
      popd;
  }
  then
    if test "$(dirstack_count)" -ge "1"
    then
      popd
    fi
  fi
}

enter_dotfiles_directory() {
  pushd "$HOME/src/setup"
}

exit_dotfiles_directory() {
  popd
}

csvtojson() {
  _do_it() {
    python -c 'import csv, json, sys; print(json.dumps([dict(r) for r in csv.DictReader(sys.stdin)]))'
  }
  # Courtesy of https://stackoverflow.com/a/65100738
  if ! test -z "$1"
  then
    if test -e "$1"
    then
      _do_it < "$1"
    else
      echo -e "$1" | _do_it
    fi
  else
    _do_it < /dev/stdin
  fi
}

flush_dns_cache() {
  sudo killall -HUP mDNSResponder
  sudo killall mDNSResponderHelper
  sudo dscacheutil -flushcache
}

toggle() {
  TOGGLE_FILE=/tmp/toggle_switch
  if test -z "$(jobs)"
  then
    log_error "No jobs have been backgrounded."
  else
    switch_position="$(cat $TOGGLE_FILE)"
    if test "$switch_position" == "up"
    then
      printf "down" > $TOGGLE_FILE
      fg "$(jobs | sed -E 's/^\[([0-9]+)\].*$/\1/' | sort -n | head -1)"
    else
      printf "up" > $TOGGLE_FILE
      fg "$(jobs | sed -E 's/^\[([0-9]+)\].*$/\1/' | sort -n | head -2 | tail -1)"
    fi
  fi
}

terraform() {
  _gather_extra_vars() {
    _gather() {
      start_pattern="$1"
      tf_extra_vars=""
      while read -r terraform_var
      do
        key=$(echo "$terraform_var" | cut -f1 -d '=')
        value=$(sed "s/$key=//" <<< "$terraform_var")
        tf_extra_vars="${tf_extra_vars} -e ${key}=${value}"
      done < <(env | grep -E "^$start_pattern")
      echo "$tf_extra_vars" | sed 's/[ ]{2,}/ /g'
    }
    _gather_tf_vars() {
      _gather "TF"
    }
    _gather_aws_vars() {
      _gather "AWS"
    }
  all=$(_gather_tf_vars && _gather_aws_vars)
  echo "$all" | tr -d '\n'
  }
  TERRAFORM_IMAGE="${TERRAFORM_IMAGE:-carlosnunez/terraform:latest}"
  tf_extra_vars="$(_gather_extra_vars)"
  docker run --rm -i -v $PWD:/app --privileged \
    -e TF_IN_AUTOMATION=true \
    --net=host \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -w /app \
    ${tf_extra_vars} \
    "$TERRAFORM_IMAGE" "$@"
}
