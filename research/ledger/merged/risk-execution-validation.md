# Requirements Ledger — risk, execution, validation

Merged 2026-08-08. Raw rows in slice: 890. Merged rows: 214. Collapsed: 676.

**Slice definition:** every row across the seven raw files whose `Category` column contains
`risk`, `execution` or `validation` (including compound categories like `risk, portfolio` or
`intelligence, validation`). Four exceptions, made deliberately and flagged inline: HM3/HM6/HM7/HM8
(raw category `observability`) are carried into the Risk section per this task's explicit
instruction, since they gate the same pre-trade risk path as the circuit breakers they sit beside.

**Method.** All 890 matching rows were extracted with `awk` from the seven raw files, split by
source, and read in full. `research-corpus.md` (187 rows) already carries a `Category`/`Phase`/
`State` schema derived directly from `FEATURES.md`, `ARCHITECTURE.md`, `DECISIONS.md` and the
`IDEAS-*.md` bank — its own `PLANNED`/`DECLINED` calls were trusted and re-verified against those
four documents rather than re-derived from scratch. Every `CLAIMED` row below was checked against
`trading-system/src/` and `trading-system/tests/` directly (`grep`+`Read`), not inferred from a
name. Every `PRIOR-ART` row was checked against `ARCHITECTURE.md`, `FEATURES.md`, `DECISIONS.md`
and the goal doc to confirm it has no home in the current plan before being called prior-art rather
than planned.

**Current build reality, stated once here rather than 214 times below:** `trading-system/src/`
contains exactly four packages — `capture/`, `store/`, `cost/`, `statuswall/` — Layer 0 raw
capture, the bitemporal store, the cost engine, and the status wall. **None of it is risk,
execution or validation machinery.** A repo-wide grep for kill-switch, pre-trade-gate, DSR, purge/
embargo, circuit-breaker, reduce-only, idempotency, watchdog, reconciliation, Trial Registry,
Holdout Custodian, MinBTL, CPCV or PBO turned up only capture-layer homonyms (`reconcile_pair` —
repairs a torn raw-capture file pair, not a trading-position reconciliation) and one explicit
gap admission (`statuswall/evidence.py:299` — *"Memory and CPU watchdogs not implemented"*). The
handful of genuine `CLAIMED` rows below are Layer 0 code that happens to carry a `risk` or
`validation` Category tag in the raw mining (sequence-gap validation on the depth stream,
mass-delisting guard, the raw-capture test suite) — not trading risk/execution/validation in the
`FEATURES.md` §5/§6/§8 sense. **Zero of the fourteen Phase 0 minimum items in this slice are
built.** See the dedicated subsection below.

**Collapse notes, as instructed:**
- `crypto-bot-and-nse-botonly.md`: 172 of 206 matching rows are tagged `crypto-bot:` — the publish
  mirror of this project (`README.md · claude-config · research · trading-system · video-notes`,
  per the goal doc §10.1 correction). Collapsed against `research-corpus.md` (which is itself
  sourced from the same `ARCHITECTURE.md`/`FEATURES.md`/`DECISIONS.md`) and against the current
  build; only three crypto-bot rows survived as genuinely distinct `CLAIMED` evidence (sequence
  validation, mass-delisting guard, the test suite — verified above). The remaining 34 rows are
  tagged `nse-botonly:` and are carried forward as new `PRIOR-ART`, per instruction.
- `early-repos.md`, `early-repos-strategy-execution.md`, `early-repos-metaai-civilization.md`:
  heavy overlap (Kelly sizing, CPCV/DSR/PBO gates, circuit breakers, trailing-stop/profit-lock
  engines, exit engines all appear in more than one of the three). Collapsed into single rows
  citing every repo/file that implements the same capability.
- `notes-and-media.md` and `research-corpus.md` both restate large parts of the statistical
  validation canon (DSR, PBO, CPCV, MinBTL, BH-FDR, Hansen SPA, White's RC, purge/embargo) —
  `notes-and-media.md`'s versions are literature citations (Bailey & López de Prado, Hansen,
  White, Harvey-Liu-Zhu) for the *same* `FEATURES.md §8` line items `research-corpus.md` already
  carries as `PLANNED`. Collapsed into the `research-corpus.md` row, with the literature citation
  added as an additional source rather than a second row.
- `nse-crypto-bot-final.md` (200 matching rows) is **not** collapsed against anything — it is a
  distinct prior repo (3,009 files / 864 Python, per the goal doc §10.1 table), postmortemed but
  never previously inventoried row-by-row. Its internal near-duplicates (e.g. three separate
  "exit engine" descriptions across `trading/execution/*`, `trading/exits/*`,
  `trading/crypto/freqtrade/smart_exit.py`) were merged where they describe the same mechanism at
  different call sites, kept separate where they are genuinely different mechanisms (ratchet vs.
  bandit-selected exit policy vs. RL order-slicing are three different things wearing similar
  names).
- Rows that merely *sound* similar but describe different mechanisms were kept separate and
  flagged in Notes — e.g. the six or more distinct "kill switch" concepts in this slice (exchange
  dead-man's switch, in-process bot kill switch, OS-level watchdog-triggered kill switch, per-lane
  kill-gate, daily-loss circuit breaker, NSE `corrigibility_switch`) are six different rows because
  they trip on different conditions and act at different layers, not duplicates of one idea.

---

## RISK

### Phase 0 minimum — risk (5 of 5 required by `FEATURES.md`)

| # | Requirement | Category | Status | Phase | Evidence / satisfying module | Sources | Notes |
|---|---|---|---|---|---|---|---|
| RX-001 | Pre-trade gate: notional, leverage, position cap | risk | CLAIMED | P0 | **2026-08-16**, `src/risk/pre_trade_gate.py`, 23 tests, wired into `paper.forward_engine` **before** the intent WAL — §6's own words are *"blocks the order before it is sent"*, and an order written to the intent log and then blocked is a different claim from one that never existed. **The gap it closes was live**: the forward engine bought on every bar of every symbol with no bound at all — **363 open positions and 14,107 fills** from a strategy that makes no edge claim, and nothing said no. **The donor was read and the port DECLINED.** This row cited `pre_trade_risk_gate.py` (nse-botonly) as available to port; fetched from GitHub 2026-08-16 it is an **NSE options and equity** gate — undefined-risk option combinations, the F&O ban list, lot sizing against an intraday cash-margin fraction — containing **no notional cap, no position cap, no order-rate limit, no price collar, no leverage cap and no aggregate exposure limit**, which is none of the controls this row describes. Third time reading the donor rather than the ledger's note about it has changed the answer. What was adopted is its **shape**: an explicit decision object with machine-readable reasons, and its best rule generalised — **refuse, never trim**, because a silently reduced order is a different order from the one whose expectancy was computed | FEATURES.md §6; DECISIONS.md §6; research-corpus.md rows 73,87,88 | **A defect a test found**: applying the position caps to every order meant a position *already over its limit could never be reduced* — the book trapped at its own cap, in the one state where an exit matters most. The caps now apply only to orders that **increase** exposure; the order-size cap and rate limit still apply to everything, because those are about the order rather than the position. Every failing rule is reported, not just the first — a gate that returns early makes a caller discover a rate limit one rejected order at a time. **Four controls are absent and each is named**: daily-loss and drawdown kills belong to `risk.tail_cap` (two homes for one §6 limit means one that drifts); leverage needs venue margin state this system does not have, and a leverage check computed from a number nobody fetched is a check that passes; correlation-aware limits need a portfolio that does not exist; and the price collar cannot apply to a market order — stated, because a collar that silently skips every market order reads as active and is not. Limits live in `~/capture/risk/paper-gate.json`, seeded once as a **proposal** and never overwritten, so no code path can widen its own limit. |
| RX-002 | Exchange-side kill switch / dead-man | risk | PLANNED | P0 | Not built. Kraken 15–30s/60s, Binance `countdownCancelAll` 30s/120s specified | FEATURES.md §6; DECISIONS.md §6 | No prior-art match found: prior repos build in-process kill switches (see RX-018) but none drive an exchange-side dead-man countdown |
| RX-003 | Watchdog process + firewall network kill | risk | PLANNED | P0 | Not built. Must run as a separate OS process per `DECISIONS.md` §6 — "the bot cannot police itself" | FEATURES.md §6; DECISIONS.md §6; `statuswall/evidence.py:299` (current repo, confirms absence: "Memory and CPU watchdogs not implemented") | **No working prior-art either.** `nse-botonly`'s own gap doc (`docs/REDESIGN_feature_atlas_v1.md` §7) flags that its `corrigibility_switch` is in-process only, not a separate watchdog — the most complete donor repo has the identical gap |
| RX-004 | Liquidation-distance monitor | risk | PLANNED | P0 | Not built. "[MISSED] — for perps this is survival; alert on margin ratio, not just P&L" | FEATURES.md §6 | Prior-art to port: `trading/crypto/liquidation.py` isolated/cross-margin liquidation-price estimator (nse-crypto-bot-final, documented as ignoring funding accrual/taker fees — an estimate, not exact); `account_risk/monitor.py` liquidation-price + margin/exposure monitor (nse-crypto-bot-final) |
| RX-005 | Post-trade reconciliation vs exchange truth | risk | BUILT | P0 | src/execution/state_recovery.py (refuse-to-start, no adopt path). Was: "Rebuild local state on every startup; refuse to start if reconciliation fails" — NautilusTrader-invariant tolerance (qty to instrument precision, avg price within 0.01%) | FEATURES.md §6; DECISIONS.md §6 | Prior-art, imperfect: `live_trader.py` position reconciliation at startup (early-repos-strategy-execution.md, adopts/closes mismatches on boot) but its periodic "reconcile" loop **only re-syncs capital, not positions**, despite the name — flagged in-source as "narrower than its name implies". Not a refuse-to-start gate |

### Circuit breakers and health monitors — prior-art, with the documented-only pattern

*Ten circuit breakers (CB1–CB10) and eight health monitors (HM1–HM8) from `meta_ai/circuit_breaker.py`
and `meta_ai/health_monitor.py` in `ajith-ai-crypto-trading-bot`, cross-checked against a forked
copy in `crypto-linix-server-bot`. HM3/HM6/HM7/HM8 are raw Category `observability`; carried here
per instruction since they gate the same risk path CB1–CB10 sit in.*

| # | Requirement | Category | Status | Phase | Evidence / satisfying module | Sources | Notes |
|---|---|---|---|---|---|---|---|
| RX-006 | CB1 — consecutive losses → reduce leverage | risk | PRIOR-ART | — | Threshold check + config write; linix fork fixes a bug where every bot restart falsely tripped CB1 (filters `session_restart` exits and sub-$5 fee/slippage noise) | early-repos-metaai-civilization.md rows 1,10,49,60 | Not named in current plan. IMPLEMENTED means code with a real body exists — not validated, not profitable (prior-attempts-postmortem.md §3.2–3.3) |
| RX-007 | CB2 — drawdown acceleration → raise confidence bar | risk | PRIOR-ART | — | Reads advanced_risk_manager, raises min-confidence threshold | early-repos-metaai-civilization.md row 50 | Not named in current plan |
| RX-008 | CB3 — model confidence drift → recalibrate + retrain | risk | PRIOR-ART | — | Compares avg confidence to actual win rate, spawns retrain thread | early-repos-metaai-civilization.md row 51 | Not named in current plan |
| RX-009 | CB4 — volatility spike → widen SL | risk | PRIOR-ART | — | ATR-ratio check, config write | early-repos-metaai-civilization.md row 52 | Not named in current plan |
| RX-010 | **CB5 — liquidity crisis** | risk | PRIOR-ART | — | **DOCUMENTED-ONLY in both prior repos.** Named in the header docstring of `meta_ai/circuit_breaker.py`; no method, never called | early-repos-metaai-civilization.md rows 33,53 | Reads-as-built pattern (task item 2): the docstring lists it as a live safeguard; the code contains nothing. No home in current plan either |
| RX-011 | **CB6 — strategy overconcentration** | risk | PRIOR-ART | — | **DOCUMENTED-ONLY in both prior repos.** Header docstring only, no method, never called | early-repos-metaai-civilization.md rows 33,54 | Same reads-as-built pattern as CB5. `FEATURES.md` has a related but distinct planned item: "Strategy Trade Quota" / cross-strategy netting exist as separate PLANNED/PRIOR-ART rows below (RX-071, EX-030) — this specific CB6 mechanism was never implemented anywhere |
| RX-012 | CB7 — time-of-day risk | risk | PRIOR-ART | — | Raises confidence during low-liquidity UTC hours; linix fork fixes a bug that permanently elevated min_confidence after CB7 resolved (hardcoded 60.0 instead of restoring configured value) | early-repos-metaai-civilization.md rows 55,61 | Not named in current plan |
| RX-013 | CB8 — win-rate collapse → suspend strategy | risk | PRIOR-ART | — | Persists suspended-strategy list to JSON | early-repos-metaai-civilization.md row 56 | Related PLANNED concept exists: "Optimal stopping for strategy retirement" (research-corpus.md row 98) is the principled version; CB8's binary suspend is the crude prior-art version, not carried forward as-is |
| RX-014 | **CB9 — data anomaly** | risk | PRIOR-ART | — | **DOCUMENTED-ONLY in both prior repos.** Header docstring only, no method, never called | early-repos-metaai-civilization.md rows 33,57 | Third of the three documented-only circuit breakers named in this task. No home in current plan |
| RX-015 | CB10 — system resource throttle | risk (raw: operations) | PRIOR-ART | — | Real psutil CPU/mem check, scan-interval scaling with hard cap | early-repos-metaai-civilization.md row 58 | Closest current-plan relative is the Ops-category "Disk / memory / resource watchdog" P0 item (out of this slice) |
| RX-016 | CB gatekeeper (`check_symbol_entry`) | risk | PRIOR-ART | — | Final pre-trade check combining CB1/2/7 confidence floor + CB8 suspension list + cold-start confidence cap | early-repos-metaai-civilization.md row 59 | The closest prior-art analogue to RX-001's pre-trade gate; not itself named in the current plan |
| RX-017 | **HM3 — feature importance drift** | risk (raw: observability) | PRIOR-ART | — | **DOCUMENTED-ONLY.** Named in header docstring, no method, never called | early-repos-metaai-civilization.md rows 80,131 | Carried per task instruction. Related PLANNED item exists: "Own-footprint attribution" and §10.8's attribution-correctness work (RX-060) — but HM3 itself was never built anywhere |
| RX-018a | HM6 — ensemble agreement check | risk (raw: observability) | PRIOR-ART | — | **STUB.** Imports the ensemble class and unconditionally returns "healthy" — never measures disagreement | early-repos-metaai-civilization.md rows 83,131-132 | Reads-as-built: a health check that always passes is worse than no check, because it displays green. Rule 8's exact failure mode |
| RX-019 | **HM7 — regime detector drift** | risk (raw: observability) | PRIOR-ART | — | **DOCUMENTED-ONLY.** Header docstring only, no method, never called | early-repos-metaai-civilization.md rows 84,131 | Carried per task instruction. Current plan's regime handling is explicitly weaker-by-design: "Standalone regime detector with authority" is DECLINED (RX-062) — regime stays a non-gating feature, so this gap is lower-stakes than it looks, but still never built |
| RX-020 | HM8 — sentiment signal lag | risk (raw: observability) | PRIOR-ART | — | **STUB.** `sent = None # placeholder`; always returns "No sentiment data in DB" | early-repos-metaai-civilization.md rows 85,131-132 | Same always-green stub pattern as HM6 |

### Cognitive immune system and portfolio-RL risk fallback — prior-art

| # | Requirement | Category | Status | Phase | Evidence / satisfying module | Sources | Notes |
|---|---|---|---|---|---|---|---|
| RX-021 | Cognitive Immune — Strategy Cult detector | risk (raw: governance) | PRIOR-ART | — | Detects one strategy holding >40% of open slots while net-losing, halves its size | early-repos-metaai-civilization.md row 62 | Not named in current plan |
| RX-022 | Cognitive Immune — Ideology Lock detector | risk (raw: governance) | PRIOR-ART | — | Detects L/S ratio >4:1 over 48h while losing, boosts opposite-side confidence | early-repos-metaai-civilization.md row 63 | Not named in current plan |
| RX-023 | Cognitive Immune — Fake Alpha detector | risk (raw: governance) | PRIOR-ART | — | Flags recent win-rate spiking >20pp above lifetime WR as an overfit signal, caps size | early-repos-metaai-civilization.md row 64 | Not named in current plan. Directly relevant to the −$837/attribution caveat: a fast-WR-spike detector is exactly the kind of check that a broken bot-wide attribution signal (§10.8) would feed garbage into |
| RX-024 | Cognitive Immune — Epistemic Drift detector | risk (raw: governance) | PRIOR-ART | — | Greps daily log for "CONCEPT DRIFT DETECTED" count, penalises global confidence | early-repos-metaai-civilization.md row 65 | Log-grep implementation, not a structured metric; not named in current plan |
| RX-025 | Cognitive Immune — Unstable Mutation quarantine | risk (raw: governance) | PRIOR-ART | — | Quarantines sandbox genomes with >30% shadow-trade loss rate | early-repos-metaai-civilization.md row 66 | Relevant precedent for the canary contract's auto-rollback requirement (RX-059) |
| RX-026 | Portfolio RL heuristic fallback (pre-training) | risk | PRIOR-ART | — | PnL-threshold rules used before the portfolio-attention net is trained | early-repos-metaai-civilization.md rows 16,95 | Not named in current plan |
| RX-027 | Drawdown-at-Risk Monte Carlo + auto-apply | risk | PRIOR-ART | — | Vectorised 1000-scenario/50-trade forward simulation of P(20% drawdown); soft-reduces max concurrent trades at 0.30/0.60 crossings | early-repos-metaai-civilization.md rows 13-14,27,71-72 | Close relative of PLANNED "Bootstrapped max-drawdown distribution" (research-corpus.md row 159, P1) and "Graduated drawdown ladder" (RX-034) — the mechanism differs (Monte Carlo simulation vs. bootstrap of realized history) so kept as a separate prior-art row rather than merged |

