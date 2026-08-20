# Requirements Ledger — strategy, portfolio

Merged 2026-08-08. Raw rows in slice: 395. Merged rows: 149. Collapsed: 246.

**Slice definition:** every row across the seven raw files at `~/research/ledger/raw/` whose `Category`
column reads exactly `strategy` or `portfolio` (case-insensitive, parsed programmatically from each
file's markdown table — 395 rows matched: 318 `strategy`, 81 `portfolio` across
crypto-bot-and-nse-botonly.md (77), early-repos-metaai-civilization.md (8),
early-repos-strategy-execution.md (64), early-repos.md (28), notes-and-media.md (37),
nse-crypto-bot-final.md (111), research-corpus.md (70)).

**Status verified against:** `trading-system/src/{capture,store,cost,statuswall}` and `tests/`
(grepped for strategy/portfolio/arbiter/router/allocator — no matches that are real implementations;
zero `strategy/`, `portfolio/`, or `arbiter/` directories exist anywhere in `src/`) · `research/ARCHITECTURE.md`
· `research/FEATURES.md` · `research/DECISIONS.md` · `research/DESIGN-NOTE-universe-wide-scanning.md`
· `trading-system/docs/superpowers/specs/2026-08-08-final-project-goal-design.md`.

**Zero rows in this slice are CLAIMED.** The current project is entirely Layer 0 (raw capture,
bitemporal store, cost engine, status wall) — no strategy, portfolio, allocator, or arbiter code
exists anywhere in `src/`. Every row below is PLANNED, PRIOR-ART, DECLINED, or UNRESOLVED.

---

## Portfolio — allocation, sizing, risk-shaping

