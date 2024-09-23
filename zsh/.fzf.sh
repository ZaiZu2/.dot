if [[ "$(uname)" == "Darwin" ]]; then
  # macOS
  FZF_PATH="/opt/homebrew/opt/fzf"
else
  # Assume Linux
  FZF_PATH="/home/jakub/.fzf"
fi
# Update PATH if fzf bin is not already included
if [[ ! "$PATH" == *"$FZF_PATH/bin"* ]]; then
  PATH="${PATH:+${PATH}:}$FZF_PATH/bin"
fi
# Source fzf scripts
source <(fzf --zsh)
