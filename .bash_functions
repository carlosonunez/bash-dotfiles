#!/usr/bin/env bash
ASDF_PLUGINS=$(cat <<-PLUGINS
direnv
PLUGINS
)
LANG_STACKS=$(cat <<-APPS
golang
python
ruby
APPS
)
PREREQS=$(cat <<-APPS
asdf
1password
1password-cli
bash
bash-completion@2
curl
findutils
gnu-getopt
gnu-indent
gnu-sed
gnu-tar
gnupg
gnutls
grep
jq
make
openssl@3
todo-txt
tree
yq
APPS
)
HIDDEN_BASH_PROMPT_FILE="/tmp/use_hidden_bash_prompt"
ONE_GIGABYTE="$(numfmt --from=iec '1G')"
ONE_MEGABYTE="$(numfmt --from=iec '1M')"
ONE_KILOBYTE="$(numfmt --from=iec '1K')"

_add_gpg_conf_if_missing() {
  test -f "$HOME/.gnupg/gpg-agent.conf" && return 0

  cat >"$HOME/.gnupg/gpg-agent.conf" <<-EOF
default-cache-ttl 46000
pinentry-program $(which pinentry)
allow-preset-passphrase
EOF
}

# NOTE: It's assumed that the `User` and `Hostname` for "work-machine" is defined in your SSH
# config somewhere
wm() {
  if test -n "$USE_MOSH"
  then mosh --server="$(which mosh-server)" work-machine
  else ssh work-machine
  fi
}

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

log_warning_sudo() {
  >&2 echo -ne "${BYellow}WARNING${NC}: $1 (Enter password when prompted)\n"
}

log_warn() {
  log_warning "$@"
}

log_warn_sudo() {
  log_warning_sudo "$@"
}

log_error() {
  >&2 echo -ne "${BRed}ERROR${NC}: $1\n"
}

log_error_sudo() {
  >&2 echo -ne "${BRed}ERROR${NC}: $1 (Enter password when prompted)\n"
}


pushd () {
  command pushd "$@" > /dev/null
}

popd () {
  command popd "$@" > /dev/null
}

get_csp_login_status() {
  aws_ps1_hook_enabled && printf "${BYellow}[AWS${NC}: ${Yellow}%s${NC}${BYellow}]${NC}\n" "$(aws_ps1_hook)"
  azure_ps1_hook_enabled && printf "${BCyan}[Azure${NC}: ${Cyan}%s${NC}${BCyan}]${NC}\n" "$(azure_ps1_hook)"
  gcp_ps1_hook_enabled && printf "${BPurple}[GCP${NC}: ${Purple}%s${NC}${BPurple}]${NC}\n" "$(gcp_ps1_hook)"
}

install_prerequisites() {
  comm -2 <(tr ',' '\n' <<< "$PREREQS" | sort) <(brew list -1 | sort) |
    grep -Ev '^\t' |
    xargs brew install
}

configure_machine_pre() {
  install_prerequisites &&
    for plugin in $ASDF_PLUGINS $LANG_STACKS
    do
      asdf plugin list | grep -q "$plugin" || {
        log_info "Installing asdf plugin: ${BCyan}$plugin${NC}"
        asdf plugin add "$plugin";
      }
    done &&
    for stack in $LANG_STACKS
    do
      log_info "Configuring language stack: ${BCyan}$stack${NC}"
      stack_config="$HOME/.bash_${stack}_specific"
      test -f "$stack_config" && source "$stack_config"
    done &&
      
    return 0
  return 1
}

configure_machine() {
  source "$HOME/.bash_install"
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
  excludes_re='bash_(aliases|exports|functions|python|go|ruby|profile|install|custom_profile|company|history|sessions)'
  for file in $(find $HOME -type l -maxdepth 1 -name "*.bash_*" | \
    egrep -v "$excludes_re" | \
    sort -u)
  do
    source_file "$file"
  done
}

onepassword_ssh_agent_configuration_exists() {
  test -f "$HOME/.config/1Password/ssh/agent.toml"
}