| # | Requirement | Category | Status | Phase | Evidence / satisfying module | Sources | Notes |
|---|---|---|---|---|---|---|---|
| SP-001 | Portfolio netting layer above the brains | portfolio | PLANNED | P2 | `ARCHITECTURE.md` §3b; `FEATURES.md` §3b/§12 | research-corpus | Activates once a second brain holds live capital; two brains on opposite sides of one symbol currently pay fees both ways |
| SP-002 | Discounted / sliding-window Thompson-sampling capital allocator | portfolio | PLANNED | P2 | `ARCHITECTURE.md` Layer 4; `FEATURES.md` §7; `search-infrastructure-pbt-nas-bayesopt-bandits.md` §4 (verdict: "build it — best-fitting technique, and cheap") | research-corpus, crypto-bot-and-nse-botonly, notes-and-media | Vanilla Thompson assumes stationary arms; corroborated by a dedicated research-note verdict, not just the architecture doc |
| SP-003 | Capacity model / capacity tracking per strategy | portfolio | PLANNED | P2 | `ARCHITECTURE.md` Layer 1; `FEATURES.md` §7 | research-corpus, crypto-bot-and-nse-botonly | Divergence between live results and a fixed-size shadow book is the capacity signal |
| SP-004 | Symbol-level Beta Thompson-sampling bandit ("Symbol Bandit") | portfolio | PRIOR-ART | — | `paper_trader.py:2723-2732`; `live_trader.py:1643-1652`; also documented at `trading/symbol_bandit.py` in a sibling repo (not independently read there) | early-repos-strategy-execution, early-repos | Distinct axis from the strategy-capital allocator above — bandit over *which symbol*, not *which strategy* |
| SP-005 | Regime-contextual champion bandit (Thompson per strategy×regime, bounded stake multiplier) | portfolio | PRIOR-ART | — | `trading/strategy/champion_bandit.py:1-18` | nse-crypto-bot-final | Beta posteriors per strategy×regime; `stake_scale` bounded to [0.5, 2.0] |
| SP-006 | UCB1 multi-armed-bandit strategy selector | portfolio | PRIOR-ART | — | `strategy/selector.py` | early-repos | Simpler, older sibling of SP-002 and SP-005 |
| SP-007 | EXP3 adversarial bandit allocator | portfolio | PLANNED-considered | — | `IDEAS-ADVANCED.md` §6; `IDEAS-AI-FIELD.md` Part I; `search-infrastructure-pbt-nas-bayesopt-bandits.md` §4 | research-corpus, crypto-bot-and-nse-botonly, notes-and-media | Worst-case guarantees but converges slower than needed in markets that are noisy, not truly adversarial; practitioners in the research lean toward SP-002 instead |
| SP-008 | Online learning with expert advice (Hedge) | portfolio | PLANNED | — | `IDEAS-ADVANCED.md` §6; `IDEAS-AI-FIELD.md` Part I | research-corpus, crypto-bot-and-nse-botonly | Regret bounds without distributional assumptions |
| SP-009 | Risk parity / equal risk contribution allocation | portfolio | PLANNED | — | `allocation-and-regime.md` — "Allocation across strategies" | notes-and-media | Explicit verdict: "the right default" at 3–5 strategies; needs only a covariance matrix |
| SP-010 | Hierarchical Risk Parity (HRP) | portfolio | PLANNED-deprioritized | — | `allocation-and-regime.md` | notes-and-media | Verdict: "defensible but not clearly better at 3–5 branches; skip the clustering/linkage tuning." Clustering step called unstable under small-perturbation critique (unverified) |
| SP-011 | Mean-variance optimization (Markowitz / MVO) | portfolio | DECLINED | — | `allocation-and-regime.md` | notes-and-media | "An error-maximization procedure (Michaud 1989) that overweights whichever strategy got luckier with only 3–5 strategies and a year of data — don't bother" |
| SP-012 | Black-Litterman allocation | portfolio | DECLINED | — | `allocation-and-regime.md` | notes-and-media | "Don't bother — its value is an equilibrium prior reverse-engineered from market caps, and there is no equilibrium to recover from 3 internal branches." Prior-art exists regardless (PortfolioOptimizer's win-rate-derived-views Black-Litterman path, early-repos-strategy-execution) but is explicitly not to be adopted here |
| SP-013 | Drawdown-constrained optimization (CDaR) | portfolio | PLANNED-partial | — | `allocation-and-regime.md` | notes-and-media | "Don't build the full LP formulation, but keep the underlying concept" |
| SP-014 | Empirical "starving" allocator | portfolio | PLANNED | — | `DECISIONS.md` (carried decision); `allocation-and-regime.md` | notes-and-media | Judged more robust than any formal optimizer at 3–5 strategy scale because it doesn't require trusting a thin-data covariance estimate; goal doc §3 makes this the enforcer of the prime directive |
| SP-015 | Rebalance scheduler | portfolio | PLANNED | P2 | `FEATURES.md` §7 | research-corpus, crypto-bot-and-nse-botonly | Scheduled, not continuous |
| SP-016 | P&L attribution by cost component | portfolio | PLANNED | P1 | `FEATURES.md` §7 [MISSED] | research-corpus | Split gross edge / fees / slippage / funding / impact |
| SP-017 | Attribution by strategy, venue, regime | portfolio | PLANNED | P2 | `FEATURES.md` §7 | research-corpus | Multi-axis P&L attribution |
| SP-018 | RMT / Marchenko-Pastur covariance denoising | portfolio | PLANNED | P2 | `FEATURES.md` §7 [MISSED]; `IDEAS-ADVANCED.md` §15 | research-corpus (cited twice from two source docs, collapsed to one row) | Discard eigenvalues indistinguishable from random before rebuilding the correlation matrix — otherwise "optimal" weights fit sampling error |
| SP-019 | RMT covariance cleaning — working prior-art | portfolio | PRIOR-ART | — | `pattern_brain/nodes/physics.py` (`RMTDenoiseNode`); `MODEL_PERFORMANCE_REPORT.md` | early-repos | Described as the first (and most durable) model shown to genuinely beat baseline — real, cost-robust risk reduction confirmed multi-year/multi-regime, though the model's own realized-Sharpe significance was later honestly downgraded in the same log. Directly satisfies SP-018 if ported |
| SP-020 | Constrained optimisation via CVXPY | portfolio | PLANNED | P2 | `FEATURES.md` §7 | research-corpus, crypto-bot-and-nse-botonly | Markowitz, CVaR, tracking-error minimisation, MIP cardinality caps; pairs with RMT denoising |
| SP-021 | Bayesian posteriors via NumPyro | portfolio | PLANNED | P2/P3 | `FEATURES.md` §7 | research-corpus | NUTS on JAX for stochastic volatility / regime detection / hierarchical alpha; returns a distribution, not a point estimate |
| SP-022 | Distributionally Robust Optimization (DRO) | portfolio | PLANNED | — | `IDEAS-ADVANCED.md` §9 | research-corpus, crypto-bot-and-nse-botonly | Optimises the worst case within an uncertainty set; addresses covariance mis-estimation directly |
| SP-023 | Multi-objective / Pareto frontier optimization (return vs drawdown vs turnover) | portfolio | PLANNED | — | `IDEAS-ADVANCED.md` §9 | research-corpus, crypto-bot-and-nse-botonly | |
| SP-024 | Robust optimization | portfolio | PLANNED | — | `IDEAS-ADVANCED.md` §9 | research-corpus | Cheaper cousin of DRO |
| SP-025 | Stochastic programming | portfolio | PLANNED | — | `IDEAS-ADVANCED.md` §9 | research-corpus | Heavy machinery, flagged as such for a handful of strategies |
| SP-026 | Nonlinear filtering for latent market state (particle / unscented) | portfolio | PLANNED | — | `IDEAS-SYNTHESIS.md` Part IV | research-corpus | Regime as a latent state observed through noise, posterior updated online |
| SP-027 | Kalman / particle filters for latent state estimation | portfolio | PLANNED | — | `IDEAS-ADVANCED.md` §10 | research-corpus | Prior-art: `KalmanHedgeRatio` inside pairs trading (SP-063), `KalmanTrend` inside the stat-arb family (SP-063) |
| SP-028 | Pessimism proportional to capacity distance | portfolio | PLANNED | — | `IDEAS-SYNTHESIS.md` Part I | research-corpus | Continuous penalty version of "scale up slowly" |
| SP-029 | Universal portfolios (Cover) | portfolio | PLANNED | — | `IDEAS-AI-FIELD.md` Part I | research-corpus, crypto-bot-and-nse-botonly | Provable regret vs. best constant-rebalanced portfolio in hindsight; valuable purely as a benchmark |
| SP-030 | Quality-diversity archive (MAP-Elites) for the strategy population | portfolio | PLANNED | — | `IDEAS-INTELLIGENCE.md` §9 | research-corpus, crypto-bot-and-nse-botonly | Maintain an archive indexed by behaviour, not score — correlation is what kills portfolios |
| SP-031 | Quality-diversity generator — working prior-art | strategy | PRIOR-ART | — | `trading/strategy/generators/quality_diversity.py:1-20` | nse-crypto-bot-final | pyribs `GridArchive` + CMA-ME emitter over a (activity × directional bias) behaviour space; elites face the standard guardrail. Directly satisfies SP-030's mechanism if adapted |
| SP-032 | Lyapunov stability proof for the allocation feedback loop | portfolio | PLANNED | — | `IDEAS-ADVANCED.md` §17; `IDEAS-AI-FIELD.md` Part III | research-corpus | Prove signal→position→P&L→sizing cannot diverge |
| SP-033 | Scheduling / integer programming for rebalance ordering | portfolio | PLANNED | — | `IDEAS-ADVANCED.md` §17 | research-corpus | |
| SP-034 | Barbell allocation | portfolio | PLANNED | — | `IDEAS-STRATEGIC.md` §8 | research-corpus, crypto-bot-and-nse-botonly | Extreme safety plus small extreme-convexity allocation, avoiding the ruinous middle |
| SP-035 | Stochastic portfolio theory / relative arbitrage (Fernholz) | strategy | PLANNED | — | `IDEAS-SYNTHESIS.md` Part IV | research-corpus, crypto-bot-and-nse-botonly | Proves relative arbitrage under observable diversity/volatility-structure conditions without forecasting; crypto's concentration dynamics make the diversity condition directly testable |
| SP-036 | Stochastic optimal control / HJB formulation | portfolio | PLANNED | — | `IDEAS-SYNTHESIS.md` Part IV | crypto-bot-and-nse-botonly | Disciplines the execution/portfolio-choice problem statement even where intractable directly |
| SP-037 | Hazard model over own strategy population (survival curves) | portfolio | PLANNED | — | `IDEAS-SYNTHESIS.md` Part II | crypto-bot-and-nse-botonly | Outputs probability a strategy is alive in 90 days, for sizing |
| SP-038 | Competing-risks analysis (cause-specific hazards) | portfolio | PLANNED | — | `IDEAS-SYNTHESIS.md` Part II | crypto-bot-and-nse-botonly | Which death to defend against, per strategy |
| SP-039 | Actuarial expected-remaining-life sizing input | portfolio | PLANNED | — | `IDEAS-SYNTHESIS.md` Part II | crypto-bot-and-nse-botonly | Position size reflects expected remaining edge life, not just current Sharpe |
| SP-040 | Birth-cohort effect tracking | portfolio | PLANNED | — | `IDEAS-SYNTHESIS.md` Part II | research-corpus, crypto-bot-and-nse-botonly | Strategies discovered in the same regime share failure modes and die together — a hidden correlation cluster |
| SP-041 | Curiosity budget for information-seeking probes | portfolio | PLANNED | — | `IDEAS-INTELLIGENCE.md` §4 | crypto-bot-and-nse-botonly | Fixed fraction of capital/compute for actions whose purpose is information, not profit |
| SP-042 | Live capacity discovery | portfolio | PLANNED | — | `IDEAS-INTELLIGENCE.md` §5 | crypto-bot-and-nse-botonly | Grows size deliberately until marginal edge decays — measures rather than assumes the capacity ceiling |
| SP-043 | Cost-of-operation inside the objective | portfolio | PLANNED | — | `IDEAS-INTELLIGENCE.md` §5 | crypto-bot-and-nse-botonly | Compute/data/inference/API costs belong in the P&L |
| SP-044 | Operator time costed explicitly | portfolio | PLANNED | — | `IDEAS-STRATEGIC.md` §3 | crypto-bot-and-nse-botonly | So high-maintenance strategies don't silently fill the portfolio |
| SP-045 | Multi-period portfolio optimization with transaction costs (receding-horizon MPC) | portfolio | PLANNED | — | `IDEAS-STRATEGIC.md` §7 | crypto-bot-and-nse-botonly | Executes first step, re-plans |
| SP-046 | Fractional (half/quarter) Kelly position sizing | portfolio | PLANNED | — | `ARCHITECTURE.md` Layer 4 Sizer; `risk-and-failure.md` §4 | research-corpus (ARCHITECTURE citation), notes-and-media | Half-Kelly ≈ 75% of growth at 25% of variance; full Kelly produces 50–60% drawdowns ~20% of the time over 1,000 bets |
| SP-047 | Portfolio Kelly + HRP risk-weight engine | portfolio | PRIOR-ART | — | `trading/advintel/portfolio_risk.py:145-239` | nse-crypto-bot-final | Riskfolio-lib / PyPortfolioOpt-backed, numpy fallback |
| SP-048 | Portfolio max-drawdown + heat + Riskfolio optimizer | portfolio | PRIOR-ART | — | `trading/advintel/portfolio_risk.py:240-375` | nse-crypto-bot-final | Aggregate portfolio heat (risk deployed), MinRisk objective |
| SP-049 | Portfolio optimizer — HRP / Black-Litterman / max-Sharpe / min-variance / risk-parity / Kelly | portfolio | PRIOR-ART | — | `portfolio/optimizer.py:1-519` | early-repos-strategy-execution, early-repos | SLSQP risk-parity, PyPortfolioOpt HRP with pure-Python fallback, correlation-pair reporting; multi-asset Kelly path present but found dead (unreachable via method dispatch) in one repo instance |
| SP-050 | NSE capital-allocation optimizer (CVXPY Mean-CVaR / Ledoit-Wolf / Risk-Parity / Enhanced-Indexing) | portfolio | PRIOR-ART | — | `capital_allocation_optimizer.py`; `experience_scenario_matrix_builder.py`, `ledoit_wolf_covariance_estimator.py`, `integer_lot_allocator.py`, `capital_allocation_engine_store.py` | crypto-bot-and-nse-botonly (nse-botonly rows) | Real CVXPY-solved convex risk-budget allocation with cardinality/turnover/gross-net constraints, CLARABEL/SCS solver fallback, bootstrap-resampled scenario matrix, atomic-JSON state. Feature-donor per goal doc §5 — NSE market itself is out of scope, this machinery is not |
| SP-051 | Exploration-slot portfolio bookkeeping (min-concurrent-trades floor, Pyramid add-on sizing, daily-performance/checkpoint/peak-P&L persistence) | portfolio | PRIOR-ART | — | `paper_trader.py:296-304,1783-1819,2999-3226,139-147,3471-3481`; `live_trader.py:79-80,986-1009,1370-1496,1706-1864` | early-repos-strategy-execution | Grouped; pyramid add-on is a 2nd position in the same symbol at 40% capital, "profit-funded" only if unrealised P&L on the existing leg covers it |
| SP-052 | Opportunity Interruptor (early-close worst exploration for a materially better signal) | portfolio | PRIOR-ART | — | `paper_trader.py:3037-3163`; `live_trader.py:1887-2015` (live version dead in practice) | early-repos-strategy-execution | Closes the worst open exploration if a signal scoring ≥75 exists and its EV beats hold-EV via a RecoveryPredictor. Same shape as SP-102's optimal-stopping rule below — a working precedent, not a substitute for it |
| SP-053 | Portfolio RL Agent (correlation-aware, manages all open positions per tick) | portfolio | PRIOR-ART, unverified | — | `meta_ai/portfolio_rl.py` | early-repos | State recorded as "DOCUMENTED (per HOW_TO_RUN.md)" only — not independently read this pass; carried forward honestly rather than dropped |
| SP-054 | Editable paper-wallet / simulation-engine design (per-market pluggable-reality `Wallet` objects) | portfolio | UNRESOLVED | — | `online-editable-paper-money-engine.md` (surveys Freqtrade/Hummingbot/Alpaca/QuantConnect/OpenAlgo) | nse-crypto-bot-final | Design-only, never built even in the source repo. Directly relevant to `ARCHITECTURE.md` §4 open question 4, "paper-mode fill fidelity — determines whether shadow is a separate stage or already built" |
| SP-055 | Perp funding as an explicit P&L line, charged at actual settlement times, never smoothed | portfolio | PLANNED | — | `DECISIONS.md` §9 | research-corpus, crypto-bot-and-nse-botonly | 1h/4h/8h by venue |

## Strategy — core family taxonomy (`FEATURES.md` §4)

| # | Requirement | Category | Status | Phase | Evidence / satisfying module | Sources | Notes |
|---|---|---|---|---|---|---|---|
| SP-056 | Funding-rate carry | strategy | CLAIMED | P1 | **2026-08-16**, `src/strategy/funding_carry.py`, 19 tests. Delta-hedged, per the user's answer to the spec's §11 Q2 on 2026-08-16. **One expression, evaluated identically on every candidate** — §5a.5 calls per-symbol tuning *"the single most dangerous thing that could be implemented here"*, so the only per-symbol quantity is the funding percentile against that symbol's own history. The acceptance threshold is the **capacity-th best net carry among everything that cleared the cost gate**, so it rises with opportunity flow rather than being a number somebody chose. **Live result at the spec's own gate (one settlement): 0 proposals of 1,100 candidates.** Delta-hedged funding carry on binance does not pay for its own round trip in a single settlement on any symbol in the universe today — 394 declined below the cost gate, 301 not dollar-quoted, 232 on an unpaired venue, 173 with no spot leg. It takes a **24-settlement (8-day)** hold to find 2, and **90 settlements (30 days)** to find 55. Per the spec, *"a refusal is a pass for this phase"* | research-corpus, crypto-bot-and-nse-botonly | Latency-immune, viable at this size. **Three defects found by running it, each of which flatters.** (1) The universe was an *optional* argument defaulting to `None`, which skipped the filter — and the filter is what establishes that a hedge leg exists. Unfiltered, the top four proposals were BTWUSDT, ESPORTSUSDT, SPORTFUNUSDT and STARUSDT at **79–137% annualised**, and **173 candidates had no spot market to hedge against**: the funding was paying for exactly the risk the hedge was supposed to remove. Now required. This is the defect that cannot be seen in the output — the proposals look excellent. (2) **A vocabulary collision made every spot quote refuse, silently and totally**: the store's venue is a FEED (`binance-spot`), the fee table's is an EXCHANGE (`("binance","spot")`), so 868 of 868 binance perps declined `cost_refused`. Neither table was wrong — they disagree about what a word means. (3) The capacity rule over-fills on ties: 48 symbols sit at binance's **1 bp default funding rate**, so the threshold landed on a value dozens share. Ties are reported through `over_capacity`, never broken — and the overflow is itself the finding, since a screen whose acceptance threshold lands on the venue's default rate is ranking noise rather than carry. **(4) The worst one, found after this row was already committed: the gate compared the ANNUALISED carry against the ONE-OFF round-trip cost** — 1095 bps against 24 bps, PASS — but an annual rate is only earned by holding for a year. Over one 8-hour settlement that trade earns **1 bp and pays 24**, a 23 bp loss, and needs 24 settlements to break even. The gate passed trades that lose money on every realistic holding period and the output looked outstanding. It now gates on carry **earned** over a declared `holding_settlements`, restoring the spec §4 step 3 rule; the annualised figure lives in its own field because it is what compares instruments with different schedules, and separate fields are what stop the two being confused again. **(5) Exposed while fixing (4):** charging funding inside the perp leg's cost quote double-counts with the sign reversed — this trade is *short* the perp, so funding is its revenue — and it made a pass unrunnable by re-reading the whole clock-gated funding dataset once per symbol. Proposes only: no sizing, no orders. |
| SP-057 | Funding-rate carry — working prior-art | strategy | PRIOR-ART | — | `strategies/funding_arbitrage.py:1-501` (`FundingRateMonitor`/`FundingArbitrageStrategy`); `trading/advintel/arbitrage.py:156-233` (delta-neutral farming detector, breakeven/annualized-net-of-fee math) | early-repos-strategy-execution, early-repos, nse-crypto-bot-final | Fades the over-leveraged side; pre-payment urgency confidence boost. Directly satisfies SP-056's mechanism |
| SP-058 | Spot-perp basis | strategy | PLANNED | P1 | `FEATURES.md` §4 | research-corpus, crypto-bot-and-nse-botonly | Same latency-immune profile as funding carry |
| SP-059 | Cross-venue funding differential (Binance vs. Hyperliquid perps) | strategy | PLANNED | — | `ARCHITECTURE.md` §3b | research-corpus, crypto-bot-and-nse-botonly | Tradeable carry spread, no cross-venue latency edge needed — both legs rebalance on funding intervals |
| SP-060 | Calendar / term-structure spreads | strategy | PLANNED | P2 | `FEATURES.md` §4; `ARCHITECTURE.md` §3b | research-corpus, crypto-bot-and-nse-botonly | Dated-futures calendar basis |
| SP-061 | Directional momentum / trend-following family | strategy | PLANNED | P2 | `FEATURES.md` §4 | research-corpus, crypto-bot-and-nse-botonly | Latency-insensitive |
| SP-062 | Directional momentum/trend/breakout — working prior-art (~50+ named classes across two independent repo lineages) | strategy | PRIOR-ART | — | `strategies/trend/trend_strategies.py` (10: EMACross, TripleEMA, MACDTrend, Ichimoku, SuperTrend, ADXTrend, ParabolicSAR, DonchianBreakout, VWAPTrend, LinearRegressionTrend); `strategies/momentum/momentum_strategies.py` (6: ROCMomentum, DualMomentum, MFIDivergence, OBVDivergence, CVDMomentum, VolumeSurge); `strategies/breakout/breakout_strategies.py` (6); `analysis/alpha_factor_zoo.py` (20 cross-sectional factors); `trading/strategy/library/catalog/momentum.py` (12: incl. AQR TSMOM); `trading/strategy/library/catalog/trend.py` (16: incl. Turtle System-2, KAMA, TEMA); `trading/strategy/library/catalog/breakout.py` (10) | early-repos-strategy-execution, early-repos, nse-crypto-bot-final | Grouped per instructions rather than emitted as 60+ rows. Two genuinely separate implementations (not duplicates of each other) |
| SP-063 | Mean reversion family | strategy | PLANNED | P2 | `FEATURES.md` §4 | research-corpus, crypto-bot-and-nse-botonly | |
| SP-064 | Mean reversion — working prior-art (~22 named classes) | strategy | PRIOR-ART | — | `strategies/mean_reversion/mean_reversion_strategies.py` (8: RSIReversion, BollingerBandReversion, ZScoreReversion, VWAPReversion, KeltnerReversion, StochasticReversion, CCIReversion, WilliamsRReversion); `trading/strategy/library/catalog/mean_reversion.py` (14: incl. Connors RSI-2, Ultimate Oscillator) | early-repos-strategy-execution, nse-crypto-bot-final | |
| SP-065 | Cross-venue relative value | strategy | PLANNED | P3 | `FEATURES.md` §4 | research-corpus, crypto-bot-and-nse-botonly | Needs same-region VMs |
| SP-066 | Liquidation-cascade fading | strategy | PLANNED | P3 | `FEATURES.md` §4 | research-corpus, crypto-bot-and-nse-botonly | High risk, real edge, needs the venue-health layer first. Distinct-mechanism exception item, already its own row |
| SP-067 | Liquidation-cascade fading — working prior-art | strategy | PRIOR-ART | — | `selector.py:893-959` (`CASCADE_RIDE_SHORT` gate — blocks a LONG during an active downward cascade, substitutes a dedicated SHORT); `paper_trader.py:1908-1911,1931-1940,2263-2277`; `trading/strategy/library/catalog/order_flow.py` (liquidation-cascade hunting, one of 9) | early-repos-strategy-execution, nse-crypto-bot-final | |
| SP-068 | Event-driven (listings, unlocks, upgrades) | strategy | PLANNED | P3 | `FEATURES.md` §4 [MISSED] | research-corpus, crypto-bot-and-nse-botonly | A distinct, under-explored family |
| SP-069 | Event-driven & macro — working prior-art catalog (23 templates) | strategy | PRIOR-ART | — | `trading/strategy/library/catalog/event_macro.py` | nse-crypto-bot-final | Earnings/budget/RBI/Fed/election event trading, merger/dividend arbitrage, index-rebalance front-run, macro carry trades, factor investing. Exceeds current plan's scope (macro/factor-investing not named in `FEATURES.md` §4) — flagged, not silently folded in |
| SP-070 | Statistical arbitrage / pairs (including cointegration mechanism) | strategy | PLANNED | P3 | `FEATURES.md` §4; `IDEAS-ADVANCED.md` §16 (cointegration theory: Engle-Granger, Johansen) | research-corpus, crypto-bot-and-nse-botonly | Distinct-mechanism exception item (pairs/cointegration), already its own row — not a near-duplicate collapse target |
| SP-071 | Statistical arbitrage / pairs — working prior-art (huge: 33+ named classes) | strategy | PRIOR-ART | — | `strategies/pairs_trading.py:1-583` (`PairsTradingStrategy`/`CointegrationTester`/`KalmanHedgeRatio`, Engle-Granger + Kalman-filtered hedge ratio, 9 crypto pairs); `strategies/statistical_arb/stat_arb_strategies.py` (4: KalmanTrend, WaveletTrend, FourierCycle, HurstExponent); `trading/strategy/library/catalog/statistical_arbitrage.py` (33: pairs, cointegration Engle-Granger/Johansen+Kalman, basket/ETF/index arb, factor arb, correlation arb, sector rotation, cash-and-carry, roll-yield harvesting, cross-exchange/triangular/DEX-CEX/cross-chain arb) | early-repos-strategy-execution, nse-crypto-bot-final | The 33-class catalog reaches well beyond crypto scope (crack/spark spreads, gold-silver ratio) — flagged as exceeding current instrument scope |
| SP-072 | Statistical arbitrage / pairs — named but never implemented in nse-botonly | strategy | UNRESOLVED | — | `docs/ideas/main_ai_brain_all_strategies.md` §3a; `docs/REDESIGN_feature_atlas_v1.md` §4 | crypto-bot-and-nse-botonly (nse-botonly row) | Cointegrated-pair mean-reversion named in nse-botonly's own strategy taxonomy but no implementing module found anywhere in its `strategy_engine/` or `paper_trading/` — a real gap even in the most complete prior repo |
| SP-073 | Variance risk premium harvest (options) | strategy | PLANNED | P3 | `FEATURES.md` §4; `ARCHITECTURE.md` §3b | research-corpus, crypto-bot-and-nse-botonly | Latency-immune and durable — the strongest options family for this profile |
| SP-074 | Delta-neutral vol / gamma scalping (options) | strategy | PLANNED | P3 | `FEATURES.md` §4 | research-corpus, crypto-bot-and-nse-botonly | |
| SP-075 | Volatility-surface trading — working prior-art | strategy | PRIOR-ART | — | `strategies/volatility_surface.py:1-205` | early-repos-strategy-execution, early-repos | Deribit IV vs. realized-vol divergence, BTC/ETH only. Distinct-mechanism exception item (volatility surface) — kept as its own row rather than folded silently into SP-073/074 since it is a specifically-implemented divergence strategy, not the more general VRP/gamma-scalping framing; a documented bug was noted in the source but not detailed by the mining pass |
| SP-076 | Covered calls / cash-secured puts (options) | strategy | PLANNED | P3 | `FEATURES.md` §4 | research-corpus, crypto-bot-and-nse-botonly | Simplest entry, caps upside |
| SP-077 | Skew and calendar/diagonal option spreads | strategy | PLANNED | P3 | `FEATURES.md` §4 | research-corpus, crypto-bot-and-nse-botonly | |
| SP-078 | Advanced options Greeks-flow strategies — working prior-art, exceeds current plan (27-template catalog) | strategy | PRIOR-ART | — | `trading/strategy/library/catalog/options.py` | nse-crypto-bot-final | Dealer gamma-exposure/vanna/charm flow, dispersion trading, vol cone, ML delta-gamma hedging — none of these are named in `FEATURES.md` §5b's options layer, flagged as scope beyond current plan rather than silently merged |
| SP-079 | Instrument sequencing: spot+perps first, dated futures next, options as Phase 6 | strategy | PLANNED | — | `ARCHITECTURE.md` §3b; goal doc §5 instrument-segment table | research-corpus, crypto-bot-and-nse-botonly | |
| SP-080 | Options Greeks / IV-surface / independent vol-forecast requirement for options agents | strategy | PLANNED | — | `DECISIONS.md` §9; `dual-agent-spec.md` §3 | crypto-bot-and-nse-botonly, notes-and-media | A call is not "long" — it is +delta +vega −theta; strike/expiry selection modelled as its own decision |
| SP-081 | Market making / passive liquidity | strategy | DECLINED | — | `FEATURES.md` §4; `ARCHITECTURE.md` §0; `crypto-exchange-fees-maker-economics.md` | research-corpus, crypto-bot-and-nse-botonly, notes-and-media (x2 verdict rows) | No reachable rebate tier at this size, 10–20× queue disadvantage |
| SP-082 | Market-making strategy family — working prior-art, not to be ported (11 named classes) | strategy | DECLINED | — | `trading/strategy/library/catalog/market_making.py` | nse-crypto-bot-final | Avellaneda-Stoikov, Guéant-Lehalle-Fernandez-Tapia, delta-neutral option/perp MM, RL market-making — real, working code that the current plan explicitly excludes |
| SP-083 | Latency arbitrage | strategy | DECLINED | — | `FEATURES.md` §4; `crypto-latency-cloud-vs-colo.md` §4 | research-corpus, crypto-bot-and-nse-botonly, notes-and-media (x2) | 5–10µs races vs. an ~8ms cloud floor — categorically closed |
| SP-084 | High-frequency / microstructure strategy family — working prior-art, not to be ported (11 classes) | strategy | DECLINED | — | `trading/strategy/library/catalog/high_frequency.py` | nse-crypto-bot-final | Queue-position arb, quote-stuffing detection, DeepLOB/Deep-OFI neural microstructure models — corroborates the closed-segment finding with a concrete, working, explicitly-excluded implementation |
| SP-085 | Triangular arbitrage | strategy | DECLINED | — | `FEATURES.md` §4; `DECISIONS.md` §3 | research-corpus, crypto-bot-and-nse-botonly | Found never profitable after fees in a 2024 Binance study |
| SP-086 | WorldQuant "101 Formulaic Alphas" reuse | strategy | DECLINED | — | `ARCHITECTURE.md` §5; `alpha-discovery-gp-symbolic-regression.md` | research-corpus (x2 collapsed), crypto-bot-and-nse-botonly, notes-and-media | Hand-curated (not GP-discovered), gross of costs, public since 2015-16, assumed crowded/decayed; ~65% of published anomalies fail to replicate (Hou/Xue/Zhang 2020) |
| SP-087 | Sub-second brain (frequency band 3) | strategy | PLANNED | — | `DECISIONS.md` §3 | research-corpus, crypto-bot-and-nse-botonly | Decision stands as a measured, empirically-pruned branch, not an asserted opinion; goal doc §8 confirms it is still built even though the allocator is expected to starve it |
| SP-088 | RL bounded to execution scheduling only, not alpha generation | strategy | PLANNED | — | `DECISIONS.md` §8 | crypto-bot-and-nse-botonly | "RL: real for execution (order slicing, dense reward), shaky for alpha" |
| SP-089 | End-to-end RL for strategy generation | strategy | DECLINED | — | `IDEAS-ADVANCED.md` §5; `finml-subsecond-and-dontbuild.md` B3 | crypto-bot-and-nse-botonly, notes-and-media | Single-trader has zero market impact, breaking the RL premise; documented reward hacking. Prior-art RL-trading code (PPO/DQN/SAC/TD3/A2C/DDPG, `trading/strategy/library/catalog/machine_learning.py`) exists regardless in nse-crypto-bot-final — real, working, explicitly not the path chosen here |
| SP-090 | LLM as direct trading decider | strategy | DECLINED | — | `IDEAS-ADVANCED.md` §8; `ARCHITECTURE.md` §6 | crypto-bot-and-nse-botonly | Alpha Arena: four of six frontier LLMs lost 30–63% in 17 days, autonomous, on-chain verifiable |

## Strategy — game theory and search-discipline framing

All PLANNED, all sourced from `IDEAS-STRATEGIC.md`/`IDEAS-ADVANCED.md`/`IDEAS-INTELLIGENCE.md` via research-corpus.md (also independently mined in crypto-bot-and-nse-botonly's mirror pass — collapsed together).

| # | Requirement | Category | Status | Phase | Evidence / satisfying module | Sources | Notes |
|---|---|---|---|---|---|---|---|
| SP-091 | Explicit "do not compete here" exclusion list, written before strategy search | strategy | PLANNED | — | `IDEAS-STRATEGIC.md` §2 | research-corpus, crypto-bot-and-nse-botonly | Latency-sensitive MM, speed-edge, colocation-dependent, licensed-data-dependent strategies excluded first |
| SP-092 | Advantage-first strategy generation | strategy | PLANNED | — | `IDEAS-STRATEGIC.md` §2 | research-corpus, crypto-bot-and-nse-botonly | Start from the advantage, not generate-then-filter |
| SP-093 | Operational-annoyance premium screening lens | strategy | PLANNED | — | `IDEAS-STRATEGIC.md` §2 | research-corpus, crypto-bot-and-nse-botonly | Edges persist when irritating: obscure venues, manual onboarding, awkward settlement |
| SP-094 | Trade-rate-implied fee bill as a pre-screen filter | strategy | PLANNED | — | `IDEAS-STRATEGIC.md` §2 | research-corpus | Any strategy quoting trades-per-second is really quoting a fee bill |
| SP-095 | Auction theory (matching engine as auction) | strategy | PLANNED | — | `IDEAS-ADVANCED.md` §19 | research-corpus | Price-time priority, pro-rata matching, batch auctions |
| SP-096 | Adverse selection / signalling | strategy | PLANNED | — | `IDEAS-ADVANCED.md` §19 | research-corpus | The formal frame for why passive strategies bleed |
| SP-097 | Stackelberg (leader-follower) game theory | strategy | PLANNED | — | `IDEAS-ADVANCED.md` §19 | research-corpus | Execution against a reactive opponent |
| SP-098 | Mechanism design | strategy | PLANNED | — | `IDEAS-ADVANCED.md` §19 | research-corpus | Why venues choose their fee/matching rules; predicts rule changes |
| SP-099 | Evolutionary game theory | strategy | PLANNED | — | `IDEAS-ADVANCED.md` §19 | research-corpus | Strategy populations competing; explains crowding qualitatively |
| SP-100 | Forced-flow calendar | strategy | PLANNED | — | `IDEAS-INTELLIGENCE.md` §6 | research-corpus, crypto-bot-and-nse-botonly | Predictable non-discretionary flow (settlement, expiry, rebalance, unlock, funding intervals) is the most durable edge class |
| SP-101 | "Who loses when I win, and why do they accept that?" required declaration | strategy | PLANNED | — | `IDEAS-INTELLIGENCE.md` §6; `DESIGN-NOTE-universe-wide-scanning.md` §1 | research-corpus | Mandatory alongside Mechanism Declaration |
| SP-102 | Model other participants as agents, not noise | strategy | PLANNED | — | `IDEAS-INTELLIGENCE.md` §6 | research-corpus | Explicit participant taxonomy; powerful and easy to overfit |
| SP-103 | Natural-experiment mining | strategy | PLANNED | — | `IDEAS-INTELLIGENCE.md` §8 | research-corpus | Exogenous shocks (outages, halts, listings) as causal-identification instruments already in the history |
| SP-104 | Alpha as an ecological niche; competitive exclusion | strategy | PLANNED | — | `IDEAS-SYNTHESIS.md` Part III | research-corpus, crypto-bot-and-nse-botonly | Two strategies exploiting the identical inefficiency cannot coexist indefinitely |
| SP-105 | Niche-invasion forecasting | strategy | PLANNED | — | `IDEAS-SYNTHESIS.md` Part III | research-corpus | Predict which corners get competed away next |
| SP-106 | Prefer convex payoff profiles to disorder | strategy | PLANNED | — | `IDEAS-STRATEGIC.md` §8 | research-corpus, crypto-bot-and-nse-botonly | Long optionality, long gamma, stress-paying liquidity provision |
| SP-107 | Optimal harvest rate (deliberately trade below capacity) | strategy | PLANNED | — | `IDEAS-FRONTIER.md` §2 | crypto-bot-and-nse-botonly | Trading an edge at max size accelerates its death |
| SP-108 | Endogenous decay model (footprint-dependent edge half-life) | strategy | PLANNED | — | `IDEAS-FRONTIER.md` §2 | crypto-bot-and-nse-botonly | Models edge half-life as a function of own deployed capital/visibility |
| SP-109 | Abstention / reject option | strategy | PLANNED | — | `IDEAS-ADVANCED.md` §1; `IDEAS-INTELLIGENCE.md` §2 | crypto-bot-and-nse-botonly | Model permitted to say "don't trade" |
| SP-110 | Three-brain tree structure by frequency band | strategy | PLANNED | — | `DECISIONS.md` §1-2; `ARCHITECTURE.md` §0 | research-corpus | Hours-to-minutes, minutes-to-seconds, sub-second, each with its own BULL/BEAR/PROFIT-TAIL triad; frequency reorganised as a property within family, not the primary axis |

## Universe-wide scanning — ⚠ flagged watch item

**Status as measured 2026-08-08 (goal doc §5a.7, §10.3):** the design is fully specified and rated
8/10 conditional (`DESIGN-NOTE-universe-wide-scanning.md`). **The mechanism is unbuilt and the
capture-side prerequisite is unwired**: `tail_specs()` exists and is tested on both `BinanceVenue`
and `HyperliquidVenue`, but `capture/cli.py:169` calls `core_specs()` unconditionally with no
`--tail-symbols` argument, so capture runs **6 symbols** (`BTCUSDT`/`ETHUSDT`/`SOLUSDT` +
`BTC`/`ETH`/`SOL`) against **~1,290 reachable symbols** across venues. The breadth test that gates
the whole architecture (§5a.4) cannot run on 6 symbols.

| # | Requirement | Category | Status | Phase | Evidence / satisfying module | Sources | Notes |
|---|---|---|---|---|---|---|---|
| SP-111 | Universe-wide always-on scanning with per-symbol tradability gate | strategy | PLANNED | — | `DESIGN-NOTE-universe-wide-scanning.md`; goal doc §5a | research-corpus, crypto-bot-and-nse-botonly | ⚠ Watch item 1. Unit of edge is `(symbol, condition, moment)`, not `(symbol)` or `(strategy)`. This is a property of the whole system, not a strategy family — it sits underneath every family above |
| SP-112 | Universal, parameter-free setup definitions with own-history normalisation | strategy | PLANNED | — | `DESIGN-NOTE-universe-wide-scanning.md` §3 | research-corpus, crypto-bot-and-nse-botonly | Per-symbol variation only from z-scores/percentiles against own history — never fitted per-symbol parameters. Called "the single most dangerous thing that could be implemented" if violated |
| SP-113 | Acceptance threshold that rises with opportunity flow (optimal stopping) | strategy | PLANNED | — | `DESIGN-NOTE-universe-wide-scanning.md` §4 | research-corpus, crypto-bot-and-nse-botonly | Dry powder has computable option value; the more symbols watched, the pickier each trade must be |
| SP-114 | Corroboration across independent data types for setup triggers | strategy | PLANNED | — | `DESIGN-NOTE-universe-wide-scanning.md` §5 | research-corpus, crypto-bot-and-nse-botonly | Trade flow AND funding AND open interest, not one signal alone — anti-manipulation defence against a thin-book bait attack |
| SP-115 | Persistence requirements on setup triggers | strategy | PLANNED | — | `DESIGN-NOTE-universe-wide-scanning.md` §5 | research-corpus, crypto-bot-and-nse-botonly | Conditions must hold for a duration, not fire instantaneously |
| SP-116 | Minimum viable setup size gate | strategy | PLANNED | — | `DESIGN-NOTE-universe-wide-scanning.md` §6 | research-corpus | Expected profit must exceed all-in cost; the tail has least competition *and* least capacity |
| SP-117 | SymbolScanner — working prior-art (500+ symbol composite scorer) | strategy | PRIOR-ART | — | `trading/scanner.py:1-611` | early-repos-strategy-execution | ⚠ Directly matches the goal-doc ambition. Scores 500+ futures symbols on a 13-component weighted composite (trend/vol/volume/momentum/regime/VPIN/cascade/entropy/Lévy/pattern/bandit), sector-balanced top-N across 12 sectors to avoid BTC-correlated clustering, auto-blacklist at WR<25%/auto-unblacklist at WR≥60%. **Nothing like this exists in the current project.** A ticker-prefilter companion (`_prefilter_by_ticker()`, cuts 560+ symbols to ~150 by volume/price-move ranking with no extra API calls) exists in the same file under Category=execution — outside this slice, noted here since it directly relates |
| SP-118 | Symbol Scanner — earlier/simpler prior-art variant (215+ symbols, bulk-ticker) | strategy | PRIOR-ART | — | `trading/scanner.py` | early-repos | 1-call bulk-ticker API vs. 558 individual calls, 120s interval. Same underlying file lineage as SP-117 under a different categorization pass (there tagged market-data, outside this slice's category filter, corroborating rather than a new capability) |
| SP-119 | Broker-sense breadth funnel (6-stage screen→heat→look→verify→decide→clean cascade) | strategy | PRIOR-ART | — | `trading/broker_sense/funnel.py:150,190` (`BrokerSenseFunnel.run_cycle`) | nse-crypto-bot-final | ⚠ Directly matches goal-doc §5a.5's required "two-stage funnel: cheap coarse screen across the whole universe, expensive evaluation only on candidates" — a working precedent for exactly the mechanism the breadth gate needs |
| SP-120 | Binance filter-lane top-N breadth ranker | strategy | PRIOR-ART | — | `trading/broker_sense/binance_filter_lane.py:215,278`; `trading/crypto/freqtrade/brain_executor.py:529-620` (`open_filter_lane`) | nse-crypto-bot-final | Ranks the whole UI-captured market by named filter presets (momentum, squeeze, funding-extreme, liquidity) to restore trade breadth beyond a per-symbol funnel |
| SP-121 | Cross-sectional GP asset-picker (rank-IC validated) | strategy | PRIOR-ART | — | `trading/brain/picking.py:68,92` (`GPLearnFactorMiner`, `AssetPicker`) | nse-crypto-bot-final | Ranks a universe of symbols by a symbolic-regression-learned factor, validated via rank Information Coefficient |
| SP-122 | Per-segment ranked screener with offline-safe fallback | strategy | PRIOR-ART | — | `trading/screener/screener.py:396-527` | nse-crypto-bot-final | Ranked-candidate generator per NSE/CRYPTO segment, deduped watchlist union |
| SP-123 | Full-universe opportunity radar (nse-botonly BACKLOG B43, QUEUED) | strategy | UNRESOLVED | — | `docs/ideas/full_universe_opportunity_radar.md` (BACKLOG B43) | crypto-bot-and-nse-botonly (nse-botonly row) | ⚠ A streaming full-universe (cash+options) scanner firing on setup conditions, gated by net-EV/FDR/throughput/selection walls, surfacing candidates rather than auto-trading — this is a concrete design proposal for the breadth-scanning mechanism itself, but it was never built even in nse-botonly, the most complete prior repo. It is queued, not prior-art |

## Three-bot architecture, arbiter, and the missing top-level router — ⚠⚠ flagged watch item

**This is the same hole twice.** `nse-botonly`'s own `BACKLOG B42` (`docs/ideas/main_ai_brain_all_strategies.md`,
status QUEUED) records that its "main AI brain" — a top-level strategy-of-strategies allocator — was
never built, in the most complete and best-tested prior repo in the account. The current project's
plan calls for the same kind of thing (an "arbiter" that "selects trades," `DECISIONS.md` §1/§11) but
**no arbiter, router, or strategy-selection code of any kind exists in `trading-system/src/`** — not
even a stub. There is no `strategy/`, `portfolio/`, or `arbiter/` directory in the tree. The only
working precedents for "combine many strategies/signals into one decision" are in prior repos
(SP-133, SP-134 below), and the specific "regime-weighted router blending several engines" design
was never built anywhere, including in the repo that specified it.

| # | Requirement | Category | Status | Phase | Evidence / satisfying module | Sources | Notes |
|---|---|---|---|---|---|---|---|
| SP-124 | BULL bot — long/call side only, calibrated P(up) + conviction | strategy | PLANNED | P1 | `FEATURES.md` §3b; `DECISIONS.md` §9-10; `bull-bear-profit-agents-spec.md` §1 | research-corpus (tree row), crypto-bot-and-nse-botonly, notes-and-media | Independent bot, not a model head; proposes only, cannot decide |
| SP-125 | BEAR bot — short/put side only | strategy | PLANNED | P1 | Same as SP-124 | crypto-bot-and-nse-botonly, notes-and-media | Short-side position limits stricter than long — a squeeze has no ceiling |
| SP-126 | PROFIT-TAIL bot — entry timing + position management after fill | strategy | PLANNED | P2 | `FEATURES.md` §3b; `DECISIONS.md` §10-11 | notes-and-media | Cannot reject a selected trade, cannot refuse to close a loser; hard stop overrides it absolutely |
| SP-127 | Three-state LONG/SHORT/FLAT output space + contradiction-forces-FLAT rule | strategy | PLANNED | — | `dual-agent-spec.md` §2 | notes-and-media | Both agents firing high → FLAT is not confidence, it's self-contradiction; both low → FLAT is no edge |
| SP-128 | **Arbiter / meta-labeling trade-selection authority** | strategy | PLANNED | P2 | `DECISIONS.md` §1,§9,§11; `dual-agent-spec.md` §2 | crypto-bot-and-nse-botonly | ⚠ "The arbiter selects trades" is decided in principle (`DECISIONS.md` §11) but has **zero implementation, zero detailed design beyond meta-labeling in the abstract**, and zero code anywhere in the current project. This is the abstract commitment; SP-129 below is the concrete unbuilt design for the same gap |
| SP-129 | **Regime-weighted "main AI brain" top-level strategy router — the concrete unbuilt design** | strategy | UNRESOLVED | — | `docs/ideas/main_ai_brain_all_strategies.md` (nse-botonly `BACKLOG B42`, status QUEUED) | crypto-bot-and-nse-botonly (nse-botonly row) | ⚠⚠ **The flagged gap.** A soft-weighting regime router blending 4 per-regime engines (bull-trend, bear-trend, volatile, flat) via a non-stationary bandit, behind a hard validation gate — nse-botonly's own docs say this "does not yet exist." It still doesn't, anywhere, in any repo mined. The current project's abstract arbiter commitment (SP-128) has not been elaborated to this level of design either. Building this is a prerequisite for `goal.md` §2's "nine bots think, three arbiters select" and §8's definition of done |
| SP-130 | Multi-agent debate upgrade (bull vs. bear critique before the arbiter decides) | strategy | PLANNED-idea | — | `IDEAS-ADVANCED.md` §8 | crypto-bot-and-nse-botonly | Upgrades the BULL/BEAR split to argue before the arbiter, rather than voting independently |
| SP-131 | StrategySelector — working prior-art (60+ strategy weighted-vote aggregator) | strategy | PRIOR-ART | — | `strategies/selector.py:109-1329`; `strategies/base_strategy.py:12-88` (`BaseStrategy`/`TradeSignal` abstract base) | early-repos-strategy-execution, early-repos | ⚠ The closest working precedent for a top-level combiner: instantiates 60+ strategies, runs applicable ones per regime, aggregates weighted votes (DB win-rate + Granger-causal validity multiplier), with an Order-Flow Override, a Conviction Trade Gate, and 10+ external signal injections (on-chain, options/GEX, cross-exchange OB, tick CVD, pairs, funding-arb, symbolic regression, orderbook depth, exchange flow, Hawkes — each wrapped in try/except so a missing module silently no-ops). This is a *strategy-voting* aggregator, not a *regime-router-of-brains* — a materially simpler mechanism than SP-129, but real, working, and instructive |
| SP-132 | Debate Council — working prior-art (3-agent heuristic arbiter) | strategy | PRIOR-ART | — | `meta_ai/debate_council.py` | early-repos-metaai-civilization | Advocate/Bear heuristic scoring + reputation-weighted Arbiter decision (APPROVE / APPROVE_SIZED / APPROVE_DEFER / REJECT); pure heuristic, no LLM call despite the "Agent" naming. Per-(strategy, regime, hour-bucket) reputation persists after close. The nearest working precedent for an *arbiter*, as opposed to a strategy-voting selector |
| SP-133 | Per-coin best-strategy tournament / library-ensemble majority-vote decider | strategy | PRIOR-ART | — | `trading/crypto/freqtrade/percoin_decider.py:1-20`; `trading/crypto/freqtrade/library_decider.py:1-12` | nse-crypto-bot-final | Vectorized-backtests every executable strategy per coin, re-weights by learned confidence, picks the single best strategy above threshold or stays FLAT — no ensemble fallback. A third, independent working precedent for strategy-combination, distinct in design from SP-131/132 |

## Strategy generation / evolution infrastructure

Not named anywhere in the current project's strategy/portfolio plan rows (the goal doc's "research
loop" describes the *governance* around this — hypothesis → code → sealed evaluation — but not this
specific machinery). All PRIOR-ART, all substantial, all unbuilt in the current project.

| # | Requirement | Category | Status | Phase | Evidence / satisfying module | Sources | Notes |
|---|---|---|---|---|---|---|---|
| SP-134 | Symbolic-regression / GP alpha-discovery generator suite (6 generators, one shared admission gate) | strategy | PRIOR-ART | — | `trading/strategy/generators/{symbolic,alpha_mining,llm_mutation,rd_agent,optuna_tune}.py`; `trading/strategy/genome.py`, `evolve.py`, `operators.py`; `start_all.sh:65-79` (env-gated kill switches per generator) | nse-crypto-bot-final | gplearn, PySR, Operon, SINDy, DEAP-GP+NSGA-II, formulaic-alpha/AlphaGen mining, LLM-as-mutation-operator, RD-Agent(Q) researcher, Optuna NSGA-II tuner — all scored through one CPCV+DSR+PBO+family-wise-error gate. Caution: a research note (notes-and-media, `alpha-discovery-gp-symbolic-regression.md`) finds "no audited, live, real-capital evidence that GP/symbolic-regression search produces durable edge" — the code is real and mature, the edge claim is unverified either way |
| SP-135 | StrategyFoundry (per-segment seed catalog + online discovery + promotion ledger) | strategy | PRIOR-ART | — | `trading/strategy/foundry.py:1-489` | nse-crypto-bot-final | `FoundrySpec` catalog across 8 segments, `research_segment()` online discovery, `leaderboard()`/`promote()` keeping top-K per segment behind a deflation gate |
| SP-136 | SkillLibrary / lifelong self-evolving controller (Voyager-style admit/retire loop) | strategy | PRIOR-ART | — | `trading/brain/skills.py:42`; `trading/strategy/self_evolve.py:1-19` | nse-crypto-bot-final | Admits guardrail-passed survivors; `reevaluate()` re-scores admitted skills on fresh data and retires ones that no longer hold up |
| SP-137 | Evolved-strategy → live-decider wiring (registry promotion, brain-pipeline attach) | strategy | PRIOR-ART | — | `trading/strategy/registry.py:1-14`; `trading/strategy/evolved_link.py:1-19` | nse-crypto-bot-final | ⚠ Cautionary parallel: this exact wiring (`attach_to_pipeline()`) was found to have previously left the brain pipeline's `evolved_strategy` field "declared but never set" — a silent no-op bug later fixed. A direct structural analogue to the current project's own uncalled `tail_specs()` and absent router (SP-111, SP-129) |
| SP-138 | Second, independently-built genetic-evolution engine (meta_ai/civilization lineage) | strategy | PRIOR-ART | — | `meta_ai/genetic_evolution.py`, `evolved_strategy.py`; `ai_civilization/evolution/{mutation_engine,crossbreeder,expression_tree,strategy_adapter}.py`; `meta_ai/llm_analyst.py` (`generate_strategy_code`) | early-repos-metaai-civilization, early-repos | Kept deliberately distinct from SP-134 — a second, independently-built GA/GP lineage (Gene/individual dataclasses, single-point crossover + elitism, NSGA-II Pareto ranking on Sharpe/win-rate/max-DD, hall-of-fame bridge into the live selector) in a different repo, not a duplicate. Notably includes a real (non-simulated) LLM call that writes a `BaseStrategy` subclass, gated by syntax-check + dangerous-import blocklist + sandboxed dry-run before being seeded into evolution |
| SP-139 | SOTA gap assessment for strategy-generation engines | strategy | DOCUMENTED-ONLY | — | `research/strategy-generation-sota-2026.md`; `research/t8-strategy-evolution-oss.md` | nse-crypto-bot-final | Finds the fixed-genome DEAP evolution (SP-134) is not frontier; recommends AlphaGen/AlphaForge, OpenEvolve LLM-mutation, and a pyribs quality-diversity archive — a research note pointing past the prior repo's own implementation, worth reading before rebuilding this from scratch |
| SP-140 | Qlib NSE alpha-research substrate | strategy | UNRESOLVED, blocked | — | `t8-stitch-blueprint.md` §2,§7 | nse-crypto-bot-final | Planned Alpha158/360 factor library + CPU GBDT ranker — blocked in the source repo itself: "Qlib has no py3.13 wheel." A cautionary dependency-availability lesson if this project ever considers Qlib |

## Per-trade paper-only exploration and online-learning feedback

| # | Requirement | Category | Status | Phase | Evidence / satisfying module | Sources | Notes |
|---|---|---|---|---|---|---|---|
| SP-141 | Exploration-slot trading system (20 named experimental ideas) | strategy | PRIOR-ART | — | `trading/experimental_strategies.py:1-1294` (`ExperimentalStrategyEngine`, 20 real detector functions); `paper_trader.py:1942-2159,1977-2046` | early-repos-strategy-execution | Paper-only. Named ideas include PANIC_BOTTOM_BOUNCE, CROSS_SECTIONAL_MOMENTUM, ANTI_SIGNAL, CARRY_EXPERIMENT, CASCADE_RIDE_SHORT, MICRO_SPIKE_SCALP, session-open breakout, Wyckoff spring, BTC/ETH stat-arb, uncertainty explorer, regime-gap explorer, recovery arc, dreamer-guided; Thompson-samples among simultaneous candidates. IdeaIntelligence capital multiplier scales proven-winning ideas up to 50% of initial capital cap |
| SP-142 | Per-trade online-learning feedback bundle | strategy | PRIOR-ART | — | `paper_trader.py`/`live_trader.py`, ~15 cited line ranges: Online Direction Learner, Entry Timing Calibrator, Concept-drift monitor, Dreamer-v3 world-model recording, MFE Capture Learner, counterfactual/causal ("what if exit was N bars earlier") analysis, MAML fast-regime-adaptation feed, Peak-Drawdown-Advisor + Trade-DNA retrain triggers, ensemble outcome feedback, isotonic confidence calibration | early-repos-strategy-execution | Grouped — ~15 closely related feedback mechanisms recorded after every trade close, feeding various online learners. Most run in both paper and live; a few are paper-only or noted inert-in-live |
| SP-143 | Bounce-Back recovery trades | strategy | PRIOR-ART | — | `ml/models/bounce_back.py`; `paper_trader.py:2318-2440`; `live_trader.py:1287-1341` | early-repos-strategy-execution, early-repos | Same-direction recovery trade on decelerating adverse momentum + support (TDA/Hawkes) + recovery-probability threshold; bypasses the same-symbol pyramid cap and even the max-concurrent cap in paper |

## NSE-specific feature-donor machinery

Per goal doc §5, NSE is **explicitly out of scope as a market** ("Zero NSE... a feature donor, never a
target market"). These rows are the machinery worth adapting, not the market itself.

| # | Requirement | Category | Status | Phase | Evidence / satisfying module | Sources | Notes |
|---|---|---|---|---|---|---|---|
| SP-144 | NSE options strategy engine (ADX regime gate, ORB signal, credit-spread leg selector + moneyness classifier, 0-DTE regime router + structure builder + entry planner) | strategy | PRIOR-ART | — | `strategy_engine/session_strategy_regime_gate.py`, `opening_range_breakout_strategy.py`, `credit_spread_leg_selector.py`, `option_moneyness_classifier.py`, `zero_dte_regime_router.py`, `zero_dte_option_structures.py`, `zero_dte_entry_planner.py` | crypto-bot-and-nse-botonly (nse-botonly rows) | Feature-donor: the regime-routing and defined-risk-structure machinery generalizes past NSE options |
| SP-145 | T4 options intelligence (per-strike Black-76 Greeks, Max Pain, PCR, GEX zero-gamma-flip + walls, OI heatmap, IV Rank/Percentile, multi-leg payoff) | strategy | PRIOR-ART | — | `run_options_t4.py`; `trading/options/{chain,greeks,iv}.py` | nse-crypto-bot-final | Directly relevant to `FEATURES.md` §5b's required Phase-6 Greeks-based options risk gate — real, working precedent for that exact machinery |
| SP-146 | Cross-exchange spot arbitrage scanner | strategy | PRIOR-ART | — | `trading/advintel/arbitrage.py:107-153` | nse-crypto-bot-final | Fee/slippage-aware buy-cheapest/sell-richest spread scan, only flagged actionable when it clears round-trip cost |
| SP-147 | Prediction-market screener (Polymarket) | strategy | PRIOR-ART | — | `trading/screener/prediction.py:25-101` | nse-crypto-bot-final | Gamma-API scan, edge = distance from coin-flip, paper-only. Likely out of scope per goal doc §5 (crypto spot/perp/options only) — flagged rather than silently dropped |

## Standalone mechanisms (exception clause — not folded into a family row)

| # | Requirement | Category | Status | Phase | Evidence / satisfying module | Sources | Notes |
|---|---|---|---|---|---|---|---|
| SP-148 | ICT Smart Money Concepts strategy | strategy | PRIOR-ART | — | `strategies/ict_smart_money.py:1-716` | early-repos-strategy-execution, early-repos | Order Blocks, FVG, BOS/ChoCH, Liquidity Pools, Premium/Discount — 5-concept confluence-scored SMC strategy. No analog anywhere in the current plan; a genuinely distinct technical-analysis mechanism |
| SP-149 | VPIN-informed flow and "funding clock" as dedicated strategy mechanisms | strategy | UNRESOLVED — not found as standalone | — | Embedded only, inside SP-117's SymbolScanner composite (VPIN is 1 of 13 components) and SP-131's StrategySelector signal injections (exchange flow, one of 10+) | early-repos-strategy-execution | Both are named in the exception list this ledger was asked to watch for specifically. Neither appears as its own strategy class anywhere in this 395-row slice — VPIN and exchange-flow surface only as sub-components of composite scores, and "funding clock" (funding-hour timing) does not appear as a strategy-category row at all in any of the seven raw files (it lives in `FEATURES.md` §2 feature-engineering, outside this slice's category filter). Recorded honestly as not found rather than fabricated |

---

## Slice summary

**Coverage caveat, stated plainly:** this merge was built from the seven pre-mined raw files, not
from re-reading the prior repos directly. Several source rows in `early-repos.md` and
`nse-crypto-bot-final.md` are themselves marked "DOCUMENTED (per changelog, not independently read
this pass)" or "file exists, content not read" by the mining pass that produced them — those
uncertainties are carried into this ledger's Notes rather than resolved. `docs/BACKLOG.md` (2,653
lines) and `docs/PLAN.md` (955 lines) in nse-botonly were only header-skimmed by the original mining
pass, and `docs/research/` there (207 files) was ~20-file sampled — genuinely new strategy/portfolio
content may exist in the unsampled remainder and is not reflected here.

### Counts by status

| Status | Count |
|---|---|
| PLANNED | 76 |
| PRIOR-ART | 56 |
| DECLINED | 10 |
| UNRESOLVED | 7 |
| CLAIMED | 0 |

(149 rows total. A handful of PLANNED rows carry "-partial", "-idea", or "-deprioritized" qualifiers
in their Status cell where the evidence was more nuanced than a clean binary — counted under PLANNED
above.)

### The five most important UNRESOLVED rows

1. **SP-129 — the regime-weighted "main AI brain" top-level strategy router.** The single most
   important gap in this entire slice. Named, designed in outline, and abandoned unbuilt in the best
   prior repo (`BACKLOG B42`); not built, and not even designed to this level of detail, in the
   current project. Everything downstream of "nine bots think, three arbiters select" (goal doc §2)
   depends on this existing.
2. **SP-123 — full-universe opportunity radar (`BACKLOG B43`).** The concrete design for the breadth
   scanner's coarse-screen stage was written and queued, never built. Without it, SP-111 (universe-wide
   scanning) has a plan but no design for its cheapest, highest-leverage component.
