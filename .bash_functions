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

extract_from_lpass_note() {
    print_usage() {
        printf "usage: extract_from_lpass_note [note_name] [search_term]\n"
    }

    if [[ $# -ne 2 ]]; then
        printf "${BRed}Error: Two arguments required, note name and field name.\n${NC}"
        print_usage
        return
    fi
    which lpass 2>/dev/null 1>/dev/null || {
        printf "${BRed}Error: LastPass isn't installed. Run this to do so: 'brew install lastpass-cli'.${NC}\n"
        print_usage
        return 1
    }
    
    [[ -f ~/.lpass/session_privatekey ]] || {
        printf "${BRed}Error: You're not logged into LastPass.${NC}\n"
        return 1
    }
    note_name=$1
    predicate=$2
    lpass show "$note_name" | \
        egrep "$predicate\:" | \
        sed "s/^$predicate\: \(.*\)$/\1/" 

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
  git branch 2>/dev/null | egrep "^\*" | sed 's/* //'  
}


