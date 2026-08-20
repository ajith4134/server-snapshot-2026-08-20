---
name: trading-bot-goal-and-ledger
description: "Where the crypto trading project's goal and Requirements Ledger live, and the four times the corpus already held what the plan was missing"
metadata: 
  node_type: memory
  type: project
  originSessionId: bf5a5150-d785-455c-af49-9be1126ba144
  modified: 2026-08-08T08:49:50.021Z
---

The autonomous crypto trading system has two documents that must be read before any design work, and
were repeatedly re-derived from scratch before they existed.

**The goal:** `trading-system/docs/superpowers/specs/2026-08-08-final-project-goal-design.md`,
settled in interview 2026-08-08. Prime directive: maximise the fraction of green days subject to a
hard tail-loss cap the system cannot raise. Carry is the earnings core; directional strategies earn
allocation only by raising the portfolio's green-day rate at the same cap. Done means the full tree —
nine bots across three brains, running unattended on live capital. Crypto only, zero NSE. Two human
gates: the capital dial, and paper → real money.

**The ledger:** `~/research/ledger/`. 1,485 rows across 8 slices, merged from 3,214 raw rows across
seven sources — the research corpus, six prior trading repos, and seven video breakdowns. Rebuild the
index with `python3 ~/research/scripts/build_ledger_index.py`; the output is gitignored because it
reports machine state.

**The number that matters: 29 CLAIMED against 599 PRIOR-ART.** For every capability the current
project satisfies, roughly twenty exist as working code in repositories no plan references.

**Why it exists.** On 2026-08-08, four capabilities were designed from scratch that the corpus already
held — `DESIGN-NOTE-universe-wide-scanning.md`, `decision-lineage-feature-attribution-logging.md`,
`IDEAS-INTELLIGENCE.md`, and `IDEAS-STRATEGIC.md` §9. All four were sitting unreferenced.

**How to apply:** search the ledger before writing anything new, and before concluding a capability
does not exist. Declining a row is allowed; forgetting one is not — every row ends CLAIMED, PLANNED
or DECLINED with a written reason.

Two facts worth carrying separately, both measured not assumed: `ajith4134/crypto-bot` is **not** a
prior bot, it is the publish mirror of the current project. And `nse-botonly` is the most complete
system in the account — 587 Python files, near-zero stubs — whose own `BACKLOG B42` records that its
top-level strategy router was never built, which is the identical hole the current project has.

Related: [[trading-bot-intelligence-standard]]
