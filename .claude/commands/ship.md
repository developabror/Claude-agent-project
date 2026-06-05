---
description: Prepare and verify a coordinated release of both backend and frontend — version bumps, changelog, pre-flight gate. Does not push or deploy without explicit approval.
argument-hint: [major|minor|patch]   (default: derive from conventional commits)
disable-model-invocation: true
allowed-tools: Read, Edit, Bash(./gradlew:*), Bash(cd backend && ./gradlew:*), Bash(npm run:*), Bash(cd frontend && npm run:*), Bash(git:*), Bash(docker build:*)
---

Prepare a release. Delegate to `release-manager`. Bump hint: $ARGUMENTS (default: derive from commits).

## Pre-flight gate — refuse to proceed if any is red (show evidence)
- [ ] Backend `cd backend && ./gradlew build` green (unit + integration)
- [ ] Frontend `cd frontend && npm run validate` green
- [ ] `/contract-sync --check` reports IN-SYNC
- [ ] Working tree clean; on a releasable branch
- [ ] `docker build` both images; they start with health UP

## Then
- Bump versions (backend `version` per semver + project PATCH rule; frontend `package.json`).
- Generate/update `CHANGELOG.md` from conventional commits since the last tag.
- Update READMEs/version references the projects require.

## Output
A release summary: versions, changelog excerpt, gate results, and the **exact, un-executed** tag/push/deploy commands.

## Hard stop
**Do NOT push tags/images or deploy** — present the commands and wait for explicit approval. Never ship with a red gate or open contract drift.
