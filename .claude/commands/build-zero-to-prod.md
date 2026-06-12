---
description: Bootstrap this template from empty to a deployable, tested, containerized full-stack app (Spring Boot + React), wiring both sides via the API contract.
argument-hint: [product brief — name, domains, auth model] (optional; will ask if omitted)
disable-model-invocation: true
---

You are the **main-thread conductor** for a 0→production build, running in a **root session**. Follow the `zero-to-prod` skill as the master sequence. Brief: $ARGUMENTS

> **Scope note (read first):** a root session **plans and hands off — it does not edit code** (see
> `prompt-handoff`). You can't invoke the child `/scaffold-*` commands or child subagents from root
> (they load only inside each side). So the root produces **prompts**, the user **applies them per side**:
> for each side, write a scaffold prompt into `<side>/prompt-base/`, then the user `cd`s in
> (`cd backend && claude` → apply it / run `/scaffold-backend`) to run that side's specialists. The root
> session owns only planning + the contract codegen + the compose files.

0. **Preflight.** Run `/doctor` — confirm Docker+Compose, Java 21, Node 20+, npm, git. Fix any FAIL before going further (don't scaffold against a broken toolchain).

1. **Confirm the brief.** If $ARGUMENTS is thin, delegate to `product-planner` (a root agent) or ask 2–3 crisp questions: product name, base package, core domains/entities, auth model (external IdP vs local), first endpoints. **Define the FE↔BE contract seam before building either side.**

2. **Backend 0→prod.** Write `backend/prompt-base/010-scaffold-backend.md` (the `BACKEND-SETUP.md` playbook as a self-contained prompt). The user applies it from a backend session (`/scaffold-backend`); it ends with springdoc emitting and committing `backend/openapi.json`.

3. **Contract.** Run `/contract-sync` (a root command — codegen is allowed from root) to generate the frontend API client from `backend/openapi.json`.

4. **Frontend 0→prod.** Write `frontend/prompt-base/020-scaffold-frontend.md` (the `FRONTEND-SETUP.md` playbook), with the data layer consuming the **generated** client. The user applies it from a frontend session (`/scaffold-frontend`).

5. **Compose the system.** Create/verify the three compose files (see `local-stack`): root `compose.yaml` (db + backend + frontend), `backend/compose.yaml`, `frontend/compose.yaml`. Copy `.env.example` → `.env`.

6. **Verify (running system).** Both gates green (`./gradlew build`, `npm run validate`), contract gate green (OpenAPI + Pact), then **`/redeploy --full`** brings the whole stack up healthy and a smoke E2E hits the backend **through the frontend's `/api` proxy**. Show the evidence — production-ready means the running system passed, not the build log.

## Rules
- Match depth to the brief — start with the smallest layout that holds; don't scaffold unrequested features.
- Use **plan mode** before large steps. Each step closes with a runnable check, not an assertion.
- Stop and report if any gate is red; never declare "production ready" without green evidence.
- Do **not** push images or deploy — that's the explicit, approved `/ship` step.
