#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
GODOT_BIN=${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}
OUT_DIR=$(mktemp -d)
"$GODOT_BIN" --headless --path "$ROOT" --editor --import --quit > "$OUT_DIR/import.log" 2>&1
"$GODOT_BIN" --headless --path "$ROOT" --quit-after 120 -- --smoke > "$OUT_DIR/smoke.log" 2>&1
cat "$OUT_DIR/smoke.log"
grep -q 'SMOKE_TEST_PASS' "$OUT_DIR/smoke.log"
if grep -q 'SCRIPT ERROR\|Assertion failed' "$OUT_DIR/smoke.log"; then exit 1; fi
"$GODOT_BIN" --headless --path "$ROOT" --fixed-fps 60 --quit-after 72000 -- --campaign-test > "$OUT_DIR/campaign.log" 2>&1
cat "$OUT_DIR/campaign.log"
grep -q 'CAMPAIGN_TEST_PASS' "$OUT_DIR/campaign.log"
if grep -q 'SCRIPT ERROR\|Assertion failed' "$OUT_DIR/campaign.log"; then exit 1; fi
printf 'Test logs: %s\n' "$OUT_DIR"
