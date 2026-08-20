#!/usr/bin/env python3
"""Builds the Requirements Ledger index from the merged slice files.

Rule 8: a display shows measured state, never asserted state. Every number here is
parsed from a slice file that exists on disk right now. Nothing is typed by hand,
and a slice that is missing renders as missing rather than being quietly omitted.

Rule 9: the output reports machine state, so it is generated on demand and never
committed. This script is the deliverable; INDEX.md is its exhaust.

Usage:  python3 scripts/build_ledger_index.py [--check]

    --check   exit 1 if any expected slice is absent, for use in a pre-push hook.
              Without it, a missing slice is reported and the exit code stays 0.
"""
from __future__ import annotations

import argparse
import datetime as dt
import re
import sys
from pathlib import Path

LEDGER_ROOT = Path(__file__).resolve().parent.parent / "ledger"
RAW_DIR = LEDGER_ROOT / "raw"
MERGED_DIR = LEDGER_ROOT / "merged"
INDEX_PATH = LEDGER_ROOT / "INDEX.md"

# Ordered by how the ledger is meant to be read, not alphabetically.
STATUSES = ["CLAIMED", "PLANNED", "PRIOR-ART", "DECLINED", "UNRESOLVED"]

# Statuses that only apply to the build-process table, which catalogues practices
# for building the system rather than capabilities of it.
PRACTICE_STATUSES = ["ADOPTED", "CANDIDATE"]

ALL_STATUSES = STATUSES + PRACTICE_STATUSES

# Spellings that mean an existing status under a different word. Found 2026-08-16:
# 22 rows across the slices read BUILT, which is CLAIMED's meaning exactly - "a
# named module in the current project satisfies it", and every one of them cites a
# `src/` path. The parser did not know the word, so it fell through to
# `unclassified`, and the index reported those 22 rows under a line that says they
# "sit in tables whose layout carries the status in a section heading rather than a
# column". That line was false about them: they carry a status column, filled in,
# with a synonym.
#
# Normalised here rather than by editing the 22 rows, because one of them reads
# BUILT (derived; not yet acted on) and that qualification is load-bearing - VX-011
# says in its own note that it "should not read plain BUILT until something acts on
# a rung". Rewriting the cells would have to preserve that, and a parser that knows
# one extra word is the smaller change. The rows themselves are the place to unify
# the spelling (Rule 7: one concept, one word) and that is a separate sweep.
STATUS_SYNONYMS = {"BUILT": "CLAIMED"}

# What a complete ledger looks like. A slice absent from disk is a hole in the
# anti-forgetting mechanism, so it must be named rather than inferred from silence.
EXPECTED_SLICES = {
    "data-and-models.md": "market-data, feature-engineering, models",
    "strategy-and-portfolio.md": "strategy, portfolio",
    "risk-execution-validation.md": "risk, execution, validation",
    "PARTIAL-nse-crypto-bot-final-ops.md": "ops/governance — nse-crypto-bot-final",
    "PARTIAL-notes-and-media-ops.md": "ops/governance — notes, video, misc research",
    "ops-governance-research-corpus.md": "ops/governance — research corpus",
    "ops-governance-early-repos.md": "ops/governance — five early repos",
    "ops-governance-nse-botonly.md": "ops/governance — nse-botonly",
}

SEPARATOR_CELL = re.compile(r":?-{2,}:?")
ROW_ID = re.compile(r"([A-Z]{2,4})-\d+")
HEADER_CELLS = {"#", "requirement", "feature", "file", "practice", "defect"}


def parse_markdown_rows(path: Path) -> list[list[str]]:
    """Returns the data rows of every markdown table in the file.

    Header rows, separator rows and prose are dropped. A row is kept only if it
    has three or more cells, which excludes the single-cell dividers some slices
    use between sections.
    """
    rows: list[list[str]] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.lstrip().startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 3:
            continue
        if all(SEPARATOR_CELL.fullmatch(c) or c == "" for c in cells):
            continue
        if cells[0].strip("*").lower() in HEADER_CELLS:
            continue
        rows.append(cells)
    return rows


def classify_row(cells: list[str]) -> str | None:
    """The status of a row, or None when no cell holds a status token.

    Slices differ in column layout — some carry a Phase column, some do not — so
    the status is found by value rather than by position. Bold markers are stripped
    because several slices emphasise the status cell.
    """
    for cell in cells:
        token = cell.replace("**", "").strip()
        # Some cells read "CLAIMED (partial)" or "DECLINED as primary".
        head = token.split("(")[0].split(" as ")[0].strip()
        head = STATUS_SYNONYMS.get(head, head)
        if head in ALL_STATUSES:
            return head
    return None


def row_prefixes(rows: list[list[str]]) -> set[str]:
    return {m.group(1) for cells in rows if (m := ROW_ID.match(cells[0]))}


def summarise_slice(path: Path) -> dict:
    rows = parse_markdown_rows(path)
    counts = {s: 0 for s in ALL_STATUSES}
    unclassified = 0
    for cells in rows:
        status = classify_row(cells)
        if status is None:
            unclassified += 1
        else:
            counts[status] += 1
    return {
        "name": path.name,
        "rows": len(rows),
        "counts": counts,
        "unclassified": unclassified,
        "prefixes": sorted(row_prefixes(rows)),
        "bytes": path.stat().st_size,
    }


