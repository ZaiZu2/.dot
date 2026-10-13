#!/bin/sh
# Sourced by the tmux pickers (find_project.sh, find_claude.sh): the shared fzf
# theme, and the mapping of a pane cwd to its project root and a short label.
#
# The functions use shell builtins only and return through variables instead
# of stdout, so calling them once per row costs no fork.

DEV="${HOME}/dev"

# Popup sizing, see picker_size. Widths are in terminal columns.
#
# Share of the client's width the popup may take, in percent.
PICKER_CAP_PCT=90
# Narrowest preview worth showing; below it the preview is dropped.
PICKER_PREVIEW_MIN=40
# tmux draws the popup border on the left and right edge, inside `-w`.
PICKER_POPUP_BORDER=2
# fzf's gutter left of each list line (pointer and marker, one column each)
# plus the scrollbar column it keeps right of the list.
PICKER_LIST_PAD=3
# A fixed `--preview-window` size counts the preview's content only: fzf adds
# its left and right border and one column of padding inside each (fzf 0.62).
PICKER_PREVIEW_PAD=4

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

# picker_short_path <abs path> -> $PICKER_PATH.
#
# The path as the pickers list it: relative to $DEV when under it (checked
# first, as $DEV lies inside $HOME), with `~` for $HOME otherwise. Any other
# path is kept as it is. $DEV itself is not special-cased and gets `~/dev`.
picker_short_path() {
  case "$1" in
  "$DEV"/*) PICKER_PATH=${1#"$DEV"/} ;;
  "$HOME") PICKER_PATH="~" ;;
  "$HOME"/*) PICKER_PATH="~${1#"$HOME"}" ;;
  *) PICKER_PATH=$1 ;;
  esac
}

# picker_size <list_w> <preview_w> <client_w> -> $PICKER_POPUP_W and
# $PICKER_PREVIEW_W (0 when the preview is dropped).
#
# Sizes the popup from its content: the list at its full width beside a
# preview of preview_w columns, capped at PICKER_CAP_PCT of the client. Over
# the cap the preview takes what is left beside the list; when that is less
# than PICKER_PREVIEW_MIN, or no preview width is known, the popup is the list
# alone, still capped.
#
# list_w is the width of the widest list line and preview_w that of the
# preview's content (0 or empty for none), both without padding or border;
# client_w is the tmux client's width. $PICKER_PREVIEW_W is the size to hand to
# fzf's `--preview-window`, $PICKER_POPUP_W the one for tmux's `-w`.
# Clobbers the scratch variables `_cap` and `_list`.
picker_size() {
  _cap=$((${3:-0} * PICKER_CAP_PCT / 100))
  _list=$((${1:-0} + PICKER_LIST_PAD + PICKER_POPUP_BORDER))
  PICKER_PREVIEW_W=${2:-0}
  if [ "$PICKER_PREVIEW_W" -gt 0 ]; then
    PICKER_POPUP_W=$((_list + PICKER_PREVIEW_W + PICKER_PREVIEW_PAD))
    [ "$PICKER_POPUP_W" -le "$_cap" ] && return 0
    PICKER_POPUP_W=$_cap
    PICKER_PREVIEW_W=$((_cap - _list - PICKER_PREVIEW_PAD))
    [ "$PICKER_PREVIEW_W" -ge "$PICKER_PREVIEW_MIN" ] && return 0
  fi
  PICKER_PREVIEW_W=0
  PICKER_POPUP_W=$_list
  [ "$PICKER_POPUP_W" -le "$_cap" ] || PICKER_POPUP_W=$_cap
}
