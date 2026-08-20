# ARCHITECTURE — Autonomous Crypto Trading System

**Status:** design spec, not yet built. Supersedes `SYNTHESIS.md`.
**Date:** 2026-08-01
**Basis:** 42 research files in `~/research/` (~2.0MB), six parallel research areas, ~30 `sonnet`
agents. Prior design: `DECISIONS.md` (retained — most of it survives). Prior attempt:
`github.com/ajith4134/nse-crypto-bot-final`.

> **Sourcing discipline.** Dollar figures and incident details below are **cited from research, not
> independently confirmed by this session.** Each research file carries its own `UNVERIFIED`
> appendix (24 tags across the six ops files alone). **Re-verify any number before it sizes a real
> control.** Fee schedules especially — only Binance spot and Kraken were fetched live.

---

## 0. What changed from the prior plan

**Kept:** the prime directive (consistent risk-managed income, not a lottery — protect capital, take
small edges, compound) · dual-mode risk (paper unlimited / live preservation-first) · CPU-first ·
the promotion gate · the experiment ledger · BULL/BEAR + arbiter · Dual-LLM separation · the
"starving" allocator · manual promote button.

**Changed — the organizing axis.** The prior plan splits three brains by **frequency band**.
Frequency is a property, not the primary axis. **Strategy family** determines whether you can
compete at all:

| Family | Latency sensitivity | Viable at $100k–$1M, cloud VM |
|---|---|---|
| Directional / momentum (minutes–hours) | None — 20–500ms is noise against a 1-min hold | **Yes** |
| **Carry — funding, basis, spot-perp** | None by construction | **Yes — strongest available edge, unnamed in the prior plan** |
| Relative value / cross-venue | Seconds | Marginal — needs same-region VMs |
| Market making / passive liquidity | Microseconds | **No** — no reachable rebate tier + 10–20x queue disadvantage |
| Latency arbitrage | 5–10 μs modal race duration | **No** — categorically; cloud floor is ~8ms+ |

The prior sub-second brain sits in the two closed rows. **Reorganize by family; frequency becomes a
property within each.**

**Dropped:** synthetic benchmarks as the development target · 500–1000 nodes as a starting goal ·
"no prior art therefore novel" as a reason to proceed · dashboard-for-every-node as a phase-1
requirement.

### Why the prior attempt failed (from its own `PROJECT_BRIEF.md`)

It chose Mackey-Glass chaos as development data *because* "crypto daily-direction is ~random and
useless for development," and reported 52% → 96.4%. **That number proves the plumbing works and
nothing about markets.** Mackey-Glass is deterministic, stationary, non-adversarial. Every
hyperparameter tuned to reach 97% on it is tuned to a signal-rich system that does not resemble the
target. The property that made it attractive — "accuracy provably rises as it learns" — is exactly
what made it misleading.

And the parenthetical was the real finding: **if daily direction is near-random, that is the domain
telling you where the edge is not.** Substituting a tractable proxy deferred that confrontation to
the most expensive possible moment.

---

## 1. Component architecture

Six layers. Lower layers are preconditions for higher ones — **build order follows this list.**

### Layer 0 — Truth

Nothing above this works if this is wrong, and every error here is silent.

| Component | Contract |
|---|---|
| **Bitemporal Store** | Every row carries `event_time`, `ingestion_time`, `availability_time`. Append-only — corrections are new rows, never overwrites. |
| **Clock-Gated Access API** | **The only** path to data, shared by backtest and live. Serves `availability_time <= sim_clock`. Joins key on **availability_time, not event_time.** |
| **Snapshot-on-Ingest** | Immutable, checksummed. **Never re-pull history** — exchanges silently revise it; identical code returns different numbers months later. |
| **Provenance Stamper** | Every run records lockfile hash, container digest, data snapshot ID, seeds, git commit. |
| **Frozen Universe Snapshots** | Which pairs were tradeable at each decision date. Deriving it from a current table encodes today's knowledge of who was ever listed. |