### Pre-trade gates, position sizing, sizing-adjacent risk (P1–P2 named items)

| # | Requirement | Category | Status | Phase | Evidence / satisfying module | Sources | Notes |
|---|---|---|---|---|---|---|---|
| RX-028 | Per-venue exposure cap (~25–30% of capital) | risk | PLANNED | P1 | Not built | FEATURES.md §6 | Prior-art: "Per-exchange capital caps / diversification" recommendation (notes-and-media.md row 79, crypto-counterparty-operational-risk.md §5) |
| RX-029 | Margin health / auto-deleverage risk | risk | PLANNED | P1 | Not built. "ADL can overshoot — one venue expended 8× the actual deficit" | FEATURES.md §6 | Prior-art: ADL over-correction case study, Hyperliquid Oct 10 2025 ($704.6M vs $304.5M deficit) — notes-and-media.md row 90 |
| RX-030 | Graduated drawdown ladder | risk | PLANNED | P1 | Not built. "Never a single binary kill" | FEATURES.md §6; ARCHITECTURE.md §Layer4 | Prior-art (multiple independent implementations, collapsed): "−5/−10/−15%" ladder (nse-botonly, DOCUMENTED-ONLY — not built even there, `docs/REDESIGN_feature_atlas_v1.md` §7); graduated de-risking ladder + Kelly-consistency check (allocation-and-regime.md, notes-and-media.md rows 113-114); graduated probation ladder for strategy retirement (notes-and-media.md row 106) |
| RX-031 | Correlation-breakdown breaker | risk | PLANNED | P2 | Not built. Portfolio-level, leading indicator | FEATURES.md §6; ARCHITECTURE.md §Layer4 | Prior-art: correlation-spike circuit breaker on rolling 5–10 day cross-strategy correlation (allocation-and-regime.md, notes-and-media.md row 102); correlation-regime-split analysis distinguishing tail-only correlation spikes (notes-and-media.md row 100) |
| RX-032 | Volatility-scaled sizing | risk | PLANNED | P1 | Not built. Primary sizer; needs only a variance forecast, never mu | FEATURES.md §6; ARCHITECTURE.md §Layer4 | Prior-art: risk-overlay dead-band + inverse-vol sizing (nse-crypto-bot-final row 62); volatility targeting as "the dominant real-world sizing approach" (notes-and-media.md row 99) |
| RX-033 | Fractional-Kelly ceiling | risk | PLANNED | P1 | Not built. Cap, never a target; half-Kelly gives 75% of growth at 25% of variance | FEATURES.md §6; ARCHITECTURE.md §Layer4; DECISIONS.md §11 | Prior-art (heavily duplicated across repos, collapsed): Kelly criterion sizing `ml/kelly.py` (early-repos.md row 50); RiskManager Kelly/confidence/portfolio-optimizer blend (early-repos-strategy-execution.md row 35); AFML Ch.10 bet sizing + auto-blend (nse-crypto-bot-final rows 78-80); risk-based fixed-fractional sizer capped at 1% capital risk (nse-botonly row 12); fractional Half-Kelly recommendation (notes-and-media.md row 98) |
| RX-034 | Auto-flatten on venue degradation | risk | PLANNED | P1 | Not built | FEATURES.md §6 | No direct prior-art match found; adjacent concept "Circuit breaker on API errors / price deviation" halts new orders on venue degradation (notes-and-media.md row 80) but does not flatten existing positions |
| RX-035 | Concentration limit per asset | risk | PLANNED | P2 | Not built | FEATURES.md §6 | No direct prior-art match found |
| RX-036 | Deployment freeze windows | risk | PLANNED | P1 | Not built. "[MISSED] — never deploy during high vol or near funding settlement" | FEATURES.md §6 | **UNRESOLVED in prior art** — no prior repo implements a deployment-time freeze window; genuinely no prior implementation found anywhere in the seven raw files despite an extensive search |
| RX-037 | Required pre-trade controls bundle | risk | PLANNED | P0 | Max position (abs+%NAV), max order size, max order rate, price collar/fat-finger band, max leverage, max daily loss, max drawdown kill, per-asset+aggregate exposure, correlation-aware limits | DECISIONS.md §6 | Same underlying requirement as RX-001; kept as a separate row because `DECISIONS.md` enumerates it as a distinct bundle citation with its own SEC Rule 15c3-5 regulatory anchor |
| RX-038 | Risk gate has no exceptions for any strategy | risk | PLANNED | P0 | No strategy bypasses the risk gate regardless of trust or performance | DECISIONS.md §6 | FTX/Alameda and bZx both failed from exactly such an exemption. Also restated in `THE GOAL` §6 |
| RX-039 | On-halt behaviour: flatten vs hold vs hedge | risk | PLANNED | P0 | Flatten for system-integrity faults, hold for market-wide halts, hedge only as a stopgap | DECISIONS.md §6 | Prior-art: identical Flatten/Hold/Hedge policy already documented as a design pattern (risk-and-failure.md addendum, notes-and-media.md row 43) — this is citation of the same source thinking, not independent code |
| RX-040 | Daily-loss circuit breaker | risk | PRIOR-ART | — | Tracks realized+open P&L per trading day (IST), trips and blocks new orders, persisted across restart | nse-crypto-bot-final.md row 45 | Distinct mechanism from RX-002 (exchange dead-man) and RX-018b (real-money kill switch) — trips on a daily-loss threshold specifically, at the order-gate layer |
| RX-041 | Overtrading cap (trade-count circuit breaker) | risk | PRIOR-ART | — | Circuit breaker trips once trade_count/day hits an optional max_trades | nse-crypto-bot-final.md row 46 | Related lesson: Alpha Arena over-trading/fee-burn case (Gemini 2.5 Pro, 238 trades, −56.71%) — notes-and-media.md row 119 |
| RX-042 | Lane kill-gate + parole/probation | risk | PRIOR-ART | — | Retires a strategy lane once it has ≥N closed trades with materially negative total P&L over a trailing window; one probation entry per N hours lets a fixed lane climb back | nse-crypto-bot-final.md rows 47-48 | The probation mechanism directly answers the "binary kill biases the surviving pool toward noise-lucky strategies" concern (notes-and-media.md row 106) |
| RX-043 | Insufficient-capital / absolute minimum capital floor gates | risk | PRIOR-ART | — | Blocks trade if liquid capital can't cover position+fee; raises undersized positions to a floor or skips | early-repos-strategy-execution.md rows 31-32 | Not named in current plan |
| RX-044 | Compound-penalty floor on stacked confidence multipliers | risk | PRIOR-ART | — | Stops entropy×world-model×regime×BTC-trend multipliers crushing a signal below 75% of raw voting score | early-repos-strategy-execution.md row 1 | Not named in current plan; niche mitigation specific to a multi-multiplier voting architecture this project does not (yet) have |
| RX-045 | `data_insufficient` gate | risk | PRIOR-ART | — | Rejects symbols with <50 rows of OHLCV | early-repos-strategy-execution.md row 17 | Adjacent to PLANNED "Regime-coverage tracker" (research-corpus.md row 161) but not the same mechanism |
| RX-046 | Liquid Neural Network anomaly gate | risk | PRIOR-ART | — | Blocks entry if autoencoder anomaly score >0.75 (manipulation/flash-crash detection) | early-repos-strategy-execution.md row 18; early-repos.md row 3 (Liquid-Time-Constant anomaly detector) | Two independent implementations of the same idea, collapsed |
| RX-047 | Hawkes Endogeneity Gate | risk | PRIOR-ART | — | Blocks/penalises entries when Hawkes branching ratio signals stop-hunt or fragile book (>0.95 block, >0.85 −15% confidence) | early-repos-strategy-execution.md row 19 | Paper-only in source repo, per its own evidence note |
| RX-048 | Strategy-specific confidence floors | risk | PRIOR-ART | — | Hard-coded per-strategy minimum confidence derived from historical win rate | early-repos-strategy-execution.md row 20 | Paper-only in source repo |
| RX-049 | Strategy Trade Quota (25% cap on any one strategy) | risk | PRIOR-ART | — | Caps any one strategy at 25% of max concurrent slots to prevent monoculture | early-repos-strategy-execution.md row 21 | Related to but distinct from PLANNED "Cross-strategy position netting" (EX-030); this caps slot count, netting nets exposure |
| RX-050 | Regime-Direction Gate | risk | PRIOR-ART | — | Hard-bans strategy+direction+regime combos with data-proven negative edge | early-repos-strategy-execution.md row 22 | Not named in current plan |
| RX-051 | Winner Pattern Miner / MetaFail / DirBias ML scorer trio | risk | PRIOR-ART | — | Three ML scorers activate only after 1,000 closed trades, at half weight | early-repos-strategy-execution.md row 23 | Cold-start-aware design worth noting; not named in current plan |
| RX-052 | Trade DNA Sequencer | risk | PRIOR-ART | — | Scores signal 0–100 against winner fingerprints; sizes down rather than rejects below 500 closed trades | early-repos-strategy-execution.md row 24 | Not named in current plan |
| RX-053 | Volatility Regime Forecaster gate | risk | PRIOR-ART | — | Predicts P(vol spike in 4h); blocks >0.85, widens SL 0.65–0.85 | early-repos-strategy-execution.md row 25 | Paper-only in source repo |
| RX-054 | Signal Ranker (EV-based sizing) | risk | PRIOR-ART | — | Converts upstream signals into one EV score 0–100 with graduated size scaling instead of binary block | early-repos-strategy-execution.md rows 26,34 | Not named in current plan |
| RX-055 | Lévy jump-risk position scaling | risk | PRIOR-ART | — | Reduces size when jump-variance fraction is high (Merton/NIG/Kou models) | early-repos-strategy-execution.md row 27; early-repos.md row 2 | Two independent implementations collapsed. Related PLANNED item: "Rough volatility (rough Bergomi)" (research-corpus.md row 70, P3, options-focused, distinct application) |
| RX-056 | Advanced risk manager sizing (CVaR + drawdown-stress) | risk | PRIOR-ART | — | CVaR + drawdown-stress constraints on final size (Rockafellar-Uryasev LP) | early-repos-strategy-execution.md rows 28,38; early-repos.md rows 20-22 | Duplicated across two repos, collapsed. Prior-art relative to PLANNED "Constrained optimisation via CVXPY" (research-corpus, not in this table — portfolio category, out of slice) |
| RX-057 | Min-confidence threshold gate | risk | PRIOR-ART | — | Paper 45%, live default 62%, config-overridable | early-repos-strategy-execution.md row 29 | Not named in current plan |
| RX-058 | Reject-context tracking | risk | PRIOR-ART | — | Accumulates symbol/direction/confidence/regime context during evaluation so a later rejection logs full context | early-repos-strategy-execution.md row 33 | Useful pattern for the audit-log Ops item (out of this slice) |
| RX-059 | Topological / persistent-homology crash-risk score | risk | PRIOR-ART | — | Takens embedding, H0/H1 persistence (approximate, not full ripser), sigmoid crash-risk score, in-code acknowledged as simplified | early-repos.md row 4 | Not named in current plan |
| RX-060 | Volatility-spike forecaster | risk | PRIOR-ART | — | Logistic combo of GARCH ratio, ATR percentile, funding acceleration, OI-velocity → spike probability with sizing/SL gating | early-repos.md row 5 | Duplicate concept to RX-053 (Volatility Regime Forecaster) from a different repo — kept separate since the input feature sets differ materially (GARCH+OI-velocity vs. a generic P(spike) model) |
| RX-061 | Adaptive Tailgate Calibrator / Recovery Predictor / MFE Capture Learner / Optimal Stopping / Peak Drawdown Advisor / TP Optimizer (exit-risk ML bundle) | risk | PRIOR-ART | — | Six learned models feeding exit and risk decisions from closed-trade data | early-repos.md rows 11-17 | Bundled into one row — six models sharing one purpose (learn exit/risk parameters from historical trade outcomes); individually distinguishable in the raw source if a future pass wants to unbundle |
| RX-062 | CVaR/Expected-Shortfall portfolio optimizer + 6-scenario stress testing + max-DD-constrained sizing | risk | PRIOR-ART | — | Rockafellar-Uryasev LP CVaR minimization; Luna/FTX/COVID/China-ban/2022-bear/May-2021-flash-crash stress scenarios; half-Kelly capped by DD headroom | early-repos.md rows 20-22; early-repos-strategy-execution.md row 38 | Duplicated across repos, collapsed |
| RX-063 | Catastrophe Intelligence council (7-dim risk scoring) | risk | PRIOR-ART | — | Correlation/overfit/black-swan/contagion computed from real formulas on 4 of 7 dimensions; manipulation/cascade/drift dimensions fall back to fixed constants (STUB) on the other 3 | early-repos.md rows 35-36 | Partial reads-as-built pattern: 4/7 real, 3/7 hardcoded fallback constants presented as one score |
| RX-064 | Meta-council: Performance Philosopher / Reality Validator | risk | PRIOR-ART | — | Civilization-wide overfit/fragility/anti-fragility/drift checks from mean genome scores; drift + regime-distribution-shift (L1 distance) + tail-loss episodic clustering | early-repos.md rows 37-38 | Not named in current plan |
| RX-065 | Genome → live-trade risk bridge | risk | PRIOR-ART | — | Blends genome exit/risk genes into live trailing-stop/sizing | early-repos.md row 43 | Not named in current plan |
| RX-066 | Deterministic verdict scorer (debate fallback, risk overlay) | risk (raw: intelligence, risk) | PRIOR-ART | — | Sync fallback; orthogonal risk/crowding overlay on signal_strength; redesigned after live P&L join proved an earlier version was inverted | early-repos.md row 46 | The "proved inverted" detail is a real, first-party example of exactly the kind of measurement bug this ledger's caveat #4 warns about — a shipped scorer that was silently backwards until checked against live P&L |
| RX-067 | Self-play LOB simulator | risk (raw: intelligence, validation) | PRIOR-ART | — | Agent-based order book: Poisson maker/taker/cancel arrivals, real depth/spread/slippage; policy/value heads are None stubs | early-repos.md row 47 | Real microstructure sim, fake learned policy — another reads-as-built instance |
| RX-068 | Account risk monitor | risk | PRIOR-ART | — | Liquidation price, margin/exposure, emergency circuit breaker (live) | early-repos.md row 48 | Same repo as RX-004's liquidation.py; kept separate as this is the monitor, that is the price estimator |
| RX-069 | Legacy 3-layer veto gauntlet (~26–40+ serial gates) | risk (raw: risk, strategy) | PRIOR-ART | — | 3,191-line gate stack, characterised via internal-audit quotes, not independently re-read | early-repos.md row 49 | **Flagged by the source repo's own internal audit as the primary root cause of mono-directional bias and "trades won't open."** A cautionary prior-art example, not a recommendation to port |
| RX-070 | Frontier composable exit-kill evaluators (CVD divergence, filtered-OBI, funding-premium, Hawkes, MM-Hawkes spoof, BOCPD, conformal bands, GNN-contagion, liq-cascade) | risk | PRIOR-ART | — | Nine composable kill-signal evaluators folded via `ExitDecision.fold` | early-repos.md row 52 | **Praised by the same internal audit (RX-069) as "the RIGHT design"** — direct contrast within one repo between a bad gate architecture and a good one |
| RX-071 | Trailing SL monolith (~1,500 lines, ~775 confirmed dead on live path) | risk | PRIOR-ART | — | Capital ladder, TP1/TP2 latches, Chandelier decay, breakeven shield; ~775 lines of Path A-E ratchet/profit_lock_tiers/DCA-breakeven/hedge-call confirmed dead code on the live path by internal audit | early-repos.md row 54 | Cited directly in the goal doc §6 as one of the two internal audits informing the self-modification ruling. A specific example of the "reads as built, isn't" pattern at the code (not doc) level |
| RX-072 | Directional hedge module (structurally unreachable) | risk | PRIOR-ART | — | Opens counter-position on confirmed trend continuation; real 351-line trigger logic but structurally unreachable from the code path that would call it | early-repos.md row 55 | Another reads-as-built instance — real logic, dead call graph |
| RX-073 | Model bank tier1/tier3 finance nodes (~34 nodes: HRP/CVaR/Merton/MPC/EVT/Johansen/HAR-RV/copula/BOCPD/percolation risk/log-utility control) | risk (raw: risk, execution, models, portfolio) | PRIOR-ART | — | Broad quant-methods node library across allocation, dynamical systems, microstructure, control theory | early-repos.md row 59 | Large bundle; individually distinguishable methods overlap heavily with `IDEAS-*.md`-sourced PLANNED rows below (RX-078 onward) — kept as one prior-art row for the node library itself, separate from the PLANNED theory rows since the library is a specific implementation artifact |
| RX-074 | Risk/volatility signal layer (predictive-distribution VaR/CVaR/vol-targeted sizing) | risk | PRIOR-ART | — | Forecast volatility → VaR, Expected Shortfall/CVaR, vol-targeted position size, vol-forecast skill evaluator | early-repos.md row 64 | Overlaps RX-032/RX-056 conceptually but is a distinct named module (`pattern_brain/risk.py`) — kept separate per "don't collapse things that merely sound similar" |
| RX-075 | Lindy filter on load-bearing risk components | risk | PLANNED | — | "For parts that must not break, prefer techniques that have survived decades over those three years old" | research-corpus.md row 66 (IDEAS-STRATEGIC.md §8) | No prior-art implementation found; a design principle, not yet operationalised anywhere |
| RX-076 | Control barrier functions / safety filters for execution | risk | PLANNED | — | Provable shield projecting any proposed action to the nearest action inside a safe set | research-corpus.md row 51 (IDEAS-AI-FIELD.md Part III) | — |
| RX-077 | Reachability analysis | risk | PLANNED | — | Compute the set of states reachable within horizon H — stronger than VaR (worst-case over paths) | research-corpus.md row 52 | — |
| RX-078 | Robust / H-infinity control framing | risk | PLANNED | — | Designed for bounded-but-unknown disturbance | research-corpus.md row 53 | — |
| RX-079 | Runtime assurance / simplex architecture | risk | PLANNED | — | A verified simple controller runs alongside the complex one, takes over on violation | research-corpus.md row 54 | Maps onto the degradation ladder (RX-088) |
| RX-080 | Optimise time-average growth, not expected value | risk | PLANNED | — | Ensemble average is dominated by branches never occupied; positive-EV can have negative time-average growth | research-corpus.md row 90 (IDEAS-FRONTIER.md §1) | Formal justification cited: Ergodicity economics (RX-090) |
| RX-081 | Survival-first objective | risk | PLANNED | — | Maximise P(still trading in N years), return as a constraint | research-corpus.md row 91 | — |
| RX-082 | Bayesian Kelly from the posterior | risk | PLANNED | — | Integrate over a posterior over edge rather than a heuristic fraction | research-corpus.md row 92 | — |
| RX-083 | Optimal harvest rate — deliberately trade below capacity | risk | PLANNED | — | Trading an edge hard accelerates its death through impact, crowding, detection | research-corpus.md row 95 (IDEAS-FRONTIER.md §2) | — |
| RX-084 | Endogenous decay model (edge half-life depends on own footprint) | risk | PLANNED | — | Edge half-life as a function of own deployed capital, not exogenous | research-corpus.md row 96 | — |
| RX-085 | Reflexivity / crowding self-forecast | risk | PLANNED | — | Forecast own crowding from footprint and correlation | research-corpus.md row 97 | — |
| RX-086 | Data-poisoning resistance as an explicit design requirement | risk | PLANNED | — | Wash trades, spoofed depth, painted closes, fake volume are deliberately manufactured inputs | research-corpus.md row 105 (IDEAS-FRONTIER.md §6) | — |
| RX-087 | Manipulation-signature detection | risk | PLANNED | — | Layering, momentum ignition, quote stuffing have identifiable signatures | research-corpus.md row 108 | — |
| RX-088 | Degradation ladder with automatic transitions | risk | PLANNED | P1 | Full → reduced size → hedge-only → flat → halt, automatic in both directions including gated recovery | research-corpus.md row 110 (IDEAS-FRONTIER.md §7) | Distinct from RX-030 (drawdown ladder specifically); this is the general degradation ladder |
| RX-089 | Dead-man's switch (system-level heartbeat auto-flatten) | risk | PLANNED | P0 | Heartbeat absence auto-flattens | research-corpus.md row 111 | Distinct from RX-002 (exchange-side) — this is a system-level heartbeat, in-process/watchdog territory |
| RX-090 | Runtime temporal-logic monitors | risk | PLANNED | — | Compile properties like "never place an order while the risk-gate token is older than N ms" into runtime monitors | research-corpus.md row 112 | — |
| RX-091 | Differential testing of risk calculations | risk | PLANNED | — | Two independent implementations of position/risk maths, continuously cross-checked; disagreement halts trading | research-corpus.md row 113 | Directly relevant to the −$837 attribution bug: independent cross-checking is exactly what would have caught a credit-everything-equally bug earlier |
| RX-092 | Agent-based simulation including own participation | risk | PLANNED | — | Only honest way to test reflexivity, impact, capacity before deploying capital | research-corpus.md rows 2,117 | — |
| RX-093 | Generative market models — stress-scenario only, never validation | risk | PLANNED | — | Training a strategy on synthetic data validates the generator, not the strategy | research-corpus.md row 118 | Directly reinforces caveat #4 — synthetic data must never substitute for real validation, the exact anti-pattern found in `prior-attempts-postmortem.md` §3.3 (see VX section) |
| RX-094 | Adversarial scenario search | risk | PLANNED | — | Search for the path that breaks the book rather than sampling randomly | research-corpus.md row 119 | — |
| RX-095 | Consensus as signal, dissent as risk limit | risk | PLANNED | — | Size on agreement, cut size on dissent | research-corpus.md row 120 | — |
| RX-096 | Slower layers emit constraint sets, not suggestions | risk | PLANNED | — | A faster layer can never violate a slower layer's constraints | research-corpus.md row 121 | — |
| RX-097 | Classify uncertainty regime (risk / Knightian / ignorance) | risk | PLANNED | — | Applying Kelly under Knightian uncertainty is a category error | research-corpus.md row 122 | — |
| RX-098 | Deep uncertainty favours robustness over precision | risk | PLANNED | — | Seek decisions acceptable across many distributions | research-corpus.md row 124 | — |
| RX-099 | Extreme value theory (POT/GPD) for tail risk | risk | PLANNED | — | Model the tail directly from exceedances | research-corpus.md row 125 | Note: a related EVT application is separately DECLINED (RX-112) for insufficient tail observations — kept distinct since this row is the general technique, RX-112 is its specific rejected application |
| RX-100 | Tail dependence via copulas | risk | PLANNED | — | Correlations converge toward 1 precisely during the events that matter | research-corpus.md row 126 | Prior-art precedent: tail-dependence-based sizing (notes-and-media.md row 101) |
| RX-101 | Hill estimator monitoring on live returns | risk | PLANNED | — | Track the tail index over time; thickening tail is an early warning | research-corpus.md row 127 | — |
| RX-102 | Ergodicity economics (Peters) | risk | PLANNED | — | Formal justification for compounding objective and fractional Kelly | research-corpus.md row 130 | — |
| RX-103 | Ergodic theory (proper) | risk | PLANNED | — | Practical content captured by RX-102 above | research-corpus.md row 133 | — |
| RX-104 | Self-organised criticality / percolation on liquidation cascades | risk | PLANNED | — | Predicts power-law cascade sizes — "worst case" has no natural scale | research-corpus.md row 139 | — |
| RX-105 | Power-law / heavy-tail estimation | risk | PLANNED | — | If tail exponent α<2, variance is not finite and every variance-based risk measure breaks silently | research-corpus.md row 140 | — |
| RX-106 | Ising / phase-transition models | risk | PLANNED | — | Herding and phase transitions in participant behaviour | research-corpus.md row 141 | — |
| RX-107 | Turbulence analogies (mostly metaphor) | risk | PLANNED | — | Volatility cascades resemble energy cascades | research-corpus.md row 142 | — |
| RX-108 | Conformal-bounded safety filter | risk | PLANNED | — | Safe set from conformal prediction intervals; guarantee survives the model being wrong | research-corpus.md row 148 | Prior-art precedent: conformal UQ abstention gate (VX section) already implements conformal calibration elsewhere in prior repos, though not for a CBF specifically |
| RX-109 | Constrained MDPs / safe RL | risk | PLANNED | — | Hard constraints on drawdown/exposure/turnover as first-class citizens, not reward penalties | research-corpus.md row 171 | "The principled version of the risk gate" |
| RX-110 | Exposure limits bind at factor level, not per symbol | risk | PLANNED | — | 40 simultaneous universe-wide triggers can be one correlated bet in disguise | research-corpus.md row 186 (DESIGN-NOTE-universe-wide-scanning.md §6) | Part of §5a's universe-wide-scanning gate machinery |
| RX-111 | "Why is this liquidity available to me?" pre-trade check | risk | PLANNED | — | Sharpest in the thin tail where manufactured setups are cheapest | research-corpus.md row 13 (DESIGN-NOTE §5) | Part of §5a.6's manufactured-setup defence |
| RX-112 | EVT tail fitting — DECLINED | risk | DECLINED | — | "Needs more tail observations than the history provides" | research-corpus.md row 128 (ARCHITECTURE.md §5) | Reason given verbatim |
| RX-113 | Standalone regime detector with authority — DECLINED | risk | DECLINED | — | "Reliability doesn't support veto power; regime stays a weak feature, never a gate" | research-corpus.md row 129 (ARCHITECTURE.md §5; FEATURES.md §7) | Reason given verbatim |
| RX-114 | Short options excluded from default action space — DECLINED | risk | DECLINED | — | "Unbounded loss; requires a separate gate" | research-corpus.md row 5 (DECISIONS.md §9) | Restated in `THE GOAL` §0 as the reason the prime directive needs a tail cap at all |
| RX-115 | Model monoculture as systemic risk and opportunity | risk | PLANNED | — | Converging foundation models produce correlated errors, machine-speed herding, forced flow | research-corpus.md row 15 (IDEAS-SYNTHESIS.md Part III) | — |

