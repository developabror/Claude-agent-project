---
description: Deliver a full-stack feature end-to-end across backend and frontend, contract-first, with reviews as the closing gate.
argument-hint: <feature description>
---

Deliver this feature across both sides, **contract-first**: $ARGUMENTS

Follow the `monorepo-workflow` skill. Orchestrate from the main thread (subagents can't nest).

> **Scope note:** this is a **root** session, so the per-side *specialist subagents* named below are
> **not loaded here** (agents only walk UP from cwd). Root keeps planning + contract; run each
> side's specialist chain by launching a session in that folder (`cd backend && claude`,
> `cd frontend && claude`), or — for a single session — let the main thread do the slice itself using
> that side's skills, which **do** load on demand at the root.

## Sequence
1. **Plan (root).** Delegate to `product-planner` (a root agent) → spec + the **contract seam** (endpoints/DTOs) + a per-side task list. Confirm scope before coding.
2. **Backend slice** (in a `backend/` session, or main-thread direct): `backend-architect` → `api-designer` (define endpoints + commit `openapi.json`) → `jpa-persistence-engineer`/`db-migration-engineer` → `spring-boot-engineer` → `backend-test-engineer` → `spring-security-engineer` if auth-touching → `backend-code-reviewer`.
3. **Sync the contract (root):** run `/contract-sync` so the frontend client regenerates from the new spec.
4. **Frontend slice** (in a `frontend/` session, or main-thread direct): `frontend-architect` → `data-state-engineer` (use the generated client) → `react-engineer` → `frontend-test-engineer` → `accessibility-auditor`/`web-performance-engineer`/`frontend-security-auditor` as relevant → `frontend-reviewer`.
5. **Verify:** both gates green + contract gate green; show the evidence.

## Rules
- The contract seam is fixed **before** either side implements against it. Backend and frontend slices may then proceed in parallel only if they touch disjoint files.
- Close with the adversarial reviewers (`backend-code-reviewer`, `frontend-reviewer`) in fresh context; resolve every Critical before done.
- Reserve multi-agent fan-out for genuinely parallel work — it's ~15× the tokens of a single pass.
