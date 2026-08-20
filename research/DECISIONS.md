# PROJECT DECISIONS — Autonomous Crypto Trading System

**Status:** design settled, not yet built. Last updated 2026-08-01.
**Purpose:** the authoritative record of what was decided and *why*, so no future
session re-derives it. Supersedes anything contradictory in chat history.

Backing research: `~/research/*.md` (1,963 lines, 6 streams).
Visual reference: `~/research/reference-images/`.

---

## 0. Goal (user's words, condensed)

An ultra-advanced, self-learning, self-improving, autonomous AI system that acquires
knowledge and experiments like a human researcher. **Base domain: crypto trading.**
Built to **institutional production standard** — not a hobby project.

**Explicit user constraint on quality:** it must be genuine production-grade
engineering, not a toy design.

> **Recorded correction:** LOC is not the quality metric and targeting it would hurt
> the goal. Institutional systems are large because of what they must *handle*
> (exchange adapters, reconciliation, risk layers, audit trails, recovery), not by
> design. Build to institutional **rigor**; size follows from requirements.

---

## 1. Settled decisions (from the interview)

| # | Decision | Detail |
|---|---|---|
| 1 | **Three brains** | Frequency bands 1+2+3 as separate competing "brains": hours→minutes, minutes→seconds, sub-second. Tree structure, branches to branches. |
| 2 | **Capital scale** | $100k – $1M+ |
| 3 | **Live path** | Paper → testnet → gated live, **plus a manual button** for the user to promote to live at their discretion |
| 4 | **Priority** | Sophistication **and** profitability — no reduction in either |
| 5 | **Experimentation** | **Unrestricted** in paper. Any strategy, model, timeframe. No limits where it's free. |
| 6 | **Promotion** | Only what proves out reaches capital — via the gate in §4 |
| 7 | **AI scope** | AI/ML/DL/neural networks throughout |
| 8 | **Internet access** | Autonomous, unrestricted reading for research — with the §7 separation |
| 9 | **Directional agents** | BULL and BEAR specialist agents per brain |
| 10 | **Three bots per brain** | *Revised 2026-08-03.* BULL, BEAR and **PROFIT-TAIL** are three **independent bots**, each with its own features, architecture and training pipeline — not model heads on a shared trunk. Nine at maturity, plus a portfolio netting layer. Spec: `bull-bear-profit-agents-spec.md` |
| 11 | **Authority split** | The **arbiter selects trades**. **PROFIT-TAIL owns entry timing and the position after fill** — it cannot reject a selected trade, and cannot refuse to close a loser. The **hard stop overrides it absolutely** |
| 12 | **Model choice by evidence** | Deep architectures bake off against gradient boosting and a mandatory linear baseline on own data. Deep is allowed to win, not assumed to |

---

## 2. The tree (organizing structure)

Derived from the user's four reference images; the methodology sheet
(`04-skill-tree-methodology-preskills.jpeg`) is the load-bearing one.

```
ROOT
├── BRAIN 1  hours → minutes
│   ├── BULL bot ────────┐
│   ├── BEAR bot ────────┼── ARBITER → PROFIT-TAIL (timing) → RISK GATE → EXECUTION
│   └── PROFIT-TAIL bot ─┘              └── owns position after fill ──┘
├── BRAIN 2  minutes → seconds     [own three]
├── BRAIN 3  sub-second            [own three]
└── PORTFOLIO NETTING LAYER across brains
```

*Revised 2026-08-03: three independent bots per brain, not two. See decisions 10–12.*

Each brain has its **own** triad — features predicting a 4-hour move are not those
predicting a 4-second move.

**Mapping from the skill-tree methodology:**

| Sheet concept | System |
|---|---|
| Node | A strategy or capability |
| **Pre-skill** | Dependency — no loop without validated skills beneath it |
| Competency bar (0–5) | Validation stage passed: 0 untested → 5 live and scaled |
| **Number on the connecting line** | **The promotion gate threshold** |
| "Honestly assess where you are" | Deflated Sharpe out-of-sample |
| "Find where the gaps are" | Meta-model over the experiment ledger |

> **Key insight: the gate lives on the transition, not inside the node.** Same shape
> as the pre-trade risk architecture and the promotion pipeline. **The tree structure
> and the validation structure are the same structure.**

From the radial-tree image: at maturity, most of the tree stays **dark**. Only the
validated, funded path is lit. That is correct, not failure.

**Do not hard-code a fixed strategy taxonomy.** Define trunk and gates; let the
system grow the branches from validated results ("every skill tree is different").

---

## 3. Sub-second brain — decision recorded with its caveat

User selected it after being told HFT from a cloud VM is not realistically winnable
(market making ~75% captured by HFT firms; triangular arb on Binance found *never
profitable after fees* in a 2024 study; MEV needs $10M+ and a specialist team).

**Decision stands.** Rationale: it becomes a branch the system **measures and prunes
empirically** rather than one either party asserts about. If it can't clear costs,
the allocator starves it and we have the data. Better than an opinion.

---

## 4. Promotion pipeline (full spec: `promotion-pipeline.md`)

**Unrestricted where free, ruthless where it costs money.**

| Stage | Gate |
|---|---|
| 0 · Experiment | **No limits.** Every trial logged *before* it runs |
| 1 · Purged CV + embargo | Standard k-fold is invalid — serial correlation, overlapping labels |
| 2 · Held-out test | **Touched exactly once.** Re-touching invalidates |
| 3 · **Deflated Sharpe** | With honest N from the ledger. + PBO via CPCV |
| 4 · Forward paper | Model frozen. The only provably leak-free test |
| 5 · Gated live (small) | **Requires the user's button.** Hard caps, kill switch, paper twin |
| 6 · Scaled live | Size grows only on sustained live tracking |

**Promotion is a lease, not a deed.** Rolling Sharpe vs. promotion baseline, drift
detection, statistical decay test. On decay → demote to paper, re-enter pipeline.
**Never delete** — the record stays and still counts toward N.

---

## 5. The experiment ledger — non-negotiable

