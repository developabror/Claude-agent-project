---
description: Preflight the dev environment before scaffolding — checks Docker+Compose, Java 21, Node 20+ (24 rec.), npm, git, and recommended tools (jq, rg, python3). Read-only.
allowed-tools: Read, Bash(bash:*), Bash(docker:*), Bash(java:*), Bash(node:*), Bash(npm:*), Bash(git:*), Bash(jq:*), Bash(rg:*), Bash(python3:*)
---

Run the environment preflight: `bash .claude/scripts/doctor.sh`. Report its table verbatim, then:

- If any row is **FAIL** → list exactly what to install and the required version, and **stop** — don't scaffold against a broken toolchain.
- **WARN** rows (recommended tools) are fine to proceed past; note them.
- If all green → confirm the environment is ready and point to `/build-zero-to-prod`.

Run this **before** `/build-zero-to-prod` or `/scaffold-*`. It's read-only (only `--version` checks); the script always exits 0 and never changes anything.
