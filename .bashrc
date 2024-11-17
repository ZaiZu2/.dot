export XDG_CONFIG_HOME="$HOME/.config"

for file in ~/.bash/.bash_git ~/.bash/.bash_prompt ~/.bash/.bash_completions; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done
unset file;
