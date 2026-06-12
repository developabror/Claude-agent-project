# Architecture Decision Records (ADRs)

The *why* behind this template — so the reasoning survives the people. Each entry is intentionally
short: the decision, why, and its status. **Add a new ADR** (don't rewrite an old one) when a decision
changes — supersede it and note which number it replaces.

Format: `## NNN. Title` · **Decision** · **Why** · **Status** (Accepted / Superseded by NNN).

---

## 001. Monorepo with sibling isolation
**Decision:** one tree — `backend/` and `frontend/` as siblings under a root control plane, each with its own `.claude/`.
**Why:** Claude Code discovery is asymmetric (agents/commands walk up; skills/CLAUDE.md also load from descendants; settings cwd-only). Siblings sit outside each other's subtree *and* ancestor chain, so opening one side never loads the other — isolation is structural, not configured. One tree also makes a contract change one PR, not two (kills cross-repo drift). See `docs/ARCHITECTURE.md`.
**Status:** Accepted.

## 002. Orchestration lives in the main thread, not in "orchestrator" subagents
**Decision:** no orchestrator subagents; coordination is slash commands + CLAUDE.md delegation tables.
**Why:** subagents cannot spawn subagents. An "orchestrator agent" with `tools: Agent(...)` can't actually delegate. The main thread is the only orchestrator.
**Status:** Accepted.

## 003. Root sessions are prompt-only (prompt-handoff)
**Decision:** a root session plans and writes implementation prompts into `<side>/prompt-base/`; the user applies them from inside each side. Root never hand-edits source. `prompt-base/` is gitignored.
**Why:** keeps implementation inside the isolated team that owns it (right agents/skills loaded), and keeps the working prompts out of version control. Allowed-from-root exceptions: read-only audits, contract codegen, release/version edits.
**Status:** Accepted.

## 004. Backend stack: Java 21 · Spring Boot 3.4 · Gradle (not Maven)
**Decision:** Gradle multi-module (`common/domain/infra/service/api`), Java 21, no Lombok.
**Why:** matches the reference project's real build; convention plugin declares the toolchain/versions once; `api` vs `implementation` scoping speeds incremental builds. Records + virtual threads remove most Lombok needs.
**Status:** Accepted.

## 005. Frontend stack: React 18 · TypeScript (strict) · Vite
**Decision:** Vite + strict TS, React Router v7 data mode, TanStack Query (server state), Zustand (client), RHF+zod (forms), Tailwind v4 + shadcn/ui, Vitest/RTL/MSW + Playwright.
**Why:** the user delegated the framework choice; this is the mid-2026 mainstream SPA stack and aligns with a separate Spring Boot API.
**Status:** Accepted.

## 006. OpenAPI is the contract source of truth; client is generated
**Decision:** springdoc emits `openapi.json` (committed); the frontend client is generated from it (Orval). Never hand-edit generated files; a `git diff --exit-code` gate catches drift.
**Why:** the recurring full-stack bug class is FE↔BE drift. Generating from one source makes shape drift un-mergeable.
**Status:** Accepted.

## 007. Three contract axes, kept distinct
**Decision:** shape = OpenAPI codegen (`api-contract`); behavior = Pact (`contract-testing`); completeness + audience = `api-coverage`; async = AsyncAPI (`realtime-contract`).
**Why:** each catches a different failure. Codegen can't catch a behavior change; Pact can't catch an endpoint the FE forgot to call; OpenAPI doesn't cover sockets.
**Status:** Accepted.

## 008. Endpoint audience via `x-audience`; coverage is report-only
**Decision:** every operation declares `x-audience: [frontend|external|internal|webhook|admin]` in the spec; `/api-coverage` reports uncovered/unclassified/phantom/leak but does **not** block the build.
**Why:** not every endpoint is for the SPA — classifying first prevents external/webhook endpoints from false-flagging as "uncovered." Report-only chosen by the owner to keep it advisory.
**Status:** Accepted.

## 009. Errors: RFC 9457 ProblemDetail; the human-readable field is `detail`
**Decision:** one `@RestControllerAdvice` → `ProblemDetail` with a stable `errorCode` and a mandatory human-readable `detail` (+ `violations`). A 4xx/409 with no `detail` is a contract violation.
**Why:** RFC field is `detail`, not `message` — naming it consistently prevents the FE from reading the wrong key. A frontend that suppresses toasts must still receive the text.
**Status:** Accepted.

## 010. Security: stateless OAuth2 resource server; non-JWT on a second filter chain
**Decision:** explicit `SecurityFilterChain`, `STATELESS`, deny-by-default, JWT validated via `issuer-uri`; opaque/API-key auth gets its own `@Order`ed filter chain. Tokens in HttpOnly cookies/memory, never `localStorage`.
**Why:** Security 6 removed `WebSecurityConfigurerAdapter`; delegating token issuance to an IdP is the 2026 norm; weakening the JWT chain to fit a second auth model is how leaks happen.
**Status:** Accepted.

## 011. Persistence: Flyway (forward-only) + Testcontainers (no H2)
**Decision:** schema owned by Flyway (`ddl-auto=validate`), migrations immutable/fix-forward, destructive changes two-step; integration tests use Testcontainers + `@ServiceConnection`, never H2.
**Why:** H2-as-Postgres hides dialect bugs; an editable migration breaks reproducibility; forward-only keeps code rollbacks safe.
**Status:** Accepted.

## 012. Invariants live in the schema, not service `if`s
**Decision:** every "must never happen" rule is a DB constraint (unique/check/`EXCLUDE`) backed by a rejecting/property test.
**Why:** service-layer checks are racy (TOCTOU) and get forgotten; a constraint can't be bypassed. (Directly targets the overlap/ordering bugs that recurred in the reference project.)
**Status:** Accepted.

## 013. Observability via Micrometer Observation + OTLP; traceId end-to-end
**Decision:** OTLP export (vendor-neutral), structured JSON logs, and a `traceId` propagated FE→BE→logs (and echoed in ProblemDetail non-prod).
**Why:** "the protocol matters, not the library." One `traceId` turns a user report into a single grep.
**Status:** Accepted.

## 014. Local-stack: three compose files + redeploy-on-every-change
**Decision:** root `compose.yaml` (full stack), `backend/compose.yaml`, `frontend/compose.yaml` (+ Prism mock of the contract). After any change, `/redeploy` the narrowest stack, then `--full` before merge.
**Why:** the running system is the proof, not the build log. Per-side stacks keep blast radius small; the Prism mock lets the FE run against the contract offline.
**Status:** Accepted.

## 015. Deploy + commit/push governance
**Decision:** deploys are digest-pinned, one-service-at-a-time, with post-deploy health verify and a ready rollback; never `latest`. **Finalize → local commit always; never push to git remote/Docker Hub without an exact instruction (then ask git/Docker/both); Docker tag = sha+semver at confirm time.** Enforced by `ask` permissions + CLAUDE.md + skills.
**Why:** an unverified deploy is an unmonitored outage; a full disk crash-loops the box (hence the disk guard). Pushes are irreversible/outward-facing, so they require explicit per-action consent.
**Status:** Accepted.

## 016. Model tiers per agent
**Decision:** opus = architecture/security/review/performance/planning; sonnet = implementation + contract/coverage/release coordination; haiku = deterministic generation (DB migrations).
**Why:** upgrading the model on judgment-heavy work beats more tokens; cheap mechanical work doesn't need opus. Aliases are portable; pin full IDs if a tier is load-bearing and an alias mis-resolves.
**Status:** Accepted.

## 017. Enforcement: hooks over prose
**Decision:** deterministic hooks (PreToolUse destructive-Bash guard, PostToolUse best-effort format, SessionStart team banner). A Stop test-gate is documented as opt-in, not wired.
**Why:** CLAUDE.md prose is followed ~70% of the time; hooks ~100%. The Stop gate is left off by default to avoid trapping turns before the suite is fast.
**Status:** Accepted.

## 018. Brand-neutral template
**Decision:** base package `com.example.app`, example domain `order`/`customer`, generic auth/error names — zero coupling to any source project.
**Why:** it's a reusable `project-template`, not one product's repo. Defaults are meant to be overridden.
**Status:** Accepted.
