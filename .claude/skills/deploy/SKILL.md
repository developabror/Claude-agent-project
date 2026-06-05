---
name: deploy
description: Use when deploying either or both services to a remote environment, or writing/reviewing deploy automation — pre-flight gate, disk/resource guard, immutable digest-pinned images, post-deploy health verification, and a rollback step. Enforces never-deploy-`latest`, same-artifact promotion, verify-after-deploy, and an always-available rollback. Read before /deploy or any release.
---

# Deploy (safe, reversible, verified)

A deploy is not done when the command returns — it's done when the **new version is verified healthy
in the target** and a **rollback is one command away**. Every rule here exists because skipping it
caused an outage.

## Pre-flight gate (refuse to deploy if any is red)
- [ ] Both gates green: `./gradlew build`, `npm run validate`
- [ ] Contract in sync (`/contract-sync --check`)
- [ ] **Local full stack came up healthy** (`/redeploy --full`) — never deploy what didn't run locally
- [ ] Image is **digest-pinned** (git-sha + semver), the *same* artifact promoted from the last env
- [ ] Working tree clean; on a releasable ref

## Resource guard (run FIRST on the target — a full disk crash-loops the box)
```bash
df -h /                 # free space on the target
docker system df        # image/volume/build-cache usage
# if low: docker image prune -f && docker builder prune -f   # dangling only — NEVER `prune -a` blind
```

## Deploy steps
1. **Push** the digest-pinned image(s) to the registry (`ask`-gated).
2. **Pull + recreate** on the target one service at a time: `docker compose pull <svc> && docker compose up -d <svc>`.
3. **Verify** (mandatory): poll the new container's healthcheck until UP (with a timeout), then hit a
   real endpoint. Backend: `/actuator/health/readiness`. Frontend: `/` 200 + a deep link.
4. **Confirm** the running image digest matches what you intended (`docker inspect`), not a stale tag.

## Rollback (always ready)
- Keep the **previous digest** recorded before deploying. Rollback = `docker compose up -d` pinned to
  the previous digest, then re-verify. Never roll forward to "fix" a bad deploy under pressure.
- DB migrations are **forward-only and backward-compatible** (see `flyway-migrations`) so a code
  rollback never strands the schema — that's why destructive migrations are two-step.

## Hard rules
- **Never deploy a `latest`-only tag** to staging/prod — only immutable digests.
- **Verify after every deploy** — an unverified deploy is an unmonitored outage.
- Deploy + push are **explicit, approved** actions (`disable-model-invocation` on `/deploy`/`/ship`); never auto-fire them.
- **Pushing the image to Docker Hub requires explicit per-action confirmation.** When the developer confirms, **ask: git, Docker, or both**, generate the tag (**git-sha + semver**) at confirm time, and push only the named target. Without an exact instruction, push nothing (see the commit & push policy in `git-workflow`). A local commit, by contrast, is made on every finalize without asking.
- One service at a time; confirm health before moving to the next.
- Secrets come from the platform secret store / env, never from the image or repo.

## Definition of done
New digest live and **verified healthy** in the target; previous digest recorded for rollback; smoke endpoint returns; logs clean.
