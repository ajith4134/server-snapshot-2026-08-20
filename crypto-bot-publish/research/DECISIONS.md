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

---

## 2. The tree (organizing structure)

Derived from the user's four reference images; the methodology sheet
(`04-skill-tree-methodology-preskills.jpeg`) is the load-bearing one.

```
ROOT
├── BRAIN 1  hours → minutes
│   ├── BULL agent ──┐
│   │                ├── ARBITER → LONG / SHORT / FLAT → RISK GATE → EXECUTION
│   └── BEAR agent ──┘
├── BRAIN 2  minutes → seconds     [own triad]
└── BRAIN 3  sub-second            [own triad]
```

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
5. `gh` CLI not yet installed (preferred over the GitHub MCP server).

---

## 13. Next actions (in order)

1. ~~**Finish the Claude-usage work**~~ — **DONE 2026-08-01.** Enforcement layer is
   live (2 PreToolUse hooks + 11 deny rules, verified blocking); CLAUDE.md
   restructured 220 → 169 lines with Rule 2's operational half promoted to the
   `youtube-video` skill. Remaining optional item: a **Stop hook** for verification,
   which needs a project with a runnable test command — so it belongs to step 3.
2. **Write the full system spec** from this document. ← *next*
3. Phase 0: repo skeleton, ledger schema, risk gate, NautilusTrader integration —
   **before any strategy code**. Add the Stop hook here, wired to the real test suite.
