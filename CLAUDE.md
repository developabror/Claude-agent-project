# CLAUDE.md — monorepo root (control plane)

This is the **root** of a two-service product: `backend/` (Spring Boot / Java 21) and
`frontend/` (React / TS / Vite). From here you coordinate **both**. To work on one side in
isolation, `cd` into it and launch Claude there — only that side's agents/skills load.

## How orchestration works here
- **You (the main thread) are the orchestrator.** Subagents cannot spawn subagents, so you delegate
  to specialists via the Agent tool / slash commands — there is no "orchestrator subagent."
- **Contract-first, always.** Any change crossing the FE↔BE boundary defines the API contract
  (endpoints/DTOs) *before* either side implements it. The backend OpenAPI spec is the source of
  truth; the frontend client is generated from it. Run `/contract-sync` after backend API changes.

## Root agents (delegate proactively)
| Agent | Use for |
|---|---|
| `product-planner` | turn an idea into a spec + a sequenced, full-stack task plan (read-only) |
| `api-contract-guardian` | detect/fix FE↔BE drift via OpenAPI codegen + diff gate |
| `release-manager` | coordinated, verified release across both sides |

(Backend/frontend specialists live in their own folders and are **not** loaded at the root — `cd`
into a side to use them, or let the side's `/scaffold-*` command drive them.)

## Root commands
| Command | Does |
|---|---|
| `/build-zero-to-prod` | empty template → deployable full-stack app (drives both `/scaffold-*`) |
| `/new-feature "<desc>"` | full-stack feature, contract-first, reviews as the gate |
| `/contract-sync [--check\|--fix]` | reconcile the FE↔BE contract (the anti-drift gate) |
| `/ship [major\|minor\|patch]` | prepare + verify a release (no push/deploy without approval) |
| `/status` | one-glance health of both sides + contract |

## Root skills (shared, load in child sessions too)
`monorepo-workflow` (coordination + discovery rules) · `api-contract` (the shared wire contract +
codegen) · `git-workflow` (conventional commits, semver, PR gates) · `zero-to-prod` (the master playbook).

## Discovery & isolation (why the layout is what it is)
- agents/commands walk **up** (root never loads a child's; a child never loads a sibling's).
- skills/CLAUDE.md walk up **and** load from descendants **on demand** (so a root session can use a
  child's skills while coordinating; a child session can't reach a sibling).
- settings.json is **cwd-only** (each side self-contained).
- **Net:** `frontend/` ⟂ `backend/` (siblings, fully isolated); root sees both. Details in `docs/ARCHITECTURE.md`.

## Working principles (apply on every task)
- **Plan before non-trivial work** (3+ steps / architectural). Write the spec first.
- **Close the loop**: every task ends with a runnable check (tests/build/contract gate), not an
  assertion. Show evidence; don't claim "done" on a red gate.
- **Adversarial review** before merge: `backend-code-reviewer` / `frontend-reviewer` in fresh context.
- **Least surprise, smallest diff.** Match plan depth to scope; don't scaffold what nobody asked for.
- **Self-improve**: when corrected, capture the rule so the mistake doesn't recur.

## Adapting the template
Frontend framework swap → edit `frontend/.claude/skills`. Maven instead of Gradle → edit
`backend/.claude/skills/gradle-build` + `backend-build-engineer`. New service → new sibling folder
with its own `.claude/` (auto-isolated). Model tiers are per-agent (`opus`/`sonnet`/`haiku`); verify
with `/agents` and pin full model IDs if an alias mis-resolves.
