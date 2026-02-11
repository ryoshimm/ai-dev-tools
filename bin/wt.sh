# wt: shell function wrapper for git worktree helper
# Usage: add the following line to your .zshrc
#   source /path/to/ai-dev-tools/bin/wt.sh

__wt_script="${${(%):-%x}:A:h}/wt"

wt() {
  if [[ "$1" == "dir" ]]; then
    shift
    local dir
    dir="$("$__wt_script" dir "$@")" || return
    cd "$dir"
  else
    "$__wt_script" "$@"
  fi
}
