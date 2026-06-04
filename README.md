# Aesop — PR storyteller

> Every pull request has a story. Aesop tells it — and ends with the moral.

A Claude Code skill that turns a pull request into a narrated walkthrough:
what the author did, why, how it evolved across commits, with embedded code
snippets and Mermaid diagrams — then closes with **the moral**: a blunt read on
the change's criticality and blast radius.

## Install

From this repo as a marketplace:

```
/plugin marketplace add Bise-Dev/aesop
/plugin install aesop@bise-dev
```

Or try it locally without installing:

```
claude --plugin-dir /path/to/aesop
```

## Usage

```
/aesop:aesop                 # story the current branch's PR
/aesop:aesop 123             # story PR #123
/aesop:aesop <pr-url>        # story by URL
```

### Flags

| Flag | Effect |
|------|--------|
| `--level <outsider\|junior\|intermediate\|senior>` | Pitch of the explanation. Default `intermediate`. |
| `--outsider` / `--senior` | Aliases for the extreme levels. |
| `--deep` | Force deep full-graph blast-radius tracing (read-only subagent). |
| `--md` | Also write `pr-story-<n>.md`. |
| `--html` | Also write a self-contained HTML viewer (Mermaid + diff coloring). |

No flags → the story prints to the terminal, then Aesop offers to export it.

## The explanation level

One dial — the reader's expertise — sets what to assume vs explain, jargon,
analogies, per-snippet commentary, diagram count, and prose density. It **never**
changes the risk verdict: an outsider gets the same blast-radius read as a
senior, just framed in plain "what breaks, who feels it" terms.

| Level | Assumes | Focus |
|-------|---------|-------|
| `outsider` | general tech literacy | what the code does, domain + idioms, plain-language impact |
| `junior` | the language + basics | non-obvious idioms, why-this-over-that, pitfalls |
| `intermediate` *(default)* | language + domain + framework basics | implications, trade-offs, coupling, edge cases |
| `senior` | everything | subtle correctness / perf / security / architecture only |

Details: [`skills/aesop/references/levels.md`](skills/aesop/references/levels.md).

## What it does

1. **Gathers** PR metadata, files, commits, review + inline comments, and the
   full diff (auto-detecting the current branch's PR via `gh`).
2. **Mines intent** from the description and review discussion.
3. **Assesses blast radius** — direct callers/importers by default; escalates to
   a deep full-graph trace when the change is critical or far-reaching.
4. **Narrates** the story in logical (intent) order with `story-diff` snippets,
   line references, and Mermaid diagrams for cross-file flows.
5. **Closes with the moral** — a criticality + blast-radius risk table and a
   one-line "what to watch".

## Repo layout

```
aesop/
├── .claude-plugin/
│   ├── plugin.json          # plugin manifest
│   └── marketplace.json     # makes this repo its own marketplace
└── skills/aesop/
    ├── SKILL.md             # workflow + arguments
    ├── references/          # output format, blast-radius method, levels
    └── scripts/             # gh gathering + HTML renderer
```

## Requirements

- [`gh`](https://cli.github.com/) authenticated against the target repo.
- `jq` (used by the gathering script).
- The HTML viewer loads `marked` and `mermaid` from a CDN at view time; vendor
  them or add Subresource Integrity for a hardened/offline setup (see the note
  in `scripts/render-html.sh`).

## Notes

Risk verdicts are advisory — double-check high-impact conclusions with a
qualified reviewer before acting on them.

## License

MIT — see [LICENSE](LICENSE).
