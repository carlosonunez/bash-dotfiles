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

alias phone='scrcpy --bit-rate 2M'
alias phone_slow='scrcpy --bit-rate 1M'
alias xq='docker run --rm -i carlosnunez/xq'
alias travis=run_travis
alias authy='docker run --rm --env AUTHY_KEY carlosnunez/authy-cli-docker:latest'
alias git='git'
alias git='hub'
alias googler='googler -n 5 --url-handler ~/.googler/url_handler.sh'
alias killmatch='kill_all_matching_pids'
alias rtv='RTV_BROWSER=w3m rtv --enable-media'
alias find='find -E'
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
    alias ctodo="todo.sh -d $CLIENT_TODO_DIR/.todo.cfg"
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