def render(summaries: list[dict], missing: list[str], raw_rows: int) -> str:
    stamped = dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    total_rows = sum(s["rows"] for s in summaries)
    total_unclassified = sum(s["unclassified"] for s in summaries)
    totals = {
        s: sum(x["counts"][s] for x in summaries) for s in ALL_STATUSES
    }

    out: list[str] = []
    add = out.append

    add("# REQUIREMENTS LEDGER — INDEX")
    add("")
    add(f"**Generated {stamped}** by `scripts/build_ledger_index.py`.")
    add("")
    add("Generated, never hand-written (Rule 8). Not committed, because it reports machine")
    add("state rather than a fact about the project (Rule 9). Rebuild with:")
    add("")
    add("```")
    add("python3 scripts/build_ledger_index.py")
    add("```")
    add("")
    add("## What this is")
    add("")
    add("The anti-forgetting mechanism. Every feature, constraint and idea found across the")
    add("research corpus, eight prior repositories and seven video breakdowns, deduplicated")
    add("into one list where each row is **CLAIMED** by a named module, **PLANNED** into a")
    add("phase, held as **PRIOR-ART** in a prior repo, **DECLINED** with a written reason, or")
    add("**UNRESOLVED**.")
    add("")
    add("**Declining is allowed. Forgetting is not.** The build reconciles against this list")
    add("twice — once when a module ships, once in a final sweep.")
    add("")

    if missing:
        add("## ⚠ INCOMPLETE — slices absent from disk")
        add("")
        add("These are holes in the mechanism, listed rather than inferred from silence.")
        add("")
        for name in missing:
            add(f"- `{name}` — {EXPECTED_SLICES[name]}")
        add("")
    else:
        add("## Completeness")
        add("")
        add("All expected slices present.")
        add("")

    add("## Totals")
    add("")
    add("| Status | Count | Meaning |")
    add("|---|---|---|")
    meanings = {
        "CLAIMED": "a named module in the current project satisfies it",
        "PLANNED": "named in a design document, not built",
        "PRIOR-ART": "working code in a prior repo, in no current plan",
        "DECLINED": "refused, with the reason written down",
        "UNRESOLVED": "no home in any plan and no implementation — the gaps",
        "ADOPTED": "build-process practice already in CLAUDE.md, a skill, or a hook",
        "CANDIDATE": "build-process practice not yet adopted",
    }
    for s in ALL_STATUSES:
        if totals[s]:
            add(f"| **{s}** | {totals[s]} | {meanings[s]} |")
    add(f"| *unclassified* | {total_unclassified} | rows in tables carrying no status column |")
    add(f"| **TOTAL ROWS** | **{total_rows}** | across {len(summaries)} slice files |")
    add("")
    add(f"Merged from **{raw_rows} raw rows** across {len(list(RAW_DIR.glob('*.md')))} mined sources.")
    add("")

    add("## Slices")
    add("")
    header = "| Slice | Scope | Rows | " + " | ".join(STATUSES) + " | IDs |"
    add(header)
    # Slice, Scope, Rows, <statuses…>, IDs
    add("|" + "---|" * (4 + len(STATUSES)))
    for s in summaries:
        scope = EXPECTED_SLICES.get(s["name"], "—")
        cells = [str(s["counts"][k] or "·") for k in STATUSES]
        ids = "/".join(s["prefixes"]) or "·"
        add(f"| `{s['name']}` | {scope} | {s['rows']} | " + " | ".join(cells) + f" | {ids} |")
    add("")

    add("## How to read the numbers")
    add("")
    add("**PRIOR-ART is the finding, not CLAIMED.** A large PRIOR-ART count against a small")
    add("CLAIMED count means most of what has been built in this account exists in repositories")
    add("no current plan references. That is the loss this ledger was built to stop.")
    add("")
    add("**A slice reporting zero CLAIMED is usually correct, not broken.** There is no")
    add("`strategy/`, `portfolio/` or `arbiter/` directory in `trading-system/src/`, so no row in")
    add("those categories can be satisfied yet.")
    add("")
    add("**PRIOR-ART never means proven.** `prior-attempts-postmortem.md` §3.2–3.3 records that")
    add("documentation outgrew validated results and the validation target was substituted for")
    add("synthetic data. It means working code exists, and nothing more.")
    add("")
    add("**Unclassified rows are not missing rows.** They sit in tables whose layout carries the")
    add("status in a section heading rather than a column — most of them UNRESOLVED lists.")
    add("")
    add("**CLAIMED counts rows spelled `BUILT` too.** They are the same claim — a named module")
    add("in the current project satisfies it — and every `BUILT` row cites a `src/` path. Until")
    add("2026-08-16 the parser did not know the word, so 22 satisfied rows were reported as")
    add("unclassified and the CLAIMED total read 22 low. The rows keep their own wording, one of")
    add("them deliberately (`VX-011`, *BUILT (derived; not yet acted on)*).")
    add("")
    return "\n".join(out) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true",
                        help="exit 1 if any expected slice is absent")
    args = parser.parse_args()

    if not MERGED_DIR.is_dir():
        print(f"no merged directory at {MERGED_DIR}", file=sys.stderr)
        return 1

    present = sorted(p for p in MERGED_DIR.glob("*.md") if p.name != INDEX_PATH.name)
    summaries = [summarise_slice(p) for p in present]
    missing = [n for n in EXPECTED_SLICES if not (MERGED_DIR / n).exists()]
    raw_rows = sum(len(parse_markdown_rows(p)) for p in RAW_DIR.glob("*.md"))

    INDEX_PATH.write_text(render(summaries, missing, raw_rows), encoding="utf-8")

    total = sum(s["rows"] for s in summaries)
    print(f"wrote {INDEX_PATH}  —  {total} rows across {len(summaries)} slices")
    if missing:
        print(f"INCOMPLETE: {len(missing)} slice(s) absent: {', '.join(missing)}")
        if args.check:
            return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
