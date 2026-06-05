---
description: Add a REST endpoint to the backend, contract-first, with validation, ProblemDetail errors, tests, and an updated OpenAPI spec.
argument-hint: <METHOD /api/v1/resource — purpose>
---

Add this endpoint, contract-first: $ARGUMENTS

1. **Contract** (`api-designer`, read the `rest-api-design` skill): path under `/api/v1`, request/response **records**, status codes, validation, `ProblemDetail` mapping, springdoc annotations.
2. **Implement** (`spring-boot-engineer`): thin controller → service → (delegate persistence to `jpa-persistence-engineer` if it touches the DB). Constructor injection, `@Valid`, no entity leakage.
3. **Test** (`backend-test-engineer`): web slice + integration test, **positive and negative** (validation 400 with `violations`, conflict 409 **with message**, auth 401/403).
4. **Spec**: regenerate + commit `openapi.json`; note the change for `/contract-sync` so the frontend client updates.
5. **Review** (`backend-code-reviewer`): resolve Criticals.

Done when tests are green and the endpoint returns DTOs + `ProblemDetail` errors with messages.
