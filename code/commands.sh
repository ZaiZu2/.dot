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
  write_claude_context_imports
}

# Symlink every file under <src_root> into <dest_root>, keeping the tree structure
symlink_tree() {
  local src_root=$1
  local dest_root=$2
  local force=${3-false}
  local correct_links=0

  for dot_path in "$src_root"/**/*; do
    local rel_path=${dot_path##"$src_root/"}
    local target_path="$dest_root/$rel_path"

    if [ -d "$dot_path" ]; then
      # Remove any broken links from target directories - handles situation in which some files
      # were removed from DOT repo but their symlinks persisted in user's dotfiles
      if [ -d "$target_path" ]; then
        for target_dotfile in "$target_path"/*; do
          if [[ -L $target_dotfile && ! -e $target_dotfile ]]; then
            rm "$target_dotfile"
            multi "$GREEN" "Removing broken symlink " "$BLUE" "$target_dotfile"
          elif [[ -d $target_dotfile && ! -d "$dot_path/${target_dotfile##*/}" ]]; then
            # The matching source directory was removed/renamed - any symlinks left behind one or
            # more levels down are now broken; clean them up and prune the directory if now empty
            while IFS= read -r -d '' stale_link; do
              rm "$stale_link"
              multi "$GREEN" "Removing broken symlink " "$BLUE" "$stale_link"
            done < <(find "$target_dotfile" -type l ! -exec test -e {} \; -print0)
            find "$target_dotfile" -type d -empty -delete
          fi
        done
      fi
      continue # Do not symlink directories
    fi

    # A tracked symlink whose own target is gone would only produce a broken link, removed again on the next run
    if [[ -L "$dot_path" && ! -e "$dot_path" ]]; then
      multi "$YELLOW" "Skipping " "$BLUE" "$dot_path" "$YELLOW" ", it is a broken symlink"
      continue
    fi

    # Skip already existing, correct symlinks - readlink, as realpath would resolve through tracked files which are
    # symlinks themselves and never match
    if [[ -L "$target_path" && $(readlink "$target_path") = "$dot_path" ]]; then
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

# Link every skill directory of an external .claude directory (e.g. a work repo) into ~/.claude/skills, one symlink
# per skill. A non-empty <prefix> is joined to each skill name with '-', e.g. prefix 'ps' maps 'note' to 'ps-note'.
link_claude() {
  local claude_dir=$1
  local prefix=${2-}
  local force=${3-false}
  local correct_links=0

  if [ ! -d "$claude_dir/skills" ]; then
    multi "$RED" "No skills directory found in " "$BLUE" "$claude_dir"
    return 1
  fi

  validate_claude_prefix "$prefix" || return 1

  local src_root="$(realpath "$claude_dir")/skills"
  local dest_root="$HOME/.claude/skills"
  mkdir -p "$dest_root"

  for skill_src in "$src_root"/*/; do
    skill_src=${skill_src%/}
    local target_path="$dest_root/${prefix:+${prefix}-}${skill_src##*/}"

    # Skip already existing, correct symlinks
    if [[ -L "$target_path" && $(readlink "$target_path") = "$skill_src" ]]; then
      correct_links=$((correct_links + 1))
      continue
    fi

    # Earlier versions linked skills file by file - drop those links so the directory itself can be linked
    if [[ -d "$target_path" && ! -L "$target_path" ]]; then
      unlink_claude_files "$target_path" "$skill_src"
    fi

    if [[ -L "$target_path" && "$force" = false ]]; then
      multi "$YELLOW" "Skipping " "$BLUE" "$target_path" "$YELLOW" ", symlink already exists"
    elif [[ -e "$target_path" && ! -L "$target_path" ]]; then
      # Never replaced, even when forced - it holds files which do not come from <claude_dir>
      multi "$YELLOW" "Skipping " "$BLUE" "$target_path" "$YELLOW" ", it is not a symlink"
    else
      multi "$GREEN" "Created symlink " "$BLUE" "$target_path" "$GREEN" " -> " "$BLUE" "$skill_src"
      ln -sfn "$skill_src" "$target_path"
    fi
  done
  [ "$correct_links" -ne 0 ] && multi "$GREEN" "Skipped $correct_links correct symlinks"
  return 0
}

# Remove ~/.claude/skills/<prefix>-* symlinks that point into <claude_dir>/skills
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

  for skill_path in "$HOME/.claude/skills/${prefix}-"*; do
    if [ -L "$skill_path" ]; then
      [[ $(readlink "$skill_path") == "$src_root/"* ]] || continue
      rm "$skill_path"
      multi "$GREEN" "Removed symlink " "$BLUE" "$skill_path"
    elif [ -d "$skill_path" ]; then
      unlink_claude_files "$skill_path" "$src_root"
      [ -e "$skill_path" ] && continue
    else
      continue
    fi
    removed=$((removed + 1))
  done

  multi "$GREEN" "Removed $removed skills"
}

# Remove symlinks under <skill_dir> that point into <src_dir>, then any directories left empty. Handles skills that
# earlier versions linked file by file.
unlink_claude_files() {
  local skill_dir=$1
  local src_dir=$2

  while IFS= read -r entry; do
    [[ $(readlink "$entry") == "$src_dir/"* ]] || continue
    rm "$entry"
    multi "$GREEN" "Removed symlink " "$BLUE" "$entry"
  done < <(find "$skill_dir" -type l)

  # Prune directories left empty, deepest first; non-empty ones (foreign files) are kept
  find "$skill_dir" -depth -type d -empty -delete
}

