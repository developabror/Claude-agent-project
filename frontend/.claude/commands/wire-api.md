---
description: Generate the typed frontend API client (types + axios client + TanStack Query hooks + MSW) from the backend OpenAPI spec.
argument-hint: [path to backend openapi.json] (default: ../backend/openapi.json)
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash(npx orval:*), Bash(npx openapi-typescript:*), Bash(git diff:*)
---

Generate/refresh the typed API client from the backend contract. Spec: $ARGUMENTS (default `../backend/openapi.json`). Read the `api-contract` and `data-fetching` skills. Delegate to `data-state-engineer`.

1. Ensure `orval.config.ts` points `input → ../backend/openapi.json`, `output → src/lib/api/generated/` (types + typed axios client + TanStack Query hooks + MSW handlers). Set `output.override.mutator: { path: './src/lib/api-client.ts', name: 'api' }` so the generated calls go through the **shared** axios instance (with the auth/refresh interceptors) instead of a fresh `axios`. If `orval.config.ts` is absent, create it.
2. Run `npx orval` (or `npx openapi-typescript ../backend/openapi.json -o src/lib/api/generated/schema.ts` for types-only).
3. Confirm the generated client uses the **shared axios instance** (auth/refresh interceptors), not a fresh one.
4. **Commit** the generated files — they are the contract artifact, not throwaway. Never hand-edit them.

Hard rule: types flow **from the backend spec**. If the frontend "needs" a shape the spec doesn't have, fix the backend (`api-designer`) and regenerate — don't hand-write it. Then `git diff` should be clean on a re-run (the drift gate).
