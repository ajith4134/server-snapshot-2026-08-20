# Mined: early repos — strategy, trading/execution, portfolio layers

Mined 2026-08-08. Source: `ajith-ai-crypto-trading-bot` (`strategies/`, `trading/`, `portfolio/`)
read in full, diffed against `crypto-linix-server-bot`, plus full read of the two linix-only files.

**Provenance note:** this inventory was produced by a mining agent that returned its findings as a
message rather than writing a file. Transcribed to disk by the orchestrating session to prevent
loss. Content unaltered.

**Coverage note:** `paper_trader.py` and `live_trader.py` were inventoried by a delegated subagent;
all other files read directly. `ai-advanced-crypto-bot-final`, `ai-crypto-trading-bot` and
`pattern-brain` are NOT covered here — see `early-repos.md` if it exists, otherwise they remain
unmined.

**Critical caveat carried from `prior-attempts-postmortem.md` §3.2–3.3:** IMPLEMENTED means code
with a real body exists. It does **not** mean validated, and it does not mean profitable. That
repo's documentation grew faster than its validated results, and its validation target was
substituted for synthetic Mackey-Glass data.

---

## Strategy layer

| Feature | What it does | Category | Evidence | State |
|---|---|---|---|---|
| BaseStrategy / TradeSignal | Abstract base all strategies inherit; regime filter + min-bar gate in `__call__`, helpers (`_last`, `_crosses_above`, `_atr_stop`) | strategy | strategies/base_strategy.py:12-88 | IMPLEMENTED |
| StrategySelector | Instantiates 60+ strategies, runs applicable ones per regime, aggregates weighted votes into one `AggregatedSignal` | strategy | strategies/selector.py:109-1329 | IMPLEMENTED |
| Civilization genome injection | Wraps top-trust-score evolved genomes as extra strategy voters alongside the 60+ built-ins | strategy | selector.py:245-306 | IMPLEMENTED |
| Performance-based dynamic weighting | Adjusts each strategy's vote weight from DB win-rate + Granger-causal validity multiplier | strategy | selector.py:310-354 | IMPLEMENTED |
| Order-Flow Override | When tick CVD and cross-exchange order-book imbalance both agree >0.6, zeroes opposing votes, locks direction, confidence floor 75% | strategy | selector.py:735-769 | IMPLEMENTED |
| Conviction Trade Gate | Extreme funding + OI velocity >0.5% + cascade >0.7 aligned locks direction, floors confidence at 85% | strategy | selector.py:1145-1186 | IMPLEMENTED |
| Liquidation Cascade Gate (CASCADE_RIDE_SHORT) | Blocks a LONG during an active downward cascade, substitutes a dedicated SHORT signal | strategy | selector.py:893-959 | IMPLEMENTED |
| Compound-penalty floor | Stops stacked confidence multipliers (entropy × world-model × regime × BTC-trend) crushing a signal below 75% of raw voting score | risk | selector.py:1119-1128 | IMPLEMENTED |
| 10+ external signal injections | On-chain, options/GEX, cross-exchange OB, tick CVD, pairs, funding-arb, symbolic regression, orderbook depth, exchange flow, Hawkes — each wrapped as extra long/short votes | strategy | selector.py:497-733 | IMPLEMENTED (each in try/except so a missing module silently no-ops) |
| StrategyCoroner | Auto-suspends strategies via Bayesian Beta-posterior on rolling win-rate; hard-suspend, watch-list (half size), star-performer (1.3× size), auto-reactivation | governance | strategies/strategy_coroner.py:1-354 | IMPLEMENTED |
| PairsTradingStrategy / CointegrationTester / KalmanHedgeRatio | Engle-Granger cointegration + Kalman-filtered dynamic hedge ratio + z-score entry/exit for 9 crypto pairs | strategy | strategies/pairs_trading.py:1-583 | IMPLEMENTED |
| FundingRateMonitor / FundingArbitrageStrategy | Tracks funding rates, fades over-leveraged side, pre-payment urgency confidence boost | strategy | strategies/funding_arbitrage.py:1-501 | IMPLEMENTED |
| ICTSmartMoneyStrategy | Order Blocks, FVG, BOS/ChoCH, Liquidity Pools, Premium/Discount — 5-concept confluence-scored SMC strategy | strategy | strategies/ict_smart_money.py:1-716 | IMPLEMENTED |
| VolatilitySurfaceStrategy | Deribit IV vs realized-vol divergence, BTC/ETH only | strategy | strategies/volatility_surface.py:1-205 | IMPLEMENTED (see bug below) |
| trend/ family (10 classes) | EMACross, TripleEMA, MACDTrend, Ichimoku, SuperTrend, ADXTrend, ParabolicSAR, DonchianBreakout, VWAPTrend, LinearRegressionTrend | strategy | strategies/trend/trend_strategies.py | IMPLEMENTED |
| mean_reversion/ family (8 classes) | RSIReversion, BollingerBandReversion, ZScoreReversion, VWAPReversion, KeltnerReversion, StochasticReversion, CCIReversion, WilliamsRReversion | strategy | strategies/mean_reversion/mean_reversion_strategies.py | IMPLEMENTED |
| momentum/ family (6 classes) | ROCMomentum, DualMomentum, MFIDivergence, OBVDivergence, CVDMomentum, VolumeSurge | strategy | strategies/momentum/momentum_strategies.py | IMPLEMENTED |
| breakout/ family (6 classes) | ATRVolatilityBreakout, RangeBreakout, BollingerSqueezeBreakout, SupportResistanceBreakout, VolumeBreakout, OpeningRangeBreakout | strategy | strategies/breakout/breakout_strategies.py | IMPLEMENTED |
| orderflow/ family (4 classes) | OrderBookImbalance, FundingRate, LongShortRatio, OpenInterestDivergence | strategy | strategies/orderflow/orderflow_strategies.py | IMPLEMENTED |
| pattern/ family (5 classes) | CandlestickPattern, ChartPattern, HarmonicPattern, ElliottWave, WyckoffPhase | strategy | strategies/pattern/pattern_strategies.py | IMPLEMENTED |
| statistical_arb/ family (4 classes) | KalmanTrend, WaveletTrend, FourierCycle, HurstExponent | strategy | strategies/statistical_arb/stat_arb_strategies.py | IMPLEMENTED |
| sentiment_based/ family (3 classes) | FearGreed, SentimentMomentum, OnChainSignal | strategy | strategies/sentiment_based/sentiment_strategies.py | IMPLEMENTED |
| `strategies/volume/` | Empty package, 0-byte `__init__.py`, not referenced in `CATEGORY_WEIGHTS`/`REGIME_STRATEGY_MAP` | strategy | strategies/volume/ | DOCUMENTED-ONLY |
| `strategies/ml_based/` (ajith repo) | Empty package; real content exists only in the linix fork | strategy | strategies/ml_based/ | DOCUMENTED-ONLY |