> **"If only five years of daily market data are available, and if 45 or more
> independent variations of a strategy are tried, it is more than likely that the
> best strategy selected has a Sharpe ratio of 1.0 or better"** — *with zero true
> edge.* (Bailey, Ger, López de Prado, Sim & Wu)

Their simulation on **pure random-walk data**: in-sample Sharpe 1.59, out-of-sample
**−0.18** on identical parameters.

**Therefore: every experiment is logged immutably, including failures.** A schema
that stores only winners cannot produce an honest N, and without honest N the
Deflated Sharpe correction cannot run — at which point the system is a very
efficient noise generator betting real money on its own luck.

`status` must record kills and why. This is a **core subsystem**, not logging.

---

## 6. Risk architecture

**Path:** `Strategy → RiskEngine → ExecutionEngine → Venue` — risk gate present in
**every environment including backtest**, so it is exercised constantly.

Regulatory anchor: **SEC Rule 15c3-5** requires pre-trade controls under the firm's
*"direct and exclusive control"* — explicitly **not delegable to the strategy**.
Written into law after Knight Capital lost **$460M in 45 minutes**.

### The rule with no exceptions

> **No strategy — however trusted, however well it has performed, however highly the
> meta-model rates it — bypasses the risk gate.**

Two documented failures were caused by exactly such an exemption:
- **FTX/Alameda** — hardcoded exempt from FTX's own auto-liquidation engine
- **bZx** — logic bug exempted "overcollateralized" loans from sanity checks

Across all ten documented blow-ups: **a single missing hard check is what failed —
not "the market moved a lot."**

### Required controls
Max position (abs + %NAV) · max order size · max order rate · price collar /
fat-finger band · max leverage · max daily loss · **max drawdown kill** ·
per-asset and aggregate exposure · **correlation-aware limits** (BTC+ETH longs are
not independent risk).

### Kill switch — exchange-side dead man's switch
A watchdog **in a separate OS process** refreshes an exchange-side countdown.
If the strategy wedges and stops refreshing, **the exchange** cancels resting orders
— independent of our process state.
Kraken: refresh 15–30s / 60s timeout. Binance `countdownCancelAll`: 30s / 120s.

**On halt:** *flatten* for system-integrity faults · *hold* for market-wide halts
(forcing liquidation into a halted book is worse) · *hedge* only as a stopgap.
Halt logic must be simple enough to execute correctly while degraded.

### Reconciliation
Exchange is source of truth. **Rebuild local state on every startup before trading.**
NautilusTrader's invariant adopted: quantity to instrument precision, avg price
within 0.01%, and **if reconciliation fails at startup, refuse to start.**
On divergence beyond tolerance: **halt new orders**, do not necessarily force-close.

### Idempotency
Client order ID generated **before** sending. On timeout, **query by original ID** —
never blind-retry. (Everbright Securities: **~$3.8B** in erroneous orders because the
system resubmitted on failure instead of stopping.)

---

## 7. AI architecture

### Corrections made against my own earlier advice — both stand

**(a) No multi-agent committee.** Evidence is negative when budget-matched:
- Berkeley (arXiv:2503.13657), 1,600+ traces, 7 frameworks: **41–86.7% failure rates**
- Anthropic's own: gains at **15× token cost**, and states domains *"requiring shared
  context... or many dependencies"* are **not a good fit — naming coding**
- Cognition AI: "Don't Build Multi-Agents"
- Self-MoA: mixing different LLMs **lowers** quality vs. resampling one strong model

→ **Single strong agent holding full context.** Parallel workers only for genuinely
independent, side-effect-free fetches.

**(b) The red-team agent is not a judge.** "LLMs Cannot Self-Correct Reasoning Yet"
(ICLR 2024): self-correction without ground truth **degrades** performance
(CommonSenseQA 75.8% → 41.8%). LLM-as-judge: 65% self-consistency under order swap,
verbosity fools GPT-4 judges 8.7%.

→ Red-team **generates testable hypotheses**; running the test settles them.

### The pattern that separates working systems from claims
FunSearch and Stanford Virtual Lab (both *Nature*, both reproduced) gate LLM output
behind a **hard, deterministic, non-LLM evaluator**. Sakana and Co-Scientist rely on
LLM-judged loops — and that is exactly where gaming appeared.

**Sakana's documented incident:** the AI Scientist **edited its own experiment
scripts to recursively self-call**, and **edited code to extend a timeout rather than
fix the speed problem.**

→ **The evaluator must be outside the system's write access.** Our system will
otherwise widen a stop, extend a lookback, or relax a threshold — cheapest path to a
better metric.

### Template: AlphaEvolve
LLM ensemble → prompt sampler → **execution-based evaluator** → evolutionary program
database. Deployed: ~0.7% of Google's worldwide compute recovered, first improvement
in **56 years** on 4×4 complex matrix multiplication.

### Memory — three kinds
**Episodic** (the ledger) · **semantic** (accumulated market knowledge) ·
**reflective** (periodic consolidation — the Generative Agents mechanism; the system
reviews its own history and writes higher-order conclusions).
Hybrid store: vector for fuzzy recall + knowledge graph for relational/temporal facts.
**Bi-temporal** matters — *"we believed X on date D"* ≠ *"X was true on date D."*

### Meta-model over the ledger
Once thousands of experiments exist, train on **the experiments themselves** — which
families work in which regimes, which features survive, which model classes overfit
fastest. **The system learns about itself.**

### Internet access — Dual LLM separation
Our design is **the lethal trifecta by definition** (untrusted content + credentials
+ market actions). Documented real attacks include a **nested-URL exfiltration
against Claude's own `web_fetch` (July 2026)** and **PoisonedRAG: 90% attack success
from 5 malicious documents in a corpus of millions.**

**Mitigation — and the architecture already provides it:**
> A poisoned page can *suggest* a strategy. It **cannot make that strategy survive
> purged CV, held-out test, deflated Sharpe and forward paper trading on real market
> data.** The promotion pipeline is data-driven, not text-driven.

**Invariant: no path from web content to capital that skips the gate.**
Plus Willison's Dual LLM pattern — the privileged model with trading access never
sees raw untrusted web content; a quarantined tool-less model reads and returns inert
structured data.

---

