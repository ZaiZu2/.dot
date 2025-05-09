dog() {
  echo 'dog' 
  echo 'cat' && return 1
  echo 'bat'
}

log_tool_block() {
  "$@" 2>&1 | {
    while IFS= read -r line; do
      echo "  $line"
    done
  }
}

b() {
  stdbuf -oL "$1" |
    while IFS= read -r line; do
      echo "  $line"
    done
}

output=$(dog)
echo "$output"

echo '----------'
log_tool_block dog
# b dog
