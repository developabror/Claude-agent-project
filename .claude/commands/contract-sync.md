---
description: Reconcile the FE↔BE API contract — regenerate the frontend client from the backend OpenAPI spec and report/fix any drift.
argument-hint: [--check | --fix]   (default: --check)
disable-model-invocation: true
allowed-tools: Read, Edit, Grep, Glob, Bash(./gradlew:*), Bash(cd backend && ./gradlew:*), Bash(npx orval:*), Bash(npx openapi-typescript:*), Bash(git diff:*), Bash(curl:*)
---

Run the API contract pipeline (see the `api-contract` skill). Delegate to `api-contract-guardian`. Mode: $ARGUMENTS (default `--check`).

## Steps
1. **Emit the spec** from the backend: `cd backend && ./gradlew generateOpenApiDocs` (or boot + `curl :8080/v3/api-docs`). Write/diff `backend/openapi.json`.
2. **Regenerate the frontend client** from that spec: `cd frontend && npx orval` (or `openapi-typescript`) → `frontend/src/lib/api/generated/`.
3. **Report drift** as a table: endpoint/field → backend says → frontend expects → breaking? → fix.
4. Mode:
   - `--check` (default): run codegen and `git diff --exit-code` the generated files + `openapi.json`. Drift = non-zero exit; report it and STOP (this is the CI gate).
   - `--fix`: commit the regenerated `openapi.json` and frontend client; **never hand-edit generated files**. For breaking backend changes, recommend `/api/v2` or a deprecation, not a silent reshape.

## Output
`IN-SYNC` or `DRIFT` with the exact regeneration command and, if `--fix`, the resulting diff + the now-green gate. Confirm the error envelope (`ProblemDetail` with a message), pagination shape, and 409-with-message all agree on both sides.
