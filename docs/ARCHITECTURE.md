# ARCHITECTURE — how the control plane works

This template is a Claude Code **monorepo control plane**: one root that coordinates two isolated
specialist teams (`backend/` Spring Boot, `frontend/` React). The design rests entirely on how
Claude Code resolves configuration across nested directories. Get that right and the isolation is
free; get it wrong and agents leak across teams.

## 1. The discovery rule (asymmetric by config type)

Verified against the official docs (Claude Code v2.1.x, mid-2026):

| Config type | Resolution | Implication |
|---|---|---|
| **subagents** (`.claude/agents/`) | walk **up** cwd → ancestors → `~/.claude` → plugins | a root session never loads a child's agents; a child never loads a *sibling's* |
| **commands** (`.claude/commands/`) | same walk-up as subagents | same as above |
| **skills** (`.claude/skills/`) | walk up **and** load from **descendant** subtrees *on demand* when Claude touches files there | a root session can use a child's skills while coordinating; a child can't reach a sibling |
| **CLAUDE.md** | walk up (ancestors load at launch, root→cwd order); descendants load on demand | same shape as skills |
| **settings.json** | **cwd-only** — no parent inheritance (permission *arrays* merge across user/local/managed; deny>allow) | each side must be self-contained |

Sources: `code.claude.com/docs/en/sub-agents`, `…/skills`, `…/memory`, `…/settings`,
`…/large-codebases`.

## 2. Why siblings are perfectly isolated

`frontend/` and `backend/` are **siblings** under the root. For any session launched inside one of
them, the other is:
- **not an ancestor** → walk-up never reaches it, so its agents/commands/skills/CLAUDE.md never load; and
- **not within the cwd subtree** → on-demand descendant loading never reaches it either (and a
  subfolder-launched session is file-scoped to its own subtree).

Therefore **launch in `frontend/` ⇒ the backend team is completely absent**, and vice-versa — on
any version, with no configuration switch. The launch directory *is* the isolation boundary.

## 3. Why the root holds only neutral assets

The one direction that is **not** isolated is **root → child**: a root session can pull a child's
**skills/CLAUDE.md** on demand (it cannot load their *agents/commands*). That's intentional — it's
how the root coordinates both sides. The consequence: the root `.claude/` must contain **nothing
domain-specific**. A backend *skill* placed at the root would become visible in `frontend/` too. So:
- Root = orchestration agents (`product-planner`, `api-contract-guardian`, `release-manager`),
  shared skills (`monorepo-workflow`, `api-contract`, `git-workflow`, `zero-to-prod`), and
  full-stack commands. All domain-neutral.
- Domain agents/skills live only in their own side.

(Note the asymmetry cuts in your favor for agents: a backend *agent* at the root would **not** leak
into `frontend/`, because agents only walk up — but skills would, so the rule "domain assets stay in
their side" is the safe one to follow for everything.)

## 4. Orchestration lives in the main thread

**Subagents cannot spawn subagents.** So there is no "orchestrator subagent" that delegates — an
orchestrator here is a **slash command + CLAUDE.md delegation map** that the *main thread* executes,
delegating to specialists via the Agent tool. Planner/architect/reviewer agents are read-only: they
produce specs and findings the main thread then acts on. This is why `/build-zero-to-prod`,
`/new-feature`, etc. are commands, not agents.

## 5. If you need stricter isolation (optional)

The default already gives full FE↔BE isolation. Two extra knobs if you want more control:

- **Focus a root session on one side:** add `claudeMdExcludes` to `.claude/settings.local.json`,
  e.g. `["**/frontend/**"]`, to drop the other side's CLAUDE.md when working single-side from root.
- **Hard organizational lockdown** (rarely needed): package each side as a **plugin** and enable it
  per-folder via `enabledPlugins` (settings are cwd-only, so a plugin enabled only in root settings
  won't load in children), or use managed `strictPluginOnlyCustomization` to forbid project/user
  agents entirely. This is the only mechanism that *prevents* (not just scopes) ancestor/​user config.

## 6. Model tiers & a caveat

- **opus** — architecture, security, code review, performance, planning (judgment, costly to get wrong).
- **sonnet** — implementation (engineers, data layer, tests, build).
- **haiku** — mechanical generation (migrations).

The `model:` field accepts aliases (`opus`/`sonnet`/`haiku`) or full IDs (`claude-opus-4-8`,
`claude-sonnet-4-6`, `claude-haiku-4-5`). The alias path has had reported silent-fallback bugs — if a
tier is load-bearing, pin the full ID and verify with `/agents`. `CLAUDE_CODE_SUBAGENT_MODEL` can
override all subagents for cost control.

## 7. Enforcement: hooks > prose

CLAUDE.md instructions are followed ~70% of the time; **hooks are deterministic (~100%)**. This
template wires safe, best-effort hooks per side (see `.claude/hooks/` and the `hooks` block in each
`settings.json`): a **PreToolUse** guard that blocks clearly-destructive Bash, a best-effort
**PostToolUse** formatter on edits, and a **SessionStart** banner announcing which team is active.
A heavier gate (a `Stop` hook that blocks turn-end until tests pass) is **described as an opt-in
pattern but intentionally not wired** — add it to a side's `settings.json` once your suite is fast and
stable. Hooks are cwd-only, so each side carries its own.

## 8. Version notes (mid-2026)
- Subagent/skill walk-up + on-demand descendant loading: current behavior; **restart Claude after
  adding new agent files** (skills live-reload; a brand-new top-level skills dir needs a restart).
- `disable-model-invocation` (manual-only commands), `memory: project` (cross-session reviewer
  learning), and the agent `skills:` preload field are used throughout.
- Experimental **agent teams** (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) are an alternative engine for
  the cross-layer `/new-feature` flow; the default here is main-thread delegation, which needs no flag.
  (When using teams, note a teammate does **not** inherit a subagent's `skills:`/`mcpServers:`
  frontmatter — put contract-critical rules in CLAUDE.md / project skills.)