3. **SP-072 — pairs/stat-arb named but never implemented in nse-botonly.** Even the most complete
   prior repo left a named strategy family entirely unimplemented — worth knowing before assuming
   nse-botonly is a complete feature donor for this family.
4. **SP-140 — Qlib NSE alpha-research substrate, blocked on a missing Python 3.13 wheel.** A concrete,
   named dependency trap worth checking before this project reaches for Qlib.
5. **SP-149 — VPIN and "funding clock" as standalone mechanisms.** Explicitly asked for by name in
   this task's brief; genuinely not present as dedicated strategy-category capabilities anywhere in
   this slice. Recorded as not-found rather than invented.

### The five most important PRIOR-ART rows — working code that would otherwise be lost

1. **SP-117 — SymbolScanner, 500+ symbol composite scorer.** The single closest working precedent to
   the goal doc's universe-wide scanning ambition (§5a), and nothing like it exists in the current
   project.
2. **SP-131/SP-132/SP-133 — three independent working precedents for combining many strategies into
   one decision** (StrategySelector's weighted vote, Debate Council's heuristic arbiter, the per-coin
   tournament decider). None is the regime-router design the goal doc actually needs (SP-129), but
   all three are real, tested, and directly instructive for building it.
3. **SP-134/SP-138 — two independently-built strategy-evolution engines** (DEAP/gplearn/PySR/Operon/
   SINDy/RD-Agent suite, and a separate meta_ai/civilization GA lineage with a real gated LLM
   code-generation call). Neither is named anywhere in the current plan; both are mature and tested.
