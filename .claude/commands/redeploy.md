---
description: Rebuild and bring up the local docker stack and smoke-test it — the instant local verify loop after a feature or fix.
argument-hint: [--full | --backend | --frontend]   (default: --full)
disable-model-invocation: true
allowed-tools: Read, Bash(docker compose:*), Bash(docker:*), Bash(curl:*), Bash(cd backend && docker compose:*), Bash(cd frontend && docker compose:*)
---

Bring up the local stack and prove it works. Read the `local-stack` skill. Scope: $ARGUMENTS (default `--full`).

## Pick the compose file by scope
- `--backend` → `cd backend && docker compose -f compose.yaml up -d --build` (db + backend on :8080/:9090).
- `--frontend` → `cd frontend && docker compose -f compose.yaml up -d --build` (frontend + Prism mock of `../backend/openapi.json`).
- `--full` (default) → root `docker compose -f compose.yaml up -d --build` (db + backend + frontend).

## Steps
1. **Disk guard first:** `docker system df`; prune *dangling* only if low (`docker image prune -f`) — never `prune -a` blind.
2. **Up with `--build`** so changed code is rebuilt. Wait for all healthchecks to report healthy (poll, with a timeout).
3. **Smoke** (Step 2 already waited for healthchecks; these add a host-level probe):
   - `--backend` only (it publishes 8080/9090): `curl -fsS localhost:9090/actuator/health/readiness` → UP, and the API on `:8080`.
   - `--frontend`/`--full`: `curl -fsS localhost:8080/` → 200; a deep link falls back to `index.html`. (In `--full` the backend has **no published host port** — reach it only through the frontend's `/api` proxy, below, or `docker compose exec backend …`.)
   - `--full`: hit one real endpoint **through the frontend's `/api` proxy** (`curl -fsS localhost:8080/api/v1/…`) to prove the FE↔BE seam.
4. **Report** pass/fail per service. On any failure: print `docker compose logs --tail=50 <svc>` and **stop — do not declare the change done**.

## Rules
- This is the **close-the-loop** step: a feature/fix isn't done until the narrowest stack covering it is green, and `--full` is green before merge.
- If a Dockerfile/port/env/dependency changed, the side's compose **and** the root compose must already be updated (they can't drift) — fix that first.
- `docker compose down` between unrelated runs; `down -v` to reset the DB. Local only — never touches a remote target (that's `/deploy`).
