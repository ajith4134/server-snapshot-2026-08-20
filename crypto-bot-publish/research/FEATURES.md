# FEATURE CATALOGUE — Autonomous Crypto Trading System

**Companion to `ARCHITECTURE.md`** (which defines components and contracts). This is the exhaustive
capability list — what the system does, not how it is structured.

**Phase key:** **P0** = before any capital · **P1** = before first live strategy · **P2** = before
second strategy / portfolio · **P3** = scale · **—** = deliberately deferred or declined.

> ⚠️ Items marked **[MISSED]** are ones commonly forgotten until they cost money or time. They are
> the reason this document exists.

---

## 1. Market data & ingestion

| Feature | Phase | Notes |
|---|---|---|
| Spot OHLCV + trade tape, multi-venue | P0 | |
| L2 order book depth (20–50 levels) | P0 | Needed for realistic fill modelling, not just signals |
| Perpetual funding rate history + schedule | P0 | Per-venue settlement times differ — this *is* the carry edge |
| Open interest | P1 | |
| Liquidation feed | P1 | Cascade detection, and a signal family in its own right |
| Spot-perp basis / term structure | P0 | Core carry input |
| Mark price vs index vs oracle price, per venue | P1 | **[MISSED]** — Hyperliquid funds on *oracle*, others on mark. Different economics |
| Cross-venue consolidated price, **liquidity-weighted** | P1 | Naive N-source averaging is what broke Mango |
| Stablecoin peg monitor | P1 | **[MISSED]** — USDe hit $0.65 *only on Binance* during Oct 2025 |
| Exchange reserve / netflow | P2 | |
| On-chain data (DEX pools, oracle updates) | P2 | Only if trading DEX venues |
| Macro context (DXY, rates, equity beta) | P2 | Regime conditioning |
| News / social / dev-activity feeds | P3 | Behind the Dual-LLM quarantine |
| Per-feed data-quality score | P1 | **[MISSED]** — feed health as a first-class metric, not an assumption |
| Gap detection + provenance-flagged backfill | P0 | Interpolated candles must be *labelled*, never silently blended |
| Wash-trading discount on reported volume | P1 | **[MISSED]** — never size off raw aggregate volume |

## 2. Feature engineering

| Feature | Phase | Notes |
|---|---|---|
| Realized volatility, multi-horizon | P0 | |
| **HAR-RV** | P1 | Beats GARCH-family for short-horizon crypto |
| Depth-weighted order-flow imbalance | P1 | **Never level-1 OBI** — demonstrably spoofable |
| **Absorption detection (delta vs price-hold)** | P1 | **[MISSED]** Positive delta at a high is meaningless if price cannot hold — that is **absorption, not strength**, and is bearish. Raw signed delta is as naive as level-1 imbalance |
| Microprice | P2 | Volume-adjusted variant outperforms the original |
| Kyle's lambda | P2 | Liquidity-regime descriptor for sizing, not a standalone signal |
| Fractional differentiation | P1 | Stationarity without destroying memory. Use `fracdiff` (BSD-3) |
| Triple-barrier labelling | P1 | Barrier width is a hyperparameter — it goes through the Trial Registry |
| Meta-labelling | P2 | Bet sizing / precision. Not an overfitting cure |
| Sample uniqueness + sequential bootstrap | P1 | Overlapping labels violate IID |
| Funding / basis spread features | P0 | |
| Time-of-day, day-of-week, **funding-hour** effects | P1 | **[MISSED]** — funding settles at fixed times, creating predictable flow |
| Cross-sectional ranking across pairs | P2 | |
| Volatility-regime decile | P1 | Feature only — never a gate |
| Correlation / beta to BTC | P2 | |
| Feature staleness timestamp on every value | P0 | **[MISSED]** — a feature must carry when it became knowable |

**Not doing:** the 200-indicator technical zoo. 7,846 rules tested on 100 years of Dow data; the best
failed out-of-sample once corrected for search size.

## 3. Models

| Feature | Phase | Notes |
|---|---|---|
| **Linear / naive baseline, mandatory** | P0 | **[MISSED]** — every model must beat it before promotion. Cheapest overfitting check that exists |
| Gradient-boosted trees | P1 | Primary workhorse; CPU-native |
| Stacked ensemble | P2 | |
| Meta-model over the experiment ledger | P2 | Learns which strategies work in which regime |
| Champion / challenger with delayed-label comparison | P2 | "Shadow Before Swap" |
| Rolling walk-forward retrain | P1 | Preferred over continual-learning ML |
| Model registry with aliases | P1 | MLflow aliases — registry *stages* are deprecated |
| Deep learning | P3 | Only as a representation front-end feeding a simpler decider |

