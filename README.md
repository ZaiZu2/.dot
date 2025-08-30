# Dot - Dotfiles Management System

Cross-platform dotfiles manager with intelligent dependency resolution and modular tool installation.

## Usage

```bash
./dot.sh setup                           # Full environment setup
./dot.sh setup --only git nvim tmux      # Install specific tools
./dot.sh setup --exclude docker rust     # Exclude problematic tools
./dot.sh install --force                 # Reinstall all tools
./dot.sh link                            # Symlink dotfiles only
./dot.sh list                            # Show available tools
```

## Commands

| Command | Description | Options |
|---------|-------------|---------|
| `setup` | Symlink dotfiles, install fonts and tools | `--exclude <tools>`, `--only <tools>`, `--force`, `--skip-pkg-mgr` |
| `install` | Install tools only | `--exclude <tools>`, `--only <tools>`, `--force` |
| `link` | Create symlinks for dotfiles | `--force` |
| `list` | Show available tools | - |
| `create` | Generate new tool template | `<tool-name>` |

## Supported Tools

`git`, `nvim`, `tmux`, `fzf`, `go`, `rust`, `python`, `fnm`, `bat`, `jq`, `gh`, `lazygit`, `claude`, `zsh`, `alacritty`, `uv`, `docker`, `zk`

Supports macOS and Linux with automatic dependency resolution.

## TODOs

- [ ] Setup git on install - git config
- [ ] remove explicit logs for a background processes on Darwin
- [ ] automate the update process -when pulling from the repo, dotfiles should be automatically synchronized
      - you could simply pull on `sync` command of the `dot` program
