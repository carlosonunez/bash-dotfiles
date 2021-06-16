#!/usr/bin/env bash
jumpbox() {
  get_jumpbox_details_from_op() {
    details=$(sudo security find-generic-password -a "$USER" -s "jumpbox" -w 2>/dev/null)
    if test -z "$details"
    then
      if ! remote_details=$(op --vault "$ONEPASSWORD_VAULT" get item "Carlos's Jumpbox Details" | \
        jq -r '.details.notesPlain' | tr '\n' ';' )
      then
        >&2 printf "${BRed}ERROR${NC}: Can't get jumpbox details.\n"
        return 1
      fi
      set -x
      sudo security add-generic-password -a "$USER" -s "jumpbox" -w "$remote_details" -U
      echo "$remote_details"
      return
    fi
    echo "$details"
  }
  if ! details=$(get_jumpbox_details_from_op | tr ';' '\n')
  then
    >&2 printf "${BRed}ERROR${NC}: Can't get jumpbox details.\n"
    return 1
  fi
  host=$(echo "$details" | head -1)
  port=$(echo "$details" | tail -2 | tail -1)
  username=$(echo "$details" | tail -2 | head -1)
  if test -z "$host" || test -z "$port" || test -z "$username"
  then
    >&2 printf "${BRed}ERROR${NC}: Host or port is empty.\n"
    return 1
  fi
  cmd="ssh -A"
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

get_azure_login_status() {
  azure_profiles="$HOME/.azure/azureProfile.json"
  if test -f "$azure_profiles"
  then
    logged_in_user_guids=$(jq -r '.subscriptions[].user.name' $azure_profiles | \
      sort -u | \
      tr '\n' ',' | \
      sed 's/,$//'
    )
    if ! test -z "$logged_in_user_guids"
    then
      printf "${BRed}[Active Azure logins: $logged_in_user_guids]${NC}"
    fi
  fi
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
    printf "${BYellow}INFO${NC}: Loading company submodule ${BYellow}${file}${NC}\n"
    source $file
  done
}

configure_secret_settings() {
  for file in $(find $HOME -type f -name ".bash_secret_*" -maxdepth 1 | grep -v ".bash_secret_exports")
  do
    printf "${BYellow}INFO${NC}: Loading company submodule ${BYellow}${file}${NC}\n"
    source $file
  done
}

configure_bash_session() {
  source_file() {
    printf "${BYellow}INFO${NC}: Loading ${BYellow}$1${NC}\n"
    source $1
    printf "\n"
  }
  excludes_re='bash_(aliases|exports|profile|install|custom_profile|company|history|sessions)'
  for file in $(find $HOME -type l -maxdepth 1 -name "*.bash_*" | \
    egrep -v "$excludes_re" | \
    sort -u)
  do
    source_file "$file"
  done
  # Aliases and exports need to come last to prevent it breaking configuration
  # happening in other files.
  for file in aliases exports
  do
    source_file "$HOME/.bash_$file"
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
    eval $(cat $SSH_AGENT_ENV_FILE)
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


install_bash_completion() {
  if [ "$(get_os_type)" == "Darwin" ]
  then
    [ -f $(brew --prefix)/etc/bash_completion ] && . $(brew --prefix)/etc/bash_completion
  else
    [ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion
  fi
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

run_speed_test() {
  test_file_size="${1:-100MB}"
  valid_test_file_sizes="^(100mb|1gb|10gb)$"
  if ! grep -q --extended-regexp --ignore-case "$valid_test_file_sizes" < <(echo "$test_file_size")
  then
    >&2 echo "ERROR: Please provide a file size that matches '$valid_test_file_sizes'."
    return 1
  fi
  >&2 echo "Test started using $test_file_size of data; type CTRL-C to stop."
  curl -o /dev/null "https://speed.hetzner.de/${test_file_size}.bin"
}

kill_all_matching_pids() {
  pgrep $@ | while read pid; do sudo kill -9 $pid; done
}

generate_random_string() {
  length=$1
  [[ "$length" == "" ]] && length=16
  if [[ "$(uname)" == "Darwin" ]]; then
    LC_CTYPE=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c $length
  else
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c $length
  fi
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

  ec2() {
    if [[ $# -eq 0 ]]; then
      printf "${BRed}Error: Commands required.${NC}\n"
      return
    fi

    export JAVA_HOME=$(/usr/libexec/java_home 2>/dev/null)
    [[ -z $JAVA_HOME ]] && {
      printf "${BRed}Error: Java JDK is not installed. Click 'More info' to install.\n${NC}"
    /usr/libexec/java_home --request
    return 1
  }

  aws_command_with_args=`echo $@ | sed 's/^ec2\-\(.*\)$/\1/'`
  aws_access_key_lpass_predicate="Username"
  aws_secret_key_lpass_predicate="Password"
  aws_credentials_lpass_note_name="AWS: Access Key"
  aws_cli_bin_path='/usr/local/ec2'

  if [[ ! -d $aws_cli_bin_path ]]; then 
    printf "${BRed}Error: AWS CLI not found. Install it, then try again.${NC}\n"
    return 1
  fi

  aws_cli_bin_path=`find $aws_cli_bin_path -type d -maxdepth 1 | sort | tail -n 1`
  [[ -z $EC2_HOME ]] && export EC2_HOME="$aws_cli_bin_path"
  aws_cli_bin_path="$aws_cli_bin_path/bin"

  if [[ `echo $@ | egrep -q '^ls' ; echo $?` == "0" ]]; then
    maybe_search_terms=`echo $@ | sed 's/^ls \(.*\)/\1/' | tr -d ' '`
    find $aws_cli_bin_path -type f -maxdepth 1 | egrep -v "\.cmd$" | \
      grep --color "/bin/ec2-" | \
      grep --color "$maybe_search_terms"
    return
  fi


  aws_access_key=`extract_from_lpass_note "$aws_credentials_lpass_note_name" $aws_access_key_lpass_predicate`
  aws_secret_key=`extract_from_lpass_note "$aws_credentials_lpass_note_name" $aws_secret_key_lpass_predicate`
  if [[ -z $aws_access_key || -z $aws_secret_key ]]; then
    printf "${BRed}Error: LastPass couldn't find the AWS access or secret key.${NC}\n"
    return 1
  fi

  export AWS_ACCESS_KEY=`echo $aws_access_key`
  export AWS_SECRET_KEY=`echo $aws_secret_key`
  printf "Running: ${BYellow}$aws_command_with_args${NC}\n"
  eval $aws_cli_bin_path/ec2-$aws_command_with_args

  unset AWS_ACCESS_KEY
  unset AWS_SECRET_KEY
  printf "Finished running: ${BYellow}$aws_command_with_args${NC}\n" 

  return
}

ec2_help() {
  aws ls
}

get_git_branch() {
  if ! branch=$(git branch 2>/dev/null | egrep "^\*" | sed 's/* //' | tr -d '\n')
  then
    echo no_branch_yet
  else
    printf "$branch"
  fi
}

get_upstream() {
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



get_os_type() {
  case "$(uname)" in
    "Darwin")
      echo "Darwin"
      ;;
    "Linux")
      echo "$(lsb_release -is)"
      ;;
    *)
      echo "Unsupported"
      ;;
  esac
}

install_homebrew_if_missing() {
  if [ "$(get_os_type)" -ne "Darwin" ]
  then
    # Check not required for non-Darwin operating systems.
    return 0
  fi

  if [ "$(which brew)" -eq "" ]
  then
    printf "${BYellow}INFO${NC}: Installing homebrew\n"
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
      printf "${BRed}ERROR${NC}: OS [$os_type] is unsupported\n"
      return 1
      ;;
  esac
  printf "${BYellow}INFO${NC}: Running ${BGreen}${package_manager_command_to_run} $@${NC}\n"
  eval "$package_manager_command_to_run $@"
}

get_next_thing_to_do() {
  todo_dir="${1?Please provide a todo.sh-compatible directory.}"
  color_code="${2:-false}"
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
  test -z "$(git status --porcelain)" || git stash
  git pull --rebase
  test -z "$(git stash list)" || git stash pop
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
  error_code_str=""
  account_type_indicator="\$"
  if [ "$(id -u)" -eq 0 ]
  then
    account_type_indicator="\#"
  fi
  if [[ "$1" != "0" ]]
  then
    error_code_str="\[$On_Red\]\[$BWhite\]<<$1>>\[$NC\]"
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
    python_version=$(python -c 'import sys; print(".".join(map(str, sys.version_info[:3])))')
    virtualenv="\[$BGreen\][${python_version}-$VIRTUAL_ENV]\[$NC\]"
  else
    virtualenv=""
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
  if ! $(2>/dev/null git rev-parse --is-inside-work-tree 2>/dev/null)
  then
    PS1="${next_up_to_dos}$error_code_str\[$BCyan\][$(date "+%Y-%m-%d %H:%M:%S")\[$NC\] $fmtd_username@$hostname_fmtd \[$BCyan\]$(get_cwd)]\[$NC\]${virtualenv}$(print_dirstack_count)\n$(get_azure_login_status)\n\[$Yellow\]$account_type_indicator\[$NC\]: "
  elif [ "$(2>/dev/null git --no-pager branch --list)" == "" ]
  then
    PS1="${next_up_to_dos}$error_code_str\[$BCyan\][$(date "+%Y-%m-%d %H:%M:%S")\[$NC\] $fmtd_username@$hostname_fmtd \[$BCyan\]$(get_cwd)]\[$NC\] \[$Red\](NO BRANCH?)\[$NC\] ${virtualenv}$(print_dirstack_count) \n$(get_azure_login_status)\n\[$Yellow\]$account_type_indicator\[$NC\]: "
  elif ! $(2>/dev/null git diff-index --quiet HEAD)
  then
    PS1="${next_up_to_dos}$error_code_str\[$BCyan\][$(date "+%Y-%m-%d %H:%M:%S")\[$NC\] $fmtd_username@$hostname_fmtd \[$BCyan\]$(get_cwd)]\[$NC\] \[$Red\]($git_branch)\[$NC\] ${virtualenv}$(print_dirstack_count) $(summarize_commits_ahead_and_behind_of_upstream)\n$(get_azure_login_status)\n\[$Yellow\]$account_type_indicator\[$NC\]: "
  else
    PS1="${next_up_to_dos}$error_code_str\[$BCyan\][$(date "+%Y-%m-%d %H:%M:%S")\[$NC\] $fmtd_username@$hostname_fmtd \[$BCyan\]$(get_cwd)]\[$NC\] \[$Green\]($git_branch)\[$NC\] ${virtualenv}$(print_dirstack_count) $(summarize_commits_ahead_and_behind_of_upstream)\n$(get_azure_login_status)\n\[$Yellow\]$account_type_indicator\[$NC\]: "
  fi
}

preview_markdown() {
  >&2 printf "${BGreen}INFO${NC}: Visit http://localhost:6419 to view your stuff.\n"
  docker run -it --rm -v $PWD:/data -p 6419:3080 thomsch98/markserv
}

disable_sleep() {
  if ! test -d "/Applications/Fermata.app"
  then
    >&2 echo "ERROR: Fermata is not installed. Please install it."
    return 1
  fi
  if ! pgrep -i fermata
  then
    >&2 echo "INFO: Fermata isn't running. Starting it now."
    open /Applications/Fermata.app
  fi
  brightness 0
  open -a "${HOME}/src/setup/PreventSleep.app"
}

enable_sleep() {
  if ! test -d "/Applications/Fermata.app"
  then
    >&2 echo "ERROR: Fermata is not installed. Please install it."
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
        >&2 printf "${BYellow}INFO${NC}: dotfiles updated: $current_version -> $new_version"
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