validate_claude_prefix() {
  local prefix=$1

  if [[ -n $prefix && ! $prefix =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    multi "$RED" "Invalid prefix " "$BLUE" "$prefix" "$RED" ", use lowercase kebab-case (letters, digits, single inner '-')"
    return 1
  fi
}

# Write ~/.claude/context/imports.md with one @ import per bundle index under ~/.claude/context. The personal CLAUDE.md
# imports that file, so every bundle index is loaded into the session without listing the bundles by hand. Claude
# expands the imports recursively, so the indexes load in full, not as links. Rewritten only when its content changes.
write_claude_context_imports() {
  local root="$HOME/.claude/context"
  local file="$root/imports.md"
  [ -d "$root" ] || return 0

  local content='<!-- Generated by `dot link` and `dot claude context`, do not edit -->'
  local index
  for index in "$root"/*/index.md; do
    local bundle=${index%/index.md}
    bundle=${bundle##*/}
    # The @ line must stay bare: Claude does not expand imports inside code spans
    content+=$'\n\n'"## ${bundle} bundle (~/.claude/context/${bundle}/, index links are relative to it)"$'\n\n'"@${bundle}/index.md"
  done

  [[ -f "$file" && $(<"$file") == "$content" ]] && return 0
  printf '%s\n' "$content" >"$file"
  multi "$GREEN" "Updated " "$BLUE" "$file"
}

# Mount the OKF context bundle of an external .claude directory (e.g. a work repo) as ~/.claude/context/<prefix>, one
# symlink for the whole bundle, next to the personal bundle in ~/.claude/context/personal. Its index.md reaches the
# session through ~/.claude/context/imports.md, which the caller rewrites.
link_claude_context() {
  local claude_dir=$1
  local prefix=${2-}
  local force=${3-false}

  if [ ! -d "$claude_dir/context" ]; then
    multi "$RED" "No context directory found in " "$BLUE" "$claude_dir"
    return 1
  fi

  if [ -z "$prefix" ]; then
    red "Mounting a context bundle requires a prefix"
    return 1
  fi
  validate_claude_prefix "$prefix" || return 1

  local src="$(realpath "$claude_dir")/context"
  local dest_root="$HOME/.claude/context"
  local target_path="$dest_root/$prefix"
  mkdir -p "$dest_root"

  if [ "$prefix" = personal ]; then
    multi "$RED" "Prefix " "$BLUE" "personal" "$RED" " is reserved for the bundle tracked in the dot repo"
    return 1
  fi

  if [[ -L "$target_path" && $(readlink "$target_path") = "$src" ]]; then
    multi "$GREEN" "Skipped 1 correct symlink"
  elif [[ -L "$target_path" && "$force" = false ]]; then
    multi "$YELLOW" "Skipping " "$BLUE" "$target_path" "$YELLOW" ", symlink already exists"
  elif [[ -e "$target_path" && ! -L "$target_path" ]]; then
    # Never replaced, even when forced - it holds files which do not come from <claude_dir>
    multi "$YELLOW" "Skipping " "$BLUE" "$target_path" "$YELLOW" ", it is not a symlink"
  else
    multi "$GREEN" "Created symlink " "$BLUE" "$target_path" "$GREEN" " -> " "$BLUE" "$src"
    ln -sfn "$src" "$target_path"
  fi
  return 0
}

# Remove the ~/.claude/context/<prefix> symlink if it points at <claude_dir>/context
clean_claude_context() {
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

  local src="$(realpath "$claude_dir")/context"
  local target_path="$HOME/.claude/context/$prefix"

  if [[ -L "$target_path" && $(readlink "$target_path") = "$src" ]]; then
    rm "$target_path"
    multi "$GREEN" "Removed symlink " "$BLUE" "$target_path"
  else
    multi "$YELLOW" "No context bundle linked from " "$BLUE" "$claude_dir" "$YELLOW" " under " "$BLUE" "$prefix"
  fi
}

# Register every server from an MCP config (the tracked one unless a path to another mcp.json, e.g. of a work repo, is
# given) in Claude Code's user scope. Claude keeps user-scope servers in ~/.claude.json next to its own state, so that
# file cannot be symlinked. Servers missing from the config are left alone, and unchanged ones are skipped so that
# their stored OAuth sessions survive.
sync_claude_mcp() {
  local mcp_file=${1:-$CLAUDE_MCP_FILE}
  local user_conf="$HOME/.claude.json"
  local unchanged=0

  for cmd in claude jq; do
    command -v "$cmd" >/dev/null 2>&1 || {
      multi "$RED" "Required command not found: " "$BLUE" "$cmd"
      return 1
    }
  done

  if [ ! -f "$mcp_file" ]; then
    multi "$RED" "MCP config not found: " "$BLUE" "$mcp_file"
    return 1
  fi

  if ! jq -e '.mcpServers | type == "object"' "$mcp_file" >/dev/null 2>&1; then
    multi "$RED" "No " "$BLUE" "mcpServers" "$RED" " object found in " "$BLUE" "$mcp_file"
    return 1
  fi

  while IFS= read -r name; do
    local wanted="$(jq -cS --arg name "$name" '.mcpServers[$name]' "$mcp_file")"
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
  done < <(jq -r '.mcpServers | keys[]' "$mcp_file")

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
