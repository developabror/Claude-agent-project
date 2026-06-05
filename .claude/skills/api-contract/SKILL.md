---
name: api-contract
description: Use when changing anything that crosses the frontend↔backend boundary — endpoints, DTO shapes, status codes, the error envelope, pagination, or auth headers. Defines the shared contract (RFC 9457 ProblemDetail, /api/v1, capped pagination) and the OpenAPI-as-source-of-truth codegen pipeline (springdoc → openapi.json → Orval/openapi-typescript) plus the CI drift gate. The anti-drift contract both sides obey.
---

# API Contract (the FE↔BE source of truth)

The backend's **OpenAPI spec is the contract**. The frontend's client is **generated** from it.
Drift between the two is the single most common full-stack bug class — this pipeline makes it
impossible to merge drift unnoticed.

## The shared shape (both sides MUST agree)
- **Paths**: plural nouns under `/api/v1/`. Versioned. No verbs.
- **Errors**: RFC 9457 `ProblemDetail` (`application/problem+json`) — always a human-readable
  `message`/`detail`, a stable `errorCode`, and `violations[]` for validation. **A 4xx/409 with no
  message is a contract violation** (a frontend that suppresses toasts will silently drop it).
- **Pagination**: `{ content, page, size, totalElements, totalPages }` — never a bare array.
- **Status codes**: 201+Location on create, 204 on delete, 409+message on conflict, 400 with `violations` on validation. (Full table in the backend `rest-api-design` skill.)
- **Auth**: `Authorization: Bearer <jwt>` (or the project's opaque API-key/token header) — documented in the spec's `securityScheme`.

## The codegen pipeline (source of truth → generated client)
```
backend (springdoc)  ──► backend/openapi.json  ──►  frontend/src/lib/api/generated/
   /v3/api-docs            (committed = truth)        types + axios client + Query hooks (Orval)
```

**1. Emit the spec (backend):**
```bash
# build-time generation (preferred — no running server):
./gradlew clean generateOpenApiDocs   # springdoc-openapi-gradle-plugin → build/openapi.json
cp api/build/openapi.json ./openapi.json   # commit this
# or from a running app: curl localhost:8080/v3/api-docs > openapi.json
```

**2. Regenerate the client (frontend):**
```bash
# orval.config.ts points input → ../backend/openapi.json, output → src/lib/api/generated
npx orval        # types + typed axios client + TanStack Query hooks (+ MSW handlers)
# or, types only:
npx openapi-typescript ../backend/openapi.json -o src/lib/api/generated/schema.ts
```

**3. Gate drift in CI (both sides):**
```bash
# regenerate → copy to the committed path → fail if anything changed but wasn't committed
# (generateOpenApiDocs writes to build/, so copy to the committed openapi.json before diffing)
./gradlew clean generateOpenApiDocs && cp api/build/openapi.json openapi.json && git diff --exit-code openapi.json
npx orval && git diff --exit-code frontend/src/lib/api/generated
```

## Rules
- **Never hand-edit generated files** — change the backend annotations and regenerate.
- A removed/renamed field or changed status code is **breaking** → version (`/api/v2`) or deprecate; never silently reshape `/api/v1`.
- Generated MSW handlers keep frontend tests honest to the real contract — regenerate them too.
- `/contract-sync` (root command) and the `api-contract-guardian` agent run this pipeline end to end.
