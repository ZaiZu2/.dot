export ZK_NOTEBOOK_DIR="$HOME/Notes"
export BAT_THEME="kanagawa"
export EDITOR=nvim
export VISUAL=nvim

command -v brew >/dev/null 2>&1 && eval "$(brew shellenv)"

# Load all private keys into ssh-agent on login shell start up
for file in "$HOME/.ssh"/*; do
    if [ -f "$file" ] &&
        [[ "$file" != *.pub ]] &&
        [ "$(head -n 1 "$file")" = '-----BEGIN OPENSSH PRIVATE KEY-----' ]; then
        ssh-add "$(realpath "$file")"
    fi
done