**Prevents:** look-ahead leakage — structurally, not by discipline. If backtest and live use different
access paths, an off-by-one in windowing yields a great backtest and a broken system.

**Do not** adopt a feature store. Feast's leakage protection is **off by default**
(`filter_by_created_timestamp: bool = False`), it has no native streaming, and it solves a
multi-consumer coordination problem a solo operator does not have. Hand-rolled: Parquet + ZSTD
partitioned by symbol, `merge_asof(direction="backward")`, a few hundred lines, unit-tested against
synthetic leakage cases.

### Layer 1 — The reality filter

| Component | Contract |
|---|---|
| **Cost Engine** | Every strategy queries it **before a signal is accepted**. Returns round-trip breakeven for (venue, pair, size, order type). |
| **Capacity Model** | Per-strategy size ceiling. Divergence between live results and a fixed-size shadow book **is** the capacity signal. |

**Why this is the single biggest gap:** fees dominate breakeven by roughly 5–10× over slippage and
adverse selection at these sizes. Binance spot taker round-trip ≈ **20bps** (0.10/0.10, fetched
live); Coinbase retail ≈ **120bps**. **Venue and fee-tier selection outrank every execution
algorithm you could write.** Without a cost engine gating signals, paper mode manufactures edge that
evaporates live.

**Corollaries:** no reachable rebate tier at this size (needs $5M–$250M+ 30-day volume; true rebates
$250M–$1B+). TWAP/VWAP/Almgren-Chriss unnecessary — clips are 0.0005–0.05% of Binance BTC ADV
(~$19B/day), thousands of times below where slicing helps.

### Layer 2 — Search integrity

**This is what killed the prior attempt.**

| Component | Contract |
|---|---|
| **Trial Registry** | Counts cumulative N across **all** searches including discarded and abandoned. **Structurally impossible to evaluate without incrementing.** |
| **Holdout Custodian** | Owns the untouched holdout and **refuses queries**. Commit hash + "not consumed" flag; CI blocks any run touching the range before freeze. |
| **Mechanism Declaration** | No strategy may be promoted without declaring the inefficiency it exploits **and a measurable proxy for that inefficiency's health**. |
| **Validation Harness** | Deflated Sharpe as the **fitness function inside the search loop**, not a report on the winner. CPCV on finalists. MinBTL as a hard gate. BH-FDR on the promoted set. |

**The numbers that force this:** 8,800 configurations tested against a **pure random walk** produced
a best in-sample Sharpe of **1.27**, PBO 55%, ~53% of out-of-sample Sharpes negative. And with 5
years of data, **more than ~45 independent configurations** makes it near-certain you find an
in-sample Sharpe 1.0 with true out-of-sample zero.

**Purge/embargo must be configured per family/frequency** — label horizons differ by orders of
magnitude; one shared config is wrong at both ends.

**Mechanism Declaration is the decay solution.** A strategy in drawdown and a strategy whose edge is
gone are statistically indistinguishable from P&L at any useful horizon — a fundamental
signal-to-noise limit, not a stats problem. Monitoring the *mechanism* (spread compression,
opportunity frequency) is faster and stronger evidence.

### Layer 3 — Live operations

Where documented losses actually occur.

| Component | Contract |
|---|---|
| **Venue Health Monitor** | Tracks API error rate, price deviation vs reference, staleness. **Auto-halts per venue.** Never retry into a degraded matching engine. |
| **Rate-Limit Budgeter** | Central token bucket **across all strategies**. Limits are per-IP and exchange-wide. |
| **Order-Intent WAL** | Intent written **before** the request is sent. On restart, query exchange-authoritative state before resuming. Fail loud on disk-full. |
| **Watchdog** | **Separate process.** Kills the bot **and drops outbound network at the firewall** on hard-cap breach. |
| **Staleness Detector** | Sequence-number continuity (Binance diff-depth `U`/`u` chaining) + activity-adaptive threshold + periodic REST reconciliation as an independent path. |

