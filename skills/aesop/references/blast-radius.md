# aesop: criticality & blast radius

The moral of every story is a blunt read on risk. Two axes:

- **Criticality**: how much it would hurt if this change is wrong.
  `low | medium | high | critical`.
- **Blast radius**: how far the change reaches across the codebase / system.
  `small | medium | large`.

## Method (default: direct callers)

1. **List changed public symbols**: from the diff, collect exported/public
   functions, classes, types, routes, config keys, schema/migrations, env vars,
   and public API or CLI surfaces that changed.
2. **Find direct dependents**, for each symbol:
   - `search_code` for behavioral/intent matches across files.
   - Grep for the exact symbol name for precise call sites and imports.
   - Note dependents that are entry points, public APIs, shared/core modules,
     auth/security paths, data migrations, or cross-service contracts.
3. **Classify** each changed area on both axes using the signals below.
4. **Aggregate** to a single verdict for the PR (worst-case dominates).

### Criticality signals (raise the level)

- Auth, authz, secrets, crypto, payments, billing.
- Data migrations, schema changes, destructive/irreversible operations.
- Public API / contract changes (breaking signatures, response shapes).
- Concurrency, locking, retries, idempotency, money or counts.
- Error-handling / fallback paths that could fail silently.
- Infra / IaC that changes blast-prone resources (per the user's IaC rules,
  surface this for `tofu-reviewer` / `drift-detective`).

### Blast-radius signals (widen the radius)

- Many direct callers, or callers in many modules/packages.
- Changed symbol is a shared util, base class, or core type.
- Cross-service / cross-repo contract (events, RPC, queue messages).
- Config / env / feature flags consumed widely.

## Escalation: deep full-graph trace

Trigger when the verdict is **critical**, blast radius is **large**, or `--deep`
is passed. Unless `--deep`, offer it first ("This looks high-impact; run a deep
dependency trace? (y/n)").

Dispatch a read-only **`Explore`** subagent:

> Trace the full dependency graph for these changed symbols: `<list>`.
> Find transitive callers (2+ hops), entry points that ultimately reach them,
> shared modules touched, and any cross-service / cross-repo contracts.
> Return: a caller tree per symbol, the set of entry points affected, and any
> surprising long-range couplings. Read-only; do not modify anything.

Fold its findings into the moral and, where the coupling is non-obvious, into a
Mermaid dependency diagram in the story.

## The moral: output format

````markdown
## 📜 The moral

| Axis | Verdict | Why |
|------|---------|-----|
| Criticality | **high** | touches `auth/session.ts` token validation |
| Blast radius | **medium** | 7 direct callers across 3 modules |

**What to watch:** session expiry now uses `<=`; verify no caller relied on the
old exclusive boundary. Migration `0042` is irreversible; confirm a backup.

**Deep trace:** _(only if escalated)_ `validateSession` is reached by all 4 API
entry points via `requireAuth`; a regression fails every authenticated route.
````

Keep it short and concrete. Cite `file:line` where you can. State confidence
when a claim is inferred rather than verified. This is advice; remind the user
that technical/risk conclusions should be double-checked by a qualified reviewer
before acting on them.
