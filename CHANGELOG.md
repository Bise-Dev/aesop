# Changelog

All notable changes to this project are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/); versions follow
[SemVer](https://semver.org/).

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