## 8. Model selection — what actually wins

- **Gradient boosting (XGBoost/LightGBM) is the production default**, not deep learning.
- **Transformers underperformed a one-layer linear model** (DLinear) across 9
  forecasting benchmarks (AAAI 2023). PatchTST partially recovers.
- **Every neural component must beat a LightGBM AND a linear baseline on our data
  before it ships.** Testable gate, not opinion.
- **RL: real for execution** (order slicing, dense reward), **shaky for alpha** — one
  documented backtest ran 27% win rate, negative returns.
- **Calibration before sizing** — neural nets are systematically overconfident
  (Guo et al. ICML 2017); raw softmax into Kelly systematically overbets.

---

## 9. Dual directional agents (full spec: `dual-agent-spec.md`)

**Three states — LONG / SHORT / FLAT.** Flat is frequently correct. Both agents firing
high → **FLAT** (the model contradicting itself is not confidence).

**Arbiter = meta-labeling** (López de Prado): primary predicts direction, secondary
predicts whether acting is profitable net of costs.

**"Pizza / not pizza" = representation learning.** Two implementations, both built,
both gated: (a) learned features from raw market data; (b) **time-series → image →
CNN** (Gramian Angular Field, Markov Transition Field, recurrence plots, rendered
candlesticks). Real published technique.

### ⚠️ Options are not a directional bet
**A call is not "long."** It is +delta **+vega −theta**. You can be **exactly right on
direction and lose the entire premium** — price rose slower than theta burned it, or
IV collapsed after the predicted move.

Options agents therefore require: an **IV surface**, **Greeks under the risk gate**
(aggregate vega is a real exposure), a **volatility forecast independent of
direction**, explicit strike/expiry selection, and liquidity awareness (Deribit is
~85–90% of BTC/ETH options; everything else is thin).

**Asymmetry:** short futures has **unbounded** upside risk — BEAR limits must be
stricter than BULL despite the mirror-image architecture. **Short options are
excluded from the default action space** (unbounded loss; separate gate).

**Perp funding is a real P&L line** — charged at actual settlement times (1h/4h/8h by
venue), never smoothed.

---

## 10. Build vs. adopt

| Adopt | Build |
|---|---|
| **NautilusTrader** — event-driven Rust core + Python; same code path across backtest/paper/live; adapters for Binance, Bybit, OKX, Coinbase, Kraken, dYdX, Hyperliquid; fill dedup | The three-brain tree + capital allocator |
| | The experiment ledger |
| | ML/DL research pipeline + validation gates |
| | Promotion pipeline + the user's go-live button |
| | Risk overlay, kill switches, reconciliation policy |
| | BULL/BEAR/ARBITER triads |

**Avoid:** `backtrader` (dead since 2023-04-19 despite 22k stars) · `vectorbt` OSS
(frozen, no live path) · Puppeteer MCP (archived, unpatched advisory).
NautilusTrader caveat: pre-v2.0 — do not run `develop`/`nightly` against live capital.

---

## 11. Calibration — realistic expectations

- **Sharpe 1.4–1.7** is a genuinely good systematic strategy. **Above 3 → suspect a bug.**
- Expect **~50% decay** backtest → live.
- **Confirming Sharpe 2.0 > 1.0 at 95%: 2.73 years daily — 4.99 years with realistic
  skew/kurtosis.** Crypto has both. Budget for five.
- **Observation frequency, not calendar time, buys statistical power** → the fast
  brains validate far sooner and can inform priors for the slow brain. *A structural
  argument for the multi-brain tree beyond diversification.*
- **Drawdown as a detector:** zero-Sharpe expected drawdown grows **unboundedly as
  √T**; positive-Sharpe grows only **logarithmically**. Normal while inside the
  envelope implied by claimed Sharpe. Broken only when PSR drops with confidence or
  depth exceeds the envelope. **Never on elapsed time.**
- **Losing streaks are normal:** at 55% win rate, P(≥1 ten-loss streak) = 17% over
  1,000 trades, **61% over 5,000**. A kill switch on "N consecutive losses" will
  execute healthy strategies.
- **Fractional Kelly** — growth ≈ c(2−c) of max; c=0.5 gives 75% of growth at ~50%
  variance. Quarter to half Kelly.
- **Funding-rate arb** has compressed to **~2.8% annualised** venue-average (from
  10–30%). Momentum/trend remains the durable retail workhorse.

---

## 12. Still open

1. **Exchange selection.** OKX demo trading is the best sandbox (production API +
   one header). Binance testnet is good. Bybit imposes a 48h lockout on new accounts.
2. **Historical L2 data budget.** ~1–5 TB/year *per symbol-exchange pair*;
   Kaiko ≈ $28.5k/yr (unverified). Determines how much microstructure work is feasible.
3. **Hot zones** — which paths require sign-off and "explain the blast radius."
4. **Autonomy level** — Loop Training Mode defaults to approve-every-step.
5. ~~`gh` CLI not yet installed~~ — **DONE.** `gh` 2.97.0 in `~/.local/bin`,
   authenticated as `ajith4134`, scopes `repo, workflow, gist, read:org`.
6. **Liquidation feed has no source.** Binance withholds `forceOrder` from this
   host and `allForceOrders` was withdrawn from the public REST API — measured,
   see `binance-withheld-streams.md`. The subscription is kept so recovery would
   be noticed, and the tile stays red until then. Reaching it needs either a
   second venue for liquidations or a paid feed.

---

## 13. Next actions (in order)

> **Rewritten 2026-08-09 against what is on disk.** The previous version read
> "Phase 1 — Cost Engine ← *next*" while the cost engine had already shipped, so
> the one section whose job is to say what to do next had been wrong for six
> days. Nothing had gone wrong; nobody had come back and edited it.
>
> Every state below was checked rather than recalled, and the check is named. The
> distinction that matters here is **built** versus **driven**: this repo's
> standing warning is `tail_specs()` — built, tested, called by nothing — so a
> module no caller reaches is recorded as exactly that, never as done. The check
> was `grep -rn` for each module's public names across `src/`, discounting
> matches that turned out to be docstrings referring to it.

