# project-template — a Claude Code monorepo control plane

A production-grade **agentic scaffold** for a full-stack product: a **Spring Boot / Java 21**
backend and a **React / TypeScript / Vite** frontend, each with its own isolated team of Claude
Code agents and skills, coordinated by a thin **root orchestration layer**.

The promise: open the root and say *"build from zero to production"* and the system scaffolds,
implements, tests, hardens, and ships both halves. Open a sub-folder and you get a focused,
**isolated** specialist team — only frontend agents in `frontend/`, only backend agents in
`backend/`.

---

## Why this layout works (the discovery rule that drives everything)

Claude Code's config discovery is **asymmetric by type** (this nuance is the whole game — see
`docs/ARCHITECTURE.md` for the cited details):

- **agents, commands, settings.json** → resolved by **walking UP** from where you launch `claude`
  (cwd → ancestors → `~/.claude` → plugins). Descendants are **not** pulled in. (`settings.json` is
  even stricter: cwd-only, no parent inheritance.)
- **skills & CLAUDE.md** → also walk up, **and** additionally load from **descendant** subtrees
  *on demand* when Claude touches files there.

The launch directory is the isolation boundary. What you get:

| You run `claude` in… | agents / commands | skills / CLAUDE.md |
|---|---|---|
| `frontend/` | **frontend + root** (never backend) | **frontend + root** (backend is a sibling, out of subtree → never loads) |
| `backend/`  | **backend + root** (never frontend) | **backend + root** (frontend is a sibling → never loads) |
| `project-template/` (root) | **root only** (children's agents not loaded) | root **+ either child's skills/CLAUDE.md on demand** when you work in that subtree |

**The promise you care about holds for every config type:** launch in `frontend/` and the backend
team is *completely* absent — and vice-versa. That's because `frontend/` and `backend/` are
**siblings**: each sits outside the other's subtree *and* outside the other's ancestor chain, so
neither walk-up nor on-demand descendant loading can ever reach across. This is true on any Claude
Code version.

The one direction that is *not* isolated is **root → children**: a root session can pull in a
child's **skills/CLAUDE.md** on demand (it can't load their *agents/commands*). That's a feature —
it's how the root coordinates both sides. It's also why the root `.claude/` holds **nothing
domain-specific** — only neutral orchestration + shared conventions. (A backend *agent* placed at
the root would **not** leak into `frontend/`, since agents only walk up — but a backend *skill* at
the root would be visible everywhere, so keep domain skills in their own side.)

> If you launch at the root but want to focus on one side only, `claudeMdExcludes` in
> `.claude/settings.local.json` drops the other side's CLAUDE.md. See `docs/ARCHITECTURE.md`.

---

## The three teams

```
project-template/
├── .claude/                 ← ROOT: orchestration only (its skills/CLAUDE.md flow DOWN — keep neutral)
│   ├── agents/              product-planner · api-contract-guardian · api-coverage-auditor · release-manager
│   ├── skills/              monorepo-workflow · prompt-handoff · api-contract · api-coverage · contract-testing
│   │                        realtime-contract · local-stack · deploy · feature-flags · git-workflow · zero-to-prod
│   └── commands/            /doctor · /build-zero-to-prod · /new-feature · /contract-sync · /api-coverage · /redeploy · /ship · /deploy · /status
├── compose.yaml             ← FULL local stack: db + backend + frontend (/redeploy --full)
├── .env.example             ← copy to .env for local compose
├── CLAUDE.md                ← shared monorepo context (also flows down)
│
├── frontend/                ← cd here → ONLY the frontend team is visible
│   ├── .claude/
│   │   ├── agents/          frontend-architect · react-engineer · data-state-engineer · design-system-enforcer
│   │   │                    frontend-test-engineer · accessibility-auditor · web-performance-engineer
│   │   │                    frontend-security-auditor · frontend-build-engineer · frontend-reviewer
│   │   ├── skills/          react-patterns · typescript-strict · data-fetching · design-system
│   │   │                    frontend-testing · accessibility · web-performance · frontend-security · vite-build
│   │   └── commands/        /scaffold-frontend · /new-component · /new-page · /wire-api
│   ├── compose.yaml         ← frontend + Prism mock of the contract (/redeploy --frontend)
│   ├── CLAUDE.md
│   └── FRONTEND-SETUP.md    ← the master 0→prod frontend spec/prompt
│
└── backend/                 ← cd here → ONLY the backend team is visible
    ├── .claude/
    │   ├── agents/          backend-architect · spring-boot-engineer · api-designer · jpa-persistence-engineer
    │   │                    db-migration-engineer · backend-test-engineer · spring-security-engineer
    │   │                    backend-security-auditor · observability-engineer · backend-performance-engineer
    │   │                    backend-code-reviewer · backend-build-engineer
    │   ├── skills/          spring-boot · rest-api-design · jpa-patterns · spring-security
    │   │                    backend-testing · flyway-migrations · observability · gradle-build
    │   │                    design-patterns · code-quality · logging-patterns
    │   └── commands/        /scaffold-backend · /new-endpoint · /new-entity · /add-migration
    ├── compose.yaml         ← db + backend, API exposed (/redeploy --backend)
    ├── CLAUDE.md
    └── BACKEND-SETUP.md     ← the master 0→prod backend spec/prompt
```

