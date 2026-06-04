# Changelog

All notable changes to this project are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/); versions follow
[SemVer](https://semver.org/).

## [1.1.0] - 2026-06-04

### Changed
- Snippets now use **native Markdown** (` ```diff ` fences with a bold caption
  line) instead of a custom `story-diff` info string. Diffs render cleanly in the
  Claude Code terminal and on GitHub; no more literal JSON/comment noise.
- The story is now split into **named chapters** with genre-aware titles (a bug
  fix opens on "The Crime Scene", etc.).
- `--html` no longer writes a Markdown file first; it renders HTML only (via a
  temp file that is removed). `--md` + `--html` keeps both, as before.

### Added
- **Bidirectional, line-precise references** in the HTML viewer: clicking `[N]`
  in the prose scrolls to (and flashes) the exact line(s) it explains; clicking
  `[N]` in the snippet header scrolls back to the prose. An optional
  `<!-- aesop:lines N=a-b -->` comment above a fence selects the line range
  (invisible in the terminal / on GitHub); without it the ref targets the whole
  snippet.
- Reworked HTML viewer styling: warm light / charcoal dark themes that follow the
  OS preference, a muted-green brand accent, sky-toned reference highlights,
  serif chapter headings, and Geist / Geist Mono typography (CDN with full system
  fallback).

## [1.0.0] - 2026-06-04

### Added
- Initial release of the **aesop** PR-storyteller skill.
- PR context gathering via `gh` (metadata, files, commits, review + inline
  comments, diff) with auto-detection of the current branch's PR.
- Narrative story output with `story-diff` snippets, line references, and
  Mermaid diagrams for cross-file flows.
- Criticality + blast-radius assessment ("the moral"), with escalation to a
  deep full-graph trace via a read-only subagent for critical / far-reaching
  changes (`--deep`).
- Tunable explanation level (`--level outsider|junior|intermediate|senior`,
  default `intermediate`).
- Standalone Markdown (`--md`) and self-contained HTML (`--html`) export.
- Packaged as a Claude Code plugin with its own marketplace manifest.