**Evidence:** every major volatility spike since 2020 has a matching degradation on a top-5 venue —
downtime is a base rate, not a tail. Oct 10 2025 was the largest cascade on record (~$19.13B
liquidated, ~1.6M accounts); Binance degraded ~1 hour and valued collateral on internal prices,
depegging USDe to $0.65 *only there*. Compound (Nov 26 2020) lost $100M+ to a single-source oracle
whose anchor co-moved and failed too. Mango (Oct 11 2022) shows naive multi-source averaging fails
when all sources are thin — **cross-checks need liquidity weighting, not N-source averaging.**
Knight (Oct 2011) "did not have a mechanism to test whether their systems were relying on stale
data."

**Rate limits are an architectural constraint, not a config value:** per-IP, exchange-wide. Binance
`418` bans scale **2 minutes → 3 days** for repeat offenders. One strategy's burst bans all of them.
Full-jitter backoff; honor `Retry-After` over your own schedule.

**Key scoping — structural, not procedural:**
- Trading key: **withdrawal permission never enabled.** Bounds a leak to "bad trades" instead of
  total irreversible loss.
- IP allowlisting is **mandatory** on Binance for trading-capable keys (unrestricted IP = read-only).
- Trading key has **zero** read or transfer access to treasury — separate sub-account.
- Secrets: `sops` + `age`. Not an OS keyring (desktop tooling, no home on a headless VM), not
  self-hosted Vault (its own docs call Shamir unsealing hard to automate).
- **No major exchange appears to expose programmatic self-revocation of your own key.** Do not design
  a kill switch assuming it — the firewall is the reliable mechanism.

### Layer 4 — Portfolio

| Component | Contract |
|---|---|
| **Allocator** | Discounted / sliding-window Thompson sampling. Vanilla assumes stationary arms. |
| **Sizer** | Volatility targeting primary; **fractional Kelly as a ceiling, never a target.** |
| **Correlation Breaker** | Portfolio-level, separate from loss limits. Fires on rolling cross-strategy correlation spiking above baseline — a *leading* signal. |
| **Drawdown Ladder** | Graduated (−5% → cut 25%, −10% → 50%, −15% → flat), each rung confirmed over a short window. **Never a single binary kill.** |
| **Regime Feature Provider** | Volatility regime as **one weak feature** into the meta-model. **No veto power.** |

**Half-Kelly gives 75% of the growth rate at 25% of the variance** (`f(2-f)` vs `f²`) — it is not a
safety tax. Overbetting past 2× optimal drives growth **negative despite a real edge**. Volatility
targeting is preferred as the primary sizer because it needs only a variance forecast, never μ.

**Ladder must be consistent with the Kelly fraction.** Sizing that implies 15% drawdowns are routine
paired with a kill at 10% is a design bug — the breaker trips on strategies behaving exactly as
designed.

**Correlation breakdown is structural, not bad luck:** strategies converge through shared liquidity,
shared venues, and deleveraging cascades. The Aug 2007 quant meltdown hit unrelated strategies
because they shared *investors*. **Cheapest high-value check, and it is underused: compute
correlations split by volatility regime** — the worst 5% of vol days vs the rest.

### Layer 5 — Signal integrity

| Component | Contract |
|---|---|
| **Order-Book Layer** | Depth-weighted OFI. **Never level-1 imbalance** — 31% of large orders in a Dec 2024 sample could profitably spoof it. |
| **Funding & Basis Engine** | Per-venue mechanics genuinely differ: dYdX hourly with 0% default interest; Hyperliquid hourly, capped 4%/hour, funded on **oracle** price not mark. |
| **Feature Set** | Volatility (HAR-RV beats GARCH for short-horizon crypto) and order-flow imbalance. **Not** a 200-indicator library. |

