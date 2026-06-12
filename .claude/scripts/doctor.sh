#!/usr/bin/env bash
# project-template environment preflight. Read-only: only runs --version checks. Always exits 0 (reports).
set -uo pipefail
pass=0; warn=0; fail=0
row(){ printf "  %-20s %-10s %-26s %s\n" "$1" "$2" "$3" "$4"; }
have(){ command -v "$1" >/dev/null 2>&1; }
num(){ echo "$1" | grep -oE '[0-9]+' | head -1; }

echo "project-template — environment doctor"; echo
row "TOOL" "REQUIRED" "FOUND" "STATUS"
echo "  --------------------------------------------------------------------------"

# Docker + Compose v2
if have docker; then
  v=$(docker --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  if docker compose version >/dev/null 2>&1; then row "docker+compose" "yes" "${v:-?} (compose v2)" "OK"; pass=$((pass+1))
  else row "docker" "yes" "${v:-?}" "FAIL: install Compose v2"; fail=$((fail+1)); fi
else row "docker" "yes" "missing" "FAIL: install Docker + Compose v2"; fail=$((fail+1)); fi

# Java 21+
if have java; then
  jm=$(num "$(java -version 2>&1 | head -1)")
  if [ "${jm:-0}" -ge 21 ] 2>/dev/null; then row "java" ">= 21" "$jm" "OK"; pass=$((pass+1))
  else row "java" ">= 21" "${jm:-?}" "FAIL: need Temurin 21+"; fail=$((fail+1)); fi
else row "java" ">= 21" "missing" "FAIL: install Temurin 21"; fail=$((fail+1)); fi

# Node 20+ (24 recommended)
if have node; then
  nm=$(num "$(node -v 2>/dev/null)")
  if [ "${nm:-0}" -ge 20 ] 2>/dev/null; then
    if [ "${nm:-0}" -ge 24 ]; then st="OK"; else st="OK (24 recommended)"; fi
    row "node" ">= 20" "$nm" "$st"; pass=$((pass+1))
  else row "node" ">= 20" "${nm:-?}" "FAIL: need Node 20+"; fail=$((fail+1)); fi
else row "node" ">= 20" "missing" "FAIL: install Node 20+ (24 rec.)"; fail=$((fail+1)); fi

# Required: npm, git
for t in npm git; do
  if have "$t"; then row "$t" "yes" "$($t --version 2>/dev/null | head -1)" "OK"; pass=$((pass+1))
  else row "$t" "yes" "missing" "FAIL: install $t"; fail=$((fail+1)); fi
done

# Recommended: jq, rg, python3 (used by scripts/hooks/contract tooling)
for t in jq rg python3; do
  if have "$t"; then row "$t" "rec." "present" "OK"; pass=$((pass+1))
  else row "$t" "rec." "missing" "WARN: handy for scripts/hooks"; warn=$((warn+1)); fi
done

echo
echo "  Summary: $pass OK · $warn warnings · $fail failures"
if [ "$fail" -gt 0 ]; then echo "  -> Fix the FAIL rows before /scaffold-* or /build-zero-to-prod."
else echo "  -> Environment looks good. You can scaffold."; fi
exit 0
