# REQUIREMENTS LEDGER — INDEX

**Generated 2026-08-19 18:02 UTC** by `scripts/build_ledger_index.py`.

Generated, never hand-written (Rule 8). Not committed, because it reports machine
state rather than a fact about the project (Rule 9). Rebuild with:

```
python3 scripts/build_ledger_index.py
```

## What this is

The anti-forgetting mechanism. Every feature, constraint and idea found across the
research corpus, eight prior repositories and seven video breakdowns, deduplicated
into one list where each row is **CLAIMED** by a named module, **PLANNED** into a
phase, held as **PRIOR-ART** in a prior repo, **DECLINED** with a written reason, or
**UNRESOLVED**.

**Declining is allowed. Forgetting is not.** The build reconciles against this list
twice — once when a module ships, once in a final sweep.

## Completeness

All expected slices present.

## Totals

| Status | Count | Meaning |
|---|---|---|
| **CLAIMED** | 90 | a named module in the current project satisfies it |
| **PLANNED** | 497 | named in a design document, not built |
| **PRIOR-ART** | 599 | working code in a prior repo, in no current plan |
| **DECLINED** | 61 | refused, with the reason written down |
| **UNRESOLVED** | 108 | no home in any plan and no implementation — the gaps |
| *unclassified* | 136 | rows in tables carrying no status column |
| **TOTAL ROWS** | **1491** | across 8 slice files |

Merged from **3214 raw rows** across 7 mined sources.

## Slices

| Slice | Scope | Rows | CLAIMED | PLANNED | PRIOR-ART | DECLINED | UNRESOLVED | IDs |
|---|---|---|---|---|---|---|---|---|
| `PARTIAL-notes-and-media-ops.md` | ops/governance — notes, video, misc research | 96 | 12 | 59 | · | 5 | 20 | · |
| `PARTIAL-nse-crypto-bot-final-ops.md` | ops/governance — nse-crypto-bot-final | 251 | · | 2 | 185 | · | · | · |
| `data-and-models.md` | market-data, feature-engineering, models | 299 | 55 | 71 | 101 | 27 | 43 | DM/FE/MD |
| `ops-governance-early-repos.md` | ops/governance — five early repos | 108 | 1 | 17 | 51 | · | 3 | OGE |
| `ops-governance-nse-botonly.md` | ops/governance — nse-botonly | 77 | · | 1 | 71 | · | 5 | OGN |
| `ops-governance-research-corpus.md` | ops/governance — research corpus | 138 | 1 | 71 | · | 13 | 31 | OGR |
| `risk-execution-validation.md` | risk, execution, validation | 373 | 20 | 191 | 150 | 6 | 2 | EX/RX/VX |
| `strategy-and-portfolio.md` | strategy, portfolio | 149 | 1 | 85 | 41 | 10 | 4 | SP |

## How to read the numbers

**PRIOR-ART is the finding, not CLAIMED.** A large PRIOR-ART count against a small
CLAIMED count means most of what has been built in this account exists in repositories
no current plan references. That is the loss this ledger was built to stop.

**A slice reporting zero CLAIMED is usually correct, not broken.** There is no
`strategy/`, `portfolio/` or `arbiter/` directory in `trading-system/src/`, so no row in
those categories can be satisfied yet.

**PRIOR-ART never means proven.** `prior-attempts-postmortem.md` §3.2–3.3 records that
documentation outgrew validated results and the validation target was substituted for
synthetic data. It means working code exists, and nothing more.

**Unclassified rows are not missing rows.** They sit in tables whose layout carries the
status in a section heading rather than a column — most of them UNRESOLVED lists.

**CLAIMED counts rows spelled `BUILT` too.** They are the same claim — a named module
in the current project satisfies it — and every `BUILT` row cites a `src/` path. Until
2026-08-16 the parser did not know the word, so 22 satisfied rows were reported as
unclassified and the CLAIMED total read 22 low. The rows keep their own wording, one of
them deliberately (`VX-011`, *BUILT (derived; not yet acted on)*).