---

## How to use it

### 1. Spin up a brand-new product (0 → production)
From the **root**:
```
claude
> /build-zero-to-prod
```
The main thread (guided by the `zero-to-prod` skill and, for planning, the `product-planner` agent)
reads `frontend/FRONTEND-SETUP.md` and `backend/BACKEND-SETUP.md`, then drives the build. End state:
a running, tested, containerized full-stack app with CI, migrations, auth, observability, and a
synced API contract. (Run `/scaffold-backend` and `/scaffold-frontend` from inside each side, or let
`/build-zero-to-prod` walk the whole sequence.)

### 2. Work on one side only (isolated)
```
cd backend && claude     # only Spring Boot agents/skills load
cd frontend && claude     # only React agents/skills load
```

### 3. Ship a full-stack feature
From the root: `/new-feature "<description>"`. A **root session plans and hands off — it never edits
code**: it writes a self-contained prompt into `backend/prompt-base/` and/or `frontend/prompt-base/`,
runs `/contract-sync` so the types/OpenAPI stay aligned, and tells you what to run. You then `cd` into
each side, launch Claude, and apply its prompt — that side's isolated team does the edits.
(`prompt-base/` is gitignored — prompts never reach GitHub. See the `prompt-handoff` skill.)

### 4. Keep the API contract honest
`/contract-sync` (root) is the antidote to FE↔BE drift: it diffs the backend's OpenAPI against the
frontend's API client/types and reports or fixes mismatches. `contract-testing` (Pact) verifies
*behavior* on top; `realtime-contract` (AsyncAPI) covers WebSocket/SSE/events. `/api-coverage`
(report-only) checks the third axis — **completeness + audience**: every endpoint declares an
`x-audience` (`frontend`/`external`/`internal`/`webhook`/`admin`), and the audit flags any **frontend**
endpoint the SPA doesn't consume (and any external endpoint it shouldn't).

### 5. Test every change as a running system
```
/redeploy --backend     # db + backend up, smoke the API
/redeploy --frontend    # UI + a Prism mock of the contract (no real backend)
/redeploy --full        # whole stack; smoke the FE↔BE seam — run before merge
```
Each `/redeploy` rebuilds the changed images, waits for healthchecks, and smoke-tests — the running
system is the proof. Three compose files keep blast radius small (per-side) or complete (root).

### 6. Release & deploy
`/ship` prepares + verifies a release (versions, changelog, gates, local `--full` smoke). `/deploy <env>`
runs the verified digest to a remote with a disk guard, one-service-at-a-time, **post-deploy health
verify**, and a ready rollback. Both are explicit, approval-gated.

---

## Model strategy (cost ↔ capability)

| Tier | Used by | Rationale |
|---|---|---|
| **opus** | architects, planner, security auditors, code/adversarial reviewers, performance, design-system enforcer, a11y | hard reasoning, cross-cutting judgment, adversarial review |
| **sonnet** | implementation engineers (react, spring-boot, api, jpa, tests, build, data, observability) + contract/coverage/release coordinators | strong code generation at lower cost |
| **haiku** | deterministic generation (the db-migration engineer) | fast and inexpensive |

Each agent declares its own `model:` in frontmatter, so the right tier is used automatically.

---

## Adapting the template

- **Different frontend framework?** Swap the `frontend/.claude` skills (the *patterns* in
  `react-patterns`, `data-fetching`, etc.). The team structure stays the same.
- **Maven instead of Gradle?** Edit `backend/.claude/skills/gradle-build` and the
  `backend-build-engineer`. (This template defaults to **Gradle**, matching the reference repo.)
- **Add a service?** Create a new sibling folder with its own `.claude/` — it's automatically
  isolated, and the root orchestrator can coordinate it.

See `docs/ARCHITECTURE.md` for the full design rationale and the discovery-semantics deep dive, and
`docs/DECISIONS.md` for the ADR log (the *why* behind every major choice). Run `/doctor` first to
confirm your toolchain.
