---
description: Deliver a full-stack feature end-to-end across backend and frontend, contract-first, with reviews as the closing gate.
argument-hint: <feature description>
---

Deliver this feature across both sides, **contract-first**: $ARGUMENTS

Follow the `monorepo-workflow` skill. Orchestrate from the main thread (subagents can't nest).

> **Scope note:** this is a **root** session — it **plans and hands off, it does not edit code** (see
> `prompt-handoff`). The per-side specialists aren't loaded here. Root writes the slice **prompts** into
> `<side>/prompt-base/`; the user applies them from inside each side (`cd backend && claude`, etc.).

## Sequence
1. **Plan (root).** Delegate to `product-planner` (a root agent) → spec + the **contract seam** (endpoints/DTOs + `x-audience`) + a per-side task list. Confirm scope before writing prompts.
2. **Backend prompt** → `backend/prompt-base/<NNN>-<slug>.md`: delegate order `backend-architect` → `api-designer` (define endpoints + commit `openapi.json`) → `jpa-persistence-engineer`/`db-migration-engineer` → `spring-boot-engineer` → `backend-test-engineer` → `spring-security-engineer` if auth-touching → `backend-code-reviewer`. User applies it from a backend session.
3. **Sync the contract (root):** run `/contract-sync` so the frontend client regenerates from the new spec.
4. **Frontend prompt** → `frontend/prompt-base/<NNN>-<slug>.md`: `frontend-architect` → `data-state-engineer` (use the generated client) → `react-engineer` → `frontend-test-engineer` → `accessibility-auditor`/`web-performance-engineer`/`frontend-security-auditor` as relevant → `frontend-reviewer`. User applies it from a frontend session.
5. **Verify (gates):** after the user applies both prompts — both gates green + contract gate green (OpenAPI **and** Pact) + `/redeploy --full`; show the evidence.
6. **Redeploy & smoke locally (mandatory):** `/redeploy` the narrowest stack that covers the change (`--backend`/`--frontend`), then `/redeploy --full` and smoke the seam. The running system is the proof — not done until it's green.

## Apply the relevant guards (per the change)
- Touches a business invariant ("must never happen") → add a **DB constraint + a rejecting/property test** (`jpa-patterns`/`backend-testing`).
- Risky or incomplete → ship behind a **feature flag** (`feature-flags`), test both branches, schedule its removal.
- Touches realtime/events → update `asyncapi.yaml` and both sides (`realtime-contract`), not just REST.
- New/changed endpoint → set its **`x-audience`**; if `frontend`, wire **and** cover it in the SPA; run `/api-coverage` (report) to confirm no uncovered/unclassified/phantom/leak (`api-coverage`).
- Every API error path is **surfaced** in the UI and covered by a test (`frontend-testing`); the request carries a `traceId` end-to-end (`observability`).

## Rules
- The contract seam is fixed **before** either side implements against it. Backend and frontend slices may then proceed in parallel only if they touch disjoint files.
- Close with the adversarial reviewers (`backend-code-reviewer`, `frontend-reviewer`) in fresh context; resolve every Critical before done.
- Reserve multi-agent fan-out for genuinely parallel work — it's ~15× the tokens of a single pass.
