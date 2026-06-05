#!/usr/bin/env bash
# PostToolUse(Edit|Write) — best-effort format the edited file. NEVER blocks (always exit 0).
set -uo pipefail
input="$(cat)"
fp=""
if command -v python3 >/dev/null 2>&1; then
  fp="$(printf '%s' "$input" | python3 -c 'import sys,json
try:
    print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))
except Exception:
    pass' 2>/dev/null)" || fp=""
fi
[ -n "${fp:-}" ] || exit 0
[ -f "$fp" ] || exit 0
case "$fp" in
  *.ts|*.tsx|*.js|*.jsx|*.json|*.css|*.md|*.mjs|*.cjs)
    if [ -x node_modules/.bin/prettier ]; then
      node_modules/.bin/prettier --write "$fp" >/dev/null 2>&1 || true
    fi
    ;;
esac
exit 0