**Do not build the technical-indicator zoo.** 7,846 rules tested on 100 years of Dow data — the best
failed out-of-sample once corrected for search size.

**VPIN is contested even in equities** (it peaked *after* the 2010 flash crash, not before) and the
supportive crypto papers include one co-authored by the metric's own co-inventor. Treat as open.

---

## 2. Promotion pipeline

```
research → paper → shadow → reduced-size live → full live
```

| Stage | Question | Gate |
|---|---|---|
| **Paper** (unlimited risk) | Is there edge in the idea? | DSR survives full trial count · CPCV path distribution holds · MinBTL satisfied |
| **Shadow** (zero risk) | Do execution assumptions and the live code path hold? | ≥95% signal alignment · ≥90% execution-quality match · auto-halt after 3 misalignments · realized-vs-assumed fill gap within tolerance |
| **Reduced live** | Does it survive real adverse selection and impact? | **Regime coverage — a real drawdown and a real vol spike.** Not elapsed days |
| **Full live** | Capacity confirmed | No divergence from the fixed-size shadow book |

**Paper and shadow are not two rungs of one ladder** — paper fills at prices *your simulator chose*,
so it inherits every execution assumption you gave it. Shadow runs the live path against real books
and sends nothing.

**If paper already replays real L2 depth with fees and latency, the stages collapse** — you have
shadow and are calling it paper. Decide this by inspecting the fill model.

**Expect a median 73% Sharpe deterioration** backtest → live across 215 commercially promoted
strategies. A 40–60% haircut is **normal, not a kill signal.** Kill on negative Sharpe or
DSR-inconsistent divergence. Budget the drawdown limit off a **bootstrapped p75–p90**, not the single
historical max.

**Adopt "Shadow Before Swap"** for incumbent replacement: retrain a challenger on schedule, promote
only after a shadow trial on delayed labels shows a pre-registered advantage. Reported 78.4% fewer
deployed-state changes at equal-or-better quality, crypto-specific.

**Retrain vs retire:** Sharpe decline **with rising costs** → crowding, retire. Decline with flat
costs tracking the cycle → drift, retrain. Sharp step tied to a fee/rule/venue change → microstructure
break, retire. Divergence from the shadow book at larger size → capacity, reduce allocation. Each
retrain fixing it but decaying faster → structural break, retire. **Pre-commit these before a
drawdown, not during one.**

---

## 3. Build order

**Phase 0 — Truth.** Bitemporal store, clock-gated access API, snapshot-on-ingest, provenance
stamper. *Nothing downstream is trustworthy before this exists.*

**Phase 1 — Reality filter.** Cost Engine with live-fetched fee schedules per venue. *Gate every
subsequent result through it.*

**Phase 2 — Ops floor.** Venue Health Monitor, rate budgeter, order-intent WAL, watchdog + firewall
kill, key scoping. *This is where documented losses occur; it precedes any capital.*

**Phase 3 — Search integrity.** Trial Registry, Holdout Custodian, validation harness. *Before any
automated search runs, not after.*

**Phase 4 — One family, end to end.** Carry (funding/basis) — latency-immune, viable at this scale.
Take it through the full pipeline to reduced-size live. *Prove the machine on the family most likely
to work.*

**Phase 5 — Portfolio.** Allocator, sizer, correlation breaker, drawdown ladder — once there is more
than one live strategy to allocate between.

**Phase 6 — Widen.** Second family. Then, only if Layers 0–3 have held, consider scaling search.

**Dashboard: Phase 6+.** It produces zero alpha and scales with node count.

---

## 3b. Settled decisions — 2026-08-01

