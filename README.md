- [ ] Skip `.zshrc` update when running `fnm` install script
- [ ] Setup git on install - git config
- [ ] `clone_repo` function assumes the default branch is `master`, which is error-prone
- [ ] create `install` command which will only allow installing apps
- [ ] remove explicit logs for a background processes on Darwin

      ┃Symlinking binaries
      [10]  + done       { while IFS= read -r line; do; format_line "$(<"$CURR_TOOL_STATUS")" "$line";}
      ┗━━━ SUCCESS ━━━━

      Skipping /Users/AB0383Q/.zshrc, file already exists
      Provide admin credentials
      [7] 44319
      Copying fonts
      [7]  + terminated  ( while true; do; sudo -n true; sleep 60; done; )
       ━━━ RUST is already installed ━━━
      AB0383Q ❯ . .dotfiles/dot.sh setup -o rust -s -f
