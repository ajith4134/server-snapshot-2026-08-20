#!/usr/bin/env bash
# RL-021: the plan must be PRESENT in every session, not merely findable.
#
# CLAUDE.md already says "search the ledger first" and "read the source rather
# than a paraphrase of it", and it still failed - on 2026-08-17 a session
# claimed a two-week-old user ruling "is not in the record" when it was, because
# nothing put the rulings in front of it. Prose that has to be remembered is
# prose that can be skipped, so this prints them instead.
#
# SessionStart output is CONTEXT, not a gate. This hook must never block, so
# every path exits 0 - including a missing register, an unparseable one, and no
# python3.
set -uo pipefail

REPO="$HOME/trading-system"
RULINGS="$REPO/docs/rulings.json"
SPINE="$REPO/docs/AJIT-MASTER-PLAN.md"
BOARD="$HOME/research/dashboard/ajit-master-plan.html"

[ -f "$RULINGS" ] || exit 0

echo "## AJIT MASTER PLAN — standing rulings (docs/rulings.json)"
echo
echo "The user's own decisions, verbatim. Do not re-derive them, do not paraphrase"
echo "them from memory, and do not build against a design that contradicts one."
echo "A new ruling is written into that file the moment it is given, before other"
echo "work continues. Declining a ruling is allowed; forgetting one is not."
echo

python3 - "$RULINGS" <<'PY' 2>/dev/null || echo "(the rulings register did not parse)"
import json, sys
try:
    rulings = json.load(open(sys.argv[1]))["rulings"]
except Exception:
    raise SystemExit(1)
for r in rulings:
    if r.get("superseded_by"):
        continue
    said = " ".join(r.get("verbatim", "").split())[:150]
    print(f"- **{r['id']}** ({r.get('date','?')}, {r.get('scope','?')}) — {said}")
PY

echo
if [ -f "$SPINE" ]; then
    # The ACTIVE SLICE and NEXT ROW are measured and live on the board, not in
    # the document - so this points at both rather than restating either, which
    # is the mistake the superseded A-J plan made.
    echo "**Plan:** \`docs/AJIT-MASTER-PLAN.md\` is the top authority for what to build"
    echo "next. Its rows are eight-field contracts and its \`state:\` fields name probes,"
    echo "never status values."
    if [ -f "$BOARD" ]; then
        echo "**Measured state:** \`~/research/dashboard/ajit-master-plan.html\` — active"
        echo "slice, next row, and the reconciliation counts."
    else
        echo "**Measured state:** the plan board has not been generated yet."
    fi
else
    echo "**Plan:** \`docs/AJIT-MASTER-PLAN.md\` does not exist yet."
fi
exit 0