## Execution engines — `paper_trader.py` and `live_trader.py`

| Feature | What it does | Category | Evidence | State |
|---|---|---|---|---|
| PendingEntry limit-order simulation | Paper trades wait for a configurable pullback (default 0.15%) before filling, timing out after N bars | execution | paper_trader.py:50-72 | IMPLEMENTED |
| Market-order-style instant fill | Paper also opens a PendingEntry with limit==signal price to simulate instant market fills matching live | execution | paper_trader.py:2089-2124 | IMPLEMENTED |
| Live order placement | MARKET / STOP_MARKET / TAKE_PROFIT_MARKET entry, SL and TP via Binance REST | execution | live_trader.py:1059-1142 | IMPLEMENTED |
| Order cancellation on close | Cancels outstanding SL/TP before placing closing market order | execution | live_trader.py:1439-1445 | IMPLEMENTED |
| Dynamic slippage estimate | slippage% = notional / (daily_volume × liquidity_factor), clamped [0.01%, 0.5%] | execution | paper_trader.py:244-267 | IMPLEMENTED |
| Fixed live slippage | Flat configurable % on market fills | execution | live_trader.py:124,1079,1464 | IMPLEMENTED |
| 3-part fee model | Taker fee at entry and exit, plus 0.01%/8h funding accrual | execution | paper_trader.py:2526-2551; live_trader.py:1466-1483 | IMPLEMENTED |
| Position reconciliation at startup | Compares DB open trades vs actual Binance positions; adopts or closes mismatches | execution | live_trader.py:300-372 | IMPLEMENTED |
| Periodic "reconcile" loop | Runs every 5 min but only re-syncs capital — does NOT re-run position reconciliation | execution | live_trader.py:374-380 | IMPLEMENTED (narrower than its name implies) |
| Emergency close-all | Force-closes every open position at best available price | execution | paper_trader.py:637-685; live_trader.py:197-211 | IMPLEMENTED |
| Kill switch | Subscribes to KILL_SWITCH event-bus topic, force-closes all live positions | governance | live_trader.py:134,2086-2095 | IMPLEMENTED |
| Stale DB trade cleanup | On startup closes paper trades left open by a crashed session | execution | paper_trader.py:225-242 | IMPLEMENTED |
| REST price polling fallback | Batch `futures_mark_price` for symbols WebSocket hasn't updated in >3s | execution | paper_trader.py:3232-3297 | IMPLEMENTED |
| WebSocket `!miniTicker@arr` | Bulk-subscribes all futures prices via one stream | execution | paper_trader.py:3299-3311 | IMPLEMENTED |
| Externally-filled SL/TP detection | Polls positions every 30s to catch SL/TP filled outside the bot's own order tracking | execution | live_trader.py:1383-1430 | IMPLEMENTED |
| Bar-close dedup | Skips re-evaluating a symbol until a new candle closes | execution | live_trader.py:439-443 | IMPLEMENTED |
| `data_insufficient` gate | Rejects symbols with <50 rows of OHLCV | risk | paper_trader.py:825-835 | IMPLEMENTED |
| Liquid Neural Network anomaly gate | Blocks entry if autoencoder anomaly score >0.75 (manipulation / flash-crash detection) | risk | paper_trader.py:1159-1174; live_trader.py:579-587 | IMPLEMENTED (both) |
| Meta-AI ATC + Circuit Breaker gate | External adaptive trade controller can veto direction or block via circuit breaker | governance | paper_trader.py:1089-1128; live_trader.py:615-645 | IMPLEMENTED (both) |
| Hawkes Endogeneity Gate | Blocks/penalises entries when Hawkes branching ratio signals stop-hunt or fragile book (>0.95 block, >0.85 −15% confidence) | risk | paper_trader.py:1130-1157 | IMPLEMENTED — paper only |
| Strategy Coroner gate | Suspends entries from poor-win-rate strategies; size multiplier for watch-listed | governance | paper_trader.py:1176-1209; live_trader.py:660-670 | IMPLEMENTED (both) |
| Coroner min-fill bypass | Paper lets a suspended strategy through as tagged micro-exploration when active count is below minimum | governance | paper_trader.py:1184-1199 | IMPLEMENTED — paper only |
| Cognitive Immune System gate | Size/confidence adjustments from 5 pattern checks (cult behaviour, ideology lock, fake alpha, drift penalty) | governance | paper_trader.py:1211-1232 | IMPLEMENTED — paper only |
| Strategy-specific confidence floors | Hard-coded per-strategy minimums derived from historical WR (ema_cross 70%, harmonic_pattern 70%) | risk | paper_trader.py:1234-1260 | IMPLEMENTED — paper only |
| Strategy Trade Quota | Caps any one strategy at 25% of max concurrent slots to prevent monoculture | risk | paper_trader.py:1262-1278 | IMPLEMENTED — paper only |
| Regime-Direction Gate | Hard-bans strategy+direction+regime combos with data-proven negative edge | risk | paper_trader.py:1280-1317 | IMPLEMENTED — paper only |
| Winner Pattern Miner / MetaFail / DirBias trio | Three ML scorers activate only after 1000 closed trades, at half weight | risk | paper_trader.py:1319-1402; live_trader.py:672-774 | IMPLEMENTED (both) |
| Online Direction Learner | Shadow-then-live model penalising confidence when it disagrees with signal direction; trained on every close | strategy | paper_trader.py:776-797,2787-2815; live_trader.py:776-797,1575-1589 | IMPLEMENTED (both) |
| Trade DNA Sequencer | Scores signal 0-100 against winner fingerprints; <500 closed trades → size-down rather than reject | risk | paper_trader.py:1437-1481; live_trader.py:716-733 | IMPLEMENTED (both) |
| Debate Council | 3-agent adversarial debate (Advocate / Devil's-Advocate / Arbiter) sets size multiplier or REJECTs; <500-trade data-maturity guard | governance | paper_trader.py:1483-1524; live_trader.py:735-756 | IMPLEMENTED (both) |
| Volatility Regime Forecaster gate | Predicts P(vol spike in 4h); blocks >0.85, widens SL 0.65-0.85 | risk | paper_trader.py:1535-1559,1832-1841 | IMPLEMENTED — paper only |
| AI Civilization veto | External civilization module can reject a signal; authority-gated | governance | paper_trader.py:1561-1580; live_trader.py:805-820 | IMPLEMENTED (both) |
| Civilization Council deliberation | AlphaArchitect + CatastropheIntelligence + ExecutiveCapitalGovernor; can only downgrade size or reject, never upgrade | governance | paper_trader.py:1582-1624; live_trader.py:822-853 | IMPLEMENTED (both) |
| Signal Ranker (EV-based sizing) | Converts all upstream signals into one EV score 0-100 with graduated size scaling instead of binary block | risk | paper_trader.py:1651-1684; live_trader.py:876-897 | IMPLEMENTED (both) |
| Entry Timing Calibrator | Learns optimal pullback % / wait-bars per symbol+strategy; applied in paper, log-only in live | strategy | paper_trader.py:2050-2087; live_trader.py:899-916 | IMPLEMENTED (both), inert in live |
| Survival Governor | Exploration-trade floor, per-engine authority penalties, can force exploration classification | governance | paper_trader.py:1692-1722; live_trader.py:924-944 | IMPLEMENTED (both) |
| Gate Challenger / soft-block conversion | Randomly (5–25%, scaled by closed-trade count) lets a gate-blocked signal through as a minimum-size exploration instead of rejecting | governance | paper_trader.py:1057-1076,1882-1903 | IMPLEMENTED — paper only |
| Lévy jump-risk position scaling | Reduces size when jump-variance fraction is high | risk | paper_trader.py:1626-1633; live_trader.py:856-862 | IMPLEMENTED (both) |
| Advanced risk manager sizing | CVaR + drawdown-stress constraints on final size | risk | paper_trader.py:1760-1781; live_trader.py:970-984 | IMPLEMENTED (both) |
| Pyramid add-on sizing | 2nd position in same symbol at 40% capital; "profit-funded" if unrealised PnL on the existing leg covers it | portfolio | paper_trader.py:1783-1819; live_trader.py:986-1009 | IMPLEMENTED (both) |
| Min-confidence threshold gate | Paper 45%, live default 62%, config-overridable | risk | paper_trader.py:1040-1055; live_trader.py:653-654 | IMPLEMENTED (both) |
| Symbolic Regression formula signal | GP-evolved formula blended into ML confidence | strategy | paper_trader.py:962-989; live_trader.py:544-564 | IMPLEMENTED (both) |
| Adversarial Signal Testing | Perturbs features ±1% std 3× to test robustness; fragile ×0.75, robust ×1.05 | strategy | paper_trader.py:947-958 | IMPLEMENTED — paper only |
| RL ensemble signal blending | RL agent agreeing with ML direction boosts confidence +5 | strategy | paper_trader.py:991-1003; live_trader.py:534-542 | IMPLEMENTED (both) |
| On-chain advanced metrics | MVRV-Z, NVT, SSR, exchange flow into feature extras | strategy | paper_trader.py:867-884; live_trader.py:472-483 | IMPLEMENTED (both) |
| Options market signal enrichment | PCR, IV, GEX sign, combined bias | strategy | paper_trader.py:886-902; live_trader.py:485-496 | IMPLEMENTED (both) |
| Liquidation cascade enrichment | Cascade risk/direction/imminence, 24h liq volume into extras | strategy | paper_trader.py:904-921; live_trader.py:498-508 | IMPLEMENTED (both) |
| GNN cross-asset correlation refresh | Rebuilds a cross-asset price graph each loop so a GNN model can vote | strategy | paper_trader.py:776-795 | IMPLEMENTED — paper only |
| AlignmentGuardian doctrine-breach constraint | At ≥40% portfolio drawdown, reads meta-board state; on DOCTRINE_DRAWDOWN_BREACH halves max concurrent capacity and raises min confidence to 65% | governance | paper_trader.py:708-738 | IMPLEMENTED — paper only |
| Proactive Exploration Fill | When open+pending < minimum, force-opens exploration trades on unused symbols targeting the least-tested idea | strategy | paper_trader.py:308-519,763-771 | IMPLEMENTED — paper only |
| min_concurrent_trades floor check | Computes whether active count is below configured floor | portfolio | paper_trader.py:296-304 | IMPLEMENTED — paper only |
| Slot-based exploration classification | First N standard slots get real SL/TP; slots beyond become exploration trades | strategy | paper_trader.py:1905-1925 | IMPLEMENTED — paper only |
| 20 named experimental strategy ideas | Detector assigns one of 20 ideas (PANIC_BOTTOM_BOUNCE, CROSS_SECTIONAL_MOMENTUM, ANTI_SIGNAL, CARRY_EXPERIMENT…) to an exploration slot, potentially overriding direction | strategy | paper_trader.py:1942-2011 | IMPLEMENTED — paper only |
| CASCADE_RIDE_SHORT trade type | Always forced standard, direction never overridden, max 8-bar hold | strategy | paper_trader.py:1908-1911,1931-1940,2263-2277 | IMPLEMENTED — paper only |
| MICRO_SPIKE_SCALP idea | −0.5%/+0.3% SL/TP, 2-bar max hold, 15% of normal size | strategy | paper_trader.py:1983-2026,2146-2152,2271-2273 | IMPLEMENTED — paper only |
| ANTI_SIGNAL / CARRY_EXPERIMENT sizing overrides | Forced to 20% of computed size — deliberately tiny signal-quality and carry tests | strategy | paper_trader.py:1977-1982 | IMPLEMENTED — paper only |
| IdeaIntelligence capital multiplier | Proven-winning ideas scaled up to 50% of initial capital cap; underperformers get less | strategy | paper_trader.py:1990-2009 | IMPLEMENTED — paper only |
| No-SL/TP exploration arc | Non-scalp explorations set SL/TP 99% away so the trade runs its full 1500-bar life purely for MFE/MAE data; capped at 50% of initial capital | strategy | paper_trader.py:2027-2046,2153-2159 | IMPLEMENTED — paper only |
| Opportunity Interruptor | Every 2 min closes the worst open exploration early if a materially better signal (score ≥75) exists AND its EV beats hold-EV via RecoveryPredictor | portfolio | paper_trader.py:3037-3163; live_trader.py:1887-2015 | IMPLEMENTED (both; live version dead in practice) |
| Bounce-Back recovery trades | Same-direction recovery trade at 20%/inherited leverage when BounceBackIntelligence fires; bypasses same-symbol pyramid cap and even max-concurrent cap in paper | portfolio | paper_trader.py:2318-2440; live_trader.py:1287-1341 | IMPLEMENTED (both) |
| Symbol Bandit | Beta Thompson-sampling tracker updated per symbol on every close | strategy | paper_trader.py:2723-2732; live_trader.py:1643-1652 | IMPLEMENTED (both) |
| Shadow mode (variant B) | Records an alternate model's hypothetical decision alongside the real trade | strategy | paper_trader.py:2235-2243,2780-2785; live_trader.py:1148-1161,1568-1573 | IMPLEMENTED (both) |
| Rejection Tracker (shadow simulation) | Every gate rejection logged with full context and replayed as a simulated position so rejected signals' hypothetical PnL is measured | governance | paper_trader.py:277-294,842-848; live_trader.py:405-421,449-454 | IMPLEMENTED (both) |
| Inversion check | Compares accepted-trade PnL against rejected-trade shadow PnL to detect whether the gates are net harmful | governance | paper_trader.py:2817-2827; live_trader.py:1591-1601 | IMPLEMENTED (both) |
| Concept drift monitor feedback | Records prediction outcome + realised return per symbol | strategy | paper_trader.py:2848-2859; live_trader.py:1730-1740 | IMPLEMENTED (both) |
| Dreamer v3 world-model recording | Records trade state/action/outcome tuples for a world-model RL trainer | strategy | paper_trader.py:2920-2937; live_trader.py:1742-1759 | IMPLEMENTED (both) |
| MFE Capture Learner | Records MFE/MAE-vs-actual-exit outcomes; background retrain every 10 records | strategy | paper_trader.py:2939-2966; live_trader.py:1761-1783 | IMPLEMENTED (both) |
| Counterfactual / causal analysis | "What if exit was N bars earlier" fed with post-trade price history | strategy | paper_trader.py:2897-2918; live_trader.py:1785-1805 | IMPLEMENTED (both) |
| MAML fast regime adaptation feed | Feeds entry feature vector + win/loss into a meta-learning model on close | strategy | paper_trader.py:2968-2974 | IMPLEMENTED — paper only |
| Peak Drawdown Advisor retrain trigger | `maybe_retrain()` after every close | strategy | paper_trader.py:2641-2646; live_trader.py:1525-1530 | IMPLEMENTED (both) |
| Trade DNA retrain trigger | `maybe_retrain()` after every close | strategy | paper_trader.py:2648-2653; live_trader.py:1532-1537 | IMPLEMENTED (both) |
| Leverage unlock check | Every 10 closed trades, checks whether win-rate justifies higher leverage | risk | paper_trader.py:3026-3033; live_trader.py:1846-1853 | IMPLEMENTED (both) |
| Daily performance upsert | Aggregates today's closed-trade stats into a `daily_performance` row | portfolio | paper_trader.py:2999-3024; live_trader.py:1706-1728 | IMPLEMENTED (both) |
| Checkpoint capital persistence | Saves capital + counters to JSON on close/stop, restores on restart | portfolio | paper_trader.py:139-147,3471-3481; live_trader.py:1855-1864 | IMPLEMENTED (both) |
| Peak P&L tracking | In-memory running max profit/loss per open trade, flushed via MAX/MIN SQL each snapshot | portfolio | paper_trader.py:106-108,2493-2497,3221-3226; live_trader.py:79-80,1370-1374,1495-1496 | IMPLEMENTED (both) |
| Isotonic confidence calibration at startup | Force-refits confidence→realised-WR calibrator if ≥30 closed trades | strategy | paper_trader.py:604-615 | IMPLEMENTED — paper only |
| Intelligence-contribution tagging (`_intel_tag`) | Per-symbol record of which sub-systems touched a trade, flushed onto the trade record for dashboard attribution | governance | paper_trader.py:212-223,945,984,1001 | IMPLEMENTED — paper only |
| Meta-AI `on_trade_closed` propagation | Feeds outcome back into ATC, MAML, Circuit Breaker | governance | paper_trader.py:2829-2846; live_trader.py:1807-1824 | IMPLEMENTED (both) |
| Ensemble outcome feedback | Records outcome per model (lstm_bilstm, gru, cnn_bilstm, tree_ens) for accuracy dashboards | strategy | paper_trader.py:2767-2778; live_trader.py:1625-1633 | IMPLEMENTED (both) |
| Strategy / scanner performance updates | Updates per-strategy and per-symbol rolling stats on close | strategy | paper_trader.py:2655-2721; live_trader.py:1635-1642 | IMPLEMENTED (both) |
| Insufficient-capital gate | Blocks trade if liquid capital can't cover position + fee | risk | paper_trader.py:1877-1880 | IMPLEMENTED |
| Absolute minimum capital floor | Raises undersized positions to $50 / 2%-of-initial if cash allows, else skips | risk | paper_trader.py:2164-2192 | IMPLEMENTED — paper only |
| Civ sizing / SL-TP world-model override | Blends computed size/SL/TP with civilization's world-model recommendation, authority-weighted | governance | paper_trader.py:1736-1758,1843-1872; live_trader.py:951-967,1089-1110 | IMPLEMENTED (both) |
| Dead init block | `if False: pass  # disabled block — kept for structure` | portfolio | paper_trader.py:199-200 | STUB (dead code) |
| `get_pnl_snapshot` fast path | Lock-minimised dashboard read avoiding `get_trade_stats()` to prevent freeze under load | portfolio | paper_trader.py:3387-3454 | IMPLEMENTED |
| Reject-context tracking | Accumulates symbol/direction/confidence/regime context during evaluation so any later rejection logs full context | risk | paper_trader.py:456-464,608-613,1079-1087; live_trader.py:457-464 | IMPLEMENTED (both) |

## Execution / risk / governance core

| Feature | What it does | Category | Evidence | State |
|---|---|---|---|---|
| SymbolBandit | Thompson sampling per symbol AND per direction; cold-start neutral below 30 trades; 0.98 decay forgets stale regimes | governance | trading/symbol_bandit.py:1-292 | IMPLEMENTED |
| SurvivalGovernor | Exploration-rate floor (10%, 30% degraded), halves any engine's authority when it influences >65% of trades, 3-consecutive-vote consistency check before any hard block, P&L circuit breaker after 5 negative sessions | governance | trading/survival_governor.py:1-442 | IMPLEMENTED |
| SignalRanker | Converts binary gate pass/fail into a continuous 0–100 EV score across 6 weighted components with graduated size multipliers | risk | trading/signal_ranker.py:1-280 | IMPLEMENTED |
| ShadowTracker (A/B) | Runs a simulated variant B alongside real trading; win-rate/Sharpe/PnL, binomial significance test, verdict + recommendation | governance | trading/shadow_mode.py:1-369 | IMPLEMENTED |
| ShadowAutoApplier | When B proven better (p<0.05, n≥20), **automatically rewrites live config** and starts a new escalating experiment; feeds results into ML incremental retraining | governance | trading/shadow_auto_applier.py:1-286 | IMPLEMENTED |
| IdeaIntelligence | Thompson bandit over 20 named ideas; suspends WR<18% after 20 trades, auto-reactivates after 7 days, capital multiplier up to 2.5× | governance | trading/idea_intelligence.py:1-441 | IMPLEMENTED |
| ExperimentalStrategyEngine | 20 distinct detector functions (CVD divergence, Wyckoff spring, session-open breakout, panic-bottom, BTC/ETH stat-arb, anti-signal, uncertainty explorer, regime-gap explorer, carry experiment, recovery arc, dreamer-guided, micro-spike scalp…); Thompson-samples among simultaneous candidates | strategy | trading/experimental_strategies.py:1-1294 | IMPLEMENTED (all 20 have real logic) |
| EntryTimingCalibrator | Learns per-symbol/strategy optimal pullback % and max-wait-bars from historical MFE bar-of-peak; 3-tier fallback | strategy | trading/entry_timing_calibrator.py:1-214 | IMPLEMENTED |
| RiskManager | Kelly / confidence-scaled / portfolio-optimizer-blended sizing, max-concurrent enforcement, sector correlation filter (12 groups, 100+ symbols), daily-loss kill switch (**live only — paper explicitly has none**), pyramid exception at ≥85% confidence, dynamic leverage | risk | trading/risk_manager.py:1-718 | IMPLEMENTED |
| RejectionTracker | Simulates 20-bar hypothetical outcomes for every rejection; per-gate effectiveness verdict (effective/neutral/harmful); holistic inversion check with rate-limited Telegram alert | governance | trading/rejection_tracker.py:1-410 | IMPLEMENTED |
| ExitEngine | Per-trade MFE/MAE tracker, historical MFE-profile library per symbol+strategy+regime+direction, and a 7-priority exit waterfall: AI predictor → hard SL (with RecoveryPredictor override) → TP → early-loss/loser-fingerprint cuts → MFE-adaptive trailing stop → optimal-stopping (Bellman) → quantile/LSTM AI exit predictors → conformal exit deadline → momentum-decay exit → time exit → AI-civilization exit | execution | trading/exit_engine.py:1-1068 | IMPLEMENTED |
| Exploration break-even lock | After 20 consecutive profitable bars on an exploration trade, ratchets stop to entry so it can never end at a loss | execution | exit_engine.py:606-619 | IMPLEMENTED |
| SymbolScanner | **Scores 500+ futures symbols** on a 13-component weighted composite (trend/vol/volume/momentum/regime/VPIN/cascade/entropy/Lévy/pattern/bandit); sector-balanced top-N across 12 sectors to avoid BTC-correlated clustering; auto-blacklist at WR<25% after 20 trades, auto-unblacklist at WR≥60% | strategy | trading/scanner.py:1-611 | IMPLEMENTED |
| PortfolioOptimizer | HRP (PyPortfolioOpt + pure-Python fallback), Black-Litterman with win-rate-derived views, max-Sharpe, min-variance, risk-parity (SLSQP), multi-asset continuous Kelly; correlation-pair reporting | portfolio | portfolio/optimizer.py:1-519 | IMPLEMENTED |
| AdvancedRiskManager | CVaR portfolio optimisation (Rockafellar-Uryasev LP), historical crash stress-testing across 6 named scenarios (Luna, FTX, COVID, China ban, 2022 bear, May-2021 flash crash), max-drawdown-constrained sizing with quadratic headroom scaling, TDA-crash-risk leverage scale | risk | portfolio/advanced_risk.py:1-611 | IMPLEMENTED |

## `crypto-linix-server-bot` fork — net additions

| File | Net change | Category | State |
|---|---|---|---|
| `strategies/selector.py` (+54) | Adds `ml` (weight 1.6) and `microstructure` (weight 1.5) categories to every regime map; registers 4 ML + 7 microstructure instances | strategy | IMPLEMENTED |
| `strategies/strategy_coroner.py` (rewrite) | Replaces Bayesian-posterior suspension (20/30 trades) with: suspend only after 200+ closed trades AND `avg_pnl < 0`. Documented as a deliberate policy relaxation to avoid false suspensions from short bad-luck streaks | governance | IMPLEMENTED |
| `trading/rejection_tracker.py` (+169) | **Auto-adaptation.** `get_auto_adaptation_multipliers()` computes a 1.0–4.0× challenge-rate multiplier per gate from blended overall + rolling wrong-block %, persists it to disk, and `paper_trader._evaluate_symbol()` consumes it to soften harmful gates automatically. `get_regime_gate_matrix()` shows which gates are over-aggressive in which regime | governance | IMPLEMENTED |
| `trading/risk_manager.py` (+61) | Rewrites `_calculate_leverage_paper()` from flat 20× to a 3-axis dynamic 5–20×: confidence tier × per-strategy win-rate multiplier (0.70–1.30, needs ≥20 trades) × drawdown guard (0.55–1.0) × TDA scale | risk | IMPLEMENTED |
| `trading/exit_engine.py` (+243) | Tailgate Convergence Exit; multi-stage tailgate (trail width scales through 4 profit stages); peak-count modifier tightening the trail per confirmed MFE wave; volatility-adjusted trail width; loser fast-exit forcing losing trades closed at a shorter bar limit | execution | IMPLEMENTED |
| `trading/scanner.py` (+41) | `_prefilter_by_ticker()` — cuts 560+ symbols to top ~150 by 60% volume / 40% price-move ranking using already-fetched bulk ticker data (no extra API calls) before the expensive OHLCV pass; guaranteed symbols always included | execution | IMPLEMENTED |
| `trading/live_trader.py` (+7) | Adds `trailing_sl` field synced from the exit engine (dashboard visibility, not new logic) | execution | IMPLEMENTED |
| `trading/paper_trader.py` (+266) | **Harvest Mode** — when `trading.data_harvest_mode` is on and closed-trade count is below target (default 600), gate-blocked signals convert to explorations at 100% rate vs 25–60% normal, auto-disabling permanently once the target is reached | governance | IMPLEMENTED |
| `portfolio/optimizer.py` (−2) | Disables the `riskfolio` import entirely — commented as avoiding an import-lock deadlock with statsmodels under threaded scanning on Linux | portfolio | IMPLEMENTED (as a removal) |
| `strategies/microstructure/microstructure_strategies.py` (374, linix-only) | 5 classes: `VPINInformedFlowStrategy`, `LiquidationCascadeStrategy`, `FundingClockStrategy` (trades the 8h funding-payment pre/post drift), `FundingExtremeReversionStrategy`, `ExchangeFlowStrategy` | strategy | IMPLEMENTED |
| `strategies/ml_based/ml_strategies.py` (297, linix-only) | 4 classes: `EnsembleMLStrategy`, `OnlineDirectionStrategy` (River-based continuously-trained logistic), `SymbolicRegressionStrategy`, `RegimeSwitchStrategy` (swaps sub-strategy on live HMM regime) | strategy | IMPLEMENTED |

## Defects found, recorded not fixed

| Defect | Detail |
|---|---|
| `TradeSignal` field-name mismatch | `strategies/volatility_surface.py` constructs `TradeSignal(..., strategy=self.name, ...)` but the dataclass in `base_strategy.py` defines the field as `strategy_name`. The linix-only `ml_strategies.py` and `microstructure_strategies.py` use `strategy_name=` correctly. That strategy would raise on every signal |
| Periodic reconcile is misnamed | `live_trader.py:374-380` runs every 5 min but only re-syncs capital; it does not re-run position reconciliation despite the name |
| Live exploration code is dead | The Opportunity Interruptor exists in `live_trader.py` but live never opens exploration trades, so it can never fire |
