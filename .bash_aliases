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
  alias todo=todo.sh
  alias t="todo.sh -d $TODO_DIR/.todo.cfg a"
  alias tl="todo.sh -d $TODO_DIR/.todo.cfg ls"
  alias tdone="todo.sh -d $TODO_DIR/.todo.cfg do"
  alias ct="todo.sh -d $CLIENT_TODO_DIR/.todo.cfg a"
  alias ctl="todo.sh -d $CLIENT_TODO_DIR/.todo.cfg ls"
  alias ctdone="todo.sh -d $CLIENT_TODO_DIR/.todo.cfg do"
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