add_keys_to_ssh_agent() {
  if onepassword_ssh_agent_configuration_exists
  then
    >&2 echo "INFO: SSH keys are managed by 1Password. Go ahead and add them there."
    return 0
  fi

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
    local whitelisted_keys all_keys keys_to_load
    whitelisted_keys=$(pushd "$HOME/.ssh"; xargs grealpath -s < $PWD/whitelisted-keys | sort -u; popd)
    all_keys=$(grep -ElR "BEGIN (RSA|OPENSSH)" $HOME/.ssh | sort -u)
    keys_to_load="$all_keys"
    if test -n "$whitelisted_keys"
    then
      log_info "Whitelisted SSH keys found. Only loading these keys: $(tr '\n' ',' <<< "$whitelisted_keys" |
        sed 's/,$//' |
        sed 's/,/, /g')"
      keys_to_load=$(comm -2 <(echo "$whitelisted_keys") <(echo "$all_keys"))
    fi
    xargs ssh-add < <(echo "$keys_to_load")
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
  if onepassword_ssh_agent_configuration_exists
  then
    >&2 echo "INFO: This SSH agent is managed by 1Password. Restart 1Password if you're having issues."
    return 0
  fi
  killall ssh-agent && add_keys_to_ssh_agent
}

restart_gpg_agent() {
  _add_gpg_conf_if_missing
  gpg-connect-agent reloadagent /bye
}

start_gpg_agent() {
  _add_gpg_conf_if_missing
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
  alphanumeric_only=$3
  filter='a-zA-Z0-9'
  special_chars=' !"#$%&()*+,-./:;<=>?@[]^_`{|}~'"'"
  [[ -z "$length" ]] && length=16
  grep -Eiq '^true$' <<< "$alphanumeric_only" || filter="${filter}${special_chars}"
  [[ "$(get_os_type)" == "Darwin" ]] && export LC_CTYPE=C
  res="$(tr -dc "$filter" < /dev/urandom | head -c "$length")"
  grep -Eiq '^true$' <<< "$lower" && res="${res,,}"
  echo "$res"
}

generate_lcase_random_string() {
  generate_random_string "$1" "true"
}

generate_random_alphanumeric_string() {
  generate_random_string "$1" "$2" 'true'
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
  if ! branch=$(git branch 2>/dev/null | egrep "^\*" | sed 's/* //' | tr -d '\n')
  then
    echo no_branch_yet
  else
    maybe_submodule=$(git rev-parse --show-superproject-working-tree)
    if test -z "$maybe_submodule"
    then printf "%s" "$branch"
    fi
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
  ! test -f "${todo_dir}/todo.txt" && return 0

  next_up_to_do="$(head -1 "${todo_dir}/todo.txt" 2>/dev/null)"
  if [ ! -z "$next_up_to_do" ]
  then
    number_of_next_ups=$(wc -l ${todo_dir}/todo.txt | awk '{print $1}' )
    case "$color_code" in
      sensitive)
        printf "\[$BRed\][%s (1/$number_of_next_ups)]\[$NC\]\n " "$next_up_to_do"
        ;;
      project)
        printf "\[$BBlue\][%s (1/$number_of_next_ups)]\[$NC\]\n " "$next_up_to_do"
        ;;
      *)
        printf "\[$BYellow\][%s (1/$number_of_next_ups)]\[$NC\]\n " "$next_up_to_do"
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
  if ! test -z "$ASDF_RUBY_VERSION"
  then
    ruby_version="\[$BRed\][ruby-$ASDF_RUBY_VERSION]\[$NC\]"
  fi
  # using grep to evaluate go version managed by asdf is faster
  local_go_version="$(grep -oh -E '([0-9]{1,}\.[0-9]{1,}\.[0-9]{1,})' < <(which go))"
  if test -z "$local_go_version"
  then local_go_version="$(cut -f3 -d ' ' < <(2>/dev/null go version) | sed 's/go//')"
  fi
  local_go_version="\[$BGreen\][go-$local_go_version]\[$NC\]"
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
  if ! test -d "$PWD/.git" || ! $(2>/dev/null git rev-parse --is-inside-work-tree)
  then
    PS1="${next_up_to_dos}$error_code_str\[$BCyan\][$(date "+%Y-%m-%d %H:%M:%S")\[$NC\] $fmtd_username@$hostname_fmtd \[$BCyan\]$(get_cwd)]\[$NC\]${virtualenv}${ruby_version}${local_go_version}$(print_dirstack_count)\n$(get_csp_login_status)\n\[$Yellow\]$account_type_indicator\[$NC\]: "
  elif [ "$(2>/dev/null git --no-pager branch --list)" == "" ]
  then
    git_branch="NO BRANCH?"
    PS1="${next_up_to_dos}$error_code_str\[$BCyan\][$(date "+%Y-%m-%d %H:%M:%S")\[$NC\] $fmtd_username@$hostname_fmtd \[$BCyan\]$(get_cwd)]\[$NC\] \[$Red\]($git_branch)\[$NC\] ${virtualenv}${ruby_version}${local_go_version}$(print_dirstack_count) \n$(get_csp_login_status)\n\[$Yellow\]$account_type_indicator\[$NC\]: "
  elif ! $(2>/dev/null git diff-index --quiet HEAD)
  then
    git_branch="$(get_git_branch)"
    PS1="${next_up_to_dos}$error_code_str\[$BCyan\][$(date "+%Y-%m-%d %H:%M:%S")\[$NC\] $fmtd_username@$hostname_fmtd \[$BCyan\]$(get_cwd)]\[$NC\] \[$Red\]($git_branch)\[$NC\] ${virtualenv}${ruby_version}${local_go_version}$(print_dirstack_count) $(summarize_commits_ahead_and_behind_of_upstream)\n$(get_csp_login_status)\n\[$Yellow\]$account_type_indicator\[$NC\]: "
  else
    git_branch="$(get_git_branch)"
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
  file="${1:-$PWD}"
  file_abs="$(realpath "$file" | sed 's;/private;;')"
  if ! test -e "$file_abs"
  then
    log_error "File does not exist: $file_abs"
    return 1
  fi
  mountpoint=/work
  test -f "$file_abs" && mountpoint=/work/file.md
  docker run -it --net=host --rm -v "${file_abs}:$mountpoint" carlosnunez/md-fileserver:alpine \
    "$mountpoint"
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