4. **SP-050 — NSE capital-allocation optimizer**, a real CVXPY-solved convex risk-budget engine with
   cardinality/turnover constraints and solver fallback — directly satisfies much of SP-020's still-
   unbuilt PLANNED requirement.
5. **SP-119/SP-120 — broker-sense breadth funnel and filter-lane ranker.** Working precedents for
   exactly the "cheap coarse screen, expensive evaluation only on candidates" two-stage funnel the
   goal doc's universe-wide scanning gate requires (§5a.5) — the piece of infrastructure that makes
   watching ~1,290 symbols computationally survivable.

### Universe-wide scanning — what exists, where, and what does not

- **Designed:** `research/DESIGN-NOTE-universe-wide-scanning.md` (8/10 conditional verdict) and goal
  doc §5a — fully specified, including the breadth-test gate, anti-manipulation defences, and the
  rule that setup definitions must be parameter-free across symbols.
- **Not built anywhere, in any repo:** the current project has no scanner, no scorer, and no
  universe-wide strategy code of any kind in `src/`.
- **Capture-side prerequisite exists but is unwired:** `tail_specs()` is implemented and tested on
  both `BinanceVenue` and `HyperliquidVenue` (~10 passing tests), but `capture/cli.py:169` calls only
  `core_specs()` and exposes no `--tail-symbols` flag. **Capture is running 6 symbols today** against
  ~1,290 reachable across the two execution venues. This is a market-data-category finding
  (`crypto-bot-and-nse-botonly.md`'s "Tail-tier capture is unwired at the CLI entry point" row), just
  outside this slice's category filter — recorded here because the task asked for it by name.
- **Working prior-art exists and is not ported:** SP-117 (SymbolScanner, 500+ symbols, 13-component
  composite), SP-119 (broker-sense two-stage funnel), SP-120 (filter-lane breadth ranker), SP-121
  (GP-factor cross-sectional asset picker). All are real, tested code in prior repos, all absent from
  the current project.
- **The breadth test itself (§5a.4) cannot run** until the tail is wired and a wide universe is
  captured — it is blocked on infrastructure, not on strategy design.
