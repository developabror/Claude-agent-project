# CLAUDE.md — monorepo root (control plane)

This is the **root** of a two-service product: `backend/` (Spring Boot / Java 21) and
`frontend/` (React / TS / Vite). From here you coordinate **both**. To work on one side in
isolation, `cd` into it and launch Claude there — only that side's agents/skills load.

## Root sessions are PROMPT-ONLY (never edit code from here)
**In a root session (you launched `claude` at the monorepo root), do NOT hand-write or edit application
source in `backend/` or `frontend/`.** When the user asks for a change, instead **write a complete,
self-contained implementation prompt `.md` into the target side's `prompt-base/` folder**
(`backend/prompt-base/` and/or `frontend/prompt-base/`) — see the `prompt-handoff` skill for the format.
The user then `cd`s into that side, runs Claude there, and applies the prompt (the isolated team does
the actual edits). `prompt-base/` is gitignored — these prompts never reach GitHub.

- **Allowed from root** (not "touching code"): planning, read-only audits (`product-planner`,
  `api-coverage-auditor`), the deterministic contract codegen / drift report (`/contract-sync`,
  `api-contract-guardian`), and release/version/changelog edits (`release-manager`/`/ship`).
- **Handed off as a prompt** (never done from root): writing or editing controllers, components,
  services, entities, tests, styles, config — any implementation.
- *(In a `backend/` or `frontend/` session you ARE the implementer — edit directly there.)*

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
| `api-coverage-auditor` | report FE API **coverage** + endpoint **audience** (`x-audience`) — read-only, report-only |
| `release-manager` | coordinated, verified release across both sides |

(Backend/frontend specialists live in their own folders and are **not** loaded at the root — `cd`
into a side to use them, or let the side's `/scaffold-*` command drive them.)

## Root commands
| Command | Does |
|---|---|
| `/build-zero-to-prod` | empty template → deployable full-stack app (drives both `/scaffold-*`) |
| `/new-feature "<desc>"` | full-stack feature, contract-first, reviews as the gate |
| `/contract-sync [--check\|--fix]` | reconcile the FE↔BE contract (the anti-drift gate) |
| `/api-coverage` | report FE coverage + endpoint audience (uncovered/unclassified/phantom/leak) — report-only |
| `/redeploy [--full\|--backend\|--frontend]` | rebuild + bring up the local docker stack and smoke it (the instant verify loop) |
| `/ship [major\|minor\|patch]` | prepare + verify a release (no push/deploy without approval) |
| `/deploy <env>` | deploy a verified digest to a remote (disk guard, post-deploy verify, rollback) |
| `/status` | one-glance health of both sides + contract |

## Root skills (shared, load in child sessions too)
`monorepo-workflow` · `prompt-handoff` (root → side prompt files; root never edits code) ·
`api-contract` (wire contract + codegen + shared enums + traceId) ·
`api-coverage` (FE coverage + `x-audience` classification) ·
`contract-testing` (Pact behavior) · `realtime-contract` (WebSocket/SSE/AsyncAPI) ·
`local-stack` (the 3 compose files + redeploy loop) · `deploy` (safe remote deploy) ·
`feature-flags` · `git-workflow` · `zero-to-prod`.

## Local stack (test every change as a running system)
Three compose files (see `local-stack`): root `compose.yaml` = **db + backend + frontend**;
`backend/compose.yaml` = db + backend; `frontend/compose.yaml` = frontend + a Prism mock of
`backend/openapi.json`. After any change, `/redeploy` the narrowest stack, then `/redeploy --full`
before done. Copy `.env.example` → `.env`.

## Commit & push policy (STRICT — applies in every session, both sides)
- **Finalizing any change → always make a LOCAL git commit** (conventional-commit message, see `git-workflow`). This is the standing default — no confirmation needed for a *local* commit. Nothing leaves the machine.
- **Never push anywhere without explicit, per-action confirmation.** No `git push`, no `docker push`, no publish — to a git remote **or** Docker Hub — unless the developer tells you to *this time*. Default = local only.
- **When the developer confirms a push, ASK which target: git, Docker, or both** — and act only on the named target(s). Never assume both; never infer a push from "looks done."
- **Docker Hub:** generate the image tag(s) (**git-sha + semver**) **at confirmation time**, then build + push. Never push an image unprompted; never push a `latest`-only tag.
- The harness `ask` prompt on push commands is a backstop, **not** the trigger — you must already have been told to push. Without an exact instruction, push nothing, anywhere.

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
- **Redeploy locally on every change**: prove a feature/fix by bringing the stack up (`/redeploy`) and
  smoke-testing it — the running system is the proof. `/redeploy --full` is green before merge.
- **Enforce invariants where they can't be bypassed** (DB constraints + tests), not in service `if`s.
  Ship risky/incomplete work behind a **feature flag**. Surface every error; never swallow one.
- **Adversarial review** before merge: `backend-code-reviewer` / `frontend-reviewer` in fresh context.
- **Least surprise, smallest diff.** Match plan depth to scope; don't scaffold what nobody asked for.
- **Self-improve**: when corrected, capture the rule so the mistake doesn't recur.

## Adapting the template
Frontend framework swap → edit `frontend/.claude/skills`. Maven instead of Gradle → edit
`backend/.claude/skills/gradle-build` + `backend-build-engineer`. New service → new sibling folder
with its own `.claude/` (auto-isolated). Model tiers are per-agent (`opus`/`sonnet`/`haiku`); verify
with `/agents` and pin full model IDs if an alias mis-resolves.
