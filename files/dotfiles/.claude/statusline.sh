#!/usr/bin/env bash
# Claude Code status line: "branch #PR (dir)" on the left, context usage on the right edge.
input=$(cat)
dir=$(jq -r '.workspace.current_dir // .cwd' <<<"$input")
used=$(jq -r '.context_window.total_input_tokens // empty' <<<"$input")
pct=$(jq -r '.context_window.used_percentage // empty' <<<"$input")
model=$(jq -r '.model.display_name // empty' <<<"$input")

reset=$'\e[0m' dim=$'\e[2m' magenta=$'\e[35m' blue=$'\e[34m'
green=$'\e[32m' yellow=$'\e[33m' red=$'\e[31m' cyan=$'\e[36m'

short_dir=$dir
case $dir in "$HOME"*) short_dir="~${dir#"$HOME"}" ;; esac
branch=$(git --no-optional-locks -C "$dir" branch --show-current 2>/dev/null)

# PR number for the branch, cached per repo+branch. `gh` takes ~1s, so a stale
# cache is refreshed in the background and the status line never waits on it.
pr=""
if [ -n "$branch" ] && command -v gh >/dev/null; then
  root=$(git --no-optional-locks -C "$dir" rev-parse --show-toplevel 2>/dev/null)
  cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline"
  cache="$cache_dir/pr-$(printf '%s' "$root:$branch" | md5sum | cut -c1-16)"
  [ -f "$cache" ] && pr=$(<"$cache")
  if [ -z "$(find "$cache" -mmin -5 2>/dev/null)" ]; then
    mkdir -p "$cache_dir"
    touch "$cache"
    ( cd "$root" && gh pr view "$branch" --json number -q .number 2>/dev/null >"$cache.tmp"
      mv "$cache.tmp" "$cache" ) >/dev/null 2>&1 &
  fi
fi

if [ -n "$branch" ]; then
  left="$branch${pr:+ #$pr} ($short_dir)"
  left_c="${magenta}${branch}${reset}${pr:+ ${cyan}#${pr}${reset}} ${dim}(${reset}${blue}${short_dir}${reset}${dim})${reset}"
else
  left="$short_dir"
  left_c="${blue}${short_dir}${reset}"
fi

# 48439 -> 48k, 1200000 -> 1.2M
human() {
  awk -v n="$1" 'BEGIN {
    if (n >= 1000000) printf "%.3gM", n / 1000000
    else if (n >= 1000) printf "%dk", n / 1000
    else printf "%d", n }'
}

right="" right_c=""
if [ -n "$used" ]; then
  p=${pct%.*}; p=${p:-0}
  if   [ "$used" -gt 150000 ]; then col=$red
  elif [ "$used" -gt 100000 ]; then col=$yellow
  else col=$green; fi
  tokens=$(human "$used")
  right="${model:+$model }$tokens (${p}%)"
  right_c="${model:+${dim}${model}${reset} }${col}${tokens} (${p}%)${reset}"
fi

# Claude Code pads the status line, so leave a small right margin.
width=$(( ${COLUMNS:-80} - 4 ))
gap=$(( width - ${#left} - ${#right} ))
[ "$gap" -lt 2 ] && gap=2
printf '%s%*s%s' "$left_c" "$gap" "" "$right_c"
