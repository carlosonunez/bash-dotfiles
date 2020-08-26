#!/usr/bin/env bash
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
      printf "${BRed}[Active Azure logins: $logged_in_user_guids]\n${NC}"
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
  # Note that these MUST be hardlinks and not symlinks.
  # This assumption was made under the basis that I wouldn't want to commit
  # these changes since they will differ from client to client.
  for file in $(find $HOME -type f -name ".bash_company_*" -maxdepth 1)
  do
    printf "${BYellow}INFO${NC}: Loading company submodule ${file}\n"
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
  # Prevent `ssh-askpass not found` errors.
  old_display=$DISPLAY
  unset DISPLAY
  killall ssh-agent
  eval $(ssh-agent -s) > /dev/null
  grep -ElR "BEGIN (RSA|OPENSSH)" $HOME/.ssh | sort -u | xargs ssh-add
  export DISPLAY=$old_display
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

  hostname_name=$(echo "$HOSTNAME" | sed 's/.local$//')
  hostname_fmtd="\[$BBlue\]$hostname_name\[$NC\]"
  if ! $(2>/dev/null git rev-parse --is-inside-work-tree 2>/dev/null)
  then
    PS1="${next_up_to_dos}$error_code_str\[$BCyan\][$(date "+%Y-%m-%d %H:%M:%S")\[$NC\] $fmtd_username@$hostname_fmtd \[$BCyan\]$(get_cwd)]\[$NC\]$virtualenv\n$(get_azure_login_status)\[$Yellow\]$account_type_indicator\[$NC\]: "
  elif [ "$(2>/dev/null git --no-pager branch --list)" == "" ]
  then
    PS1="${next_up_to_dos}$error_code_str\[$BCyan\][$(date "+%Y-%m-%d %H:%M:%S")\[$NC\] $fmtd_username@$hostname_fmtd \[$BCyan\]$(get_cwd)]\[$NC\] \[$Red\](NO BRANCH?)\[$NC\] $virtualenv \n$(get_azure_login_status)\[$Yellow\]$account_type_indicator\[$NC\]: "
  elif ! $(2>/dev/null git diff-index --quiet HEAD)
  then
    PS1="${next_up_to_dos}$error_code_str\[$BCyan\][$(date "+%Y-%m-%d %H:%M:%S")\[$NC\] $fmtd_username@$hostname_fmtd \[$BCyan\]$(get_cwd)]\[$NC\] \[$Red\]($git_branch)\[$NC\] $virtualenv $(summarize_commits_ahead_and_behind_of_upstream)\n$(get_azure_login_status)\[$Yellow\]$account_type_indicator\[$NC\]: "
  else
    PS1="${next_up_to_dos}$error_code_str\[$BCyan\][$(date "+%Y-%m-%d %H:%M:%S")\[$NC\] $fmtd_username@$hostname_fmtd \[$BCyan\]$(get_cwd)]\[$NC\] \[$Green\]($git_branch)\[$NC\] $(summarize_commits_ahead_and_behind_of_upstream)\n$(get_azure_login_status)\[$Yellow\]$account_type_indicator\[$NC\]: "
  fi
}
