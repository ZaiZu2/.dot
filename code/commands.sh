load_platform() {
  OS="$(uname -s | tr '[:upper:]' '[:lower:]')" || return 1

  case "$OS" in
  linux | darwin) ;;
  *)
    red "Platform unsupported: $OS"
    exit 1
    ;;
  esac

  ARCH="$(uname -m | tr '[:upper:]' '[:lower:]')" || return 1
  case "$ARCH" in
  x86_64 | arm64) ;;
  *)
    red "Architecture unsupported: $ARCH"
    exit 1
    ;;
  esac

  blue "Platform recognized as $OS-$ARCH"
  source "$SCRIPT_DIR/code/$OS.sh"
}

open_sudo_session() {
  # Invalidate any cached credentials if they are incorrect
  if sudo --non-interactive true 2>/dev/null; then
    sudo --remove-timestamp
    blue "Provide admin credentials"
  fi

  if ! sudo --validate; then
    red "This script requires admin rights"
    exit 1
  fi

  (while true; do
    sudo -n true
    sleep 60
  done) &
  SUDO_SESSION_PID=$!
  trap 'kill "$SUDO_SESSION_PID" 2>/dev/null' EXIT HUP INT QUIT TERM
}

symlink_dotfiles() {
  symlink_tree "$DOTFILES_DIR" "$HOME" "${1-false}"
}