## 4. Strategy families

| Family | Phase | Verdict |
|---|---|---|
| **Funding-rate carry** | P1 | **Start here** — latency-immune, viable at this size |
| **Spot-perp basis** | P1 | Same |
| Calendar / term-structure spreads | P2 | |
| Directional momentum (minutes–hours) | P2 | Latency-insensitive |
| Mean reversion | P2 | |
| Cross-venue relative value | P3 | Needs same-region VMs |
| Liquidation-cascade fading | P3 | High risk, real edge, needs the venue-health layer first |
| Event-driven (listings, unlocks, upgrades) | P3 | **[MISSED]** — a distinct, under-explored family |
| Statistical arbitrage / pairs | P3 | |
| **Variance risk premium harvest** | P3 | Options. Latency-immune and durable — the strongest options family for this profile |
| Delta-neutral vol / gamma scalping | P3 | Options |
| Covered calls / cash-secured puts | P3 | Options. Simplest entry, but caps upside |
| Skew and calendar/diagonal spreads | P3 | Options |
| Market making / passive liquidity | — | **Closed** — no reachable rebate tier, 10–20× queue disadvantage |
| Latency arbitrage | — | **Closed** — 5–10μs races vs an ~8ms cloud floor |
| Triangular arbitrage | — | Found never profitable after fees in a 2024 Binance study |

## 5. Execution

| Feature | Phase | Notes |
|---|---|---|
| Limit / market / post-only / IOC / FOK | P0 | |
| **Reduce-only orders** | P1 | **[MISSED]** — prevents an exit accidentally opening a reverse position |
| Idempotency key on every order | P0 | Client order ID derived deterministically |
| Partial-fill tracking by remaining quantity | P0 | Never a binary filled flag |
| Fee-tier-aware venue routing | P1 | Worth more than any execution algorithm at this size |
| Maker-vs-taker decision per order | P1 | Post-only as cost reduction, not a standalone strategy |
| Per-order slippage budget + abort | P1 | **[MISSED]** — cancel if the book moved past tolerance before ack |
| **Signal expiry / time-in-force discipline** | P0 | **[MISSED]** — a signal computed 5 minutes ago must not fire now |
| Cancel/amend churn limits | P1 | Kraken and OKX penalise churn explicitly |
| **Cross-strategy position netting** | P2 | **[MISSED]** — two strategies taking opposite sides pay fees *both ways*. Net internally before routing |
| Smart order routing across venues | P3 | |
| Iceberg / hidden orders | P3 | |
| TWAP / VWAP / Almgren-Chriss | — | Clips are thousands of times below where slicing helps |

## 5b. Options layer (P3 — required before any options position)

| Feature | Phase | Notes |
|---|---|---|
| Full option chain ingestion | P3 | Strikes, expiries, bid/ask, OI per contract |
| **Implied-vol surface fit** | P3 | Skew + term structure. Black-Scholes assumptions fit crypto poorly |
| Greeks computation (Δ, Γ, ν, Θ, ρ) | P3 | Per position **and** portfolio-aggregated |
| **Zomma (dGamma/dVol)** | P3 | **[MISSED]** Third-order Greek. Near the money it runs **negative** — a vol spike drains gamma from exactly where you are positioned, without the underlying moving at all. Combined with the leverage effect (price grinds up as vol bleeds, rolls over when vol wakes), **gamma and direction get hit together** |
| **Greeks-based pre-trade gate** | P3 | **A second risk implementation** — notional limits do not describe an options book. A short-vol position can be tiny by notional, catastrophic by vega |
| IV vs realized-vol spread | P3 | The variance-risk-premium signal itself |
| Put/call skew, term-structure features | P3 | |
| **Pin risk / expiry management** | P3 | **[MISSED]** — positions near strike at expiry behave discontinuously |
| Exercise & assignment handling | P3 | Including auto-exercise rules per venue |
| Delta-hedge scheduler | P3 | Hedge frequency is a cost/risk tradeoff, not a constant |
| Vega and gamma exposure limits | P3 | Portfolio-level, distinct from notional caps |