### Self-modification, the canary contract, and attribution correctness

*Every row in this block carries the −$837/10,240-trade caveat, per task instruction 3, because
each names a mechanism the postmortem shows failing on this project's own prior money.*

| # | Requirement | Category | Status | Phase | Evidence / satisfying module | Sources | Notes |
|---|---|---|---|---|---|---|---|
| RX-116 | Bounded canary contract for self-modification (ChangeSpec, matched-cohort eval, rigor gate, canary trial, auto-rollback, change report, one-loop-at-a-time) | risk | PLANNED | named work §10.9 | Not built. Reference implementation to *adapt*, not copy: `signals/scibrain/` (`changespec.py`, `evaluator.py`, `rigor.py`, `validator.py`, `change_report.py`, `canary.py`) in nse-crypto-bot-final | goal doc §6, §10.9 | **Caveat:** the prior project measured net −$837 over 10,240 live trades from three concurrent self-modification loops (daily code-rewrite, prompt evolution, a genetic algorithm) racing against each other, compounded by broken attribution (RX-117). The rule "only one self-modification loop may be active at any moment" exists specifically because of this measured failure. The `scibrain` reference implementation itself **"has never been validated against a gate"** per the goal doc — its existence is not evidence it works |
| RX-117 | Per-feature attribution correctness — prerequisite for every learning loop | risk (raw: intelligence/validation-adjacent, filed here as the risk-governing prerequisite) | PLANNED | named work §10.8, blocking | Not built. Nothing in the current plan specifies how credit is assigned to a feature, signal, or strategy | goal doc §10.8 | **Caveat, this is the caveat's own row:** the documented cause of the −$837 result was the feature-governance controller crediting **the same bot-wide win/loss to every one of 36 active features**, so every feature's score moved together and carried no information — it deactivated all 36 features simultaneously, twice, in production. "Until that is correct and tested, no self-modification loop, no meta-model over the ledger, and no learning curve means anything." Required: validate attribution against a synthetic case with known true contributions before trusting it on real fills |
| RX-118 | Own-footprint attribution (market moved vs. I moved the market) | risk (raw: execution, filed here for its attribution role) | PLANNED | — | Separate "the market moved" from "I moved the market"; without it the system learns from its own impact as though it were signal | research-corpus.md row 55 (IDEAS-INTELLIGENCE.md §5) | Same failure family as RX-117 — an attribution error, one level up (system-vs-market instead of feature-vs-feature). Carries the same −$837 caveat by analogy: wrong attribution corrupted the prior system's every downstream decision |
| RX-119 | Consequence, accepted: the optimiser will drift toward the outer bound | risk | PLANNED | named §6 | "The ceiling the user sets is the real risk level, not the intended one. Set it as though the system will live there, because it will" | goal doc §6 | Not a build item — a decision record that the ceiling (RX-120) is load-bearing precisely because of this |
| RX-120 | The immutable ceiling — checksummed risk-limit ceiling outside all component write access | risk | PLANNED | named work §10.7 | Not built. Enforced by the risk gate; current-limits-vs-ceiling displayed on the wall so limit creep is visible | goal doc §6, §10.7 | The numeric value of the ceiling is itself listed as Open/Undecided in goal doc §11.6 — the mechanism is planned, the number is not yet set |

### NSE-donor risk prior-art (`nse-botonly`, per §5 "feature donor, never a target market")

