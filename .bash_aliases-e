alias authy='docker run --env AUTHY_KEY carlosnunez/authy-cli-docker:latest'
alias git='git'
alias git='hub'
alias googler='googler --url-handler w3m'
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
  if test -z "$CLIENT_NAME"
  then
    >&2 printf "${BYellow}WARN${NC}: \$CLIENT_NAME is not defined. \
Do so in .bash_exports to track client-specific to-dos."
  else
    alias ctodo="todo.sh -d $CLIENT_TODO_DIR/.todo.cfg"
    alias ct="ctodo a"
    alias ctl="ctodo ls"
    alias ctdone="ctodo do"
  fi
  if ! test -z "$(2>/dev/null git rev-parse --show-toplevel)"
  then
    alias ptodo="todo.sh -d $PROJECT_SPECIFIC_TODO_DIR/.todo.cfg"
    alias pt="ptodo a"
    alias ptl="ptodo ls"
    alias ptdone="ptodo do"
  fi
fi

if ! which dc &>/dev/null
then
  alias dc=docker-compose
else
  >&2 printf "${BYellow}WARN${NC}: dc is already installed; use 'compose' to use docker-compose.\n"
  alias compose=docker-compose
fi

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
