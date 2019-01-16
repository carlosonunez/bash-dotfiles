#!/usr/bin/env bash
pushd () {
  command pushd "$@" > /dev/null
}

popd () {
  command popd "$@" > /dev/null
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
  if ! git branch 2>/dev/null | egrep "^\*" | sed 's/* //'
  then
    echo no_branch_yet
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
    case "$color_code" in
      sensitive)
        printf "\[$BRed\][$next_up_to_do]\[$NC\]"
        ;;
      project)
        printf "\[$BBlue\][$next_up_to_do]\[$NC\]"
        ;;
      *)
        printf "\[$BYellow\][$next_up_to_do]\[$NC\]"
        ;;
    esac
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
$(get_next_thing_to_do "$CLIENT_TODO_DIR" "sensitive")\
$(get_next_thing_to_do "$PROJECT_SPECIFIC_TODO_DIR" "project")"
  >&2 echo "DEBUG: Next up: $next_up_to_dos"
  if [ ! -z "$next_up_to_dos" ]
  then
    next_up_to_dos="$(printf "${next_up_to_dos}"  | sed 's/\]\[/] [/')\n"
  fi
  if ! $(git rev-parse --is-inside-work-tree 2>/dev/null)
  then
    PS1="${next_up_to_dos}$error_code_str\[$BCyan\]\W]\[$NC\]\[$Yellow\]\$\[$NC\]: "
  elif ! $(git diff-index --quiet HEAD)
  then
    PS1="${next_up_to_dos}$error_code_str\[$Red\]<<$git_branch>>\[$NC\] \[$BCyan\]\W]\[$NC\]\[$Yellow\]$account_type_indicator\[$NC\]: "
  else
    PS1="${next_up_to_dos}$error_code_str\[$Green\]<<$git_branch>>\[$NC\] \[$BCyan\]\W]\[$NC\]\[$Yellow\]$account_type_indicator\[$NC\]: "
  fi
}
