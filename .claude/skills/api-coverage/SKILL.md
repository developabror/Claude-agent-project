---
name: api-coverage
description: Use to audit frontend API coverage and endpoint audience — classify every backend endpoint by x-audience (frontend/external/internal/webhook/admin) and check that every frontend-audience endpoint is actually consumed in the React app (and that external/webhook ones are not). Read before running /api-coverage or when designing an endpoint's audience. Report-only — surfaces gaps, does not block the build.
---

# API Coverage & Endpoint Audience

Answers two questions the shape (`api-contract-guardian`) and behavior (`contract-testing`/Pact) checks don't:
1. Is every endpoint the **frontend should call** actually wired up in the FE?
2. Which endpoints are **for the frontend** vs **external / internal / webhook / admin** — so coverage is measured against the right subset (not every endpoint should be FE-covered).

## Audience taxonomy — `x-audience` in the OpenAPI spec
Every operation declares its audience via the OpenAPI extension **`x-audience`** (an array — an op may
serve more than one). The spec is the single source of truth; `api-designer` sets it **at design time**.

| `x-audience` | Who calls it | FE-coverage required? | Extra rigor it must meet |
|---|---|---|---|
| `frontend` | the React SPA | **yes** | — |
| `external` | third-party servers / partners | no | versioned, API-key/OAuth client-credentials, rate-limited, documented, stable |
| `internal` | service-to-service (same system) | no | network-restricted, not publicly routable |
| `webhook` | inbound calls **from** third parties | no | signature verification, idempotent, replay-safe |
| `admin` | internal admin tooling only | only if an admin UI exists | strong authz, audited |

```yaml
paths:
  /api/v1/orders:            { get:  { operationId: listOrders,        x-audience: [frontend] } }
  /api/v1/partner/orders:    { post: { operationId: ingestPartnerOrder, x-audience: [external] } }
  /webhooks/payment:         { post: { operationId: paymentWebhook,     x-audience: [webhook] } }
```
- **Untagged = unknown** → the audit flags it. There is **no silent default**: "is this for the FE?" must be an explicit decision.

## Coverage check — how it's computed
1. Parse `backend/openapi.json` → every operation (`operationId`, method, path, `x-audience`).
2. Map each `frontend` op to its **generated client artifact** (Orval names the hook/fn by `operationId`, e.g. `useListOrders`). Grep `frontend/src/**` for a real import/use of it.
3. Classify:
   - `frontend` + used → **covered** ✓
   - `frontend` + never used → **UNCOVERED** (gap)
   - `external`/`internal`/`webhook`/`admin` → **out of FE scope** (must NOT appear in FE call sites)
   - untagged → **UNCLASSIFIED**
4. Reverse check — grep FE call sites (generated hooks + any raw `api.get('/…')`) and flag:
   - **phantom** — a path the FE calls that isn't in the spec (hand-rolled / drift), and
   - **leak** — a non-`frontend` endpoint the FE is actually calling (audience violation).

## Report (report-only — does NOT block the build)
```
frontend    : 18 covered · 2 UNCOVERED → createReport, exportCsv
external    : 5  (ok — out of FE scope)
webhook     : 2  (ok)
unclassified: 1  → classify: POST /api/v1/legacy/ping
phantom     : 1  → FE calls GET /api/v1/health (not in spec)
leak        : 0
```
Plus the actionable list. This is **advisory** — it surfaces gaps for the developer; it does not fail
CI. (Promote to a gate later if you choose.) Re-run with `/api-coverage`.

## Rules
- An endpoint's audience is a **design decision recorded in the spec** — never inferred. New endpoint → set `x-audience`.
- An **UNCOVERED frontend** endpoint has two valid fixes: **wire it in the FE**, or **re-classify it** (it wasn't really for the FE).
- `external`/`webhook` endpoints are intentionally **not** FE-covered — never "fix" coverage by calling them from the FE (that's a leak).
