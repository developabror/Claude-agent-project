---
name: prompt-handoff
description: Use in a ROOT session when the user asks for a code change — never edit backend/frontend source directly; instead write a complete, self-contained implementation prompt .md into the target side's prompt-base/ folder for the user to apply from inside that side. Defines the prompt file format, naming, and the gitignore rule (prompts never reach GitHub).
---

# Prompt Hand-off (root → side)

A root session is a **planner/prompt-author**, not an editor. The actual edits happen inside each side,
run by that side's isolated team. Your job from root: turn the request into one or more **ready-to-apply
prompt files**.

## The flow
1. User asks for a change from the **root**.
2. You **plan** it (delegate `product-planner` for anything non-trivial) and decide which side(s) it touches.
3. For each side, **write a prompt file** into that side's `prompt-base/`:
   - `backend/prompt-base/<NNN>-<slug>.md`
   - `frontend/prompt-base/<NNN>-<slug>.md`
   - `<NNN>` = zero-padded order (`010`, `020`, …) so multi-step work applies in sequence.
4. Tell the user exactly what to run: `cd backend && claude` → "apply `prompt-base/010-<slug>.md`" (same for frontend).
5. **Define the contract seam first** — if the change crosses FE↔BE, the backend prompt produces/commits the `openapi.json` change and the frontend prompt regenerates the client (`/wire-api`) from it.

## You do NOT (from root)
- Edit controllers, components, services, entities, tests, styles, or config in `backend/`/`frontend/`. Hand those off.
- The only direct root actions are read-only audits, the contract codegen/drift report, and release/version edits (see root `CLAUDE.md`).

## Prompt file format (each file is self-contained — the side session may have no other context)
```md
# <Imperative title>
Apply in: <backend|frontend>/ (run `claude` from this folder, then apply this prompt)
Depends on: <other prompt-base files that must be applied first, or "none">

## Goal
<the user-visible outcome + acceptance criteria>

## Context
<the exact files/areas involved; the contract seam (endpoints/DTOs/x-audience); any gotchas>

## Steps (delegate to this side's specialists)
1. <agent> — <what>
2. …

## Contract / cross-side
<openapi.json or asyncapi.yaml changes; x-audience; what the OTHER side's prompt expects>

## Definition of done
<gates: ./gradlew build | npm run validate · /redeploy --<side> smoke · tests · /api-coverage if endpoints changed>
```

## Rules
- **Self-contained:** name the specialists, the skills to read, and the exact acceptance checks — assume the side session starts cold.
- **One concern per prompt file;** split multi-step work into ordered files (`010-…`, `020-…`).
- **`prompt-base/` is gitignored** — prompts are local working artifacts, never committed (if a folder was tracked: `git rm -r --cached <side>/prompt-base`).
- After writing the prompts, give the user the copy-paste run instructions per side. Don't apply them yourself from root.
