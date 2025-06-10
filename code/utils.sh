setup_shell() {
  [ $# -eq 0 ] && return 1
  if [ "$1" = 'bash' ]; then
    shopt -s globstar dotglob
  elif [ "$1" = 'zsh' ]; then
    setopt shwordsplit
    setopt dotglob
  fi
}

check_fn() {
  for fn in "$@"; do
    if ! declare -f "$fn" >/dev/null; then
      red "Function '$fn' does not exist"
      return 1
    fi
  done
}

cap() {
  tr '[:lower:]' '[:upper:]' <<<"$1"
}

clone_repo() {
  local repo_url=$1
  local repo_dir=$2

  local default_branch=$(git remote show origin | sed -n 's/.*HEAD branch: //p')

  if [ -d "$repo_dir" ]; then
    blue "Pulling latest changes from $repo_url#$default_branch"
    git -C "$repo_dir" fetch || warn "Failed to pull the latest $repo_dir"
    git -C "$repo_dir" reset --hard "origin/$default_branch" || warn "Failed to reset local repo $repo_dir"

  else
    blue "Cloning repo $repo_url to $repo_dir"
    git clone --depth 1 "$repo_url" "$repo_dir" || {
      fail "Failed to clone $repo_url"
      return 1
    }
  fi
}
