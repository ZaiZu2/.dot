# Directory Update Log

## 2026-10-10

- Created [Ask about the plan before implementing a feature](ask-before-implementing-features.md), feedback on asking
  about the planned design before building a new feature.
- Created [My tmux setup](tmux-setup.md), a high-level map of the session and project window model and the Claude
  Code integration, pointing at the files that hold the details.
- Created [Concepts as high-level maps, not inventories](concepts-as-high-level-maps.md), feedback on the level of
  detail of concept files.
- Updated [Dotfiles managed by the dot repo](dotfiles-managed-by-dot-repo.md): its `description` was an unquoted
  multi-line scalar containing `: `, which is not parseable YAML; it is now a folded block scalar with the same text.

## 2026-10-05

- Created [Open Knowledge Format (OKF) 0.2 specification](references/okf-spec-0-2.md), a verbatim local copy of the spec.
- Created [Dotfiles managed by the dot repo](dotfiles-managed-by-dot-repo.md), covering the dot repo, the `dot` CLI and
  how multiple knowledge bases (personal, mounted, project) are mounted and loaded through the generated `imports.md`.
