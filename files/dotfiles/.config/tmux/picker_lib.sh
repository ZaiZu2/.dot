#!/bin/sh
# Sourced by the tmux pickers (find_project.sh, find_claude.sh): the shared fzf
# theme, and the mapping of a pane cwd to its project root and a short label.
#
# The functions use shell builtins only and return through variables instead
# of stdout, so calling them once per row costs no fork.

DEV="${HOME}/dev"

# Kanagawa (wave) colors for fzf, matching the terminal and nvim theme. Passed
# to the popup as FZF_DEFAULT_OPTS: its shell doesn't inherit this script's env.
PICKER_FZF_OPTS="--color=fg:#dcd7ba,bg:#1f1f28,hl:#7e9cd8\
,fg+:#dcd7ba,bg+:#2d4f67,hl+:#7fb4ca,gutter:#1f1f28\
,info:#727169,prompt:#957fb8,pointer:#e6c384,marker:#98bb6c\
,spinner:#957fb8,header:#727169,border:#54546d,preview-bg:#1f1f28"

# project_root <abs cwd> -> $PROJECT_ROOT (empty and non-zero if none).
#
# Collapses deep cwds to the enclosing repo/worktree root: the nearest ancestor
# holding a `.git` entry (a dir for a regular repo, a file for a linked
# worktree or submodule), i.e. what `git rev-parse --show-toplevel` prints.
# Falls back to $DEV's first component for dirs that are not a repo (yet).
project_root() {
  PROJECT_ROOT=
  case "$1" in
  /*) ;;
  *) return 1 ;;
  esac
  PROJECT_ROOT=$1
  while [ -n "$PROJECT_ROOT" ] && [ ! -e "$PROJECT_ROOT/.git" ]; do
    PROJECT_ROOT=${PROJECT_ROOT%/*}
  done
  [ -n "$PROJECT_ROOT" ] && return 0
  case "$1" in
  "$DEV"/*)
    PROJECT_ROOT=${1#"$DEV"/}
    PROJECT_ROOT="$DEV/${PROJECT_ROOT%%/*}"
    return 0
    ;;
  esac
  return 1
}

# project_label <root> -> $PROJECT_LABEL.
#
# If the parent is itself a git repo (regular `.git` dir, or a bare repo whose
# worktrees live one level deeper), the root is a linked worktree of it — label
# it "repo/worktree". Otherwise just the basename.
project_label() {
  _parent=${1%/*}
  if [ -e "$_parent/.git" ] || { [ -f "$_parent/HEAD" ] && [ -f "$_parent/config" ] && [ -d "$_parent/refs" ]; }; then
    PROJECT_LABEL="${_parent##*/}/${1##*/}"
  else
    PROJECT_LABEL="${1##*/}"
  fi
}