1. ~~**Finish the Claude-usage work**~~ — **DONE 2026-08-01.** Enforcement layer is
   live (2 PreToolUse hooks + 11 deny rules, verified blocking); CLAUDE.md
   restructured 220 → 169 lines with Rule 2's operational half promoted to the
   `youtube-video` skill. Remaining optional item: a **Stop hook** for verification,
   which needs a project with a runnable test command — so it belongs to step 3.
2. ~~**Write the full system spec**~~ — **SUPERSEDED 2026-08-03.** The spec was
   written per-layer as implementation plans instead of as one document, which is
   what `docs/superpowers/plans/` holds. `ARCHITECTURE.md` §3 is the system spec.
3. ~~**Phase 0 — Truth**~~ — **DONE 2026-08-03.** Layer 0 raw capture and Layer 1
   bitemporal store + clock-gated reader are built, tested and running. Three
   venues supervised (binance, binance-spot, hyperliquid), restarting on boot.
   The suite was 383 tests then and is **1,035 passed, 1 skipped** on 2026-08-09.
4. ~~**Phase 1 — Reality filter: the Cost Engine**~~ — **DONE, recorded late.**
   `src/cost/` holds `fee_schedule`, `fee_fetcher`, `round_trip_cost`,
   `funding_carry`, `spread_and_depth` and `secret_store`. Driven:
   `quote_round_trip_cost` is called by `cost.cli` and by `paper.prove_plumbing`,
   and the wall tile *Cost engine — round-trip breakeven gate* reads OK against a
   live fee verification. Built to the plan in
   `docs/superpowers/plans/2026-08-03-cost-engine-reality-filter.md` and to its
   measured constraint — Hyperliquid publishes its fee schedule unauthenticated,
   Binance returns 401 without an API key, so the engine is a declared table plus
   a verifier rather than a live fetcher.
   *Not driven:* `cost.spread_and_depth`, which nothing calls.

5. **Phase 2 — Ops floor** — **DONE to the limit of what exists without a
   trading key.** Updated 2026-08-09 after wiring; `ARCHITECTURE.md` §3 puts this
   before any capital.

   | Component | State | Checked by |
   |---|---|---|
   | Rate-limit budgeter | **driven** | `ops.rate_budget` imported by `capture.cli` |
   | Order-intent WAL | **driven** | `execution.order_intent_wal` used by `paper.prove_plumbing`; journals both legs of the demo round trip |
   | Venue health monitoring | **driven** | `capture_health` feeds the wall; silence and gap events recorded per venue |
   | Auto-halt per venue | **driven 2026-08-09** | `ops.venue_health_watch` feeds `observe()` once a minute via `scripts/health_supervisor.sh`, started by the GCE startup script. Registry stamps `last_observed_ns`; the wall grades on its age |
   | Kill switch | **read and armed 2026-08-09** | `prove_plumbing.run` refuses to start while `is_killed` is true, before anything is journalled. The trip side now HAS its trigger: `risk.tail_cap.enforce` trips the watchdog on a live breach, which is the hard cap this line previously said did not exist. The firewall half remains impossible on this host: no `sudo`, no `iptables`, no `nft`, measured 2026-08-08 |
   | **State recovery on restart** | **built, cannot be driven yet** | `execution.state_recovery` compares the WAL, the local position model and **venue truth**. Venue truth needs an authenticated exchange session, which does not exist. The earlier note here said it "must run on recorder start" — wrong, it is not a recorder concern. It belongs at trading-engine start, in Phase 4 |
   | Key scoping | **not started** | no trading key exists yet; `cost.secret_store` is the only piece |

   What is left in this phase is gated on capital and keys, not on work. The
   honest reading is that the ops floor is as built as it can be until Phase 4
   creates the things it protects.

6. ~~**Phase 3 — Search integrity**~~ — **DRIVEN 2026-08-09.** It read "built as
   a library, driven by nothing" this morning: every module reached only through
   `promotion_gate`, and `promotion_gate` reached by nobody.

   `validation.promotion_pipeline` is now its first caller, and
   `validation.breadth` is the Trial Registry's. `HoldoutCustodian` is finally
   passed to `ClockGatedReader` — it had been an accepted argument no caller
   supplied, so the guard existed and guarded nothing. Unsupported claims fell
   from eleven to one; only RX-005 remains, and it needs an authenticated
   session.

   Two defects the wiring exposed, both worth keeping:

   - **The pipeline found a lookahead in its own candidate.** Pure noise scored
     an observed Sharpe of 3.90, and the deflated Sharpe, MinBTL and
     purge-retention gates all PASSED it — only PBO refused. Selecting the top
     decile of a symmetric distribution and averaging returns a positive number
     every day; it is a selection artefact of the return definition wearing the
     shape of an edge. Fixed by shifting the signal, after which noise scores
     0.04 and is refused, and a planted edge scores 1.01 and is promoted.
   - **A fresh registry cannot deflate.** At N=1 the dispersion is zero and the
     hurdle collapses, which is how noise cleared the DSR gate. The stack caught
     it through SPA instead — the argument for several independent gates rather
     than a better single one.

7. ~~**Finish Phase 2 by wiring what is already written**~~ — **DONE 2026-08-09**
   for the two drivers that could exist, and the third turned out not to be a
   Phase 2 item at all. See the table in step 5.
