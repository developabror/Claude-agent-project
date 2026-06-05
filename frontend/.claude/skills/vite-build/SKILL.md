---
name: vite-build
description: Use when working in frontend/ on the build/release lifecycle — Vite config, strict TypeScript, ESLint 9 flat config + Prettier + Husky, env handling, the multi-stage Node→nginx Dockerfile (non-root, SPA fallback), and GitHub Actions CI. Enforces strict TS, prettier-last lint config, runtime env injection, and immutable image tags.
---

# Vite Build, Tooling & Packaging

Reproducible builds, fast feedback, one image that runs in every environment.

## Scripts (package.json)
```jsonc
"scripts": {
  "dev": "vite", "build": "tsc -b && vite build", "preview": "vite preview",
  "typecheck": "tsc -b --noEmit",
  "lint": "eslint .", "lint:fix": "eslint . --fix",
  "format": "prettier --write .", "test": "vitest run",
  "validate": "npm run typecheck && npm run lint && npm run test"   // the gate
}
```

## Strict TypeScript (tsconfig)
Turn it all on: `strict`, `noUnusedLocals`, `noUnusedParameters`, `noImplicitReturns`,
`noFallthroughCasesInSwitch`, `exactOptionalPropertyTypes`, `verbatimModuleSyntax`. Path alias `@/* → src/*`.

## ESLint 9 flat config (`eslint.config.mjs`)
```js
import js from "@eslint/js";
import tseslint from "typescript-eslint";
import react from "eslint-plugin-react";
import hooks from "eslint-plugin-react-hooks";
import a11y from "eslint-plugin-jsx-a11y";
import importSort from "eslint-plugin-simple-import-sort";
import prettier from "eslint-config-prettier";

export default tseslint.config(
  js.configs.recommended,
  ...tseslint.configs.recommendedTypeChecked,
  { languageOptions: { parserOptions: { projectService: true } } },
  { files: ["**/*.{jsx,tsx}"], plugins: { react, "react-hooks": hooks, "jsx-a11y": a11y },
    rules: { ...hooks.configs.recommended.rules, ...a11y.configs.recommended.rules } },
  { plugins: { "simple-import-sort": importSort },
    rules: { "simple-import-sort/imports": "error" } },
  prettier,   // MUST be last — turns off formatting rules
);
```
Husky pre-commit → `lint-staged` (eslint --fix + prettier on staged files).

## Env handling
- Only `VITE_`-prefixed vars reach the client. `.env`, `.env.development`, `.env.production` committed; `.env.local` gitignored.
- `src/env.d.ts` augments `ImportMetaEnv`; `src/config/env.ts` **validates required vars at startup and fails fast**.
- **Build-once/run-anywhere**: inject runtime config via `window.__ENV__` written by the container entrypoint, so one image serves dev/staging/prod (don't bake API URLs into the bundle).

## Multi-stage Dockerfile → nginx (non-root)
```dockerfile
FROM node:24-slim AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:stable-alpine AS runtime
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
RUN addgroup -g 1001 web && adduser -D -u 1001 -G web web \
 && chown -R web:web /usr/share/nginx/html /var/cache/nginx /var/run
USER 1001
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:8080/ || exit 1
```
`nginx.conf` must `listen 8080;` (a non-root container can't bind port 80 — match the `EXPOSE`/`HEALTHCHECK` above), SPA-fallback `try_files $uri $uri/ /index.html;`, plus gzip/brotli + immutable cache headers on hashed assets. Add a `.dockerignore` (node_modules, dist, .git).

## CI (GitHub Actions)
Cached `npm ci` → `typecheck` → `lint` → `vitest --coverage` → `playwright` (cache browsers) →
`build` → buildx push tagged **sha + semver**. typecheck/lint/test are **required PR gates**. Never ship a `latest`-only tag to staging/prod.

## Lint rules that enforce "never swallow an error"
Add to the flat config so silent failures fail the build (pairs with `frontend-security`/`data-fetching`):
- `@typescript-eslint/no-floating-promises: "error"` — every promise is awaited or explicitly handled.
- `no-empty: ["error", { "allowEmptyCatch": false }]` — no empty `catch {}`.
- `@typescript-eslint/no-misused-promises: "error"`.
- `no-console: ["warn", { "allow": ["error", "warn"] }]` — don't ship debug logs.