**Venue reality:** Deribit carries the overwhelming majority of crypto options volume — trading them
seriously means accepting single-venue concentration, directly against the per-venue exposure cap.

**Zomma, quantified** (added 2026-08-02, `instagram-findings.md` → `DbYOQlSFJSZ`). The row above was
written from a caption; the source's own worked example puts numbers on it. Same contract
(S≈30.4–31, K=30, T=90d, r=4.15%):

| Implied vol | Δ | Γ | **Zomma** |
|---|---|---|---|
| 15.9% | 0.636 | 0.130 | **−0.749** |
| 8.6% | 0.822 | 0.164 | **−0.373** |

*"Lower vol makes the gamma bell taller and narrower."* Confirms the negative-near-the-money claim
with real magnitudes rather than an assertion.

### Options tooling — do not write these from scratch

Verified 2026-08-02 (versions, licences and star counts checked against PyPI and GitHub, not taken
from the source). **Licence column matters**: GPL-3.0 is stronger copyleft than NautilusTrader's
LGPL-3.0, which §3c of `ARCHITECTURE.md` already flags as a constraint.

| Library | Version | Licence | Use |
|---|---|---|---|
| **Diffrax** | 0.7.2 | Apache-2.0 | Differentiable SDE solvers on JAX. Turns **Heston / rough Bergomi / jump-diffusion calibration from a grid search into a single optimizer call** — gradients flow back through the Monte Carlo paths |
| **py-pde** | 0.58.0 | MIT | Finite-difference PDEs. **Black-Scholes, Dupire local-vol PDE, Fokker-Planck** of a diffusion |
| **FinancePy** | 1.0.1 | **GPL-3.0** ⚠ | SABR, LMM, Hull-White, Bermudan trees, CDS curves, pinned to textbook conventions |
| **vollib** · **pysabr** · **optlib** · **tf-quant-finance** · **PyQL** (QuantLib port) | — | check before use | Option prices, IV, greeks, SABR. Named in `Da8LFnfFnqx`; worth a pass before hand-rolling a vol surface |

## 6. Risk

| Feature | Phase | Notes |
|---|---|---|
| Pre-trade gate: notional, leverage, position cap | P0 | Blocks the order *before* it is sent |
| Exchange-side kill switch / dead-man | P0 | |
| Watchdog process + firewall network kill | P0 | Separate process; the bot cannot police itself |
| Per-venue exposure cap (~25–30% of capital) | P1 | |
| **Liquidation-distance monitor** | P0 | **[MISSED]** — for perps this is survival. Alert on margin ratio, not just P&L |
| Margin health / auto-deleverage risk | P1 | ADL can overshoot — one venue expended 8× the actual deficit |
| Graduated drawdown ladder | P1 | Never a single binary kill |
| Correlation-breakdown breaker | P2 | Portfolio-level, leading indicator |
| Volatility-scaled sizing | P1 | Primary sizer |
| Fractional-Kelly ceiling | P1 | Cap, never a target |
| Auto-flatten on venue degradation | P1 | |
| Concentration limit per asset | P2 | |
| **Deployment freeze windows** | P1 | **[MISSED]** — never deploy during high vol or near funding settlement |
| Post-trade reconciliation vs exchange truth | P0 | |

## 7. Portfolio

| Feature | Phase | Notes |
|---|---|---|
| Discounted-bandit allocator | P2 | Vanilla Thompson assumes stationary arms |
| Capacity tracking per strategy | P2 | Divergence from a fixed-size shadow book |
| Rebalance scheduler | P2 | |
| **P&L attribution by cost component** | P1 | **[MISSED]** — split gross edge / fees / slippage / funding / impact. You cannot fix what you cannot attribute |
| Attribution by strategy, venue, regime | P2 | |
| Capital sweep to self-custody above a threshold | P1 | Scheduled, not continuous |
| **RMT correlation denoising (Marchenko–Pastur)** | P2 | **[MISSED — added 2026-08-02]** Sample correlation matrices are dominated by noise, and that noise is what portfolio optimisers latch onto. Compare the empirical eigenvalue spectrum against the Marchenko–Pastur bound and **discard eigenvalues indistinguishable from random**; rebuild the matrix from what survives. Without this, "optimal" weights are fitted to sampling error. Source `DYU0dMcpBFP`: *"Most correlations in financial markets are fake… if an eigenvalue looks statistically random, remove it."* Standard technique (López de Prado), not folklore |
| **Constrained optimisation via CVXPY** | P2 | Apache-2.0, v1.9.2. Expresses Markowitz, **CVaR**, tracking-error minimisation and **MIP cardinality caps** in something that reads like the maths; compiles to a cone program (ECOS/SCS/SCIP). Pairs with the row above — denoise the covariance *before* optimising, or the solver optimises noise precisely |
| **Bayesian posteriors via NumPyro** | P2/P3 | Apache-2.0, v0.21.0. NUTS on JAX. **Stochastic volatility, regime detection, hierarchical alpha** — anywhere a point estimate hides the risk that actually matters. Returns a distribution to feed the risk gate, not a single number |