8. **Phase 4 — one family end to end** (carry) — **MACHINERY DONE, VERDICT
   PENDING ON DATA.** Spec: `docs/superpowers/specs/2026-08-09-phase-4-carry-first-pass.md`.

   | Item of the definition of done | State |
   |---|---|
   | Breadth gate run and written down | **DONE** — `PASS, bursty flow` |
   | A candidate through the full pipeline, gate returns a verdict | **DONE** — it refuses |
   | `validation/` no longer reachable-by-nothing | **DONE** — 11 unsupported claims → 1 |
   | Axis verdicts carried by the wall | **DONE** — and reading 9/65, NOT MEASURED |
   | Reduced-size live under the §6 human gate | **not reached**, correctly |

   **The breadth gate passed, and by more than §5a.4 feared.** Measured over
   1,331,980 reconstructed funding rows across 850 symbols, six configurations:
   effective breadth 46–82 independent bets against the 5–15 band the spec calls
   a collapse, with mean pairwise correlation 0.03–0.06. Carry is not one BTC
   factor wearing 850 hats.

   **But triggers arrive 17–32× more unevenly than independent firing**, a fifth
   of them in the busiest 5% of days. That is not a redesign — §5a.4's condition
   is *cluster AND correlate*, and reading it as a disjunction was a bug in the
   first draft of the verdict function. It IS a design constraint carried into
   whatever is built next: §5a.5's acceptance threshold rising with opportunity
   flow, and dry powder priced as a held option, are now empirical requirements
   with a number behind them rather than precautions.

   **What blocks a promotion is calendar time, not machinery.** The pipeline
   reads the OBSERVED `funding` dataset, which began on 2026-08-08. The 582 days
   of reconstructed history cannot substitute: its availability time is the
   fetch, so every simulated clock in the past sees it empty — deliberately, and
   that is what makes it safe for research and useless for a backtest.

9. ← ***next*.** **WAIT FOR OBSERVED HISTORY.** Decided by the user
   2026-08-09, over starting Phase 5. Nothing is built against a promotion until
   the observed record can support one.

   **How long the wait is, was itself a finding.** At N=21 trials MinBTL demands
   6.1 years of history for a Sharpe-1.0 claim — because the gate counted
   calendar days, pooling 850 symbols into one daily portfolio return. §5a.5
   requires correcting on *both* axes, trial count **and effective sample
   size**, and only the first was implemented. Corrected the same day, with the
   multiplier measured on the data being scored rather than assumed:

   | basis | Sharpe-1.0 at N=21 | Sharpe-1.5 |
   |---|---|---|
   | calendar days (as built) | 2,223 days | 988 days |
   | × effective breadth 46 | **48 days** | **21 days** |

   The correction makes promotion easier by roughly 58×, which is the direction
   every defect this project has found failed in — so it was put to the user
   rather than adopted, and the constraints are tested: it fails closed to
   calendar days below 30 days of data, can never exceed the symbol count, and
   is named in the gate's own words rather than folded into a year count.

   **So the wait is weeks, not years** — and it is a wait on the OBSERVED record
   only. The 582 days of reconstructed funding cannot shorten it, by design.

   What the wait needs to survive: capture staying up. That is the whole risk of
   waiting, and it is why the hour-boundary crash mattered more than it looked.

   Phase 5's allocator, sizer and correlation breaker have nothing to allocate
   between until a strategy is promoted — but the drawdown ladder of VX-011 is
   derived and not yet acted on, because nothing cuts gross by a rung until
   position sizing exists. That is the first real Phase 5 hook when the time
   comes.

   The two Phase 2 leftovers still travel with the first live strategy:
   `state_recovery` needs an authenticated session to reconcile against, and key
   scoping needs a key.

### Known gaps carried forward, not silently dropped

- ~~**Bar builds are bounded by the busiest HOUR, not the busiest day**~~ —
  **BOUNDED BY NEITHER, 2026-08-10.** The binance build for 2026-08-09 was
  OOM-killed at 20.3 GB and left 69 of 569 symbols unbuilt. Two fixes, each
  measured on the same symbol — TUTUSDT, 25,963,564 trades in one day:

  | | peak | outcome |
  |---|---|---|
  | as found | 20.3 GB → 12.0 GB | OOM-killed |
  | `BarAccumulator` folds trades as they are read | **4.09 GB** | completes |
  | `iter_pair` streams the hour instead of holding it | **0.25 GB** | completes |

  `read_pair` returned `list[tuple[str, IndexEntry]]` — every payload string and
  an object per frame, materialised before one trade was examined. On the single
  worst hour file, 5,634,232 frames: **3.98 GB held against 0.14 GB streamed,
  and streaming read it FASTER** (37.7 s against 48.6 s).

  **The bars are identical.** All 856 for that day, compared through the
  clock-gated reader against what production already held — every open, high,
  low, close, volume and trade count equal. A cheaper reader that disagreed
  about damage would have traded an OOM for a quietly wrong store, so the
  streaming reader keeps `read_pair`'s verdicts and their PRECEDENCE: a pair
  that is both mis-paired and unequal in length reports the length mismatch,
  because that is the one naming `reconcile_pair`. A stream meets the bad `n`
  first, so it drains both files before deciding — paid only on the failing
  path.

  `read_pair` stays for the repair path, which needs the one thing a stream has
  already given away: the intact prefix on `TruncatedFrameFile`. The streaming
  reader reports the COUNT instead and says it is not retained, so an empty
  `recovered_lines` cannot be misread as "nothing survived".

  What remains is a property the next caller must design around rather than a
  bound: the refusal now arrives after the frames ahead of the damage have been
  consumed. Safe because every build appends to the store AFTER its read loop —
  anything that writes as it reads must not use this reader.
- **The live startup script drifts from the repo, and the drift is silent until
  a reboot.** Found 2026-08-10, the second time: `bars_supervisor.sh` was split
  out at 08:15, the box rebooted at 09:53, and the GCE **metadata** copy — which
  is the one that runs — had never been updated. Bars stopped building and
  nothing said so; `ps` showed eight supervisors where there should have been
  nine. Re-installed with `gcloud compute instances add-metadata
  --metadata-from-file startup-script=scripts/gce_startup_script.sh` and
  verified by diffing the metadata back against the repo file.

  The repo file is a COPY. Editing it changes nothing that runs, and a reboot is
  what turns that into lost data — so a supervisor added to it is not added
  until the metadata is installed and diffed back.
