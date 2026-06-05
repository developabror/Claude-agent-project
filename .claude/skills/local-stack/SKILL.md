---
name: local-stack
description: Use whenever a feature or fix needs to be tested as a running system — defines the three-tier docker-compose layout (root compose.yaml = full stack; backend/compose.yaml and frontend/compose.yaml = one-side test deploys) and the "redeploy locally on every change" loop. Read before editing any compose file or running /redeploy.
---

# Local Stack (compose orchestration + instant local redeploy)

Every change is proven by **bringing the system up locally and smoke-testing it** — not by assertion.
There are three compose files, each for a different blast radius:

| File | Brings up | Use after a change to… | Command |
|---|---|---|---|
| `compose.yaml` (root) | **db + backend + frontend** (full stack) | anything that crosses the seam, or before declaring done | `/redeploy --full` |
| `backend/compose.yaml` | **db + backend** (API exposed on :8080) | backend only — fast inner loop | `/redeploy --backend` |
| `frontend/compose.yaml` | **frontend + a Prism mock of `backend/openapi.json`** | frontend only — no real backend needed | `/redeploy --frontend` |

## The redeploy-on-change loop (the contract)
After **every feature or fix**:
1. Redeploy the **narrowest** stack that covers the change (`--backend` or `--frontend`) → smoke it.
2. Before calling the change done, redeploy the **`--full`** stack → run the cross-seam smoke (frontend reaches backend through the contract).
3. `/redeploy` rebuilds the changed images (`docker compose up -d --build`), waits for **healthchecks**, then runs the smoke checks and reports. Red healthcheck or smoke = not done.

This is `/verify` for a full-stack app: the running system is the proof.

## Layout rules (keep the three files consistent)
- **Root `compose.yaml`** is the source of truth for the full stack. The frontend (nginx) reaches the backend by **proxying `/api` → `backend:8080`** (same-origin, no CORS in local). `db` is only on the `backend` network; `frontend` only on the `frontend` network; `backend` bridges both (network segmentation).
- **`backend/compose.yaml`** = `db` + `backend`, with `8080`/`9090` published so you can curl the API/actuator directly. Same env/healthcheck as root.
- **`frontend/compose.yaml`** = `frontend` + a `mock-api` (`stoplight/prism mock /openapi.json`) so the UI runs against the **contract**, not a live backend — catches drift early and lets FE devs work offline.
- Every service has a **healthcheck** and `depends_on: condition: service_healthy`. Secrets/config come from `.env` (copy `.env.example`), never hard-coded.
- When a side's Dockerfile, port, env, or a new dependency (e.g. Redis) changes, the owning **build-engineer regenerates that side's compose AND the root compose** in the same change — they must not drift.

## Smoke checks (`/redeploy` runs these)
- `db` healthy → `backend` `/actuator/health/readiness` UP → `frontend` serves `/` (200) and a deep link falls back to `index.html`.
- Full stack: hit one real endpoint **through the frontend's `/api` proxy** to prove the seam.
- On failure: print the failing service's `docker compose logs --tail=50` and stop — do not declare done.

## Hygiene
- `docker compose down` (keep volumes) between unrelated runs; `down -v` to reset the DB.
- Guard disk before building (`docker system df`; prune dangling, never `prune -a` blind) — a full disk crash-loops the box.
- These files build from each side's Dockerfile (created by `/scaffold-*`); they run once those exist.