## 8. Validation & research

| Feature | Phase | Notes |
|---|---|---|
| Experiment ledger — **including abandoned runs** | P0 | Every statistic depends on the true trial count |
| Trial Registry (cumulative N, enforced) | P0 | |
| Holdout Custodian (refuses queries) | P0 | |
| Purge + embargo, **configured per family** | P0 | Horizons differ by orders of magnitude |
| CPCV harness | P1 | Finalists only — combinatorics explode |
| Deflated Sharpe as in-loop fitness | P0 | Not a report on the winner |
| PBO / CSCV | P1 | |
| MinBTL hard gate | P0 | Cheap, closed-form |
| BH-FDR on the promoted set | P1 | Bonferroni too blunt at large N |
| Hansen SPA at the promotion gate | P2 | "Does the challenger beat the incumbent, corrected for variants tried" |
| Bootstrapped max-drawdown distribution | P1 | Sets non-arbitrary circuit-breaker thresholds |
| Shadow trading with alignment metrics | P1 | ≥95% signal, ≥90% execution match |
| **Regime-coverage tracker** | P1 | **[MISSED]** — gate on having seen a drawdown and a vol spike, not elapsed days |
| Backtest-vs-live divergence monitor | P1 | Technical divergence (bug) vs statistical decay (regime) |
| **Mechanism-health metric per strategy** | P1 | **[MISSED]** — declared at promotion; the only fast decay signal |

## 9. Operations

| Feature | Phase | Notes |
|---|---|---|
| Venue health monitor + auto-halt | P0 | |
| Cross-strategy rate-limit budgeter | P0 | Limits are per-IP and exchange-wide |
| Order-intent write-ahead log | P0 | Written *before* the request is sent |
| State recovery from exchange truth on restart | P0 | |
| Clock sync via `chrony` + drift alerting | P0 | Alert well before `recvWindow`, not after rejections |
| Sequence-gap detection on book streams | P0 | Heartbeat proves the socket, not the data |
| Reconnect with full-jitter backoff, honour `Retry-After` | P0 | Bans scale to days and are per-IP |
| Disk / memory / resource watchdog | P0 | Fail loud on disk-full or the WAL dies silently |
| **Cold-start behaviour** | P0 | **[MISSED]** — defined behaviour on first boot with no state |
| **Disaster recovery runbook** | P1 | **[MISSED]** — VM dies mid-position: what recovers, in what order |
| Tiered alerting (page / notify / log) | P1 | |
| Structured audit log of every decision | P1 | |

## 10. Security

| Feature | Phase | Notes |
|---|---|---|
| Withdrawal permission **never** on trading keys | P0 | Bounds a leak to bad trades |
| IP allowlisting | P0 | Mandatory on Binance for trading-capable keys |
| `sops` + `age` secret management | P0 | |
| Treasury / cold-storage separation | P0 | Separate sub-account, zero API surface |
| Per-venue sub-accounts | P1 | Blast-radius containment |
| Key rotation procedure | P1 | No exchange appears to offer programmatic self-revocation |
| Anomaly detection on own order behaviour | P2 | **[MISSED]** — catches a compromised or runaway bot from the outside |
| **Third-party model weights treated as untrusted binaries** | P1 | **[MISSED — added 2026-08-02]** The moment Kronos is adopted as a zero-shot baseline, we load `NeoQuasar/Kronos-small` from HuggingFace. **Weights are data, and data can carry object code.** The documented technique (`Da1XG9qgd4E`): embed pre-built object code in layers the forward pass **never executes** — the network's behaviour is unchanged, so nothing looks wrong — then link it at deployment. Abstract it to a portable object format and it runs on ARM and x86 alike. This is the **xz-utils playbook**: no malicious source in the repo, just object code shipped as "tests", assembled by the resident linker into an SSH backdoor. Mitigation: **pin by content hash, prefer `safetensors` over pickle, and run inference sandboxed / network-isolated.** Detection tooling for this class is immature — containment is the control, not scanning |
| **Agent-with-wallet blast radius** | P2 | Relevant if any component is ever given spend authority. `DbGFvV0Bwn5` / `Da4XlSfhtNo` describe agents holding their own keys, paying for compute, and self-replicating while solvent. Under Rule 0's cost-of-error buckets this is **"never do" territory** unless capital movement stays behind the human gate |

