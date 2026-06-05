---
description: Audit frontend API coverage + endpoint audience — report which frontend endpoints are uncovered, which are unclassified, and any phantom/leak calls. Read-only, report-only (no build gate).
argument-hint: [path to openapi.json] (default: backend/openapi.json)
allowed-tools: Read, Grep, Glob, Bash(python3:*), Bash(jq:*), Bash(grep:*), Bash(rg:*)
---

Run the API coverage + audience audit (run this from the **repo root** — it needs both subtrees). Delegate to `api-coverage-auditor`; read the `api-coverage` skill. Spec: $ARGUMENTS (default `backend/openapi.json`).

1. Parse the spec → operations grouped by **`x-audience`** (frontend / external / internal / webhook / admin; untagged = **unclassified**).
2. For each `frontend` op, check its generated hook/fn (named by `operationId`) is actually used in `frontend/src/**`.
3. Reverse-check FE call sites for **phantom** paths (not in the spec) and **leaks** (FE calling a non-`frontend` endpoint).
4. Print the **coverage matrix** + the actionable gap list + a PASS / REVIEW verdict.

**Report-only:** this surfaces gaps for you to act on — it does **not** fail the build. (Promote to a CI gate later if you want.) Fixes for an UNCOVERED frontend endpoint: **wire it** in the FE, or **re-classify** its `x-audience`. Never "cover" an `external`/`webhook` endpoint from the FE.
