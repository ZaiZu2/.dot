source utils.sh

for file in "./tools/"*; do
  source "$file"

  basename="$(basename "$file")"
  tool="${basename%%.sh}"

  is_installed_fn="is_installed_$tool"
  install_fn="install_$tool"
  check_fn "$tool" "$is_installed_fn" "$install_fn" || return 1

  if ! "$is_installed_fn"; then
    log "$tool" "Installing '$tool' - tool not found"
    $install_fn
  else
    log "$tool" "Skipping '$tool' - tool is already installed"
  fi
done
