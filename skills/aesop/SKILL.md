---
name: aesop
description: Generate a narrative "fable" of a pull request's changes - gathers PR metadata, commits, diff, and review discussion, narrates the story with embedded code snippets and Mermaid diagrams, then closes with a "moral" assessing criticality and blast radius. Use when the user runs /aesop or asks for a PR story, review story, narrative walkthrough, change storyline, or blast-radius / impact assessment of a pull request or branch.
argument-hint: "[pr-number|url] [--level outsider|junior|intermediate|senior] [--deep] [--md|--html]"
allowed-tools:
  - Bash(gh *)
  - Bash(git *)
  - Read
  - Grep
  - Glob
---

# aesop - PR storyteller

Tell the story of a pull request: what the author did, why, how it evolved, and
what it puts at risk. Every story ends with **the moral** - a blunt read on
criticality and blast radius.

## Arguments

The user may pass any of: `<pr-number|url>`, `--level <l>`, `--deep`, `--md`, `--html`.

- No PR ref → auto-detect the current branch's PR.
- `--level <outsider|junior|intermediate|senior>` → pitch of the explanation.
  Default `intermediate`. Aliases: `--outsider` ("not my domain"), `--senior`.
  See [references/levels.md](references/levels.md).
- `--deep` → force deep full-graph blast-radius tracing (see escalation below).
- `--md` / `--html` → also write the story to a standalone file.

## Workflow

1. **Gather** - run `${CLAUDE_SKILL_DIR}/scripts/gather-pr.sh [<pr>]`. It resolves
   the PR (explicit arg, else the current branch's PR), then prints delimited
   sections: `METADATA, FILES, COMMITS, COMMENTS, REVIEWS, INLINE_COMMENTS, DIFF`.
   If it prints `AESOP_ERROR: no pull request…`, tell the user no PR exists for
   this branch and ask whether to story the local diff vs base instead
   (`git diff <base>...HEAD`). Do not invent a PR.

2. **Read for intent** - the PR `body` and the review/inline comments carry the
   *why* the code can't. Mine them for motivation, debated trade-offs, and
   revisions. For multi-commit PRs, note the evolution to narrate later.

3. **Assess blast radius** - for each changed public symbol, find direct callers
   and importers (`search_code` for intent, Grep for exact symbols). Classify
   **criticality** (low/med/high/critical) and **blast radius**
   (small/med/large). Full method + the risk table format:
   see [references/blast-radius.md](references/blast-radius.md).
   - **Escalate** to a deep full-graph trace when the verdict is `critical` or
     blast radius is `large`, or when `--deep` is passed. Offer it first
     (unless `--deep`): dispatch an `Explore` (read-only) subagent to trace
     transitive callers, entry points, and cross-service touchpoints, and fold
     its findings into the moral.

4. **Narrate** - write the story: a one-paragraph summary, then flowing prose
   split into **named chapters** (pick the PR's genre and name them as an arc -
   a bug fix opens on "The Crime Scene", etc.), with embedded code snippets and
   **Mermaid** diagrams where calls cross files or the flow is non-obvious.
   Use **native Markdown only**: ` ```diff ` fences with a bold caption line above
   each (so the terminal and GitHub render them cleanly), `[N]` for bidirectional
   references (optionally line-precise via an `<!-- aesop:lines N=a-b -->` comment
   above a fence). No custom `story-diff` info string.
   Pitch every explanation at the reader **level** (default `intermediate`): it
   sets what you assume vs explain, jargon, snippet commentary, diagram count,
   and prose density - but **never** the risk accuracy. See
   [references/levels.md](references/levels.md).
   Full output spec - chapters, diff snippets, line references, Mermaid conventions,
   length guidelines: see [references/output-format.md](references/output-format.md).

5. **The moral** - close every story with a `## 📜 The moral` section: the risk
   table, the one-line "what to watch", and any escalation findings. Frame it for
   the level (plain impact for outsider → sharp callouts for senior); the verdict
   itself is identical at every level.

6. **Output** - always print the story to the terminal. Then, honoring *exactly*
   what was asked - never write a format the user didn't request:
   - `--md` only → save `pr-story-<n>.md` in the cwd.
   - `--html` only → render HTML **without** leaving a markdown file: write the
     story to a temp file, render it, then remove the temp. e.g.
     `tmp=$(mktemp /tmp/aesop-<n>.XXXXXX.md); cat > "$tmp" <<'STORY' … STORY;
     ${CLAUDE_SKILL_DIR}/scripts/render-html.sh "$tmp" pr-story-<n>.html; rm "$tmp"`.
     Only `pr-story-<n>.html` remains.
   - both `--md` and `--html` → save `pr-story-<n>.md`, then render it to
     `pr-story-<n>.html` (the `.md` stays).
   - neither flag → after printing, offer: "Export as Markdown or HTML?"

## Scripts

- `${CLAUDE_SKILL_DIR}/scripts/gather-pr.sh [<pr>]` - all PR context via `gh`
  (auto-detects the current branch's PR).
- `${CLAUDE_SKILL_DIR}/scripts/render-html.sh <story.md> [out.html]` - render a
  saved story to a standalone HTML viewer.
