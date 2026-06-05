#!/usr/bin/env bash
# PreToolUse(Bash) guard — blocks clearly-destructive commands (deny-only; everything else passes).
# Exit 2 = block and feed the reason back to Claude. Exit 0 = allow.
# Robust by design: if it can't parse input, it FAILS OPEN (exit 0) so it never wedges a session.
set -uo pipefail

input="$(cat)"
cmd="$input"
if command -v python3 >/dev/null 2>&1; then
  parsed="$(printf '%s' "$input" | python3 -c 'import sys,json
try:
    print(json.load(sys.stdin).get("tool_input",{}).get("command",""))
except Exception:
    pass' 2>/dev/null)" || parsed=""
  [ -n "${parsed:-}" ] && cmd="$parsed"
fi

deny() { echo "guard-bash: blocked — $1. (Adjust .claude/hooks/guard-bash.sh to change this.)" >&2; exit 2; }

printf '%s' "$cmd" | grep -Eq 'rm[[:space:]]+-[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*[[:space:]]+(/|/\*|~|\$HOME)([[:space:]]|$|/)' \
  && deny "recursive force-remove of a root/home path"
printf '%s' "$cmd" | grep -Eq ':\(\)[[:space:]]*\{[[:space:]]*:[[:space:]]*\|[[:space:]]*:' \
  && deny "fork bomb"
printf '%s' "$cmd" | grep -Eq '\bmkfs\b|\bdd\b[^|]*of=/dev/|>[[:space:]]*/dev/sd' \
  && deny "disk-destroying command"
if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+push[[:space:]].*--force([[:space:]]|$)' \
   && ! printf '%s' "$cmd" | grep -q 'force-with-lease'; then
  deny "git push --force (use --force-with-lease)"
fi
printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+reset[[:space:]]+--hard' \
  && deny "git reset --hard (destroys uncommitted work)"

exit 0