| Decision | Choice | Consequence |
|---|---|---|
| **Instruments** | **Spot + futures (perps and dated) + options** | Perps/spot unlock funding carry and basis — latency-immune, viable now. Dated futures add clean calendar basis. **Options add the variance risk premium**, a third latency-immune family. Makes **liquidation-distance monitoring, margin/ADL health, and mark-vs-index-vs-oracle tracking P0**. Options add a **Greeks-based risk layer** — see sequencing note |
| **Initial live capital** | **Under $10k for the first six months** | First live phase is *paid validation, not income*. Defer capacity model, smart order routing, impact-aware sizing, per-venue exposure caps |
| **Autonomy** | **Fully autonomous within hard limits** | Human sets limits, not trades. Manual promote button retained. **Pre-trade gate, watchdog + firewall kill, and venue-health auto-halt must be COMPLETE before the first live order** |
| **Venues** | Binance · Bybit · Hyperliquid · Kraken/OKX/Coinbase selected — **see the narrowing note below** | |

### The governing principle these produce

**Capital determines what counts as over-engineering. Autonomy determines what is non-negotiable.**

Small capital would normally let most of P1 slide. Full autonomy cancels that discount for anything
in the safety path — with no human watching, nothing catches a runaway before the drawdown ladder
does. So: **the ops floor stays at full height; the sophistication layer drops away.**

Deferred by capital: capacity model · smart routing · impact-aware sizing · per-venue exposure caps ·
cross-venue RV strategies.

**Not deferred, despite small capital** — because autonomy requires them: pre-trade gate · watchdog +
firewall kill · venue-health auto-halt · liquidation-distance monitor · order-intent WAL · state
recovery · key scoping · rate budgeter · signal expiry · cold-start behaviour.

### Options — accepted as a target, sequenced late

Options are the right long-term third leg: the **variance risk premium** (options implied vol
persistently exceeding subsequent realized vol) is among the more durable findings in finance, and
harvesting it is **latency-immune** — the same property that makes funding carry viable here. It fits
this account's profile better than anything directional.

**But it is not a launch instrument, for four concrete reasons:**

1. **A different risk vocabulary.** Notional and leverage limits do not describe an options book.
   Risk becomes **delta, gamma, vega, theta** — a short-vol position can look tiny by notional and be
   catastrophic by vega. The entire pre-trade gate needs a second implementation.
2. **Venue concentration.** Deribit carries the overwhelming majority of crypto options volume.
   Trading options seriously means single-venue counterparty concentration — directly against the
   ~25–30% per-venue exposure cap.
3. **Granularity at $10k.** Contract sizes and premium quanta make position sizing coarse at this
   capital. A hedge you cannot size precisely is a hedge that adds risk.
4. **It needs an IV surface first.** Vol strategies require a fitted, validated implied-vol surface
   with skew and term structure — a modelling project in its own right, and Black-Scholes assumptions
   fit crypto poorly.

**Sequencing:** spot + perps first (Phase 4, funding carry). Dated futures next (calendar basis —
same machinery, cleaner carry than perps). **Options as Phase 6**, after the Greeks risk layer and
the IV surface exist and have been validated in paper and shadow.

### Venues — SETTLED 2026-08-01

**Execution: Binance + Hyperliquid.** **Reference-price only: Kraken, OKX, Coinbase** — independent
sources feeding the liquidity-weighted consolidated feed, carrying no execution or key risk.
**Bybit: deferred**, a reasonable third venue later.

The two execution venues are deliberately *unalike*, which is the point — they fail differently — but
it means **two of nearly everything** in the ops layer:

| Concern | Binance | Hyperliquid |
|---|---|---|
| Auth model | API key + secret | **Wallet-based** — see key note below |
| Rate limits | Per-IP, exchange-wide; `418` bans scale to 3 days | Consensus-bound, different shape |
| Latency floor | ~5–23ms from the right region | **~880ms median, almost entirely server-side** — region choice buys little |
| Funding | 8-hourly, mark price | **Hourly, oracle price, capped 4%/hour** |
| Gap detection | Diff-depth `U`/`u` sequence chaining | Different mechanism — must be built separately |
| Oct 2025 cascade | Degraded ~1h; valued collateral on internal prices; USDe depegged to $0.65 *only there* | **100% uptime** |
| Known incident | $283M compensation paid post-cascade | **JELLY (Mar 2025)** — oracle manipulation resolved by *manual validator vote*, not an automated safeguard |

