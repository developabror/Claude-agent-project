---
name: git-workflow
description: Use for version control across the monorepo — conventional commits, branching, semantic versioning, PR etiquette, and the per-side release bumps. Defines commit message format (feat/fix/...), trunk-based branching, semver derivation, and what each PR must include before merge.
---

# Git Workflow

Shared conventions for both `frontend/` and `backend/`.

## Conventional Commits (drives changelogs + semver)
```
<type>(<scope>): <summary>

<body — what & why, not how>

BREAKING CHANGE: <description>     # or a ! after the type/scope: feat(api)!: ...
```
Types: `feat` (→ MINOR), `fix` (→ PATCH), `perf`, `refactor`, `docs`, `test`, `build`, `ci`, `chore`.
Scope is the area (`api`, `orders`, `auth`, `ui`). `!` or `BREAKING CHANGE` → MAJOR.

## Branching (trunk-based)
- Short-lived branches off `main`: `feat/<scope>-<slug>`, `fix/<scope>-<slug>`.
- Rebase to keep history linear; squash-merge so each PR is one conventional commit on `main`.
- `main` is always releasable (green gates).

## Semantic versioning (per side, independent)
- Derive the bump from commits since the last tag: any `feat` → MINOR, only `fix`/`perf` → PATCH, any breaking → MAJOR.
- Backend additionally follows the project's PATCH-bump-on-each-generated-version rule. Frontend bumps `package.json`.
- Tag per side: `backend-vX.Y.Z`, `frontend-vX.Y.Z` (or a unified tag if you release in lockstep).

## Every PR must include
- [ ] Green gates: backend `./gradlew build`, frontend `npm run validate`
- [ ] If the API changed: regenerated `openapi.json` + frontend client committed, contract gate green
- [ ] Tests for new behavior (positive + negative)
- [ ] A reviewer pass (`backend-code-reviewer` / `frontend-reviewer`) and, if security-sensitive, an auditor pass
- [ ] Conventional-commit title; updated docs/CHANGELOG where required

## Hygiene
- Never commit secrets, `.env`, build output, or generated files that aren't meant to be committed (the generated **API client** and `openapi.json` ARE committed — they're the contract).
- Never force-push shared branches or `git reset --hard` on `main`.
- Commit messages and PR bodies are written for the next engineer (and the changelog) — be specific.
