# Setup fzf
# ---------
BASE_DIR="$(2>/dev/null brew --prefix)"
test -z "$BASE_DIR" && BASE_DIR="/usr/local"
if [[ ! "$PATH" == *$BASE_DIR/opt/fzf/bin* ]]; then
  export PATH="${PATH:+${PATH}:}$BASE_DIR/opt/fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "$BASE_DIR/opt/fzf/shell/completion.bash" 2> /dev/null

# Key bindings
# ------------
source "$BASE_DIR/opt/fzf/shell/key-bindings.bash"
