#!/usr/bin/env bash
# PostToolUse(Edit|Write) — best-effort format the edited Java file. NEVER blocks (always exit 0).
# Single-file format only (no full Gradle run on every edit — too slow). Uses google-java-format if present.
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
  *.java)
    if command -v google-java-format >/dev/null 2>&1; then
      google-java-format -i "$fp" >/dev/null 2>&1 || true
    fi
    # Heavier `./gradlew spotlessApply` is intentionally NOT run per-edit; run it before commit instead.
    ;;
esac
exit 0