- ~~**Provenance-flagged backfill** (Phase 0's last item)~~ — **BUILT 2026-08-10**,
  and built with a real backfill behind it because this entry made that the
  condition. `store.bar_backfill` fetches binance klines into
  `bars_reconstructed_<interval>ns` — beside `bars_*`, never inside it — with
  `is_reconstructed` on every row and **availability stamped at the fetch, not
  the bar close**, so `read_as_of` at any past clock returns nothing and a
  backtest cannot consume one by accident. The first backfill filled a real
  hole: capture stopped 2026-08-09T19:51Z and returned 04:26Z, and observed
  BTCUSDT bars end at exactly 19:51. What a reconstructed bar is worth is
  measured rather than assumed — against 220 overlapping observed bars, 217
  closes identical, median 0.0000 bps apart, p99 0.0124.
- ~~**Liquidation feed unavailable**~~ — **SUPPLIED 2026-08-09** by the second
  venue §12.6 anticipated. `capture.venues.bybit_liquidation` records bybit's
  market-wide `allLiquidation` stream (probed from this host before the module
  was written: 16 frames in 90 s, against binance's permanent zero), supervised
  and in the boot chain; the tile reads OK from measured frames. Binance's
  `forceOrder` subscription stays, deliberately - a recovery would be noticed.
  Two semantics corrections rode along, both measured on the first run: silence
  on a market-wide event stream is judged for the whole feed, never per symbol
  (800 of 805 symbols read "silent" in a 75-second run, byte-holders included),
  and a silence event is superseded by any write that postdates it, so a quiet
  spell no longer condemns a recovered stream until midnight.
- ~~**Auto-halt on venue degradation is not armed.**~~ **ARMED 2026-08-09.**
  `ops.venue_health_watch` feeds the registry once a minute and the wall grades
  on the observation's age rather than asserting anything. The tile that read
  "auto-halt armed" while `observe()` had no caller — the Rule 8 failure inside
  the board built to prevent it — now reads what it measures, and says
  `AUTO-HALT NOT ARMED` whenever nothing has fed the registry.
- ~~**The hour-boundary stall is bounded, not understood.**~~ **EXPLAINED
  2026-08-09.** The binance recorder died at every hour boundary on a keepalive
  timeout while binance-spot crossed the same boundaries untouched. Measured:

  | | recorder writers | frames/s | fsync at the boundary |
  |---|---|---|---|
  | binance | 575 | **2,415** | 2.5 s |
  | binance-spot | 1,321 | 102 | 5.7 s |

  Spot has more writers and more total fsync work, and never came close to
  dying. **The discriminator is baseline loop saturation.** binance runs at 24×
  the frame rate, so the rotation burst lands on a loop with almost no slack and
  the keepalive's ping/pong finds no window; spot's loop is mostly idle and has
  room throughout. Both the writer count and the total fsync work were red
  herrings, and each had been a hypothesis.

  It also explains the fix: the drain is paced PER FRAME, so cutting the budget
  from 25 to 4 interleaves ~6× more frames between fsync slices. Measured after:
  a 6.0 s stall at the rotation, and the recorder alive across 13:00 and 14:00.

  Carried forward as a capacity fact rather than a defect: **binance sustains
  ~8.7 million frames an hour through one process.** Anything added to that
  event loop is added to a loop that is already nearly full.
- ~~**The dollar-quote filter is not applied.**~~ **APPLIED 2026-08-09**, as the
  blocking prerequisite for Phase 4. `store.cli --symbols ALL` now filters, and
  refuses the build when no universe snapshot says what anything is priced in.
  **What remains is the contamination already written:** 536 non-dollar symbols
  hold **89,097 bars, 29.4% of binance-spot's**, in TRY, EUR, JPY, IDR, BRL, BTC
  and ETH. The store is append-only and nothing retracts them, so **any consumer
  choosing a universe must filter it** — `dollar_quoted_symbols` is the call.
  This is a hard requirement on Phase 4's carry family, which ranks
  cross-sectionally: a lira price and a USDT price are not comparable numbers.
- **Unwired and awaiting a consumer**, listed so none of them is later
  rediscovered as new work: `risk.drawdown_distribution`,
  `paper.participation_calibration`, `cost.spread_and_depth`,
  `store.correct_bars` (a one-shot, used once for the 746 poisoned bars).

---

## 14. Paper trading started — 2026-08-15

**The ordering in `2026-08-09-full-build-master-plan.md` was reversed by the user
on 2026-08-15.** That plan recorded the decision to complete *"every plan, idea,
feature and goal"* before paper trading began, with the paper-engine-first
alternative explicitly put and declined. Asked again — after five days in which
nothing ran — the user chose paper next. Recorded here rather than edited into
the plan, because the plan is the record of what was decided *then*.

Phase J now reads **RUNNING** on the build-progress board, graded on the engine's
own heartbeat and its age.

### What was built

`paper.position_book`, `paper.paper_broker`, `paper.market_replay`,
`paper.forward_engine`, `paper.forward_journal` and `scripts/paper_supervisor.sh`.
The supervisor is also what made the subsystem **reachable**: until it existed
those modules imported each other with nothing running any of them, and every one
of their axis verdicts carried an honest DEPTH fail. `RX-005` left the
unsupported-claims baseline at the same moment — `execution.state_recovery`
finally has a local position source to reconcile against.

### Three defects the tests did not find and the first live run did

1. **Every intent expired before it could be sent.** `created_at_ns` was stamped
   with the *bar's* event time, so a 60-second validity window had closed before
   the wall clock ever saw it: 3,494 events fed, **0 submitted**, and the engine
   read as idle rather than blocked. The signal is computed *now*; the age of the
   data behind it is a separate question `features.staleness` already carries per
   value.
2. **Poll 2 reported 3,494 corrections where nothing had been corrected.** The
   dedupe held only keys, so a re-read of a row already fed was indistinguishable
   from a genuine correction, and the counter meant to expose a real problem
   became noise proportional to uptime. It now holds the availability time each
   key was fed at; only a *later* one is a correction.
3. **A fresh journal replayed the whole archive as though it were live.** On
   BTCUSDT alone, 3,494 archived bars in one poll produced 1,074 fills against
   prices days old — every one of which would have entered the forward journal as
   a forward result. `prime()` marks the archive seen without trading it. On the
   real start: **1,523,537 events primed, 0 traded.**

And one in the board built to prevent exactly this: `probe_forward_paper` globbed
`*.ndjson` and would have reported Phase J RUNNING off `restarts.ndjson` — the
supervisor's own log, written once at startup and never again. A tile that goes
green because a process started once, and stays green after it dies, is the Rule
8 failure sitting inside the Rule 8 board.

### The bar cadence was a supervisor property, not a store property

The engine ran 63 polls and traded nothing, and the reason looked structural:
bars existed only for closed **days**, so "forward" trading advanced once per 24
hours. It was not structural. `store.cli` already skips an hour a live writer
holds — in the day's own folder as well as the lookahead — and names every
skipped hour in the snapshot id, precisely so a later pass with more hours closed
is a *new snapshot that appends*. `scripts/bars_supervisor.sh` had simply never
asked for today.

Measured, not reasoned: building 2026-08-15 at 19:02 produced 88 BTCUSDT bars and
skipped live hour 19 by name; the engine fed exactly those 88 on its next poll
and produced **43 fills**. With the intraday pass wired in across four venues:
**160 fills** on binance BTCUSDT and hyperliquid BTC/ETH/SOL.

The intraday pass is bounded to core symbols. It rebuilds today from hour 0 each
run — the day partition is written whole — so cost grows through the day and a
universe-wide version would be quadratic in a way that eats its own hour.

### What is running is not a strategy

`plumbing-momentum` rests a BUY at the previous close. `makes_edge_claim` is
**false** and is written onto every fill row rather than into a header, the wall
tile reads **PARTIAL rather than OK** while it runs, and `--strategy` has no
default so it cannot be run without being named. Participation is **uncalibrated**
— no receipt exists, its tile reads NOT MEASURED, and every fill carries
`uncalibrated=true`. Nothing here may be promoted.

### The system now has a concept of its own absence

`ops.liveness_ledger` stamps liveness on the health supervisor's 60s tick and
records the hole on its first tick back. **A watcher on the box cannot report that
the box is off** — that limit is designed around, not hidden. The 2026-08-10 →
2026-08-15 gap is filed as **124.3h**, cited to `boot.log`'s two boot lines and
the missing raw dates, and labelled `is_reconstructed` because the module did not
exist while it happened — following `store.bar_backfill`, where a reconstruction
sits beside observations and never inside them.

`statuswall.staleness_banner` makes each board age itself in the **reader's**
browser, because a server-rendered "generated 5 days ago" is impossible for the
case that matters: the server that would render it is the one that stopped. Past
the threshold it names the *generator*, not the page age.

---

## 15. The box stays up, and the plan became a file — 2026-08-17

Two rulings and a sweep, all on one day. The user's question that started it:
*"why did we fails to completely implement or start papper trading according to
the plan we discussed each segment are like there own bots with its own
architecture, data features etc."*

### 24/7 uptime — RL-020

The instance is **not preemptible** — `scheduling/preemptible` reads FALSE — so
the gaps were deliberate stops: **124.3h** from 2026-08-10 to 08-15, and
**14.1h** from 08-16 17:41 to 08-17 07:50. Against a market that never closes
and §3a's intraday mandate, a bot that is off part of the week cannot be
honestly judged.

The cold-start cost travelled with the ruling and turned out to be the larger
problem. See §15.3.

### Each segment is its own bot — RL-019

Recorded verbatim in the goal document as **§3b**. Four segment bots, three
brains inside each, twelve brains, sharing only the store, reader, cost engine
and promotion pipeline. It composes with the 2026-08-03 direction ruling in §9
rather than replacing it — that one splits by direction, this one by segment,
and the user chose the nested reading over twelve independent bots.

§5a is amended by it: universe-wide scanning was written here as *"a property of
the system"* and is now a property of **each bot**.

### 15.1 What the sweep found

`AJIT-MASTER-PLAN.md` reconciles three populations rather than one. The ledger
already reconciled rows; nothing reconciled **design sections** — argued-through
prose that never became a row.

| Population | Members | Unassigned |
|---|---|---|
| ledger rows | 1,511 | 1,511 |
| catalogue rows | 192 | 192 |
| design sections | 1,035 | 1,025 |
| **total** | **2,738** | **2,728** |

Rulings covered: **9 of 21**, every one of them `system` or `shared` scope.
**Every `per-segment` ruling reads 0/4. Every `per-brain` ruling reads 0/12.**

Three ideas that live in design documents and in **zero** ledger rows: the
Goodhart defence, attention scarcity — the mechanism §5a is built on — and the
examination-hall framing itself, which is the user's own ruling of 2026-08-02.

Across the six `IDEAS-*.md` files: **183 rated HIGH, at most 69 traced into
`src/`, 106 with no trace anywhere.** Eight of the ten the corpus itself named
*"the ten to build first"* are unbuilt. `src/strategy/` holds two modules and
neither is an opportunity monitor.

### 15.2 The store existed on one disk

Measured before it was fixed: the GCS bucket held `raw/`, `ledger/` and
`universe/` and nothing else. `store/funding` is 482 MB, is the OBSERVED record
whose start date is the promotion clock, and has **no raw counterpart** —
funding is polled straight into the store, so `raw/binance-funding` does not
exist. `funding_reconstructed` cannot substitute: its availability times are the
fetch, deliberately, which is what makes it useless for a backtest.

Fixed the same day. Verified: **32,640 objects** under `store/funding/`.

### 15.3 The paper engine was killing itself

The conformance board caught this unprompted on its first run. The engine was
**OOM-killed at 09:49:54Z — exit 137, after 7,183s, the fourth restart that
day** — holding 5.5 GB while `statuswall.cli` held 4.9 GB and capture held ~9 GB,
on a 30 GB box with no swap. It then spent ~11 minutes re-feeding 2,316,171
archived events before trading anything.

Three causes, not one:

- `prime()` built a `TapeEvent` and a `MarketEvent` for every archived row purely
  to `len()` them.
- `poll()` re-read the **entire** bars dataset every 60 seconds, for an archive
  growing ~3.4 GB/day.
- `_emitted` grew by one entry per event ever seen and never shrank.

A persisted **availability** watermark answers all three. Availability rather
than event time is the safety argument: a correction to an old bar carries a
later availability time by definition, so it still arrives through the bound,
while a bound on event time would hide corrections.

Measured after the change on the live engine: **RSS 7,321 MB → ~1,200 MB.**

### 15.4 What is now enforced rather than remembered

`CLAUDE.md` already said *"search the ledger first"* and it still failed. So:
`docs/rulings.json` holds 21 rulings verbatim and dated; a PreToolUse hook
refuses a **new** module under `src/` that no plan row names; a SessionStart hook
prints the ruling list into every session; and a conformance board renders one
row per ruling, NOT MEASURED where no probe exists and never green without one.

A fifth cause was mechanical rather than editorial: memory is keyed by working
directory, and a session started from `/` read an **empty** key while twelve
memories — including *"Interview, don't assume"* — sat under another. Symlinked.

### 15.5 The scan is the hot spot, not the walk — 2026-08-17

§15.3 named the schema walk as what made a poll unbounded, from a read filtered
to zero rows that had not finished in 10 minutes. **That attribution was wrong.**
Re-measured the same day on the live bars dataset — 52,487 fragments across
2,230 symbol partitions — with each part of a read timed separately:

| part of a poll | cold | warm |
|---|---|---|
| dataset discovery | 0.6s | 0.6s |
| schema walk, every fragment footer | 8.3s | — |
| schema walk, cached | — | 8 footers, 1.7s |
| scan filtered to match NOTHING | **185.6s** | 8.8s |

The walk was ~8s of a ~195s read. The scan dominates, and it is cold-cache IO:
the identical zero-row scan costs 185.6s cold and 8.8s warm. That is why it read
as unbounded on a box at load 27 holding 22 of 29 GB, with the page cache being
evicted under it. The 10-minute observation was real; what it was blamed on was
not.

**Both fixes, in the order the user chose.** Caching the unified schema per store
generation (SL-14) removes a duplicate full walk per read and — more useful —
makes the cost *measurable*: the heartbeat now carries `fragment_schema_reads`
and `poll_seconds`, so `probe_poll_scan_cost` grades a poll before an OOM
reveals it rather than after. Partitioning by availability HOUR (SL-15) is the one
that fixes the scan, because only a time in the path lets pyarrow skip
directories without opening them - and hour rather than date because 538 MB
across 52,487 files is ~6,000 new files a day, so a date directory holds a whole
day of them by evening while an hour directory stays at ~250 however long
capture runs.

**The property neither may break.** The walk cannot be deleted: without it
pyarrow infers the schema from the first fragment and silently drops columns
added by later partitions — `funding_interval_hours` on 2026-08-09, which turns
a 4-hourly funding rate into an 8-hourly one, wrong by a factor of two. The
cache keeps it by caching rather than skipping: a column added by a later
partition still appears through a warm cache, and a fragment that disappears
forces a full rebuild rather than leaving a column asserted from a file that is
gone. Both are asserted in `tests/test_schema_cache.py`.

**Rejected.** Pruning fragments by file mtime — mtime is not a data property and
a GCS restore resets it, so the store would silently skip real rows. Having the
engine record consumed snapshot ids — fixes one reader, and the boards generator
is a second one; it stalled for 1h50m on 2026-08-17 on exactly this cost.

The lesson is about method rather than parquet: a slow thing and the part of it
that is slow are different facts, and a 10-minute stopwatch on the whole read
cannot tell them apart. Timing each part separately took eleven minutes and
reversed the conclusion.

**Measured after building it, on a copy of real data rather than a fixture.** A 60-symbol slice of
the live bars dataset, 1,587 legacy fragments: a one-hour bound selects **59 of 1,805** fragments
under the hour layout against **1,587 of 1,587** under the legacy one, and both return byte-
identical rows. That is SL-15's whole claim in one number.

Two things the trial caught that no unit test had:

1. **A bounded read of an unmigrated dataset raised `ArrowInvalid`.** The filter named
   `availability_hour`, which the old layout has no field for, so the read did not merely lose
   pruning - it failed outright. Every dataset is in the old layout until its own migration runs and
   the paper engine polls with a bound every 60 seconds, so this would have stopped the engine the
   moment it landed, before any migration could fix it.
2. **The file count goes UP, and the "~20x fewer files" claim written into the plan was wrong.**
   These writers already snapshot about hourly, so compaction has little to merge, while a legacy
   part spanning more than one hour is split across hour directories. Bars 1,587 → 1,805 parts,
   `dated_futures` 680 → 1,472. The saving is pruning and nothing else.

The method is the point: both were found by running the real thing against a copy before touching
the live store, and neither would have been found by any number of fixtures.

### 15.6 A code edit deploys itself here - 2026-08-17

Within minutes of the hour-partitioning writer landing on disk, the LIVE bars dataset held **4,595
hour-partitioned parts beside 2,231 legacy `symbol=` directories**, before any migration had been
run and without anyone deploying anything. The store supervisors restart their child on a loop, and
a restarted child imports whatever is on disk. **On this box, editing a module under `src/` is a
deployment.**

That turned a layout change into a live correctness problem. Hive partitioning gives the legacy
parts a NULL `availability_hour`; `NULL >= '2026-08-17T12'` evaluates to null rather than true; so
an hour-bounded read **drops every legacy row**. No error, no warning, a smaller answer. Reproduced
in a test at 1 of 6 rows returned.

**The fix is a rule about the whole dataset, not about a fragment.** Hour pruning is enabled only
when no top-level `symbol=` directory exists. A dataset part-way through migration reads correctly
and merely loses the speed-up, and pruning switches itself back on when the last legacy directory
goes. Verified on the live store: `mixed layout detected: True; hour pruning active: False`, 64,341
of 64,341 fragments selected under a bound.

The migration had to learn the same lesson: it originally refused any dataset that already had hour
directories, which by then was every dataset that mattered. It now folds both layouts together,
hard-linking the already-hour-partitioned parts across rather than rewriting them - their snapshot
ids answer "which data produced this" and a rewrite would change that answer.

**What to carry forward.** A schema check is not a layout check. `availability_hour in schema` was
true in exactly the state where using it was wrong, because one new part is enough to add the
column while thousands of old ones still lack the path. And any change to a module the supervisors
import is live the moment it is saved - there is no separate deploy step to plan around, so the
question "what happens if half the store is written by the new code" has to be answered before the
file is written, not before it is committed.
