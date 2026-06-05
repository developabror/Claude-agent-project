---
description: Deploy a verified, digest-pinned build to a remote environment — pre-flight gate, disk guard, one-service-at-a-time, post-deploy health verify, rollback ready. Never auto-fires.
argument-hint: <env: staging|prod> [--service backend|frontend|all]
disable-model-invocation: true
allowed-tools: Read, Bash(docker:*), Bash(docker compose:*), Bash(ssh:*), Bash(curl:*), Bash(git:*)
---

Deploy to a remote target. Read the `deploy` skill. Delegate the prep/verify to `release-manager`. Target: $ARGUMENTS

## Pre-flight gate (refuse if any is red — show evidence)
- [ ] `./gradlew build` and `npm run validate` green
- [ ] `/contract-sync --check` IN-SYNC
- [ ] **`/redeploy --full` came up healthy locally** (never deploy what didn't run locally)
- [ ] Image(s) **digest-pinned** (sha + semver); the *same* artifact promoted from the prior env
- [ ] Working tree clean; previous digest recorded for rollback

## On the target
1. **Disk/resource guard FIRST:** `df -h /` and `docker system df`; prune *dangling* only if low — never `prune -a` blind.
2. **Push** the digest-pinned image(s) (`ask`-gated).
3. **Deploy one service at a time:** `docker compose pull <svc> && docker compose up -d <svc>`.
4. **Verify (mandatory):** poll the new container health until UP; hit a real endpoint (backend `/actuator/health/readiness`; frontend `/`). Confirm the live image **digest** matches intent.

## Rollback (have it ready before you start)
Record the current digest. If verify fails: `docker compose up -d` pinned to the **previous digest**, re-verify, and report — never improvise a roll-forward fix.

## Commit & push (policy)
A finalize always makes a **local commit** (no asking). **Pushing the image to Docker Hub / a git remote needs an exact instruction** — when the developer confirms, **ask: git, Docker, or both**, generate the Docker tag (git-sha + semver) at confirm time, and push only the named target. (See `git-workflow`.)

## Hard stop
Present the exact push/deploy commands and **wait for explicit approval** before running anything that mutates the remote. Never deploy a `latest`-only tag; never skip the post-deploy verify; never push without an exact instruction.