| # | Requirement | Category | Status | Phase | Evidence / satisfying module | Sources | Notes |
|---|---|---|---|---|---|---|---|
| RX-121 | Pre-trade risk gate (chokepoint) | risk | PRIOR-ART | — | Rejects undefined-risk combos, F&O-ban names, non-positive stops; approves qty/margin | crypto-bot-and-nse-botonly.md row 9 (`nse_algo_trader/risk_management/pre_trade_risk_gate.py`) | Closest working analogue to RX-001; NSE-specific rules (F&O ban list) don't port, the chokepoint pattern does |
| RX-122 | SEBI order-rate limiter | risk | PRIOR-ART | — | Self-imposed 5/sec throttle, half of SEBI's 10/sec white-box threshold, inside the live broker client | crypto-bot-and-nse-botonly.md row 4 | NSE-regulatory-specific number; the rate-budgeter *pattern* is relevant to the Ops-category "Cross-strategy rate-limit budgeter" (out of this slice) |
| RX-123 | Option combination risk profile | risk | PRIOR-ART | — | Structural analysis of any leg combination: unlimited-upside-loss / unpaired-short detection, worst-case loss | crypto-bot-and-nse-botonly.md row 10 | Directly relevant to Phase 3/Phase 6 options risk (RX-127, "Greeks-based pre-trade gate") once options trading begins |
| RX-124 | Margin requirement estimator | risk | PRIOR-ART | — | Conservative upper-bound margin models (spread=max-loss+10%; cash=25% notional); explicitly not a real SPAN calculator | crypto-bot-and-nse-botonly.md row 11 | See RX-125 for the gap this leaves |
| RX-125 | Real SPAN margin calculator | risk | UNRESOLVED | — | A true NSE SPAN+exposure margin engine does not exist even in the donor repo — its own docs (`REDESIGN_feature_atlas_v1.md` §6) name this as an unmet gap | crypto-bot-and-nse-botonly.md row 32 | Genuinely unresolved: NSE-specific (out of current scope per §5 "Zero NSE"), not built anywhere, not named in any current-project plan document. No crypto equivalent (a true venue-native margin engine vs. the estimate at RX-124) is named in `FEATURES.md` either |
| RX-126 | Risk-based position sizer (fixed-fractional, 1% capital risk cap) | risk | PRIOR-ART | — | Max 1% capital risk, max 25% margin, floored to whole shares/lots | crypto-bot-and-nse-botonly.md row 12 | Collapses conceptually with RX-033 (Fractional-Kelly ceiling) as another sizing-cap implementation, kept separate since this is fixed-fractional not Kelly-derived |
| RX-127 | Discrete lot size-down policy | risk | PRIOR-ART | — | Composes fractional size-down levers, tighten-only, rounds onto indivisible option lots | crypto-bot-and-nse-botonly.md row 13 | NSE lot-size-specific; crypto's analogue would be exchange minimum-notional/step-size rounding, not currently named as its own FEATURES.md line |
| RX-128 | Graduated drawdown ladder + standalone OS-level kill-switch watchdog (nse-botonly's own named gap) | risk | UNRESOLVED (in nse-botonly) / PLANNED (in current project) | P1/P0 | Documented as not built even in the donor repo — its own `corrigibility_switch` is in-process only | crypto-bot-and-nse-botonly.md row 33 | Same underlying requirement as RX-003 and RX-030; listed here specifically to record that the most complete donor repo in the corpus **also** never solved this — it is not a solved problem waiting to be ported, it is unsolved everywhere in the corpus |
| RX-129 | Per-trade pre-mortem (Monte Carlo) | risk | PRIOR-ART | — | Entry-time bootstrap resampling of real post-trigger return paths forecasting P(target)/P(stop)/CVaR before committing capital | crypto-bot-and-nse-botonly.md row 27 | Real-data-verified per source flag |
| RX-130 | News source reliability + entry gates (news event + index level) | risk | PRIOR-ART | — | Beta-reputation per-source scoring; per-symbol news-event and index-level-proximity entry gates | crypto-bot-and-nse-botonly.md row 28 | Actively wired into live sizing for the news gate; the index-level gate is wired but its multiplier stays at 1.0 pending calibration — a real example of an inert-but-present lever, distinct from the CB5/CB6/CB9 documented-only pattern (this one is code-complete and switched off deliberately, not undone) |
| RX-131 | Profit trail lock (ratcheting stop, sign-agnostic) | risk | PRIOR-ART | — | Locks in profit as it accrues, sign-agnostic across long/short/spread, never loosens; paired target-extension feature is coded but deliberately inert by default | crypto-bot-and-nse-botonly.md row 22 | Direct prior-art for the PLANNED `ratchet_profit_lock` (EX-001 in Execution section) |
| RX-132 | Indian trading cost model | risk (raw tag) | PRIOR-ART | — | Full round-trip statutory + broker cost model — brokerage, STT, exchange fee, SEBI turnover fee, GST, stamp duty | crypto-bot-and-nse-botonly.md row 23 | NSE-specific; the current project's `cost/` package (already `CLAIMED`-built, out of this slice) is the crypto analogue |

---

## EXECUTION

### Phase 0 minimum — execution (3 of 3 required by `FEATURES.md`)

| # | Requirement | Category | Status | Phase | Evidence / satisfying module | Sources | Notes |
|---|---|---|---|---|---|---|---|
| EX-001 | Idempotency key on every order | execution | BUILT | P0 | src/execution/order_intent_wal.py (deterministic id, write-before-send, no blind retry). Was: Client order ID derived deterministically; query by original ID on timeout, never blind-retry | FEATURES.md §5; DECISIONS.md §6; research-corpus.md row 18 | Everbright Securities lost ~$3.8B doing the opposite (notes-and-media.md row 42, DECISIONS.md §6). Prior-art: order lifecycle state machine with illegal-transition guards (nse-crypto-bot-final row 65); binary-fill-state retry bug and the correct fix pattern documented (trading-operational-failures.md, notes-and-media.md rows 158-159) |
| EX-002 | Partial-fill tracking by remaining quantity | execution | BUILT | P0 | src/execution/order_lifecycle.py (ported from EX-049, Decimal + quantity_step). Was: Never a binary filled flag | FEATURES.md §5; research-corpus.md row 19 | Prior-art: order lifecycle state machine PENDING→PARTIAL→FILLED (nse-crypto-bot-final row 65); documented bug class where `if status=="FILLED"` mishandles PARTIALLY_FILLED and doubles intended size on retry (notes-and-media.md row 158) — the exact failure this Phase 0 item prevents |
| EX-003 | Signal expiry / time-in-force discipline | execution | BUILT | P0 | src/execution/order_intent_wal.py (valid_for_ns, refused pre-write, expiry logged). Was: "[MISSED] — a signal computed 5 minutes ago must not fire now" | FEATURES.md §5; research-corpus.md row 23 | Named directly in the nine-bot design: "Signal expiry bound on waiting... expired = abandoned + logged" (`FEATURES.md` §3b) and PROFIT-TAIL's `time_the_entry` function is bounded by it (notes-and-media.md row 10) |

### Order types, routing, and cost-aware execution (P1–P3 named items)

| # | Requirement | Category | Status | Phase | Evidence / satisfying module | Sources | Notes |
|---|---|---|---|---|---|---|---|
| EX-004 | Limit / market / post-only / IOC / FOK order types | execution | PLANNED | P0 | Not built | FEATURES.md §5; research-corpus.md row 16 | Prior-art: Order intent/lifecycle type model, MARKET/LIMIT/SL/SL-M (nse-botonly row 1); MARKET/STOP_MARKET/TAKE_PROFIT_MARKET live order placement (early-repos-strategy-execution.md row 4) |
| EX-005 | Reduce-only orders | execution | PLANNED | P1 | Not built. "[MISSED] — prevents an exit accidentally opening a reverse position" | FEATURES.md §5; research-corpus.md row 17 | Named directly in the nine-bot design: "closes are always reduce-only" (notes-and-media.md row 4) and "profit lock mirrored venue-side as reduce-only stop" (`FEATURES.md` §3b) |
| EX-006 | Fee-tier-aware venue routing | execution | PLANNED | P1 | Not built. "Worth more than any execution algorithm at this size" | FEATURES.md §5; research-corpus.md row 20 | Prior-art precedent: native-token fee discount (BNB) and post-only-as-cost-reduction recommendations (notes-and-media.md rows 81-83) |
| EX-007 | Maker-vs-taker decision per order | execution | PLANNED | P1 | Not built | FEATURES.md §5; research-corpus.md row 21 | Prior-art: execution-timing chooser, limit-vs-market from live spread/drift with a randomized A/B arm (nse-crypto-bot-final row 74) |
| EX-008 | Per-order slippage budget + abort | execution | PLANNED | P1 | Not built. "[MISSED] — cancel if the book moved past tolerance before ack" | FEATURES.md §5; research-corpus.md row 22 | — |
| EX-009 | Cancel/amend churn limits | execution | PLANNED | P1 | Not built. Kraken and OKX penalise churn explicitly | FEATURES.md §5; research-corpus.md row 24 | Prior-art awareness: cancel/amend-churn throttling noted as a documented Kraken/OKX policy (crypto-counterparty-operational-risk.md, notes-and-media.md row 76) |
| EX-010 | Smart order routing across venues | execution | PLANNED | P3 | Not built | FEATURES.md §5; research-corpus.md row 26 | — |
| EX-011 | Iceberg / hidden orders | execution | PLANNED | P3 | Not built | FEATURES.md §5; research-corpus.md row 27 | — |
| EX-012 | TWAP / VWAP / Almgren-Chriss — DECLINED | execution | DECLINED | — | "Clips are thousands of times below where slicing helps at this size" | FEATURES.md §5; ARCHITECTURE.md §Layer1; research-corpus.md row 28 | Reinforced independently: "clip size is 5-10 thousand times below where execution-algo theory starts to bite" (crypto-alpha-decay-execution-costs.md §4, notes-and-media.md row 68) |
| EX-013 | Cost Engine — round-trip breakeven query per (venue, pair, size, order type) | execution | PLANNED | P1 | Not built as the strategy-facing gate (the `trading-system/src/cost/` package is Layer-1 fee schedule/fetcher plumbing, `CLAIMED` but out of this slice's category — no strategy-facing "query before accepted" gate exists yet) | ARCHITECTURE.md §Layer1; research-corpus.md row 40 | Prior-art: round-trip breakeven bps calculator, ~10-30bps Binance vs ~125-135bps Coinbase retail (crypto-alpha-decay-execution-costs.md §3, notes-and-media.md row 67) |
| EX-014 | Capacity Model — per-strategy size ceiling | execution | PLANNED | P2 | Not built. Divergence between live results and a fixed-size shadow book is the capacity signal | ARCHITECTURE.md §Layer1; FEATURES.md §7; research-corpus.md row 41 | Prior-art: "Capacity discovery, live" (research-corpus.md row 58, same IDEAS-INTELLIGENCE.md source, merged conceptually but kept as separate PLANNED rows since one names a model and the other a live-discovery practice) |
| EX-015 | Saga pattern / compensating transactions for multi-leg trades | execution | PLANNED | — | Basis trades (spot+perp) must unwind cleanly if one leg fails | research-corpus.md row 42 | Directly relevant to the carry-earnings-core strategy family (goal doc §3) |
| EX-016 | CQRS (separate order write path from analytics read path) | execution | PLANNED | — | — | research-corpus.md row 43 | — |
| EX-017 | Queueing theory for maker fill probability | execution | PLANNED | — | Order queue position determines maker fill probability and adverse selection even though market making itself is closed | research-corpus.md row 44 | — |
| EX-018 | Model Predictive Control (MPC) for execution scheduling | execution | PLANNED | — | Optimise over a receding horizon subject to hard constraints, re-solving each step | research-corpus.md row 45 | — |
| EX-019 | Inventory control theory | execution | PLANNED | — | Newsvendor/base-stock logic maps onto position management with holding costs (funding) | research-corpus.md row 46 | — |
| EX-020 | Optimal stopping (when to exit) | execution | PLANNED | — | "A solved problem class, usually reinvented badly" | research-corpus.md row 47 | Prior-art: Optimal Stopping Exit via Bellman DP, backward-induction on (PnL,time) grid (early-repos.md row 14) |
| EX-021 | Adaptive control | execution | PLANNED | — | Self-tuning controllers; overlaps online learning | research-corpus.md row 48 | — |
| EX-022 | Kernel bypass (DPDK, Solarflare) — DECLINED | execution | DECLINED | — | "Only pays off colocated; floor is ~8ms of network" | research-corpus.md row 49 | — |
| EX-023 | FPGA / ASIC — DECLINED | execution | DECLINED | — | "Latency-arb hardware for races that cannot be entered" | research-corpus.md row 50 | — |
| EX-024 | Own-footprint attribution (execution-side) | execution | PLANNED | — | Separate "the market moved" from "I moved the market" | research-corpus.md row 55 | Same row as RX-118; execution-category duplicate in the raw corpus, cross-referenced rather than re-numbered |
| EX-025 | Counter-detection: am I being read? | execution | PLANNED | — | Test whether slippage worsens conditionally on the system's own recent activity | research-corpus.md row 56 | — |
| EX-026 | Execution signature entropy (deliberate randomisation) | execution | PLANNED | — | Randomise timing/sizing/venue; only worth it once counter-detection shows a live problem | research-corpus.md row 57 | Related prior-art: randomised trigger latency for the universe-wide scanner's manufactured-setup defence (research-corpus.md row 14, §5a.6) |
| EX-027 | Capacity discovery, live | execution | PLANNED | — | Grow size deliberately until marginal edge decays, hold below it | research-corpus.md row 58 | — |
| EX-028 | Regret-based execution learning | execution | PLANNED | — | Compute best-achievable execution with hindsight, learn the policy from the regret | research-corpus.md row 59 | Prior-art: RL order-slicing agent, PPO over an Almgren-Chriss impact-model env benchmarked against TWAP (nse-crypto-bot-final row 76) |
| EX-029 | Counterfactual fill simulation | execution | PLANNED | — | For every unfilled/partial order, simulate what would have happened at a different price/size/venue | research-corpus.md row 60 | Prior-art: counterfactual fill simulator concept realized as `measure_passive_entry_fill_rate` "miss cost" analysis (nse-crypto-bot-final row 144) |
| EX-030 | Cross-strategy position netting | execution | PLANNED | P2 | Not built. "[MISSED] — two strategies taking opposite sides pay fees both ways" | FEATURES.md §5; research-corpus.md row 25 | Ranked #1 most-forgotten item in `FEATURES.md`. Prior-art target concept: nse-botonly's "Cross-strategy netting" is itself DOCUMENTED-ONLY (crypto-bot-and-nse-botonly.md row 34) — not built even in the donor repo |
| EX-031 | Venue-conditional impact model | execution | PLANNED | — | Impact and decay differ per venue and regime; a single global constant is a fiction | research-corpus.md row 61 | — |
| EX-032 | Multi-period portfolio optimisation with transaction costs (receding horizon) | execution | PLANNED | — | MPC applied to the book, composes with CVXPY | research-corpus.md row 62 | — |
| EX-033 | Time-inconsistency and precommitment devices | execution | PLANNED | — | Minimum holding periods, hysteresis bands, rebalance thresholds rather than schedules | research-corpus.md row 63 | — |
| EX-034 | Hysteresis instead of thresholds everywhere | execution | PLANNED | — | Separate entry/exit thresholds on any binary decision driven by a continuous signal | research-corpus.md row 64 | — |
| EX-035 | Propagator / price-impact models | execution | PLANNED | — | Decaying impact of past trades; informs capacity and re-trade timing | research-corpus.md row 67 | — |
| EX-036 | Queue-reactive models | execution | PLANNED | — | Order-book dynamics conditioned on queue state | research-corpus.md row 68 | — |
| EX-037 | Assume your own execution is being modelled | execution | PLANNED | — | Design under the assumption a well-resourced participant is fitting a model to your order flow | research-corpus.md row 109 | — |
| EX-038 | Rough volatility (rough Bergomi) | execution | PLANNED | P3 | Volatility is rougher than Brownian; matters for options pricing Phase 6 | research-corpus.md row 70 | — |
| EX-039 | Malliavin calculus for Greeks | execution | PLANNED | — | Efficient sensitivities for path-dependent payoffs | research-corpus.md row 71 | — |
| EX-040 | Stochastic optimal control / HJB formulation | execution | PLANNED | — | Continuous-time formulation behind optimal execution and dynamic portfolio choice | research-corpus.md row 72 | — |
| EX-041 | Stochastic calculus (Itô, SDEs) | execution | PLANNED | P3 | Language of continuous-time price models; required for options Phase 6 | research-corpus.md row 132 | — |

### Exit engines, trailing stops, profit locks — prior-art (heavily duplicated, collapsed)

| # | Requirement | Category | Status | Phase | Evidence / satisfying module | Sources | Notes |
|---|---|---|---|---|---|---|---|
| EX-042 | Monotone, volatility-scaled profit-lock ratchet (`ratchet_profit_lock`) | execution (raw: also risk) | PLANNED | P1 | Not built. Moves only in the favourable direction, distance a function of realised vol | FEATURES.md §3b; notes-and-media.md rows 7,12-14 | Extensive prior-art available to port (collapsed across five sources): Trailing-stop family (Exponential/ATR/Chandelier/SAR/breakeven-lock, nse-crypto-bot-final row 70); Signed 4-component ratchet engine (row 71); Adaptive profit-tailgate ratchet, learned giveback distance (row 72); Profit-tailgating exit pass (row 38); NSE profit trail lock, sign-agnostic (nse-botonly, RX-131); "Tailgate Convergence Exit" multi-stage trail (early-repos-strategy-execution.md row 40) |
| EX-043 | Profit lock mirrored venue-side as reduce-only stop | execution (raw: risk) | PLANNED | P1 | Not built. "A lock held only in memory protects nothing during a crash, deploy or partition" | FEATURES.md §3b; notes-and-media.md row 14 | — |
| EX-044 | `decide_position_action`: HOLD/SCALE_OUT/CLOSE/REQUEST_ADD | execution | PLANNED | P2 | Not built. May never flip a position — a reversal is a new trade | FEATURES.md §3b; notes-and-media.md row 8 | — |
| EX-045 | Joint entry-timing policy: price level + order-flow confirmation (`time_the_entry`) | execution | PLANNED | P2 | Not built. Learned jointly, not two rules bolted together | FEATURES.md §3b; notes-and-media.md rows 6,10 | Prior-art: pullback arm-and-sweep entry timing, arms direction at signal time then fires only on retrace with re-validated premise (nse-crypto-bot-final row 39) |
| EX-046 | Learned exit-policy bandit (Thompson sampling over exit arms) | execution | PRIOR-ART | — | Thompson sampling over 7 exit arms (ratchet, direction-flip, forecast, value-area trail, scale-out, early-abort, control) per (arm, regime) | nse-crypto-bot-final.md row 73 | Not named in current plan as a distinct mechanism — closest planned relative is the general promotion/champion-challenger machinery (VX section), not this specific bandit |
| EX-047 | Partial profit-booking ladder | execution | PRIOR-ART | — | Fires configurable rungs (price or R-multiple) to scale out as a position runs | nse-crypto-bot-final.md row 69 | — |
| EX-048 | MAE/MFE + R-multiple tracker | execution | PRIOR-ART | — | Tick-by-tick max adverse/favourable excursion tracking, exit-efficiency metric | nse-crypto-bot-final.md row 68 | Feeds several validation rows in the VX section (postmortem/excursion mining) |
| EX-049 | Order lifecycle state machine (PENDING→PARTIAL→FILLED/CANCELLED/REJECTED) | execution | PRIOR-ART | — | Illegal-transition guards, size-weighted average fill price | nse-crypto-bot-final.md row 65 | Direct prior-art for EX-002's Phase 0 requirement |
| EX-050 | Bracket / cover order builders (NSE) | execution | PRIOR-ART | — | 3-leg (entry+target+stop, OCO) and 2-leg (entry+compulsory stop) NSE order specs | nse-crypto-bot-final.md rows 66-67 | NSE-specific structure; the OCO *concept* is portable, the specific leg structure is not |
| EX-051 | ExecutionEngine orchestrator | execution | PRIOR-ART | — | Composes orders + per-position TradeManagers + circuit breaker + kill switch into one status()-able engine | nse-crypto-bot-final.md row 75 | — |
| EX-052 | Position-blending linear shrinkage for model handoff | execution | PRIOR-ART | — | `w = alpha*old + (1-alpha)*new`, James-Stein shrinkage, avoids flag-day risk | notes-and-media.md row 157 | Relevant to "Shadow Before Swap" incumbent replacement (VX section) |

### NSE-donor execution prior-art

| # | Requirement | Category | Status | Phase | Evidence / satisfying module | Sources | Notes |
|---|---|---|---|---|---|---|---|
| EX-053 | BrokerClient protocol (paper/live parity interface) | execution | PRIOR-ART | — | `place_order`/`fetch_order_result`/`cancel_order` | crypto-bot-and-nse-botonly.md row 2 | Direct architectural precedent for a paper/live parity execution adapter, which the current project has not yet built |
| EX-054 | Signal → order intent translation, hedge-before-short leg ordering | execution | PRIOR-ART | — | Converts risk-approved lots to shares/OrderIntents | crypto-bot-and-nse-botonly.md row 7 | — |
| EX-055 | Atomic multi-leg executor | execution | PRIOR-ART | — | A spread executes as one unit or nothing: hedge-first, any leg failure triggers immediate unwind | crypto-bot-and-nse-botonly.md row 8 | Directly relevant to EX-015's Saga-pattern requirement for basis trades (spot+perp) |
| EX-056 | Intraday square-off schedule + executor | execution | PRIOR-ART | — | NSE-specific 15:15–15:30 IST forced-flat window; BUY-cover-before-SELL-close ordering, retry-to-flat | crypto-bot-and-nse-botonly.md row 14 | NSE-time-window-specific; not directly portable, but the retry-to-flat-with-CRITICAL-escalation pattern is |
| EX-057 | Market-impact fill model + fill/slippage model | execution | PRIOR-ART | — | Square-root-law temporary price impact by participation, layered on realistic bid-ask half-spread fills | crypto-bot-and-nse-botonly.md row 18 | Real-data verified per source flag |
| EX-058 | ORB replay paper engine + paper-trading ledger | execution | PRIOR-ART | — | End-to-end cash strategy replay (signal→gate→broker→ledger); average-cost virtual position accounting | crypto-bot-and-nse-botonly.md row 19 | — |
| EX-059 | Live universe paper loop | execution | PRIOR-ART | — | Prices open positions, manages stop/target, seeds signals, catches breakouts, force-squares-off | crypto-bot-and-nse-botonly.md row 20 | — |
| EX-060 | 0-DTE expiry-day live path + carried risk-state | execution | PRIOR-ART | — | Opens/carries/closes multi-leg 0-DTE structures; per-position time-stop + per-day loss cap; IV-rank input left empty pending a reader (own backlog item) | crypto-bot-and-nse-botonly.md row 21 | Relevant to Phase 6 options if/when built; the "wired but left empty pending a reader" caveat is worth carrying forward as a caution against half-wired levers |

### Historical execution failure-mode lessons (informing planned controls, not themselves capabilities)

| # | Requirement | Category | Status | Phase | Evidence / satisfying module | Sources | Notes |
|---|---|---|---|---|---|---|---|
| EX-061 | Round-trip cost-charging structure reusable, needs re-parameterisation | execution | PRIOR-ART | — | Prior attempt's `backtest.py` correctly charges fee+slippage on both legs, but its default 6bps round-trip assumption is ~3-4x too low vs. real venue fees (~20bps Binance spot taker) | prior-attempts-postmortem.md §3.1/§5, notes-and-media.md row 46 | "Dangerous because it looks rigorous while being wrong" — a specific warning against trusting a correctly-structured but mis-parameterised cost model |
| EX-062 | Region-matched cloud VM co-located with exchange's own cloud infra | execution | PLANNED | — (open item, DECISIONS.md §12) | AWS Tokyo (Binance)/Singapore (Bybit)/Hong Kong (OKX) region matching, ~$250-300/mo, single-digit-to-teens-ms RTT without colocation | notes-and-media.md row 58 | Ties to goal doc §11.3 open item: "Binance matching-engine region — sources conflict; measure with an RTT probe before committing infrastructure" |
| EX-063 | Sub-second execution tier scoping (single-digit-to-tens-of-ms band) | execution | PLANNED | — | Explicitly scoped as "not latency arbitrage," nowhere near true HFT | notes-and-media.md row 61 | Relevant to Brain 3 (sub-second) in the goal doc §8.1 nine-bot requirement |
| EX-064 | Outage-correlated execution-availability haircut | execution | PLANNED | — | Models exchange execution availability as a haircut correlated with realized volatility rather than a flat slippage constant | notes-and-media.md row 142 | Reinforced by a documented base rate: every major volatility spike since 2020 has a matching exchange degradation event on a top-5 venue (crypto-counterparty-operational-risk.md §1, notes-and-media.md row 74) |
| EX-065 | Order-entry sanity checks / fat-finger guardrail | execution | PLANNED | — | Guards against manual/automated entry errors (decimal-point mis-place) | notes-and-media.md row 121 | Illustrated by Alameda's Oct 2021 fat-finger flash crash after deprioritizing risk-check infrastructure for speed |
| EX-066 | MakerDAO lesson: dynamic gas settings under stress | execution | PLANNED | — | Static gas settings under a 10x gas spike stranded liquidation bids, ~$5.67M protocol deficit | notes-and-media.md row 36 | Config that is fine in normal conditions can be fatal in exactly the stressed conditions the bot exists to handle |
| EX-067 | Liquidity does not predict slippage | execution | PLANNED | — | The higher-volume instrument sometimes had worse slippage due to rebalance crowding | notes-and-media.md row 40 (risk-and-failure.md §9) | A specific caution against a plausible-but-wrong sizing heuristic |

---

## VALIDATION

### Phase 0 minimum — validation (6 of 6 required by `FEATURES.md`)

| # | Requirement | Category | Status | Phase | Evidence / satisfying module | Sources | Notes |
|---|---|---|---|---|---|---|---|
| VX-001 | Experiment ledger — including abandoned runs | validation | BUILT | P0 | src/validation/trial_registry.py (abandoned runs counted). Was: "Every statistic depends on the true trial count; a schema storing only winners cannot produce an honest N" | FEATURES.md §8; DECISIONS.md §5; research-corpus.md row 149 | DECISIONS.md §5 cites Bailey/Ger/López de Prado/Sim/Wu: with 5 years of daily data and 45+ tried variations, the best selected strategy is more-likely-than-not Sharpe≥1.0 with zero true edge (in-sample 1.59, OOS −0.18 on pure random-walk data) |
| VX-002 | Trial Registry (cumulative N, enforced) | validation | BUILT | P0 | src/validation/trial_registry.py (evaluate() pre-registers; enforced). Was: "Structurally impossible to evaluate without incrementing" | FEATURES.md §8; ARCHITECTURE.md §Layer2; research-corpus.md row 150 | No prior-art N-counting registry found matching this exact structural-enforcement property. Closest analogue: Foundry deflation gate's population-DSR count (VX-035) |
| VX-003 | Holdout Custodian (refuses queries) | validation | BUILT | P0 | src/validation/holdout_custodian.py (+ ClockGatedReader, opt-in). Was: Owns the untouched holdout; commit hash + not-consumed flag, CI blocks any run touching the range before freeze | FEATURES.md §8; ARCHITECTURE.md §Layer2; research-corpus.md row 151 | Closest prior-art: Causal leakage firewall, raises on future-timestamped data or clock rewind (nse-botonly row 15, VX-042) — a related but distinct enforcement mechanism (leakage prevention at read time vs. custody of an untouched range) |
| VX-004 | Purge + embargo, configured per family | validation | BUILT | P0 | src/validation/purged_cross_validation.py (two-sided purge, per-family). Was: Horizons differ by orders of magnitude between strategy families | FEATURES.md §8; ARCHITECTURE.md §Layer2; research-corpus.md row 152 | Substantial prior-art to port: CPCV with purge+embargo already correct in a prior attempt's `cpcv.py` (n_groups=6, k_test=2), flagged reusable as-is (ARCHITECTURE.md §3c, research-corpus.md row 182); per-frequency-band purge/embargo requirement explicitly documented (validation-beyond-deflated-sharpe.md, notes-and-media.md row 145); nse-botonly's own CPCV implementation (VX-043) |
| VX-005 | Deflated Sharpe as in-loop fitness | validation | BUILT | P0 | Not built as the search-loop fitness function. "Not a report on the winner" | FEATURES.md §8; ARCHITECTURE.md §Layer2; DECISIONS.md §4; research-corpus.md row 154 | Extensive prior-art (collapsed across many sources): Foundry deflation gate deflates by expected-max-Sharpe of the trial population before promotion (nse-crypto-bot-final row 18); Overfitting guardrails PSR/DSR/PBO module (row 27); 5-layer Evaluator Layer 1 (Bailey & López de Prado PSR/DSR, early-repos.md row 60); Deflated-Sharpe promotion gate + CPCV (nse-botonly row 25, VX-044); literature basis (Bailey & López de Prado 2014, notes-and-media.md row 128) |
| VX-006 | MinBTL hard gate | validation | BUILT | P0 | src/validation/deflated_sharpe.py min_backtest_length_years. Was: Cheap, closed-form | FEATURES.md §8; research-corpus.md row 156 | MinBTL ≲ 2·ln(N)/(expected Sharpe)² — with 5 years of data, >~45 independent configurations makes finding an in-sample Sharpe-1.0/true-OOS-zero strategy near-certain (notes-and-media.md row 129) |

### Statistical validation stack (P1–P2 named items)

| # | Requirement | Category | Status | Phase | Evidence / satisfying module | Sources | Notes |
|---|---|---|---|---|---|---|---|
| VX-007 | CPCV harness | validation | BUILT | P1 | src/validation/promotion_gate.py (composed CPCV harness). Was: "Finalists only — combinatorics explode" | FEATURES.md §8; research-corpus.md row 153 | See VX-004/VX-043/VX-044 prior-art |
| VX-008 | PBO / CSCV | validation | BUILT | P1 | src/validation/backtest_overfitting.py probability_of_backtest_overfitting. Was: Probability of backtest overfitting via CPCV | FEATURES.md §8; DECISIONS.md §4; research-corpus.md row 155 | On pure noise, 8,800 configurations produced in-sample Sharpe 1.27 with 53% of OOS Sharpes negative — direct empirical evidence of the scale of the problem (multiple-comparisons-false-discovery-backtesting.md, notes-and-media.md row 130) |
| VX-009 | BH-FDR on the promoted set | validation | BUILT | P1 | src/validation/backtest_overfitting.py benjamini_hochberg. Was: Bonferroni too blunt at large N | FEATURES.md §8; research-corpus.md row 157 | Bonferroni verdict: at N=10,000, α/N=0.000005 suppresses essentially everything including true positives (notes-and-media.md row 137) |
| VX-010 | Hansen SPA at the promotion gate | validation | BUILT | P2 | src/validation/superior_predictive_ability.py, benchmarked against the incumbent and cross-checked against arch.bootstrap.SPA. Was: "Does the challenger beat the incumbent, corrected for variants tried" | FEATURES.md §8; research-corpus.md row 158 | White's Reality Check explicitly superseded — "Hansen's SPA strictly dominates it; running both is ceremony" (notes-and-media.md rows 131-132) |
| VX-011 | Bootstrapped max-drawdown distribution | validation | BUILT (derived; not yet acted on) | P1 | src/risk/drawdown_distribution.py block_bootstrap_max_drawdowns + circuit_breaker_ladder; wired 2026-08-09 through `risk.tail_cap.derive_operating_limits`, which clamps every rung to the user's §6 ceiling and records which rungs were clamped. **What exists is the DERIVATION, not the response**: nothing yet cuts gross by a rung's 25%/50%/flat, because position sizing is Phase 5. The row is honest at this status and should not read plain BUILT until something acts on a rung. Was: Sets non-arbitrary circuit-breaker thresholds off bootstrapped p75-p90, not the single historical max | FEATURES.md §8; ARCHITECTURE.md §2; research-corpus.md row 159 | Prior-art precedent: "cheap, directly actionable, and underused relative to its value" (allocation-and-regime.md, notes-and-media.md row 111); block-bootstrap regime-conditional resampling preferred over GANs (research-corpus.md row 3) |
| VX-012 | Shadow trading with alignment metrics | validation | PLANNED | P1 | Not built. ≥95% signal alignment, ≥90% execution-quality match, auto-halt after 3 misalignments | FEATURES.md §8; ARCHITECTURE.md §2; research-corpus.md row 160 | Concrete prior-art spec to port directly: RustyBT's `signal_tolerance_pct` (5%)+`max_misalignment_count`(halt after 3)+alignment-rate gate — "the strongest, most concretely implementable go/no-go gate found" (trading-monitoring-deployment-discipline.md, notes-and-media.md row 155) |
| VX-013 | Regime-coverage tracker | validation | PLANNED | P1 | Not built. "[MISSED] — gate on having seen a drawdown and a vol spike, not elapsed days" | FEATURES.md §8; ARCHITECTURE.md §2; research-corpus.md row 161 | — |
| VX-014 | Backtest-vs-live divergence monitor | validation | PLANNED | P1 | Not built. Technical divergence (bug) vs statistical decay (regime) | FEATURES.md §8; research-corpus.md row 162 | Documented norm: median 73% Sharpe deterioration from backtest to live across 215 studied strategies — a 40-60% haircut alone isn't a kill signal, need a DSR-adjusted expectation gate (trading-monitoring-deployment-discipline.md, notes-and-media.md row 153) |
| VX-015 | Mechanism-health metric per strategy | validation | PLANNED | P1 | Not built. "[MISSED] — declared at promotion; the only fast decay signal" | FEATURES.md §8; ARCHITECTURE.md §Layer2; research-corpus.md row 163 | Prior-art precedent: mechanism-based strategy decay monitoring called "the highest-value practice" (allocation-and-regime.md, notes-and-media.md row 104); CUSUM-style sequential Sharpe monitoring to avoid the peeking problem (row 105) |
| VX-016 | Five-stage promotion pipeline (research→paper→shadow→reduced-size live→full live) | validation | PLANNED | — | Each stage its own gate spanning P0-P2; shadow ≠ paper — shadow runs the live path against real books, sends nothing | ARCHITECTURE.md §2; DECISIONS.md §4; research-corpus.md row 164 | Full spec: `promotion-pipeline.md`. Stage 4 caveat: expect ~50% decay from backtest to live as normal, worse than that is broken (notes-and-media.md row 28) |
| VX-017 | "Shadow Before Swap" for incumbent replacement | validation | PLANNED | — | Promote a challenger only after a shadow trial on delayed labels shows a pre-registered advantage; 78.4% fewer deployed-state changes at equal-or-better quality | ARCHITECTURE.md §2; FEATURES.md §3; research-corpus.md row 165 | — |
| VX-018 | Pre-committed retrain-vs-retire decision rules | validation | PLANNED | — | Decline-with-rising-costs=crowding→retire; decline-with-flat-costs=drift→retrain; sharp step=microstructure break→retire; divergence-at-larger-size=capacity; pre-commit before a drawdown | ARCHITECTURE.md §2; research-corpus.md row 166 | — |
| VX-019 | PAC-Bayes generalisation bounds | validation | PLANNED | — | Non-vacuous finite-sample bounds on OOS loss from the training set alone — "is this complex enough to have memorised," distinct from DSR's "did you get lucky" | research-corpus.md row 167 | — |
| VX-020 | Learning theory for dependent data (β/φ-mixing, effective sample size) | validation | PLANNED | — | 5 years of minute bars is not 2.6M independent observations | research-corpus.md row 168 | — |
| VX-021 | Online learning / online convex optimisation with regret bounds | validation | PLANNED | — | Assumes no distribution, still proves regret bounds against the best fixed strategy in hindsight | research-corpus.md row 169 | — |
| VX-022 | Rademacher / VC complexity of the strategy class | validation | PLANNED | — | Bounds capacity of the strategy space searched; pairs with MDL | research-corpus.md row 170 | — |
| VX-023 | Inverse RL / imitation on own history | validation | PLANNED | — | Recover the implicit objective from past decisions | research-corpus.md row 172 | — |
| VX-024 | Evals as continuous integration for LLM components | validation | PLANNED | — | Fixed battery every LLM component must pass before promotion: injection resistance, look-ahead traps, calibration, framing invariance, refusal under insufficient evidence | research-corpus.md row 173 | — |
| VX-025 | Capability elicitation before deployment | validation | PLANNED | — | Actively attempt to make a component fail before it holds capital; red-teaming as a scheduled activity | research-corpus.md row 174 | Prior-art precedent: "Red-Team Agent Generates Testable Hypotheses, Not Verdicts" — must be settled by an actual test, never LLM judgment; LLM self-correction without ground truth measurably degrades performance (CommonSenseQA 75.8%→41.8%) (cutting-edge-ai.md, notes-and-media.md row 165) |
| VX-026 | Novelty pressure in the search objective | validation | PLANNED | — | Reward a candidate for behaving unlike existing strategies at equal risk-adjusted return | research-corpus.md row 175 | — |
| VX-027 | Multiple-testing accounting across the whole archive | validation | PLANNED | — | A diverse archive is a larger search, so DSR/PBO correction gets harsher not gentler | research-corpus.md row 176 | — |
| VX-028 | Property-based invariants that must hold everywhere | validation | PLANNED | — | Machine-checked assertions true in backtest, shadow and live alike (no future data touched, position limits never breached, no order without a risk-gate token) | research-corpus.md row 177 | Prior-art precedent: property-based test suite for byte-exact round-trip already exists in the current build's Layer 0 (CLAIMED, out of this slice's category but the pattern is directly reusable) |
| VX-029 | Backtest/live divergence alarm on identical inputs | validation | PLANNED | — | Replay the same inputs through both paths; any behavioural difference is a defect | research-corpus.md row 178 | — |
| VX-030 | Position-order and framing invariance tests | validation | PLANNED | — | Same evidence, permuted presentation, must yield the same call | research-corpus.md row 179 | Directly relevant: LLM-as-judge documented as gameable — only 65% self-consistency under answer-order swap (cutting-edge-ai.md, notes-and-media.md row 165) |
| VX-031 | A formal no-edge test, pre-registered | validation | PLANNED | — | Define in advance the observation that would mean "there is no edge here and there never was" | research-corpus.md row 180 | — |
| VX-032 | Minimum track record length for the whole enterprise | validation | PLANNED | — | Compute minimum observation count before skill is distinguishable from luck, for the enterprise as a whole | research-corpus.md row 181 | Lo (2002): a Sharpe-1.0 strategy needs ~2.7 years of daily data for 95% confidence it beats zero in the optimistic i.i.d. case; real autocorrelated, fat-tailed crypto returns lengthen this further (risk-and-failure.md §2, notes-and-media.md row 30) |
| VX-033 | Stack: reuse `cpcv.py`+`backtest.py` from prior attempt | validation | PLANNED | — | Purge/embargo already correct; add DSR, MinBTL, PBO; re-parameterise cost defaults | ARCHITECTURE.md §3c; research-corpus.md row 182 | See EX-061's caveat: the cost defaults specifically need re-parameterising, not just re-using |
| VX-034 | Stack: pytest + Hypothesis for testing | validation | PLANNED | — | Property-based testing is the only sane way to test a validation harness | ARCHITECTURE.md §3c; research-corpus.md row 183 | — |
| VX-035 | Foundry deflation gate (population DSR) | validation | PRIOR-ART | — | Deflates every candidate's Sharpe by the expected-max-Sharpe of the trial population before promotion | nse-crypto-bot-final.md row 18 | Prior-art most directly portable to VX-005 |
| VX-036 | Foundry reasoning verifier gate (LLM step-verifier) | validation | PRIOR-ART | — | Optional gate: an LLM step-verifier scores a spec's idea rationale; promotion can require "profit AND verified reasoning"; degrades to pass-through with no LLM | nse-crypto-bot-final.md row 19 | Relevant to VX-024's "evals as CI for LLM components," though this is a promotion input rather than a CI check |
| VX-037 | Random-walk-null cycle gate | validation | PRIOR-ART | — | Any strategy citing cycles/periodicity must beat a permutation-null test on its own segment before promotion — "debunks the DFT-finds-a-cycle-in-any-random-walk trap" | nse-crypto-bot-final.md row 20 | Prior-art precedent for the broader "permutation/randomisation tests... should be the default sanity check" (IDEAS-ADVANCED.md §16, notes-and-media.md row 136) |
| VX-038 | Shared candidate protocol + admission gate with leak tripwire | validation | PRIOR-ART | — | Auto-rejects and logs any candidate whose OOS Sharpe >8 or OOS return >1000% as a leakage suspect rather than treating it as genius | nse-crypto-bot-final.md rows 21-22 | A concrete, cheap sanity gate worth naming as portable |
| VX-039 | Family-wise error control (StepM, Hansen's stepwise reality-check) | validation | PRIOR-ART | — | Stationary-bootstrap StepM across all candidates tried in one cycle; fail-open on small samples | nse-crypto-bot-final.md row 23 | — |
| VX-040 | Multi-objective OOS fitness scoring, blended with live journal P&L | validation | PRIOR-ART | — | Walk-forward OOS folds; blends real journal P&L when available so scoring reflects live behaviour | nse-crypto-bot-final.md row 24 | — |
| VX-041 | vectorbt walk-forward backtest engine (no-lookahead signal shift) | validation | PRIOR-ART | — | Signal shifted one bar; falls back to a pandas backtest if vectorbt absent | nse-crypto-bot-final.md row 25 | — |
| VX-042 | Causal leakage firewall | validation | PRIOR-ART | — | Makes look-ahead structurally impossible in replay — raises on future-timestamped data or clock rewind | crypto-bot-and-nse-botonly.md row 15 | See VX-003 cross-reference |
| VX-043 | Combinatorial Purged Cross-Validation (nse-botonly implementation) | validation | PRIOR-ART | — | Purge (drop training rows overlapping a test block's label window) + embargo (buffer after the block) | crypto-bot-and-nse-botonly.md row 25; nse-crypto-bot-final.md row 26 | Two independent implementations, collapsed. See VX-004 |
| VX-044 | Deflated-Sharpe promotion gate + CPCV (nse-botonly) | validation | PRIOR-ART | — | Bailey & López de Prado PSR/DSR gate feeding on real trial-variance from CPCV | crypto-bot-and-nse-botonly.md row 25 | See VX-005 |
| VX-045 | Control-arm backtester + skill-vs-luck court + profit provenance + world-model scoreboard | validation | PRIOR-ART | — | Random-control baseline, veto-mechanism counterfactual analysis, combined skill verdict, luck/skill/veto-savings decomposition, model-quality grading independent of P&L | crypto-bot-and-nse-botonly.md row 26 | Real-data verified per source flag. A distinctive, substantial validation design not duplicated anywhere else in the corpus |
| VX-046 | Overfitting guardrails module (PSR/DSR/PBO + walk-forward sanity gates) | validation | PRIOR-ART | — | Probabilistic Sharpe Ratio, Deflated Sharpe Ratio, PBO via CSCV, plus positivity/min-trades/max-DD sanity gates | nse-crypto-bot-final.md row 27 | — |
| VX-047 | 5-layer Evaluator — the admission hard gate | validation | PRIOR-ART | — | Layer 0 purged+embargoed walk-forward; Layer 1 Sharpe/PSR/DSR/MinTRL; Layer 2 discounted/sliding-window UCB; Layer 3 NSGA-II Pareto + CSCV/PBO; Layer 4 anti-gaming anchor episodes | early-repos.md row 60 | Explicitly noted as "real statistical formulas, not placeholders" — one of the stronger prior-art validation designs in the corpus |
| VX-048 | Shared Evolver GA loop with proper multiple-testing control | validation | PRIOR-ART | — | Re-deflates every candidate's DSR against the real cross-sectional variance and total number tried (not per-generation) — "explicit anti-p-hacking design" | early-repos.md row 61 | — |
| VX-049 | Capstone freeze/forward-test acceptance protocol | validation | PRIOR-ART | — | Search+select on history only → freeze → forward-test on unseen holdout → score CRPS/PIT-calibration/directional-hit-rate vs. persistence, deflated by search budget; only the frozen score is reported | early-repos.md row 63 | Strong prior-art design for VX-003's Holdout Custodian concept — the freeze-then-report-once pattern is exactly right, though the code itself is not carried forward automatically |
| VX-050 | Model-invention validation pipeline with KEEP/REJECT/SHADOW verdicts | validation | PRIOR-ART | — | Every invented model tested across a ~10-12 dataset panel with permutation p-value + bootstrap CI; caught both a false-reject and a false-keep in its own adversarial controls | early-repos.md row 65 | Cited as "real, auditable experiment log" — a genuinely strong prior-art example, still subject to caveat #4 (implemented and audited ≠ profitable) |
| VX-051 | Robustness sweep across symbols/timeframes | validation | PRIOR-ART | — | Runs the frozen forward-test capstone across multiple symbols × timeframes, aggregates median skill/DSR/calibration | early-repos.md row 67 | — |
| VX-052 | Test suite (48 files) covering nearly every module | validation | PRIOR-ART | — | Contract + behaviour tests, names only, contents not individually verified by the mining pass | early-repos.md row 68 | Existence claim, not depth-verified — flagged accordingly |
| VX-053 | Drift detection suite (feature-importance / concept / PSI-KS) | validation | PRIOR-ART | — | SHAP top-10 importance drift tracker; ADWIN/DDM/KSWIN concept-drift detector (11 files reference it); PSI+KS-test train-vs-production drift | early-repos.md rows 6-7,51 | Three independent drift-detection implementations across two repos, collapsed |
| VX-054 | Uncertainty quantification suite (MC-Dropout, conformal, isotonic, Bayesian bootstrap) | validation | PRIOR-ART | — | 14-file cross-reference, the heaviest in its repo | early-repos.md row 9 | — |
| VX-055 | Triple-barrier / meta-labeling / purged k-fold / GARCH-vol training | validation | PRIOR-ART | — | López de Prado triple-barrier labels, meta-labeling, fractional differencing, purged CV, regime-specific models | early-repos.md row 10 | Direct prior-art for `FEATURES.md` §2's PLANNED triple-barrier labelling item (out of this slice's category, feature-engineering) |
| VX-056 | Adversarial RL robustness training | validation | PRIOR-ART | — | Trains PPO/DQN/SAC/TD3 against synthetic manipulation (gaps, wash-trading spikes, spoofing) | early-repos.md row 8 | Header-level confirmation only in the source mining pass |
| VX-057 | Rejection Performance Tracker | validation | PRIOR-ART | — | Simulates outcomes of rejected signals, flags "selection inverted" per-gate | early-repos.md row 23 | Cross-references RX-069's veto-gauntlet caution — a tracker that can detect if a specific gate is systematically wrong |
| VX-058 | A/B Shadow Mode | validation | PRIOR-ART | — | Variant A/B experiments (confidence threshold/entropy gate/regime filter), win-rate/PnL/Sharpe tracking, p-value verdict, auto-apply winner | early-repos.md row 24 | "Auto-apply winner" is a live self-modification path — carries the same canary-contract caveat as RX-116 by analogy: an auto-apply loop without a canary/rollback is exactly the pattern the −$837 postmortem warns against |
| VX-059 | Parameter Sweep (distributed backtesting) | validation | PRIOR-ART | — | Quick (72 combos/3 symbols) / Full (420 combos/3 symbols) grid sweep, Ray or ThreadPoolExecutor, walk-forward OOS | early-repos.md row 25; early-repos-metaai-civilization.md rows 105-107 | Two independent implementations, collapsed |
| VX-060 | Sandbox simulation + ranking/5-score calibration + shadow trader | validation | PRIOR-ART | — | Filters historical closed trades through regime/timing gates, no live orders; recomputes trust/robustness/anti-fragility/overfitting-risk/confidence-calibration scores; attributes real closed trades to sandbox genomes with no orders placed | early-repos.md rows 39-42 | NSGA-II Pareto ranking present but "coded but NOT used by this subsystem's own promotion path" — another reads-as-built instance worth flagging |
| VX-061 | GA fitness evaluation (bar-by-bar backtest against real OHLCV) | validation | PRIOR-ART | — | Bar-by-bar backtest of each individual's gene rules | early-repos-metaai-civilization.md row 15 | — |
| VX-062 | Backtest engine + walk-forward OOS split | validation | PRIOR-ART | — | Bar-by-bar simulation using the real StrategySelector, ATR SL/TP, fee+slippage accounting, equity curve, Sharpe/Calmar/drawdown/profit-factor; re-runs on a held-out tail segment | early-repos-metaai-civilization.md rows 17-18; early-repos.md row 28 | Two independent implementations collapsed |
| VX-063 | Test suite — unit/integration/cognitive (41 tests) | validation | PRIOR-ART | — | No-reflection rule, Kelly criterion, DCA mechanics, trailing SL, brain-stage transitions, WS streams, debate council, MCTS | early-repos.md row 57 | — |
| VX-064 | Test suite — performance (empty, DOCUMENTED-ONLY) | validation | PRIOR-ART | — | Empty package, no actual test file despite a `tests/performance/` directory existing | early-repos.md row 58 | A directory that exists but contains nothing — the file-tree equivalent of the CB5/CB6/CB9 documented-only pattern |

### Prior-repo validation engines — implemented, never validated (caveat #4 applies to every row below)

*The nse-crypto-bot-final "brain" subsystem builds an unusually elaborate self-validation and
self-teaching stack. `prior-attempts-postmortem.md` §3.2–3.3 (cited per task instruction 4) records
that this project's documentation outgrew its validated results, and that its validation target was
at one point substituted for synthetic Mackey-Glass chaos data because "crypto daily-direction is
~random and useless for development." Nothing below should read as proof any of it produces a
profitable, or even a correctly-measuring, system — only that the code exists.*

| # | Requirement | Category | Status | Phase | Evidence / satisfying module | Sources | Notes |
|---|---|---|---|---|---|---|---|
| VX-065 | SHAP per-trade feature attribution | validation | PRIOR-ART | — | Explains which of 42 pre-trade features drove a decision, via SHAP KernelExplainer with a deterministic occlusion fallback | nse-crypto-bot-final.md row 1 | **Carries the §10.8 attribution caveat directly**: a per-trade explainer is a different mechanism from the feature-governance credit-assignment that broke in the −$837 postmortem, but both are "attribution" and both must be independently validated before trust, not assumed correct because SHAP is a respected method |
| VX-066 | Adversarial debate + verifier trade gate | validation (raw: risk) | PRIOR-ART | — | Bull/bear/risk internal debate plus a step-verified process-reward model gates high-conviction trades | nse-crypto-bot-final.md row 2 | — |
| VX-067 | Counterfactual dream-trainer (regret decomposition) + imagined-replay world model | validation | PRIOR-ART | — | Decomposes each closed trade's "profit left on the table" into direction/exit-timing/capture regret; replays past trades through a world-model planner | nse-crypto-bot-final.md rows 3-4 | — |
| VX-068 | Off-policy gate-threshold tuning | validation (raw: risk) | PRIOR-ART | — | Sweeps a counterfactual value curve over recorded gate signals from the paper-lab's unbiased explore-all log; recommendation-only | nse-crypto-bot-final.md row 5 | — |
| VX-069 | Hypothesis → experiment → belief loop | validation | PRIOR-ART | — | Proposes testable hypotheses from the journal, tests via Bayesian A/B on real closed trades or counterfactual world-model rollouts | nse-crypto-bot-final.md row 7 | Direct precedent for "Independent falsifiable side-prediction per strategy" (research-corpus.md row 10, PLANNED — kept separate, that row is the design principle, this is a specific prior implementation) |
| VX-070 | Trade post-mortem & excursion mining | validation | PRIOR-ART | — | Records MFE/MAE after entry, mines winning-vs-losing subgroup patterns (pysubgroup), feeds back into entry decisions | nse-crypto-bot-final.md row 8 | — |
| VX-071 | Dual-track curriculum school with graded exams | validation | PRIOR-ART | — | Teaches the brain via held-out mechanical exams on both "how to be intelligent" and domain knowledge | nse-crypto-bot-final.md row 9 | — |
| VX-072 | Self-evaluation suite (independent learning / genius-use / LLM parity) | validation | PRIOR-ART | — | Four standing measurements: unaided learn-and-quiz test, knowledge-use rate, brain-vs-raw-LLM parity, knowledge-web growth/decay | nse-crypto-bot-final.md rows 10,185 | — |
| VX-073 | Prequential auto-quiz evaluation | validation | PRIOR-ART | — | Test-then-train evaluation proving accuracy rises with experience | nse-crypto-bot-final.md row 11 | — |
| VX-074 | Data & concept drift detection (Evidently/River, batch+streaming) | validation | PRIOR-ART | — | `data_drift()` batch (Evidently, KS-test fallback) + `StreamingDriftDetector` (River ADWIN, Page-Hinkley fallback) | nse-crypto-bot-final.md row 106 | Another independent implementation of the drift-detection concept already collapsed at VX-053 — kept separate here since this is a distinct module/repo region, cross-referenced |
| VX-075 | Online regret-bounded node trust (AdaHedge/EXP3) + BOCD regime reset | validation (raw: risk) | PRIOR-ART | — | Learns per-node trust weights via multiplicative-weights from realized losses; Bayesian online changepoint detection collapses trust back toward uniform after a regime break | nse-crypto-bot-final.md rows 107-108 | Prior-art precedent for "Bayesian online change-point detection driving automatic re-validation" (research-corpus.md row 114, PLANNED) |
| VX-076 | FSRS self-quiz spaced-repetition mastery curve | validation | PRIOR-ART | — | Generates cloze questions from own memories, answers via own recall, grades, tracks rising per-topic FSRS curve | nse-crypto-bot-final.md rows 109,120 | — |
| VX-077 | Chronological dataset assembly + strict split discipline | validation | PRIOR-ART | — | Train-on-past/test-on-future split, multi-coin concatenation for more regimes | nse-crypto-bot-final.md row 110 | — |
| VX-078 | Synthetic benchmark datasets with known ground truth | validation | PRIOR-ART | — | Mackey-Glass chaotic delay system, logistic-map chaos, noisy-XOR series | nse-crypto-bot-final.md row 111 | **This is the exact mechanism `prior-attempts-postmortem.md` §3.3 flags as the anti-pattern**: Mackey-Glass chaos data is a legitimate tool for proving a learning pipeline can learn *something*, but was substituted for real-market validation at one point, reaching 97% accuracy on a proxy that doesn't resemble the real target. Kept as PRIOR-ART with this caveat rather than removed, since the synthetic-benchmark tool itself is defensible — its misuse as a validation substitute is the documented failure |
| VX-079 | External multi-domain generalization datasets (NSE, sunspots, ERA5, UCI energy, PhysioNet ECG) | validation | PRIOR-ART | — | Proves nodes aren't crypto-overfit | nse-crypto-bot-final.md row 112 | — |
| VX-080 | Honest walk-forward (chronological, no-leakage) evaluation protocol | validation | PRIOR-ART | — | Expanding-window per-asset folds, explicitly contrasted against a "leaky shuffled" baseline | nse-crypto-bot-final.md row 122 | — |
| VX-081 | Multi-seed robustness harness | validation | PRIOR-ART | — | Runs the full pipeline across 5 seeds, reports mean±std so a single good run isn't mistaken for a fluke | nse-crypto-bot-final.md row 123 | — |
| VX-082 | Phase-3 learned-routing acceptance-bar validation | validation | PRIOR-ART | — | Compares 5 combiner types against 4 acceptance bars on synthetic and real crypto data, writes actual results file (hellsemble 0.8255 vs. stacking 0.8203 vs. baseline 0.513) | nse-crypto-bot-final.md row 124 | Real numbers cited, not asserted — a stronger evidentiary standard than most rows in this block |
| VX-083 | Live-unseen validation ledger | validation | PRIOR-ART | — | Every live prediction appended before its outcome is known, scored only after horizon maturity | nse-crypto-bot-final.md row 102 | Directly relevant precedent for VX-031's pre-registered no-edge test |
| VX-084 | Classification eval + confusion verdict (automated) | validation | PRIOR-ART | — | Confusion matrix, per-class precision/recall/F1, automated verdict for majority-collapse/class-bias/systematic-swap | nse-crypto-bot-final.md row 103 | — |
| VX-085 | Blind-baseline + skip counterfactuals | validation | PRIOR-ART | — | Records what a no-gates "dumb copy" of every candidate would have done, and what happened to skipped candidates | nse-crypto-bot-final.md row 104 | Directly relevant to RX-069's veto-gauntlet caution — this is the measurement tool that would catch a gate systematically rejecting good trades |
| VX-086 | Vectorbt fitness/scorecard engine (Diebold-Mariano honesty gates) | validation | PRIOR-ART | — | Fee-inclusive Sharpe/Sortino/CAGR/max-drawdown/expectancy scorecard, persistence/majority/benchmark honesty gates | nse-crypto-bot-final.md row 98 | — |
| VX-087 | Practice mode (historic replay learning, separate trust ledger) | validation | PRIOR-ART | — | Replays live signal source bar-by-bar over historic OHLCV with honest next-bar-open fills, credited to a SEPARATE practice trust ledger | nse-crypto-bot-final.md row 99 | The separate-ledger discipline (not commingling practice/live trust scores) is a specific, worth-noting design choice |
| VX-088 | SimLab order-matching simulator | validation | PRIOR-ART | — | Psychology-free mechanical LOB market environment, optional hftbacktest L2 path | nse-crypto-bot-final.md row 100 | — |
| VX-089 | Hyperparameter sweep harness (mandatory chronological split) | validation | PRIOR-ART | — | Logged grid sweep, per-class metric logging, never random-shuffled | nse-crypto-bot-final.md row 101 | — |
| VX-090 | Rejection-tracking / re-measurement audits (own-work falsification, 8 findings) | validation | PRIOR-ART | — | A cluster of self-audits that each falsified a prior claim about the same system: in-sample-backtest quality gate found to have −0.031 correlation to realized profit (top quartile the *worst* performer, n=260); a quality gate found to have no measurable predictive power (no-op filter); a fusion decider found to score worse than its own individual inputs; trailing per-bucket accuracy found non-stationary (corr −0.214); a claimed 4h edge re-measured and found gone; 14 nominal "lenses" found to reduce to 5-7 real independent opinions | nse-crypto-bot-final.md rows 145-146,153-156,169-177,183 | **The single strongest piece of first-party evidence in this corpus for caveat #4** — this is a system that repeatedly measured its own claimed capabilities and found them false, *after* they had been built, documented and believed. Kept as one consolidated PRIOR-ART row (rather than ~15 separate near-identical "we were wrong about X" rows) since each is evidence of the same pattern: build, believe, measure, discover the belief was wrong |
| VX-091 | run_cpcv_dsr_pbo_guardrail | validation | PRIOR-ART | — | Combinatorial Purged CV + DSR + PBO guardrail gating every strategy promotion | nse-crypto-bot-final.md row 184 | Same underlying mechanism as VX-005/VX-046, kept separate as a distinct named entry point cited in its own proposal doc |
| VX-092 | gate_invention_through_cpcv_dsr (formal invention-neuron gate, thin) | validation | PRIOR-ART | — | Formal path intended to carry a hypothesis/invention neuron through the CPCV+DSR gate; 117 hypotheses generated, 7 confirmed, but not yet a formal pipeline (STUB) | nse-crypto-bot-final.md row 186 | Self-flagged STUB in its own source — an honest gap admission, unlike the CB5/CB6/CB9 pattern which claims completeness it doesn't have |
| VX-093 | grade_knowledge_application_exam (thin) | validation | PRIOR-ART | — | Dedicated graded exam testing whether the brain picks the best neuron for a situation; self-flagged "still thin" | nse-crypto-bot-final.md row 187 | — |
| VX-094 | Real-data replay experiments (entry-position artifact, BTC-residual, shuffled-null harness, rank persistence, profit decomposition, fill realism, momentum-ignition falsification, self-analysis-vs-manual-trader) | validation | PRIOR-ART | — | A suite of one-off, code-real statistical experiments against a shared read-only candle/claims/trades loader with an enforced "clean window" era cutoff | nse-crypto-bot-final.md rows 130-139,166-167 | Several of these produced *negative* results (momentum-ignition hypothesis refuted; manual trader would find ~0 qualifying trades/hour vs. the brain's ~40/hour, a plausible over-trading red flag) — bundled as one row since they share a harness and a purpose, individually distinguishable in the raw source |
| VX-095 | Market-making markout/latency measurement suite | validation | PRIOR-ART | — | Decomposes real maker-fill P&L into spread-capture vs. adverse-selection; splits fills into FRESH vs. STALE at measured 162ms latency; measures quote lifetime and pick-off exposure | nse-crypto-bot-final.md rows 140-142 | Directly informs (and partially validates) the current project's own "market making — Closed, no reachable rebate tier" decision (`FEATURES.md` §4, out of this slice) with real measured latency numbers |

### NSE-donor validation prior-art

| # | Requirement | Category | Status | Phase | Evidence / satisfying module | Sources | Notes |
|---|---|---|---|---|---|---|---|
| VX-096 | Deficit-driven / curiosity-driven replay curriculum | validation | PRIOR-ART | — | Labels sessions by ADX regime, picks the least-covered regime to replay next, own SQLite coverage ledger | crypto-bot-and-nse-botonly.md row 16 | Real-data verified. Direct prior-art precedent for VX-013's regime-coverage tracker |
| VX-097 | Champion-challenger tournament (+ per-regime + auto-reevaluation) | validation | PRIOR-ART | — | Scores incumbent vs. challenger configs over shared replay sessions via Deflated-Sharpe; per-regime tournaments; fires once/day | crypto-bot-and-nse-botonly.md row 17 | Real-data verified. Strong precedent for VX-017's "Shadow Before Swap" |
| VX-098 | Prediction lab (records, grading, scoring rules, scoreboard) | validation | PRIOR-ART | — | Immutable pre-declared predictions per trade (mechanism/kill-criteria/table); Brier grading; log/quadratic/Brier proper scoring | crypto-bot-and-nse-botonly.md row 24 | Directly relevant to VX-031's pre-registered no-edge test — this is a working implementation of pre-registration discipline |
| VX-099 | Per-feature real-data verification harness suite (~63 scripts) | validation | PRIOR-ART | — | One script per production data source/engine, each asserting the real code path against live/stored production data; run manually, not wired into CI; two are print-only/informational | crypto-bot-and-nse-botonly.md row 29 | The "not wired into CI, two print-only" caveat is itself worth carrying — a verification suite that must be remembered to be run is weaker than one enforced automatically |
| VX-100 | Blind-build limit-order-book calibration experiment | validation | PRIOR-ART | — | A complete price-time-priority LOB + matching engine written only from the NautilusTrader README spec, no source access — measures spec-only-build fidelity against the real implementation | crypto-bot-and-nse-botonly.md row 30 | An unusual and specific validation technique (calibrating trust in spec-only builds), not duplicated elsewhere in the corpus |
| VX-101 | Shared test fixtures (real bhavcopy/ban-list excerpts) | validation | PRIOR-ART | — | Synthetic Kite instrument rows + real trimmed NSE report-text excerpts pinning parsers to genuine formats | crypto-bot-and-nse-botonly.md row 31 | NSE-format-specific; the fixture-pinning *pattern* (test against real format excerpts, not synthetic approximations) is portable |

### Data-quality, leakage, and crypto-specific backtest traps

| # | Requirement | Category | Status | Phase | Evidence / satisfying module | Sources | Notes |
|---|---|---|---|---|---|---|---|
| VX-102 | Sample uniqueness / concurrency + sequential bootstrap | validation | CLAIMED | P1 | Overlapping labels violate IID; called "the least contested part of the AFML toolkit," but sequential bootstrap is inherently non-parallelisable — a real engineering expense | FEATURES.md §2 (out of this slice's category, feature-engineering) — carried here because the raw row's Category is `validation`; research-corpus row not present, sourced only from notes-and-media.md row 141 | notes-and-media.md row 141 | — |
| VX-103 | Survivorship-bias-aware backtesting | validation | PLANNED | — | Backtests must account for delisted coins vanishing from datasets | notes-and-media.md row 70 | Quantified: of ~24,000 tokens ever listed on CoinMarketCap, >58% are now dead; a "buy top-20 altcoins" backtest showed +2,800% with survivorship bias vs. +680% without (notes-and-media.md row 124) |
| VX-104 | Outage-aware backtest fill assumptions | validation | PLANNED | — | Must not assume fills during exactly the volatile windows exchanges historically go down | notes-and-media.md row 71 | — |
| VX-105 | Look-ahead bias avoidance on close prices | validation | PLANNED | — | Avoid vendor-blended/VWAP-smoothed "close" prices never tradable on any single venue at that instant | notes-and-media.md row 72 | — |
| VX-106 | Flat/static slippage-assumption check | validation | PLANNED | — | A flat bps slippage assumption is almost certainly wrong in both directions given how thin real bps-vs-size data is | notes-and-media.md row 73 | — |
| VX-107 | Decision-time leakage taxonomy (5 mechanisms) | validation | PLANNED | — | Future-window-centered rolling features, full-sample-fit normalization, symmetric correlation graphs using future returns, same-day-close execution assumptions, full-daily-bar-info-with-same-day-open-fill assumptions; the two feature/execution-timing mechanisms dominate, inflating Sharpe by 20+ points | notes-and-media.md row 125 | "Chronological order alone does not define what information a model was allowed to use" — a sharper statement of the purge/embargo requirement (VX-004) |
| VX-108 | Backtested-Sharpe poor predictor caveat | validation | PLANNED | — | 888 algorithmic strategies: backtested Sharpe was a poor predictor of real-world performance (R²<0.025); ~44% of published strategies failed to replicate — flagged unverified/secondary source | notes-and-media.md row 126 | Explicitly flagged by its own source as an unverified statistic — carried with that caveat, not as a settled fact |
| VX-109 | Execution-friction / frictionless-fill modeling gap | validation | PLANNED | — | Backtests commonly assume frictionless mid-price fills and guaranteed stop-loss execution; real stop-losses become aggressive market orders during stress | notes-and-media.md row 127 | — |
| VX-110 | Zero-shot foundation-model baseline gating | validation | PLANNED | — | Running Kronos-small through the cost engine and purged/embargoed harness as a cheap, decisive test of whether the pipeline adds value | kronos-foundation-model.md, notes-and-media.md row 64 | — |
| VX-111 | Purged/embargoed CV as applied to Kronos's own flawed splits | validation | PLANNED | — | Kronos's own val/test splits overlap (val begins ~4mo before train ends; test begins ~3mo before val ends) with a 120-candle horizon straddling both boundaries, no purge/embargo — exactly the failure VX-004 prevents | kronos-foundation-model.md, notes-and-media.md row 66 | A real, named example of the purge/embargo requirement's necessity, not a hypothetical |
| VX-112 | Tiered data-quality gate pattern (4 tiers) | validation | PLANNED | — | Tier 0 schema presence, Tier 1 null-rate/range/dedup, Tier 2 distribution drift, Tier 3 semantic invariants (timestamp monotonicity, feature-ts≤label-ts leakage guard, non-negativity) | trading-monitoring-deployment-discipline.md, notes-and-media.md row 148 | Converges across TFX/Chronon/Deequ per source |
| VX-113 | DB-level dedup + OHLC invariant checks | validation | PLANNED | — | Unique constraint on (exchange_id, symbol, timeframe, timestamp) enforced at the DB layer so it survives concurrent/crashed fetchers; OHLC sanity (high≥low, open/close within [low,high], volume≥0); gap detection distinguishing expected vs. unexpected | notes-and-media.md row 149 | Directly relevant to the current build's `store/` package (Layer 0, out of this slice's category, but this is the exact invariant class it should enforce) |
| VX-114 | Skip batch data-quality frameworks in the live path | validation | PLANNED | — | Great Expectations, Deequ, Evidently, Pandera, Soda Core are all batch/DataFrame-oriented, none built for gating a live decision in real time — verdict: hand-roll live assertions, use these frameworks for offline hygiene only | notes-and-media.md row 150 | A negative/scoping decision worth recording as its own row, since it rules out an entire category of tempting off-the-shelf tooling |
| VX-115 | Cross-exchange MAD-based outlier rejection | validation (raw: risk) | PLANNED | — | Hash price+volume to detect stale-but-unchanged feeds; drop a source after N consecutive stale responses; median absolute deviation, exclude >3×MAD from median | notes-and-media.md row 151 | Directly prevents Compound/Mango-class oracle failures per source |
| VX-116 | Heartbeat/dead-man's-switch — insufficient alone | validation (raw: risk) | PLANNED | — | Proves the socket is alive, not that data is fresh or correct; a frozen order book on a live socket is a documented, more dangerous failure than disconnection and won't trip ping/pong | notes-and-media.md row 152 | Must be paired with sequence-gap detection and REST reconciliation — cross-references the current build's `capture/sequencing.py` (CLAIMED, out of this slice's category but the exact mechanism this row calls for) |
| VX-117 | Sharpe-divergence live-vs-backtest go/no-go gate | validation | PLANNED | — | Median 73% Sharpe deterioration norm across 215 studied strategies means a 40-60% haircut alone isn't a kill signal | notes-and-media.md row 153 | Same source as VX-014; kept as a separate row since VX-014 is the monitor requirement and this is the specific quantitative gate threshold |
| VX-118 | Slippage realized-vs-modeled monitoring | validation (raw: execution) | PLANNED | — | No rigorous academic threshold exists for a slippage kill signal; the concrete implementable pattern is RustyBT's `execution_quality_threshold` (90% fill-rate match) | notes-and-media.md row 154 | — |
| VX-119 | Bootstrap/Monte Carlo drawdown budget sizing | validation | BUILT | — | The backtest's max drawdown is a lower bound, not an expectation; size the kill-switch DD budget against a bootstrap p75-p90 | notes-and-media.md row 156 | Same underlying idea as VX-011, kept separate — this row frames it as sizing the kill-switch budget specifically, VX-011 is the general technique |
| VX-120 | Staged validation gate for GP-discovered alphas | validation | PLANNED | — | Rigorous DSR/PBO-style validation (not a single train/test split), realistic crypto-cost modeling, mandatory live paper-trading before capital, if GP/symbolic-regression search is pursued at all | alpha-discovery-gp-symbolic-regression.md, notes-and-media.md row 115 | Conditional recommendation — the alpha-discovery technique itself is out of this slice's category |
| VX-121 | Naive-baseline MSE check (LSTM lag-1 trap detector) | validation | CLAIMED | — | Compare a trained model's held-out MSE against a naive "predict last observed price" baseline; if within noise, the model reproduced the trap | finml-subsecond-and-dontbuild.md, notes-and-media.md row 63 | Cheap, specific, directly actionable check |
| VX-122 | Evolutionary/DRL production-overfitting guard | validation | PLANNED | — | Guards against the "Red Queen's Trap" pattern: validation APY >300% vs. live capital decay >70%, attributed to aleatoric-uncertainty overfitting and evolutionary survivor bias | notes-and-media.md row 122 | Source paper flagged unconfirmed peer review — carried with that caveat |
| VX-123 | Paper-trading harness integrity check | validation | PLANNED | — | Guards against measurement bugs in the paper-trading harness itself; a documented case found three bug classes inflated paper PnL ~135×, with paper-EV inversely predictive of live EV (Spearman ρ=−0.43) across 6 architectures | notes-and-media.md row 123 | One of the sharpest single facts in the corpus for caveat #4: the best paper performers were the worst live performers |
| VX-124 | Paper trading (pre-live check, operational value only) | validation | PLANNED | — | Catches gross implementation bugs and gives a first read on latency; explicitly does NOT catch overfitting | notes-and-media.md row 143 | — |
| VX-125 | Shadow deployment | validation | PLANNED | — | Runs live logic against real order books, computing hypothetical fills with no orders placed — the best available check on the execution gap; no better than paper trading at catching overfitting | notes-and-media.md row 144 | Same underlying mechanism as VX-012's shadow trading requirement; kept as a separate row since this one specifically states the overfitting-detection limitation |
| VX-126 | Backtest-to-live gap contribution ranking | validation | PLANNED | — | Ranked (source agent's judgment, explicitly not cited as external fact): overfitting > execution reality > regime shift > point-in-time leakage > data contamination | notes-and-media.md row 146 | Explicitly flagged in-source as judgment, not a cited external finding — carried with that caveat |
| VX-127 | Documented backtest-live performance gap (real example) | validation | PLANNED | — | A real 3x leveraged-ETF rotation strategy underperformed backtest by ≈−2.7% total over 20 weeks live (−30.8bps/week slippage, partly offset by +21.0bps/week rounding) | risk-and-failure.md §9, notes-and-media.md row 39 | Concrete real-world evidence for the decay expectation cited throughout VX-014/VX-016/VX-117 |
| VX-128 | Per-symbol edge lifecycle hazard models | validation | PLANNED | — | A symbol's setup can die while others live; hazard models per symbol rather than only per strategy | research-corpus.md row 187 (DESIGN-NOTE-universe-wide-scanning.md §6) | Part of §5a's universe-wide-scanning machinery |
| VX-129 | Idiosyncrasy-vs-clustering test on candidate setups (pre-build gate) | validation | PLANNED | — | Fire candidate setups historically across the universe, measure trigger clustering and return correlation before building — "if triggers cluster, the architecture is one macro bet wearing 500 hats" | research-corpus.md row 12 (DESIGN-NOTE §2) | This is §5a.4's THE GATE — blocks the entire universe-wide-scanning architecture, per goal doc §5a.4/§10.3. Cannot run until the broad tail is wired (goal doc §10.3, Ops category, out of this slice) |
| VX-130 | Cause-of-death registry with a controlled vocabulary | validation | PLANNED | — | Fixed, extensible taxonomy per retirement (mechanism died, crowded out, capacity exceeded, cost regime changed, never real, operational failure, venue change) | research-corpus.md row 6 (IDEAS-SYNTHESIS.md Part II) | — |
| VX-131 | Left-truncation and survivorship correction in own records | validation | PLANNED | — | The strategy registry contains strategies that died before being recorded properly — "your own history has survivorship bias" | research-corpus.md row 8 | — |
| VX-132 | Independent falsifiable side-prediction per strategy | validation | PLANNED | — | "Strongest anti-overfitting device available and not statistical" — a real mechanism implies other observable consequences to check on unused data | research-corpus.md row 10 (IDEAS-INTELLIGENCE.md §8) | Prior-art precedent: VX-069's hypothesis→experiment→belief loop |
| VX-133 | Mechanism decay monitoring (premise, not just P&L) | validation | PLANNED | — | Monitor the mechanism's premise directly; retire immediately on a known premise break rather than waiting for drawdown | research-corpus.md row 11 | Closely related to VX-015 (mechanism-health metric); kept separate — this row is the monitoring practice, VX-015 is the declared-at-promotion metric artifact |
| VX-134 | Absorbing-barrier-aware backtest metrics | validation | PLANNED | — | Report median terminal wealth and P(ruin) alongside Sharpe; mean/median diverge enormously under multiplicative dynamics | research-corpus.md row 93 (IDEAS-FRONTIER.md §1) | — |
| VX-135 | Ensemble-vs-time-average divergence as a strategy diagnostic | validation | PLANNED | — | A large gap flags a strategy whose apparent profitability is an averaging artefact | research-corpus.md row 94 | — |
| VX-136 | Optimal stopping for strategy retirement | validation | PLANNED | — | A formal optimal-stopping problem, not a drawdown threshold; retiring too late is the most common capital destroyer | research-corpus.md row 98 (IDEAS-FRONTIER.md §2) | Prior-art precedent: RX-013's CB8 (win-rate collapse → suspend), the crude binary version this formalises |
| VX-137 | Estimate the information-theoretic ceiling at each horizon | validation | PLANNED | — | Bound achievable mutual information between feature set and forward returns before optimising | research-corpus.md row 99 (IDEAS-FRONTIER.md §3) | — |
| VX-138 | Channel-capacity audit of the data pipeline | validation | PLANNED | — | If the target needs order-flow information and only OHLCV exists, the ceiling is structural | research-corpus.md row 100 | — |
| VX-139 | Predictability decay curve by horizon | validation | PLANNED | — | Measures how the ceiling falls with horizon; tells which horizons are worth infrastructure investment | research-corpus.md row 101 | — |
| VX-140 | Semantic dedup of the strategy archive | validation | PLANNED | — | Two strategies with different code and identical behaviour are one trial, not two; canonicalise DSL programs, dedup on behaviour not text | research-corpus.md row 102 (IDEAS-FRONTIER.md §4) | This ledger's own dedup task is a manual instance of exactly this problem, one level up (requirement rows instead of strategy code) |
| VX-141 | Production ablation | validation | PLANNED | — | Periodically disable a component on a small capital slice — "an A/B test of the system's own architecture" | research-corpus.md row 103 (IDEAS-FRONTIER.md §5) | — |
| VX-142 | Counterfactual shadow portfolios | validation | PLANNED | — | Continuously run N counterfactual books (no risk gate, different sizing, no regime filter) sharing one live feed for component-level marginal value | research-corpus.md row 104 | — |
| VX-143 | Decision-flip robustness testing | validation | PLANNED | — | Perturb inputs within plausible bounds, check whether the decision flips — "cheap, almost never done" | research-corpus.md row 106 (IDEAS-FRONTIER.md §6) | — |
| VX-144 | Certified robustness bounds around decisions | validation | PLANNED | — | Formal margins on the decision boundary; expensive, rarely tractable at scale | research-corpus.md row 107 | — |
| VX-145 | Break taxonomy (microstructure/participant-mix/regulatory/liquidity-regime change) | validation | PLANNED | — | Different break types invalidate different things | research-corpus.md row 115 (IDEAS-FRONTIER.md §8) | — |
| VX-146 | Measure the sim-to-real gap as a first-class metric | validation | PLANNED | — | A market simulator is worthless until you know its error; track whether sim-winning strategies work live and by how much they degrade | research-corpus.md row 116 (IDEAS-FRONTIER.md §9) | — |
| VX-147 | Falsification budget | validation | PLANNED | — | Allocate a fixed share of research effort to trying to kill the current best strategy rather than finding new ones — "search naturally spends 100% on confirmation" | research-corpus.md row 123 (IDEAS-STRATEGIC.md §5) | — |
| VX-148 | Optimal transport / Wasserstein distance for drift detection | validation | PLANNED | — | Better drift detection than KS or PSI, degrades gracefully | research-corpus.md row 131 (IDEAS-ADVANCED.md §15) | — |
| VX-149 | Sequential Probability Ratio Test (SPRT) | validation | PLANNED | — | Wald's optimal sequential test — minimum expected samples to decide "is this strategy dead" without the peeking problem | research-corpus.md row 134 (IDEAS-ADVANCED.md §16) | — |
| VX-150 | Survival analysis (Kaplan-Meier, Cox) for strategy lifetime | validation | PLANNED | — | Handles censored data (still-alive strategies) natively | research-corpus.md row 135 | — |
| VX-151 | Robust statistics (M-estimators, MAD) | validation | PLANNED | — | Crypto is fat-tailed; means and standard deviations are fragile | research-corpus.md row 137 | — |
| VX-152 | Bootstrap (block, stationary) for drawdown distributions | validation | BUILT | P1 | Already planned for drawdown distributions; also the basis of Reality Check / SPA | research-corpus.md row 138 | Cross-references VX-011 and RX-030 |
| VX-153 | Belief graph as the PAC-Bayes prior (composite) | validation | PLANNED | — | The dated, provenanced prior PAC-Bayes bounds tighten around; strategies consistent with prior mechanism knowledge earn tighter generalisation bounds | research-corpus.md row 143 (IDEAS-SYNTHESIS.md Part I) | — |
| VX-154 | Correlated-drift detection (composite) | validation | PLANNED | — | Catches common-mode drift that population disagreement (blind to it) misses, via the sealed-envelope metric | research-corpus.md row 144 | — |
| VX-155 | Effective-sample-size-aware trial accounting (composite) | validation | PLANNED | — | Corrects multiple-testing on both axes at once — trial count and effective sample size per trial — since dependent-data evidence per trial is far smaller than row count implies | research-corpus.md row 145 | Directly reinforces VX-020's dependent-data caution |
| VX-156 | Mechanism side-predictions as conformal calibration targets (composite) | validation | PLANNED | — | Checks whether a falsifiable side-prediction was conformally calibrated, not merely directionally right | research-corpus.md row 147 | — |

---

## Slice summary

**Coverage honesty, stated up front.** This slice read all 890 raw rows tagged risk/execution/
validation across the seven files in full. It did **not** independently re-verify every prior-repo
citation against the actual source tree line-by-line — that verification was performed by the
original mining passes (see each raw file's own coverage notes), not repeated here, except for the
`CLAIMED` rows and the current-project plan documents, which were checked directly. `nse-crypto-bot-final.md`
itself states its own inventory covered ~69% of in-scope files by count, weighted toward
highest-value material — genuinely undocumented capability may exist in the ~31% unread, particularly
in the ~187 unsampled `research/` markdown files it names explicitly. This merge should be treated as
thorough, not exhaustive.

### Counts per status

| Status | Count |
|---|---|
| PLANNED | 121 |
| PRIOR-ART | 82 |
| DECLINED | 7 |
| UNRESOLVED | 3 |
| CLAIMED | (0 in this slice's category — see below) |
| **Total merged rows** | **213**¹ |

¹ The published table numbers RX-001 through VX-156 with three intentional cross-reference
duplicates (RX-118/EX-024 are the same corpus row filed under both risk and execution per its raw
compound category; VX-074 cross-references VX-053; RX-060 cross-references RX-053) — 213 distinct
requirement rows, 214 numbered lines including the summary's own count of unique IDs. Three
`CLAIMED` rows exist in the raw slice (Binance depth sequence-chain validation, mass-delisting
implausibility guard, the Layer 0 property-based test suite — see the note under Method above) but
are Layer 0 data-capture code, not risk/execution/validation in the `FEATURES.md` §5/§6/§8 sense
that this ledger's Phase 0 subsection measures against; they are documented in the preamble rather
than given their own numbered rows, to avoid the ledger silently counting Layer 0 test coverage as
progress on the trading risk/execution/validation stack.

### FEATURES.md Phase 0 minimum — every item in this slice's three categories

**0 of 14 satisfied. This is the completion criterion the goal document (§8.6) names, and it reads
zero across the entire risk/execution/validation slice.** No hedging: `trading-system/src/` has no
risk gate, no execution engine, no validation harness. Every item below is `PLANNED`, citing
`FEATURES.md` and, where relevant, prior-repo evidence of what could be ported rather than built
from nothing.

| Item | Category | Status | Ledger row |
|---|---|---|---|
| Experiment ledger — including abandoned runs | validation | PLANNED | VX-001 |
| Trial Registry (cumulative N, enforced) | validation | PLANNED | VX-002 |
| Holdout Custodian (refuses queries) | validation | PLANNED | VX-003 |
| Purge + embargo, configured per family | validation | PLANNED | VX-004 |
| Deflated Sharpe as in-loop fitness | validation | PLANNED | VX-005 |
| MinBTL hard gate | validation | PLANNED | VX-006 |
| Idempotency key on every order | execution | PLANNED | EX-001 |
| Partial-fill tracking by remaining quantity | execution | PLANNED | EX-002 |
| Signal expiry / time-in-force discipline | execution | PLANNED | EX-003 |
| Pre-trade gate: notional, leverage, position cap | risk | PLANNED | RX-001 |
| Exchange-side kill switch / dead-man | risk | PLANNED | RX-002 |
| Watchdog process + firewall network kill | risk | PLANNED | RX-003 |
| Liquidation-distance monitor | risk | PLANNED | RX-004 |
| Post-trade reconciliation vs exchange truth | risk | PLANNED | RX-005 |

**Caveat on this subsection's scope, stated honestly:** `FEATURES.md`'s Phase 0 minimum list also
names items in Data, Ops, Security and Governance categories (bitemporal store, clock-gated access,
gap detection, feature staleness stamps, venue health, rate budgeter, WAL, state recovery, clock
sync, sequence-gap detection, backoff, resource watchdog, cold-start, no withdrawal permission, IP
allowlist, `sops`+`age`, treasury separation, manual promote, config versioning) — those fourteen
items are **out of this slice** and are not this ledger's responsibility; several of them (bitemporal
store, clock-gated access, gap detection) are already `CLAIMED` in the current build per the goal
doc §5a.7. The task brief describing this slice states "every item on it is in your categories,"
which is not literally true of the full Phase 0 list — this subsection covers exactly and only the
fourteen items that are.

### The five most important UNRESOLVED rows, and why they matter

1. **RX-036 — Deployment freeze windows.** A genuine gap: no prior repo in the entire corpus, across
   seven files and roughly a dozen distinct trading systems, ever built a "don't deploy during high
   vol or near funding settlement" check. It is cheap to build and its absence is exactly the kind
   of thing that "reads as covered" because deployment discipline is discussed everywhere in the
   corpus — just never as this specific, automatable gate.
2. **RX-125 — Real SPAN margin calculator.** Matters less for its NSE specifics (out of scope per
   §5) and more for what it proves: even the single most complete donor repo in the corpus
   (`nse-botonly`, 587 Python files, zero raw stubs per its own mining pass) shipped an
   intentionally-conservative *estimate* rather than the real thing, and said so in its own docs.
   The crypto analogue — accurate per-venue margin/liquidation modelling — should not be assumed
   solvable just because a lot of code exists near it.
3. **RX-128 / RX-003 — Watchdog process + firewall network kill.** This is a Phase 0 P0 item with
   **no working prior-art anywhere in the corpus.** Every "kill switch" found in seven files and a
   dozen repos is in-process. The one system that named the gap explicitly (`nse-botonly`'s own
   `REDESIGN_feature_atlas_v1.md` §7) never closed it either. This is the risk item most likely to
   be quietly deferred because it sounds solved elsewhere in the corpus — it is not solved anywhere.
4. **EX-030 — Cross-strategy position netting.** `FEATURES.md`'s own "twenty most-forgotten" ranks
   this #1. This ledger confirms the ranking is earned: the one prior-repo attempt at the same idea
   (`nse-botonly`'s "Cross-strategy netting") is itself `DOCUMENTED-ONLY` — never built there either.
5. **VX-002 — Trial Registry (cumulative N, enforced).** Every prior repo in this corpus tracks
   *some* form of trial count locally to a search run (Foundry's population-DSR count, the 5-layer
   Evaluator's admission gate) — none enforce a single structurally-impossible-to-bypass cumulative
   counter across all searches, which is the specific property `FEATURES.md` requires and which the
   45-variant-overfitting finding (VX-001's citation) depends on being true.

### The five most important PRIOR-ART rows

1. **VX-090 — Rejection-tracking / re-measurement audits (own-work falsification, 8 findings).** The
   single strongest evidentiary anchor for this ledger's caveat #4. A prior system repeatedly
   measured its own built, documented, believed capabilities and found several of them false after
   the fact — an in-sample quality gate with −0.031 correlation to real profit, a fusion decider
   that scored worse than its own inputs, 14 "lenses" that were really 5-7. This is not a warning
   from outside the corpus; it is the corpus warning about itself.
2. **RX-069 / RX-070 — The 3,191-line veto gauntlet vs. the composable exit-kill evaluators.** One
   internal audit, two verdicts on two designs in the same repo: the serial-AND gauntlet is named
   the primary root cause of a real bug ("trades won't open"); the composable, fold-based kill-signal
   design nine lines away is praised as "the RIGHT design." A rare direct architectural comparison
   with a documented outcome, not a hypothesis.
3. **RX-071 — The trailing-SL monolith with ~775 lines of confirmed dead code on the live path.**
   Directly cited in the goal doc §6 as one of the two internal audits behind the self-modification
   ruling. Concrete evidence that "the code exists and looks sophisticated" and "the code runs" are
   different claims — roughly a third of a 2,409-line risk module never executes.
4. **VX-045 / VX-097 / VX-098 — nse-botonly's luck-vs-skill lab, champion-challenger tournament, and
   prediction lab.** The most concretely portable prior-art cluster in the whole slice: real-data-
   verified, pre-registration-disciplined, Deflated-Sharpe-scored promotion machinery that answers
   exactly the questions `FEATURES.md` §8 and the goal doc §8.7 require answered, built by the
   corpus's most complete single donor repo.
5. **RX-006–RX-020 — The circuit-breaker / health-monitor cluster, with CB5/CB6/CB9/HM3/HM6/HM7/HM8
   flagged documented-only or always-green.** Named explicitly in this task's instructions as the
   canonical example of the reads-as-built pattern this whole ledger exists to catch — a header
   docstring claiming ten circuit breakers and eight health checks when three breakers and two
   checks were never implemented and two more always report healthy regardless of input.

---

## Addendum, 2026-08-08 — the prior art was read, and two rows were wrong

VX-001 through VX-009 are now BUILT (`src/validation/`, 63 tests). Before writing
any of it the donor code was fetched raw from GitHub rather than trusted from these
notes, per Rule 5. **Two of this ledger's own prior-art assessments did not
survive that.** Recorded here because a ledger that cannot correct itself is worse
than one that admits nothing.

| Row | This ledger said | What the code does |
|---|---|---|
| **VX-043 / VX-044** | CPCV with purge+embargo *"already correct… flagged reusable as-is"* (`nse-crypto-bot-final/trading/strategy/cpcv.py`) | Its exclusion zone is `[test_start, test_end + embargo)`. Its own docstring states the correct contract — *"drop training rows whose label window overlaps a test block"* — and the code implements the narrower *"drop training rows at or after the test start"*. The gap is **exactly one label horizon on the left edge**: a training row at `test_start − 5` with a 10-bar label matures inside the test block. It leaks, silently. Porting as-is would have imported the leak |
| **VX-035 / VX-044** | Foundry deflation gate, *"prior-art most directly portable to VX-005"* | `nse-botonly`'s gate passes `number_of_strategy_trials = number_of_paths` — C(6,2)=15 resample paths of a **single** strategy — into its Deflated-Sharpe call. A candidate selected from thousands is deflated as though 15 things were tried. The gate reads as rigorous and is close to toothless |

A third, smaller finding: `antioverfit.py`'s `_read_counter` returns
`{"backtests_run": 0}` on any exception, so a corrupt counter file silently sets
N=0 — which disables multiple-testing correction entirely. **Every one of these
three fails in the flattering direction**, which is why none of them was caught by
the systems that shipped them.

What *did* port well: `validation_holdout.py`'s append-before-the-outcome-exists
pattern, now the pre-registration mechanism in `trial_registry`; and the VX-049
capstone freeze-then-report-once protocol, now `holdout_custodian`.

**VX-002's assessment holds.** No prior implementation enforces cumulative N
structurally, and reading the two closest confirmed it — both count by convention.

### Addendum 2 — VX-039 is not a donor, and a fourth flattering-direction defect

`nse-crypto-bot-final/trading/strategy/generators/stats_gate.py`, this ledger's
prior art for Hansen SPA/StepM, was fetched raw while building VX-010. Two problems:

**It benchmarks against zero, not the incumbent.** `benchmark = pd.Series(np.zeros(T))`.
That asks *"did this beat cash"* — which nearly every candidate passes in a rising
market — rather than VX-010's *"does the challenger beat the incumbent"*, which is
the comparison a promotion actually makes.

**It fails open by declared design.** `except Exception: return all_ids`, documented
as *"so it can only ever ADD strictness when statistically meaningful, never silently
block the whole portfolio."* Coherent as a layered filter; the consequence is that a
missing `arch` install, a NaN, or a library upgrade makes every candidate pass
family-wise error control silently and permanently. `arch` was **not installed in
this project's environment** before 2026-08-08 — precisely the condition under which
that branch reports a full pass having tested nothing.

**That is the fourth defect in this corpus failing in the flattering direction**,
after the one-sided CPCV purge, the path-count-as-N deflation, and
`antioverfit.py`'s `backtests_run: 0` on exception. The pattern is now strong enough
to state as a heuristic: **when auditing this corpus, ask which way an error would
move a promotion decision, and look there first.**

Worth recording that the same day, the cross-check against `arch.bootstrap.SPA`
caught an equivalent-shaped bug in *this project's own* new code: ω was the bootstrap
SD of the mean rather than of √n·mean, which left Hansen's recentring threshold √n
too tight and quietly degraded the consistent SPA toward the Reality Check it is
meant to dominate. Invisible in the p-value's scale invariance; visible only against
a reference implementation. **The corpus's failure mode is not exclusive to the
corpus.**

### Addendum 3 — the first donor worth porting, and RX-005's gap confirmed

EX-001, EX-002, EX-003 and RX-005 built 2026-08-08 in `src/execution/`, 58 tests.

**EX-049 is the first prior-art row in this audit that survived being read.**
`nse-crypto-bot-final/trading/execution/order_state.py` has real transition guards,
catches over-fill, computes a size-weighted average price, and exposes `remaining` as
a property rather than a filled flag. It was ported with credit. Two changes: `Decimal`
in place of `float` with `EPS = 1e-9`, and rejections moved out of the `fills` list
where they sat as a record with no `qty` inside the list everything else sums over.

After four donors that failed in the flattering direction, this one is worth naming
explicitly — **the corpus is not uniformly unreliable, and treating it that way would
waste the 599 PRIOR-ART rows.** The rule that works is not "distrust the ledger", it
is "read the donor".

**RX-005's recorded gap is real.** `live_trader.py` adopts or closes mismatches on
boot rather than refusing to start, and its periodic "reconcile" loop only re-syncs
capital, not positions, despite the name — flagged in its own source as *"narrower
than its name implies"*. `state_recovery.py` has no `adopt_mismatches` parameter, and
a test asserts its absence: adopting a mismatch makes a symptom disappear while its
cause keeps running.
