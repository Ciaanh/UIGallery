#!/usr/bin/env bash
# Runs the whole suite. Usage, from the repo root:  ./tests/run.sh
set -u

LUA=${LUA:-"/c/Program Files (x86)/Lua/5.1/lua.exe"}
LUAC=${LUAC:-"/c/Program Files (x86)/Lua/5.1/luac.exe"}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT" || exit 1

fail=0

echo "-- syntax --"
for f in UIGallery.lua core/*.lua core/UI/*.lua examples/*/*.lua generated/*.lua tools/*.lua tests/*.lua; do
    if "$LUAC" -p "$f" 2>/dev/null; then
        printf '  %-44s OK\n' "$f"
    else
        printf '  %-44s FAIL\n' "$f"; fail=1
    fi
done

run() {
    local label=$1; shift
    if out=$("$LUA" "$@" 2>&1); then
        printf '  %-44s OK\n' "$label"
    else
        printf '  %-44s FAIL\n' "$label"; echo "$out" | sed 's/^/      /'; fail=1
    fi
}

echo "-- tests --"
run "snippets up to date" tools/gen-snippets.lua . --check
run "registry" tests/registry.lua .

echo
[ "$fail" -eq 0 ] && echo "ALL PASS" || echo "FAILURES"
exit $fail
