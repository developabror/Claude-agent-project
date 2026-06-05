---
name: feature-flags
description: Use when shipping a risky or incomplete change behind a flag, doing a gradual rollout, or adding a kill-switch — covers flag types, backend + frontend evaluation, default-off safety, and mandatory flag cleanup. Lets changes ship dark and roll back without a deploy. Read before merging anything that isn't safe to expose to all users immediately.
---

# Feature Flags (ship dark, roll back without deploying)

A flag decouples **deploy** from **release**: merge and deploy continuously, expose when ready, and
**kill a bad change instantly without a rollback deploy**. Every flag is also a debt — it must be removed.

## Flag types (pick the narrowest)
- **Release flag** — gate an in-progress feature (default **off**); flip on when complete.
- **Kill switch** — wrap a risky/expensive path so it can be disabled in seconds during an incident.
- **Ops/throttle** — toggle behavior under load (e.g. disable a heavy report).
- (Avoid long-lived **permission** flags — that's authorization, belongs in security, not a flag.)

## Backend (Spring)
- Evaluate flags in one place (a `FeatureFlags` component backed by config / a provider like Unleash/
  Flagsmith / OpenFeature). Never scatter `if (env.X)` reads.
- **Default off / safe**: an unknown or unreachable flag evaluates to the *safe* value (feature hidden),
  never crashes the request. Flag the *behavior*, not the schema — migrations and DTOs ship regardless.

## Frontend (React)
- One `useFlag('name')` hook (provider-backed); render the flagged branch conditionally. The flag's
  default is the **current/safe** UI. No flag value gated on client-only state that the backend can't honor.
- A flag that changes an API call must be honored on **both** sides — never let the FE call an endpoint the BE flag has disabled.

## Lifecycle (flags are temporary)
- Every flag is created with an **owner and a removal date/condition** (record it — a TODO or the flag's description).
- After full rollout: delete the flag **and both code branches** in a dedicated cleanup PR. Stale flags
  rot into dead conditionals and surprise behavior. Track open flags so they don't accumulate.

## Rules
- Default-off, fail-safe evaluation; a flag system outage must not take the app down.
- Test **both** branches (flag on and off) — the off path is the one that ships first.
- A flag is not a substitute for a backward-compatible contract: the contract still holds in both states.
- Schedule the cleanup when you create the flag — an un-removed flag is the real cost.