# Symlink every file under <src_root> into <dest_root>, keeping the tree structure. A non-empty <prefix> is prepended
# to the first path component, e.g. prefix 'ps-' maps 'note/SKILL.md' to '<dest_root>/ps-note/SKILL.md'.
symlink_tree() {
  local src_root=$1
  local dest_root=$2
  local force=${3-false}
  local prefix=${4-}
  local correct_links=0

  for dot_path in "$src_root"/**/*; do
    local rel_path=${dot_path##"$src_root/"}
    local target_path="$dest_root/$prefix$rel_path"

    if [ -d "$dot_path" ]; then
      # Remove any broken links from target directories - handles situation in which some files
      # were removed from DOT repo but their symlinks persisted in user's dotfiles
      if [ -d "$target_path" ]; then
        for target_dotfile in "$target_path"/*; do
          if [[ -L $target_dotfile && ! -e $target_dotfile ]]; then
            rm "$target_dotfile"
            multi "$GREEN" "Removing broken symlink " "$BLUE" "$target_dotfile"
          fi
        done
      fi
      continue # Do not symlink directories
    fi

    # Skip already existing, correct symlinks
    if [[ -L "$target_path" && $(realpath "$target_path") = "$dot_path" ]]; then
      correct_links=$((correct_links + 1))
      continue
    fi

    if [[ -f "$target_path" && "$force" = false ]]; then
      multi "$YELLOW" "Skipping " "$BLUE" "$target_path" "$YELLOW" ", file already exists"
    elif [[ -L "$target_path" && "$force" = false ]]; then
      multi "$YELLOW" "Skipping " "$BLUE" "$target_path" "$YELLOW" ", symlink already exists"
    else
      mkdir -p "$(dirname "$target_path")"
      multi "$GREEN" "Created symlink " "$BLUE" "$target_path" "$GREEN" " -> " "$BLUE" "$dot_path"
      ln -sf "$dot_path" "$target_path"
    fi

  done
  [ "$correct_links" -ne 0 ] && multi "$GREEN" "Skipped $correct_links correct symlinks"
}

# Link skills from an external .claude directory (e.g. a work repo) into ~/.claude/skills. A non-empty <prefix> is
# joined to each skill name with '-', e.g. prefix 'ps' maps 'note' to 'ps-note'.
link_claude() {
  local claude_dir=$1
  local prefix=${2-}
  local force=${3-false}

  if [ ! -d "$claude_dir/skills" ]; then
    multi "$RED" "No skills directory found in " "$BLUE" "$claude_dir"
    return 1
  fi

  validate_claude_prefix "$prefix" || return 1

  symlink_tree "$(realpath "$claude_dir")/skills" "$HOME/.claude/skills" "$force" "${prefix:+${prefix}-}"
}

# Remove ~/.claude/skills/<prefix>-* symlinks that point into <claude_dir>/skills, then any emptied skill directories
clean_claude() {
  local claude_dir=$1
  local prefix=${2-}

  if [ -z "$prefix" ]; then
    red "Cleaning requires a prefix"
    return 1
  fi
  validate_claude_prefix "$prefix" || return 1

  if [ ! -d "$claude_dir" ]; then
    multi "$RED" "Directory not found: " "$BLUE" "$claude_dir"
    return 1
  fi

  local src_root="$(realpath "$claude_dir")/skills"
  local removed=0

  for skill_dir in "$HOME/.claude/skills/${prefix}-"*/; do
    [ -d "$skill_dir" ] || continue
    skill_dir=${skill_dir%/}

    while IFS= read -r entry; do
      [[ $(readlink "$entry") == "$src_root/"* ]] || continue
      rm "$entry"
      removed=$((removed + 1))
      multi "$GREEN" "Removed symlink " "$BLUE" "$entry"
    done < <(find "$skill_dir" -type l)

    # Prune directories left empty, deepest first; non-empty ones (foreign files) are kept
    find "$skill_dir" -depth -type d -empty -delete
  done

  multi "$GREEN" "Removed $removed symlinks"
}

validate_claude_prefix() {
  local prefix=$1

  if [[ -n $prefix && ! $prefix =~ ^[a-z0-9]+$ ]]; then
    multi "$RED" "Invalid prefix " "$BLUE" "$prefix" "$RED" ", use a single lowercase word (letters and digits)"
    return 1
  fi
}

# Register every server from the tracked MCP config in Claude Code's user scope. Claude keeps user-scope servers in
# ~/.claude.json next to its own state, so that file cannot be symlinked. Servers missing from the tracked config are
# left alone, and unchanged ones are skipped so that their stored OAuth sessions survive.
sync_claude_mcp() {
  local user_conf="$HOME/.claude.json"
  local unchanged=0

  for cmd in claude jq; do
    command -v "$cmd" >/dev/null 2>&1 || {
      multi "$RED" "Required command not found: " "$BLUE" "$cmd"
      return 1
    }
  done

  if [ ! -f "$CLAUDE_MCP_FILE" ]; then
    multi "$RED" "MCP config not found: " "$BLUE" "$CLAUDE_MCP_FILE"
    return 1
  fi

  while IFS= read -r name; do
    local wanted="$(jq -cS --arg name "$name" '.mcpServers[$name]' "$CLAUDE_MCP_FILE")"
    local current="$(jq -cS --arg name "$name" '.mcpServers[$name] // empty' "$user_conf" 2>/dev/null)"

    if [ "$wanted" = "$current" ]; then
      unchanged=$((unchanged + 1))
      continue
    fi

    if [ -n "$current" ]; then
      claude mcp remove --scope user "$name" >/dev/null || return 1
    fi
    claude mcp add-json --scope user "$name" "$wanted" >/dev/null || {
      multi "$RED" "Failed to register MCP server " "$BLUE" "$name"
      return 1
    }
    multi "$GREEN" "Registered MCP server " "$BLUE" "$name"
  done < <(jq -r '.mcpServers | keys[]' "$CLAUDE_MCP_FILE")

  [ "$unchanged" -ne 0 ] && multi "$GREEN" "Skipped $unchanged unchanged MCP servers"
  return 0
}

create_tool_template() {
  local tool=$1
  local cap_tool="$(cap "$tool")"
  local tool_path="$(realpath "$SCRIPT_DIR/tools")/$tool.sh"

  if [ -f "$tool_path" ]; then
    multi "$BLUE" "$cap_tool" "$RED" " already exists, template not created"
    return 1
  fi

  touch "$tool_path"
  # Tabs with `-EOF` allow to indent here-doc without injecting indentation into file
  cat >"./tools/${tool}.sh" <<-EOF
		deps_${tool}() {
		  echo ''
		}

		is_installed_${tool}() {
		  command -v ${tool} >/dev/null 2>&1;
		}

		install_${tool}() {
		  # Must be nested within 'install_${tool}' function to not polute global scope during sourcing
		  install_linux() {

		  }

		  install_darwin() {
		     brew install ${tool} || {
		       fail "Failed to install ${tool}"
		     return 1
		     }
		  }

		  if [ "\$OS" = 'darwin' ]; then
		    install_darwin || return 1
		  elif [ "\$OS" = 'linux' ]; then
		    install_linux || return 1
		  fi
		}
	EOF
  chmod +x "$tool_path"
  multi "$GREEN" "Template created for " "$BLUE" "$cap_tool" \
    "$GREEN" " at " "$BLUE" "$tool_path"
}
