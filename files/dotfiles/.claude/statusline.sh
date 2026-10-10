#!/usr/bin/env bash
# Claude Code status line: "dir on branch (#PR)" on the left, "model (cache time left/context size)" on the right edge.
#
# Inside tmux it also keeps the cache expiry of its pane in $TMPDIR/claude-cache/<pane>, for the Claude picker
# (~/.config/tmux/find_claude.sh), and starts ~/.config/tmux/claude_cache_notify.sh once when a 1h cache is about to
# expire. settings.json sets statusLine.refreshInterval, so both keep moving while the session is idle.
input=$(cat)
dir=$(jq -r '.workspace.current_dir // .cwd' <<<"$input")
used=$(jq -r '.context_window.total_input_tokens // empty' <<<"$input")
model=$(jq -r '.model.display_name // empty' <<<"$input")
model_id=$(jq -r '.model.id // empty' <<<"$input")
cache_ttl=$(jq -r '.prompt_cache.ttl // empty' <<<"$input")
cache_exp=$(jq -r '.prompt_cache.expires_at // empty' <<<"$input")

# Bedrock inference-profile ARNs resolve to opaque IDs rather than a model
# name, so if display_name didn't already give us one, cast the ARN back to
# its underlying model via the mapping in settings.json's env block.
if [ -z "$model" ] && [ -n "$model_id" ]; then
  settings="$HOME/.claude/settings.json"
  if [ -f "$settings" ]; then
    model=$(jq -r --arg id "$model_id" '
      {OPUS: "Opus", SONNET: "Sonnet", HAIKU: "Haiku"} as $names
      | .env // {}
      | to_entries[]
      | select(.key | test("^ANTHROPIC_DEFAULT_(OPUS|SONNET|HAIKU)_MODEL$"))
      | select(.value as $v | $id | contains($v))
      | .key | capture("ANTHROPIC_DEFAULT_(?<name>OPUS|SONNET|HAIKU)_MODEL").name
      | $names[.]
    ' "$settings" | head -n1)
  fi
fi

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

# 48439 -> 48k, 1200000 -> 1.2M
human() {
  awk -v n="$1" 'BEGIN {
    if (n >= 1000000) printf "%.3gM", n / 1000000
    else if (n >= 1000) printf "%dk", n / 1000
    else printf "%d", n }'
}

ctx="" ctx_c=""
if [ "${used:-0}" -gt 0 ]; then
  if   [ "$used" -gt 150000 ]; then col=$red
  elif [ "$used" -gt 100000 ]; then col=$yellow
  else col=$green; fi
  ctx=$(human "$used")
  ctx_c="${col}${ctx}${reset}"
fi

# Time until the prompt cache goes cold; from then on the next prompt pays for the whole context again.
cache="" cache_c=""
cache_dir="${TMPDIR:-/tmp}/claude-cache"
pane=${TMUX_PANE#%}
if [ -n "$cache_exp" ]; then
  secs=$(( cache_exp - $(date +%s) ))
  if [ "$secs" -le 0 ]; then
    cache="cold"
    cache_c="${red}${cache}${reset}"
  else
    if   [ "$secs" -le 300 ]; then col=$red
    elif [ "$secs" -le 600 ]; then col=$yellow
    else col=$green; fi
    cache="$(( (secs + 59) / 60 ))m"
    cache_c="${col}${cache}${reset}"
  fi

  if [ -n "$pane" ]; then
    mkdir -p "$cache_dir/notified"
    printf '%s %s\n' "$cache_exp" "$cache_ttl" >"$cache_dir/$pane"
    # Remind once per expiry, and only for the 1h cache: a 5m one runs out during every short break. Detached, since
    # Claude Code cancels a status line run that is still in flight at the next update.
    if [ "$cache_ttl" = 1h ] && [ "$secs" -gt 0 ] && [ "$secs" -le "${CLAUDE_CACHE_LEAD:-300}" ] &&
      [ "$(cat "$cache_dir/notified/$pane" 2>/dev/null)" != "$cache_exp" ]; then
      printf '%s\n' "$cache_exp" >"$cache_dir/notified/$pane"
      nohup "${XDG_CONFIG_HOME:-$HOME/.config}/tmux/claude_cache_notify.sh" "$TMUX_PANE" "$cache_exp" \
        </dev/null >/dev/null 2>&1 &
    fi
  fi
elif [ -n "$pane" ]; then
  # A new session in the pane: whatever the previous one left behind no longer applies.
  rm -f "$cache_dir/$pane"
fi

# "Opus 5.5 (55m/130k)": whichever of the two figures are known, each in its own color.
stats="$cache${cache:+${ctx:+/}}$ctx"
stats_c="$cache_c${cache:+${ctx:+${dim}/${reset}}}$ctx_c"
right="$model${model:+${stats:+ }}${stats:+($stats)}"
right_c="${model:+${dim}${model}${reset}}${model:+${stats:+ }}${stats:+${dim}(${reset}${stats_c}${dim})${reset}}"

# Claude Code pads the status line, so leave a small right margin.
width=$(( ${COLUMNS:-80} - 4 ))

# "~/.dot on master (#12)". In a pane too narrow for the whole line the path gives way first: it is cut from the left,
# by exactly as much as it takes to fit, down to its last directory at most:
# ~/dev/work/repo/src -> …ev/work/repo/src -> …epo/src -> …/src.
git_info="${branch:+ on $branch${pr:+ (#$pr)}}"
room=$(( width - ${#right} - ${#git_info} - 2 ))
path=$short_dir
last="…/${path##*/}"
[ "$room" -ge "${#last}" ] || room=${#last}
if [ "${#path}" -gt "$room" ]; then
  path="…${path: -$(( room - 1 ))}"
fi
left="$path$git_info"
left_c="${blue}${path}${reset}${branch:+ ${dim}on${reset} ${magenta}${branch}${reset}}"
left_c+="${pr:+ ${dim}(${reset}${cyan}#${pr}${reset}${dim})${reset}}"

gap=$(( width - ${#left} - ${#right} ))
[ "$gap" -lt 2 ] && gap=2
printf '%s%*s%s' "$left_c" "$gap" "" "$right_c"