> ⚠️ **Key scoping differs fundamentally between them, and the Binance rule does not transfer.**
> On Binance the control is an API key with **withdrawal permission never enabled** plus mandatory IP
> allowlisting. Hyperliquid is on-chain: the owner wallet key **can move funds by definition** — there
> is no "disable withdrawal" flag on it. The equivalent control is an **API/agent wallet** that can
> trade but cannot transfer, with the owner key never present on the trading VM.
> **Verify the exact agent-wallet permission model against Hyperliquid's own docs before any key is
> generated** — this is the one place where getting the mapping wrong is unrecoverable, and it was not
> verified in this session.

**Cross-venue consequence:** the funding differential *between* Binance perps and Hyperliquid perps
is itself a tradeable carry spread, and it needs no cross-venue latency edge — both legs rebalance on
funding intervals. That is a Phase 4/5 candidate strategy, not just a data artefact.

### Venue narrowing — rationale (retained)

At <$10k, all six venues sit at **base fee tier** (meaningful tiers need $5M–$250M+ 30-day volume),
so cross-venue routing has no tier differential to exploit — while costing six integrations, six
rate-limit budgets, six key scopes, six failure modes. Coinbase (~120bps round-trip) and Kraken
(0.40/0.80) would consume the entire edge of any strategy that clears Binance's ~20bps.

**Recommended split:**
- **Execution: Binance + Hyperliquid.** Binance for fees, depth, and funding markets. Hyperliquid for
  its Oct 2025 record — 100% uptime while Binance degraded ~1h and dYdX was down ~8h — and on-chain
  verifiable fills.
- **Reference only: Kraken, OKX, Coinbase.** Independent price sources feeding the liquidity-weighted
  consolidated feed. This is precisely the defence Mango's failure argues for, obtained without
  execution risk or integration cost.
- **Bybit: add later.** Reasonable third venue; its Feb 2025 record ($1.5B stolen, $5.5B bank run in
  24h) argues for addition rather than launch.

---

## 3c. Stack — SETTLED 2026-08-01

All versions and constraints below were **verified live** against PyPI and GitHub, not recalled.

| Layer | Choice | Why |
|---|---|---|
| **Language** | **Python 3.12**, uv-managed | System Python is **3.14.4 — too new**. `polars` supports only ≤3.13; `nautilus_trader` requires ≥3.12,<3.15. **3.12 is the widest-supported intersection.** Do not use system Python |
| **Execution framework** | **NautilusTrader** 1.230.0 | Adapters cover **binance + hyperliquid** (both execution venues), **deribit** (Phase 6 options), **kraken + okx** (reference), plus `tardis` for historical crypto data. Rust core, Python API. 25.1k stars, pushed 2026-08-01 |
| **Storage** | **Parquet + ZSTD**, partitioned by symbol | No TSDB initially. If later: **ClickHouse or QuestDB — never TimescaleDB** (no native ASOF JOIN, which is exactly what backtesting needs) |
| **Query / transform** | **DuckDB** 1.5.5 + **Polars** 1.43.2 | DuckDB handles 100GB+ locally; ASOF joins native |
| **ML** | **LightGBM** 4.7.0, scikit-learn, **Optuna** capped at 50–100 trials | GBT beats DL at these horizons and is CPU-native. 12 cores / 29GB available |
| **Validation** | **Reuse `cpcv.py` + `backtest.py` from `nse-crypto-bot-final`** | Purge/embargo already correct. Add DSR, MinBTL, PBO. **Re-parameterise cost defaults** |
| **Experiment tracking** | **MLflow**, file store, no daemon | W&B free tier forbids corporate use. MLflow registry *stages* are deprecated — use aliases |
| **Secrets** | **`sops` + `age`** | No OS keyring (desktop tooling), no self-hosted Vault |
| **Dependencies** | **`uv` 0.12.1 + `uv.lock`** | Already installed |
| **Process supervision** | **`systemd --user`** | Verified running; needs no sudo |
| **Testing** | **pytest + Hypothesis** | Property-based testing is the only sane way to test a validation harness |

