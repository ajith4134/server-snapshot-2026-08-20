#!/usr/bin/env bash
# Rule 4 enforcement for RL-021: a NEW module under trading-system/src/ needs a
# row in AJIT MASTER PLAN naming it.
#
# The escape hatch is ADDING THE ROW, which is the behaviour wanted rather than
# an obstacle to route around. Editing an existing file is never blocked, so
# ordinary work is untouched; this catches exactly one thing, which is building
# something no plan row asked for.
#
# Why this and not a warning: CLAUDE.md already says "search the ledger first"
# and it still failed. RL-011 was ruled on 2026-08-03 - three independent bots
# with their own data, features and architecture - and was 2 of 22 built two
# weeks later, because work and plan drifted apart with nothing measuring the
# gap. Prose that has to be remembered is prose that can be skipped.
#
# exit 2 BLOCKS. exit 1 does not. PreToolUse fails closed by design - a wrong
# block here is merely annoying, and the reason prints on stderr where it is
# read. Every other path exits 0: a hook that blocks because its own plan is
# missing, or because a payload did not parse, would make the repo unworkable
# for reasons that are not the writer's fault.
set -uo pipefail

SPINE="$HOME/trading-system/docs/AJIT-MASTER-PLAN.md"

payload=$(cat)
path=$(printf '%s' "$payload" \
  | python3 -c 'import json,sys
try:
    print(json.load(sys.stdin).get("tool_input", {}).get("file_path", ""))
except Exception:
    print("")' 2>/dev/null)

[ -z "$path" ] && exit 0           # unreadable payload: not something to block on
case "$path" in
    */trading-system/src/*) ;;
    *) exit 0 ;;                   # tests, docs, scripts, anything outside src/
esac
[ -e "$path" ] && exit 0           # an edit to an existing module, not a new one
[ -f "$SPINE" ] || exit 0          # no plan yet is not the writer's fault

stem=$(basename "$path"); stem=${stem%.py}

# `__init__` is package scaffolding, not a module with a responsibility. A plan
# row for it would be a row that means nothing, and requiring one would teach
# the habit of writing rows to satisfy the hook.
[ "$stem" = "__init__" ] && exit 0

if grep -q -- "$stem" "$SPINE"; then
    exit 0
fi

cat >&2 <<EOF
BLOCKED by require-plan-row.sh (RL-021).

  new module : $path
  plan       : $SPINE

No row in AJIT MASTER PLAN names "$stem". Building something the plan does not
ask for is the failure this hook exists to catch.

To proceed: add the row. Eight fields, none optional -

  does / satisfies / sources / depends on / probe / accepts / state

and 'state:' must read 'measured by <probe>', never a status value. The parser
refuses a typed state, so a row that asserts its own health will not load.

Declining a row is allowed. Forgetting one is not.
EOF
exit 2
