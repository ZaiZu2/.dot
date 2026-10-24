#!/usr/bin/env bash
# Claude Code status line: "dir on branch (#PR)" on the left, "model (cache time left/context size)" on the right edge.
#
# It also keeps the cache expiry of its session in $DOT_STATE_DIR/claude/expiry/<session_id>, for the Claude picker
# (~/.config/tmux/find_claude.sh), and starts ~/.config/tmux/claude_cache_notify.sh once when a 1h cache is about to
# expire. Keyed by session, not by tmux pane: a session moved to the background runs in a daemon worker without
# $TMUX_PANE. settings.json sets statusLine.refreshInterval, so both keep moving while the session is idle.
input=$(cat)
session_id=$(jq -r '.session_id // empty' <<<"$input")
dir=$(jq -r '.workspace.current_dir // .cwd' <<<"$input")
used=$(jq -r '.context_window.total_input_tokens // empty' <<<"$input")
model=$(jq -r '.model.display_name // empty' <<<"$input")
model_id=$(jq -r '.model.id // empty' <<<"$input")
cache_ttl=$(jq -r '.prompt_cache.ttl // empty' <<<"$input")
cache_exp=$(jq -r '.prompt_cache.expires_at // empty' <<<"$input")

# For a Bedrock inference-profile ARN, display_name only reflects the alias it was picked through (the latest model of
# that family), not the model the profile routes to. Ask Bedrock instead, once per ARN: the answer never changes, and
# the lookup runs in the background so the status line never waits on `aws`. Until it lands, display_name stands.
# anthropic.claude-haiku-4-5-20251001-v1:0 -> Haiku 4.5, anthropic.claude-sonnet-5 -> Sonnet 5.
case $model_id in
  arn:aws:bedrock:*inference-profile/*)
    if command -v aws >/dev/null; then
      cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline"
      cache="$cache_dir/model-$(printf '%s' "$model_id" | md5sum | cut -c1-16)"
      if [ -s "$cache" ]; then
        model=$(<"$cache")
      elif [ -z "$(find "$cache" -mmin -5 2>/dev/null)" ]; then
        mkdir -p "$cache_dir"
        touch "$cache"
        region=$(cut -d: -f4 <<<"$model_id")
        ( arn=$(aws bedrock get-inference-profile --region "$region" --inference-profile-identifier "$model_id" \
            --query 'models[0].modelArn' --output text 2>/dev/null)
          name=$(sed -E 's|.*/||; s/^[a-z]+\.claude-//; s/-[0-9]{8}//; s/-v[0-9]+:[0-9]+$//' <<<"$arn" |
            awk -F- '$1 ~ /^[a-z]+$/ && NF > 1 { v = $2; for (i = 3; i <= NF; i++) v = v "." $i
              printf "%s %s", toupper(substr($1, 1, 1)) substr($1, 2), v }')
          [ -n "$name" ] && printf '%s' "$name" >"$cache" ) >/dev/null 2>&1 &
      fi
    fi
    ;;
esac

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
# Same path as CLAUDE_STATE_DIR in ~/.config/tmux/claude_sessions.sh, which this script does not source.
state_dir="${DOT_STATE_DIR:-${TMPDIR:-/tmp}/dot-state}/claude"
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

  if [ -n "$session_id" ]; then
    mkdir -p "$state_dir/expiry" "$state_dir/notified"
    printf '%s %s\n' "$cache_exp" "$cache_ttl" >"$state_dir/expiry/$session_id"
    # Remind once per expiry, and only for the 1h cache: a 5m one runs out during every short break. Detached, since
    # Claude Code cancels a status line run that is still in flight at the next update.
    if [ "$cache_ttl" = 1h ] && [ "$secs" -gt 0 ] && [ "$secs" -le "${CLAUDE_CACHE_LEAD:-300}" ] &&
      [ "$(cat "$state_dir/notified/$session_id" 2>/dev/null)" != "$cache_exp" ]; then
      printf '%s\n' "$cache_exp" >"$state_dir/notified/$session_id"
      nohup "${XDG_CONFIG_HOME:-$HOME/.config}/tmux/claude_cache_notify.sh" "$session_id" "$cache_exp" \
        </dev/null >/dev/null 2>&1 &
    fi
  fi
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