### Three constraints this environment imposes

**1. No containers.** Neither Docker nor Podman is installed, and there is no sudo to add them. The
research recommends pinning images **by digest** for reproducibility — **that option does not exist
here.** Substitute: `uv.lock` + recorded resolved versions + immutable checksummed data snapshots +
the provenance stamper. Weaker than digest-pinned containers; state the weakness rather than pretend
otherwise.

**2. NautilusTrader is LGPL-3.0**, not MIT/BSD like the rest of the stack. Importing it as a Python
library is dynamic linking, so it does **not** make your code copyleft — but obligations attach if
you ever modify Nautilus itself or distribute a bundled product. **Fine for private operation;
re-examine before any distribution.**

**3. Nautilus must not own Layer 0.** Its "same code path across backtest and live" property is
precisely the Layer 0 contract and the main reason to adopt it — but **the bitemporal store stays
ours**, and Nautilus consumes from it. Letting the framework own the truth layer surrenders the
`availability_time` guarantee to a data model that was not designed for it.

### Why NautilusTrader over ccxt + a custom loop

The decisive property is **one code path for backtest and live**. The validation research is explicit
that when backtesting uses a more permissive data-access path than live trading, the two silently
diverge and an off-by-one in windowing produces a great backtest and a broken system. Nautilus
enforces the shared path architecturally; ccxt does not, and a custom event engine means rebuilding
that guarantee by hand.

`ccxt` remains useful as a **thin fallback** for venues or endpoints Nautilus does not cover, and for
one-off REST reconciliation — not as the execution path.

### Considered and rejected — ZipLime (logged 2026-08-02)

**`Limex-com/ziplime`** — Zipline reimplemented on Polars. Verified real and active: **452★,
GPL-3.0, Python ≥3.12, PyPI 1.19.16, last push 2026-07-22.** It advertises the *same* decisive
property we chose Nautilus for — *"Live: use identical strategy implementations between backtesting
and live deployments"* — and its published benchmark puts ZipLime fastest, with `nautilus_trader`
second, across Lean, Backtrader, Zipline-reloaded and Pinescript.

**Rejected on two grounds, neither of them speed:**

1. **The benchmark is vendor-published** by Limex, on their own library. Not independent evidence.
2. **GPL-3.0 is stronger copyleft than Nautilus's LGPL-3.0.** §3c already treats LGPL as a live
   constraint — LGPL permits importing as a library without infecting our code, and only bites if
   we modify or redistribute Nautilus itself. **GPL-3.0 does not draw that line the same way.** For
   a private, unredistributed system it is workable, but it is strictly worse than the position we
   already accepted, in exchange for a benchmark we cannot verify.

Switching cost is also real: adapters for **binance + hyperliquid** (both chosen execution venues)
plus deribit for Phase 6 are the reason Nautilus was selected. ZipLime does not replace those.

**Revisit only if** an independent benchmark shows a decisive margin *and* the licence position is
re-examined. Not otherwise.

### Kronos — a dependency caveat, not a stack change

`shiyu-coder/Kronos` verified at **35,412★, 5,902 forks, MIT** — but **last push 2026-04-13**, roughly
four months stale as of writing. The API is fixed at `max_context=512`, with the documented usage
`pred.predict(df=klines[-400:], pred_len=120)` — so the 400-in/120-out figure is a **constraint of the
context window**, not a tuning choice. The authors' own README caveat is worth quoting into any
promotion decision: *"Raw signals are not pure alpha. No transaction costs, no risk neutralization.
A research tool, not a money printer."*

