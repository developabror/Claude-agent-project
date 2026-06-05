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

## Commit & push policy (STRICT)
The boundary is **local commit vs. remote push**. Local is automatic; remote is always confirmed.

1. **Finalize → local commit, always.** When a change is finalized (gates green, smoke passed), create
   a local commit with a conventional-commit message. No confirmation needed — it never leaves the machine.
   ```bash
   git add -A && git commit -m "feat(orders): …"   # local only
   ```
2. **Never push without an exact instruction.** Do **not** run `git push`, `git push --tags`,
   `docker push`, or any publish — to a git remote or **Docker Hub** — unless the developer says so for
   *this* change. "Looks done" is never a reason to push. Default = local only.
3. **On confirmation, ask the target: git, Docker, or both.** Act only on what's named.
   - **git** → `git push` (+ `git push --tags` if releasing).
   - **Docker** → tag the image **at confirm time** with **git-sha + semver**, then `docker push` (never `latest` alone).
   - **both** → only when the developer says both.
4. These actions are permission-gated to **`ask`** (the harness prompts) as a backstop — but the prompt
   is not the trigger; the instruction is.

## Hygiene
- Never commit secrets, `.env`, build output, or generated files that aren't meant to be committed (the generated **API client** and `openapi.json` ARE committed — they're the contract).
- Never force-push shared branches or `git reset --hard` on `main`.
- Commit messages and PR bodies are written for the next engineer (and the changelog) — be specific.