_nsvtojson() {
  _do_it() {
    local dialect dialect_reg_cmd
    dialect_reg_cmd="# none"
    case "${FORMAT,,}" in
      csv)
        dialect="unix"
        ;;
      psv)
        dialect="custom"
        dialect_reg_cmd="csv.register_dialect('custom', delimiter='|', quoting=csv.QUOTE_NONE)"
        ;;
      tsv)
        dialect="custom"
        dialect_reg_cmd="csv.register_dialect('custom', delimiter='"'\t'"', quoting=csv.QUOTE_NONE)"
        ;;
      *)
        dialect="unix"
        ;;
    esac
    script=$(printf 'import csv, json, sys; %s; print(json.dumps([dict(r) for r in csv.DictReader(sys.stdin, dialect="%s")]))' \
             "$dialect_reg_cmd" \
             "$dialect" | sed -E 's/# none;//')
    python -c "$script" < /dev/stdin
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

csvtojson() {
  _nsvtojson "$*"
}

psvtojson() {
  FORMAT=psv _nsvtojson "$*"
}

tsvtojson() {
  FORMAT=tsv _nsvtojson "$*"
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
  docker run --rm -it -v $PWD:/app --privileged \
    -e TF_IN_AUTOMATION=true \
    -e HTTP_PROXY \
    -e HTTPS_PROXY \
    -e http_proxy \
    -e https_proxy \
    -e no_proxy \
    --net=host \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -w /app \
    ${tf_extra_vars} \
    "$TERRAFORM_IMAGE" "$@"
}

_update() {
  zip_file="$1"
  vault="$2"
  path="$3"
  title="$4"
  test -f "$zip_file" && rm "$zip_file"
  op_cli document get "$title" --vault "$vault" --output "$zip_file" &&
  zip -fjr "$zip_file" $path &&
  op_cli document edit "$title" --vault "$vault" "$zip_file"
}

update_secret_settings() {
  _update \
    "$HOME/Downloads/environment.zip" \
    "$OP_DEFAULT_VAULT" \
    "$HOME/.bash_secret_*" \
    "Secret Environment Settings"
}

update_ssh_and_aws_keys() {
  export_gpg_keys &&
    _update \
      "$HOME/Downloads/keys.zip" \
      "$OP_DEFAULT_VAULT" \
      "$HOME/.ssh/*" \
      "SSH and AWS Keys"
}

export_gpg_keys() {
  gpg --export --armor > "$HOME/.ssh/public_keys"
  gpg --export-secret-keys --armor >  "$HOME/.ssh/private_keys"
  gpg --export-ownertrust > "$HOME/.ssh/ownertrust"
}

if onepassword_ssh_agent_configuration_exists
then
  killall ssh-agent;
  case "$(get_os_type)" in
    Darwin)
      export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
      ;;
    Linux)
      export SSH_AUTH_SOCK=~/.1Password/agent.sock
      ;;
    *)
      >&2 echo "Automatic 1Password configuration isn't available for this OS yet."
      ;;
  esac
fi