**Security note:** using it means loading third-party weights from HuggingFace. See
`FEATURES.md` §10 — pin by content hash, prefer `safetensors`, run inference sandboxed.

---

## 4. Open decisions

1. ~~**Stack.**~~ **SETTLED — see §3c.** Python 3.12 / NautilusTrader / Parquet+DuckDB / LightGBM.
   Rule 7 naming syntax is therefore unblocked: **PEP 8 `snake_case`**, modules named for
   responsibility (`risk_gate.py`, `cost_engine.py`, `bull_agent.py`), never `utils`/`helpers`.
2. **Fable and data retention.** Fable 5 mandates 30-day retention and is unavailable under ZDR.
   Routing proprietary strategy code through it is a policy decision. **Settle cold, before the
   escalation protocol first fires.**
3. **Binance matching-engine region** — sources conflict (Tokyo vs us-east-1). **Measure empirically
   with an RTT probe before committing infrastructure.**
4. **Paper-mode fill fidelity** — determines whether shadow is a separate stage or already built.
5. **Which venues.** Fee schedules re-verified live only for Binance spot and Kraken.

---

## 5. Not doing, with reasons

| Not doing | Why |
|---|---|
| Feature store (Feast) | Leakage protection off by default; no streaming; solves multi-consumer coordination you don't have |
| Dedicated TSDB initially | Parquet + DuckDB/Polars suffices; if later, **ClickHouse or QuestDB — not TimescaleDB** (no native ASOF JOIN, which is exactly what backtesting needs) |
| Custom binary storage format | A NautilusTrader maintainer talked this down; one builder made a faster format then chose a database anyway |
| Weights & Biases | Free tier states corporate use is not allowed |
| Self-hosted Vault / OS keyring | Adds an unattended component that itself needs securing |
| Great Expectations on the live path | Maintainers closed streaming support as unsupported |
| NAS | Searches network topology, not strategy logic. 22,400 GPU-hours in the original |
| WorldQuant Alpha101 reuse | Not GP-discovered — hand-curated, trade publication, gross of costs, public since 2015 |
| Market making / latency arb | Structurally closed at this size and latency |
| EVT tail fitting | Needs more tail observations than the history provides |
| Standalone regime detector with authority | Reliability doesn't support veto power |
| `mlfinlab` dependency | Public repo is **stub code** — function bodies are `pass`; real code behind a paid wall. Use `fracdiff` (BSD-3) |

---

## 6. Cautionary record

- **Alpha Arena / Nof1.ai (Oct–Nov 2025).** Six frontier LLMs, $10k each, autonomous, Hyperliquid
  perps, on-chain verifiable. 17 days: Qwen3-Max **+22.32%**, DeepSeek **+4.89%**, Claude Sonnet 4.5
  **−30.81%**, Grok 4 **−45.3%**, Gemini 2.5 Pro **−56.71%**, GPT-5 **−62.66%**. Causes were mundane:
  over-trading into fees, rigid directional bias, no stop discipline. **Absent risk rails, not exotic
  failure.**
- **Paper-vs-live rank correlation of −0.43** across six deployed bots — the harness ranked best
  performed worst. A validation process can point at the wrong strategies, not merely fail to help.
- **Derwent Capital Markets.** Twitter-mood paper (86.7% claimed accuracy) → real fund → closed in
  ~a year → formal non-replication in 2017.
- **Survivorship.** >14,000 of ~24,000 listed tokens are dead (>58%). One naive top-20 altcoin
  backtest: **+2,800% with bias vs +680% without.**
- **AlphaEvolve is not peer-reviewed** — self-labeled white paper, closed source, results
  self-reported. FunSearch (*Nature* 625) and ADAS (ICLR 2025) are peer-reviewed. Using the pattern
  is reasonable; treating its numbers as proof it transfers to trading is the extrapolation the
  research could not validate.
