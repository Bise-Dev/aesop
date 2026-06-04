# aesop — explanation level

One dial: the **reader's expertise**. It sets the *floor* (what you assume known)
and the *ceiling* (what's worth explaining), plus jargon, analogies, snippet
commentary, diagram count, and prose density. Tone follows from the level
(gentle teacher → peer → terse expert).

**Default: `intermediate`.** Set with `--level <outsider|junior|intermediate|senior>`.
Aliases: `--outsider` = "not my domain"; `--senior` = expert/staff.

**Invariant — never trade accuracy for level.** The criticality and blast-radius
verdict is identical at every level. Only its *framing* changes: outsider gets
system/business impact in plain words; senior gets a sharp risk callout. Never
soften or omit a real risk because the reader is junior.

## The levels

### `outsider` — "not my domain"
Reader is technically literate but new to this language, stack, or domain.
- **Assumes:** general programming literacy only.
- **Explains:** what the code does, domain concepts, language/framework idioms,
  *why it matters* in plain terms. Define every acronym on first use.
- **Jargon:** minimal; plain synonyms. **Analogies:** liberal.
- **Snippets:** narrate intent line by line.
- **Diagrams:** more, conceptual — what flows where, who calls whom.
- **Prose:** verbose, gentle pace.

### `junior`
Reader knows the language and basic programming, early career.
- **Assumes:** the language + general programming.
- **Explains:** non-obvious idioms, design patterns, *why this choice over the
  alternative*, common pitfalls. Teach the reasoning. Define domain/advanced terms.
- **Jargon:** define advanced + domain terms. **Analogies:** occasional.
- **Snippets:** key lines + the reasoning behind them.
- **Diagrams:** flow + sequence where helpful.
- **Prose:** explanatory.

### `intermediate` — default
Competent engineer fluent in the stack.
- **Assumes:** language, domain idioms, ML/framework basics. Do **not** explain
  Python syntax, ML 101, or language/domain basics.
- **Explains:** implications of implementation choices, trade-offs, interactions
  with other code, edge cases, coupling, blast radius.
- **Jargon:** used freely; define only niche terms. **Analogies:** rare.
- **Snippets:** the decision the snippet embodies, not its mechanics.
- **Diagrams:** where calls cross files or blast radius spans modules.
- **Prose:** balanced, high signal.

### `senior` — expert / staff
- **Assumes:** everything. Only the non-obvious earns words.
- **Explains:** subtle correctness, concurrency, performance, security, and
  architectural ramifications; non-obvious coupling; what even an expert might
  miss skimming the diff.
- **Jargon:** free, terse. **Analogies:** none.
- **Snippets:** included only when non-obvious; minimal commentary.
- **Diagrams:** only for genuinely complex coupling.
- **Prose:** dense and short — every line earns its place. Skip anything a
  senior reads straight off the diff.

## Length multiplier

Applied on top of the size table in [output-format.md](output-format.md):

| Level | prose / snippet count |
|-------|-----------------------|
| outsider | ~1.5× (more prose, more diagrams, more snippets) |
| junior | ~1.2× |
| intermediate | 1.0× (baseline) |
| senior | ~0.6× (fewer words, fewer snippets, only what's non-obvious) |

## The moral, by level

- **outsider:** "what could break and who feels it" — system/user/business impact
  in plain language, plus the risk table.
- **junior:** risk table + "what to watch" + a short note on *why* it's risky.
- **intermediate:** risk table + "what to watch" (baseline).
- **senior:** sharp risk callouts; assume mitigations are understood, name only
  the ones that matter.
