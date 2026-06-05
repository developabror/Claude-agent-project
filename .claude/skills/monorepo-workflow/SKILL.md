---
name: monorepo-workflow
description: Use at the repo root to coordinate work across the frontend and backend — how the root orchestrates both sides, which command/agent owns what, the discovery/isolation rules, and how to drive a full-stack change. Read when running /build-zero-to-prod, /new-feature, /contract-sync, or /ship from the root.
---

# Monorepo Workflow (root control plane)

The root coordinates two isolated teams. **Orchestration happens in the main thread** (you, via these
commands and CLAUDE.md) because subagents cannot spawn subagents — an "orchestrator" is a plan you
execute by delegating to specialists, not a subagent that delegates.

## Who owns what
| Layer | Lives in | Drives |
|---|---|---|
| Root | `.claude/` here | planning, the FE↔BE contract, releases, full-stack commands |
| Frontend | `frontend/.claude/` | all React/TS specialists + skills (only loaded when working in `frontend/`) |
| Backend | `backend/.claude/` | all Spring Boot specialists + skills (only loaded when working in `backend/`) |

## Discovery & isolation (the rule that makes this work)
- **agents/commands** walk UP from cwd → a root session never loads child agents; a child session never loads a *sibling's*.
- **skills/CLAUDE.md** walk up AND load from descendants **on demand** → a **root** session can use either child's skills while coordinating; a **child** session can't reach a sibling (out of subtree + ancestor chain).
- **settings.json** is cwd-only (no inheritance) → each side is self-contained.
- Net: launch in `frontend/` → only frontend; in `backend/` → only backend; at root → both, on demand.

## Driving a full-stack change (the loop)
1. **Plan** — delegate to `product-planner` (or `/new-feature`). Define the **contract seam first**.
2. **Backend slice** — work in `backend/` (or delegate its specialists): architect → api-designer (+ commit `openapi.json`) → jpa/migration → spring-boot-engineer → tests → security → reviewer.
3. **Sync contract** — `/contract-sync` regenerates the frontend client from the new spec (see `api-contract`).
4. **Frontend slice** — work in `frontend/`: architect → data-state-engineer (uses generated client) → react-engineer → tests → a11y/perf/security → reviewer.
5. **Verify** — both gates green (`./gradlew build`, `npm run validate`) + contract gate.
6. **Ship** — `/ship` (release-manager) prepares versions/changelog; deploy is explicit.

## Parallelism
- Within one side, fan out specialists only when they touch **disjoint files** (component vs query layer vs tests).
- Across sides, backend and frontend slices can proceed in parallel **only after the contract seam is fixed** — otherwise the frontend implements against a moving target.
- Reserve multi-agent fan-out for genuinely parallel, high-value work (it costs ~15× the tokens of a single pass).

## Working on one side from the root
Prefer `cd backend` / `cd frontend` and launch there for a focused, isolated session. If you stay at
root, you can drop the other side's CLAUDE.md via `claudeMdExcludes` in `.claude/settings.local.json`.
