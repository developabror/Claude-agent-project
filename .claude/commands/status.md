---
description: One-shot health snapshot of the whole monorepo — build/test/lint status of both sides, contract sync state, and git status.
allowed-tools: Read, Glob, Grep, Bash(git status:*), Bash(git log:*), Bash(./gradlew:*), Bash(cd backend && ./gradlew:*), Bash(cd frontend && npm run:*), Bash(git diff:*)
---

Produce a concise monorepo health snapshot. Run the cheap checks and report a table — do not fix anything.

## Gather
- **Git**: `git status -s`, current branch, commits since last tag (both sides).
- **Backend**: does it compile/test? (`cd backend && ./gradlew check -q` or report last build state if running is too slow — your call based on repo size).
- **Frontend**: `cd frontend && npm run typecheck` and `npm run lint` (fast); note test status.
- **Contract**: is `openapi.json` newer than the generated frontend client? Flag possible drift (or run `/contract-sync --check` if quick).

## Report (a single table)
| Area | Status | Notes |
|---|---|---|
| Backend build | ✅/❌/⏳ | … |
| Frontend typecheck/lint | ✅/❌ | … |
| Contract sync | ✅/⚠️ | … |
| Git | clean/dirty | branch, unpushed |

End with the top 1–3 things needing attention. Keep it short — this is a glance, not an audit.