## 11. Intelligence layer

| Feature | Phase | Notes |
|---|---|---|
| Dual-LLM quarantine for untrusted content | P1 | Reader has no tools and no credentials |
| **LLM look-ahead guard** | P1 | **[MISSED]** — LLMs know outcomes inside their training window; any LLM-derived signal is contaminated on those dates |
| Research synthesis / literature ingestion | P2 | |
| Automated postmortem writer | P2 | Feeds the ledger |
| Knowledge base / memory | P2 | |
| LLM-authored strategy code | P3 | Sandboxed, gated, never auto-promoted |

> **This section is the thin version.** The full capability space for intelligence, autonomy and
> self-knowledge — 71 candidate features, 39 rated HIGH — is in **`IDEAS-INTELLIGENCE.md`**
> (added 2026-08-02). The ten highest-leverage, in order: belief records with provenance and
> half-life · read/verified/observed epistemic classes · verification-before-ingestion ·
> abstention as a real action · self-calibration scoring · "who loses when I win?" ·
> meta-analysis over the Trial Registry · own-footprint attribution · cost-of-operation in the
> objective · property-based invariants across backtest/shadow/live.

## 12. Governance & compliance

| Feature | Phase | Notes |
|---|---|---|
| Manual promote button | P0 | Already decided |
| Config versioning + rollback | P0 | |
| Change log tied to deployments | P1 | |
| **Tax / accounting fill record** | P1 | **[MISSED]** — every fill, timestamped, in an exportable ledger. Painful to reconstruct after the fact |
| **Jurisdiction / venue eligibility check** | P1 | **[MISSED]** — which venues are legally usable, and KYC tier limits |
| Retention policy for proprietary code and data | P1 | Decides whether Fable 5 is usable at all |

## 13. Observability

| Feature | Phase | Notes |
|---|---|---|
| Latency histograms per venue and endpoint | P1 | |
| Fill-quality metrics vs assumed | P1 | The number that predicts live degradation |
| Cost breakdown dashboard | P2 | |
| Strategy health board | P2 | |
| Ultra-visual animated node dashboard | P3 | Produces zero alpha; scales with node count |

---

## The twenty most-forgotten, ranked

1. **Cross-strategy netting** — paying fees to trade against yourself
2. **P&L attribution by cost component** — cannot fix what you cannot attribute
3. **Liquidation-distance monitor** — survival metric for perps
4. **Signal expiry** — stale signals firing into a changed market
5. **Linear baseline as a promotion prerequisite**
6. **Mechanism-health metric** — the only fast decay signal
7. **Regime-coverage gate** instead of elapsed days
8. **Tax/accounting fill record**
9. **Cold-start behaviour**
10. **Disaster-recovery runbook**
11. **Reduce-only orders**
12. **Feature staleness timestamps**
13. **Deployment freeze windows**
14. **Funding-hour seasonality**
15. **Stablecoin peg monitoring**
16. **Mark vs index vs oracle price per venue**
17. **Wash-trading volume discount**
18. **LLM look-ahead guard**
19. **Jurisdiction / venue eligibility**
20. **Per-feed data-quality scoring**

## Phase 0 minimum — nothing live before all of these

Data: bitemporal store, clock-gated access, gap detection, feature staleness stamps.
Validation: ledger with abandoned runs, Trial Registry, Holdout Custodian, purge/embargo, DSR
in-loop, MinBTL.
Execution: idempotency keys, partial-fill tracking, signal expiry.
Risk: pre-trade gate, kill switch, watchdog + firewall, liquidation-distance monitor, reconciliation.
Ops: venue health, rate budgeter, WAL, state recovery, clock sync, sequence-gap detection, backoff,
resource watchdog, cold-start.
Security: no withdrawal permission, IP allowlist, `sops`+`age`, treasury separation.
Governance: manual promote, config versioning.
