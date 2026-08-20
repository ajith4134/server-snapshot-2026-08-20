# Live Trading ML Monitoring & Deployment Discipline

Researched: 2026-08-01, by Sonnet 5 subagent (three parallel research passes: drift metrics, data quality/staleness, deployment discipline).
Part of a 6-agent parallel sweep on ML infra + operational discipline for a solo autonomous crypto trading system.

---

# Part A — Monitoring That Actually Matters

## A1. Drift detection metrics — what each is actually for

| Metric | Good for | Core weakness |
|---|---|---|
| PSI | Coarse, bulk shift on binned/discretized features | Arbitrary thresholds, empirically low sensitivity |
| KL-divergence | Theoretical foundation, Bayesian model comparison | Asymmetric, blows up at zero-probability bins, outlier-sensitive |
| KS test | Nonparametric distribution equality, small samples | p-value hypersensitivity at scale |
| Wasserstein/EMD | Magnitude-aware continuous drift | Outlier-sensitive, no built-in significance threshold |

**PSI**: `PSI = Σ(Actual% − Expected%) × ln(Actual%/Expected%)` — mathematically Jeffrey's divergence (symmetrized KL). VERIFIED (rdrr.io/cran/scorecard, arXiv 2307.11878). The 0.1/0.25 thresholds trace to B. Lewis, "Introduction to Credit Scoring" (1994) — a credit-scorecard heuristic, not statistically derived. VERIFIED (Journal of Risk Model Validation 2020, Annals of Operations Research 2026). Academic reviews call the thresholds unsupported by error-rate analysis; **Evidently AI's own benchmark found PSI stays silent until drift exceeds ~10% at 100k observations, and barely detects drift confined to a 20%-segment unless that segment shifts ~100%.** VERIFIED (evidentlyai.com/blog/data-drift-detection-large-datasets). PSI is popular because it's cheap and interpretable, not because it's sensitive.

**KL-divergence**: asymmetric, undefined at zero-probability regions unless smoothed, outlier-sensitive. VERIFIED (WhyLabs docs, Arthur.ai). Production systems generally use **Jensen-Shannon divergence** (symmetrized KL via midpoint) instead. Behaves similarly to PSI per Evidently's benchmark.

**KS test**: tests max distance between empirical CDFs, returns a p-value. **At >100,000 observations it flags even 0.5% drift as statistically significant** — Evidently recommends KS only under ~1,000 observations, distance metrics above. VERIFIED (evidentlyai.com, corroborated Deepchecks). For tick/trade-level crypto data, KS will alarm on noise essentially continuously.

**Wasserstein distance**: a true metric, sensitive to shift magnitude, no p-value hypersensitivity. Evidently AI defaults to it for numerical features above 1,000 reference observations (threshold 0.1); NannyML recommends it or Jensen-Shannon for continuous data. VERIFIED (docs.evidentlyai.com, arXiv 2404.18673). Note: WhyLabs does not default to Wasserstein — its recommended method is Hellinger distance. No vendor consensus.

### Does non-stationarity break naive drift detection? Yes — the most important finding in Part A.

1. **Theoretical**: a 2026 "Window Dilemma" paper (arXiv 2602.06456) formally proves that under continuous/incremental drift, *no* reference-vs-current window boundary correctly represents either the old or new "true" distribution. Their experiments found a plain model with no drift detector sometimes **outperformed** a drift-aware one. VERIFIED. A fixed-reference PSI/KS check against "training-time distribution" is structurally the wrong tool for financial features — the reference itself is non-stationary.

2. **Practitioner framing (Stefan Jansen, ml4trading.io, ch. 26 "MLOps and Governance")** — distinguishes **"technical pipeline divergence"** (bug) from **"statistical performance decay"** (correct code, decayed predictions from regime change/overfitting/alpha decay). *"Treating statistical decay as a bug wastes debugging time, while treating bugs as decay leads to unnecessary model changes."* VERIFIED. Four-quadrant diagnostic: drift-detected + no decay = model robust; decay + no drift detected = monitoring gap; both = retrain.

The mechanism practitioners actually use to distinguish "real regime change" from "my backtest was overfit" is **not a drift metric** — it's **Deflated Sharpe Ratio (DSR)** and **Combinatorial Purged Cross-Validation (CPCV)** (López de Prado), applied *before* going live, so live decay can be attributed. VERIFIED, well-established quant literature (Bailey & López de Prado).

**Finance-appropriate combination** (Neri 2021, arXiv 2103.14079; Jansen ml4trading.io): generic distributional metrics (PSI/KS/Wasserstein) on raw input features, layered with **stream-native sequential change detectors — ADWIN, Page-Hinkley, DDM — applied to the prediction-error stream**, purpose-built for non-stationary/streaming data. A finance-specific capstone comparison found **Page-Hinkley most responsive in real time**, ADWIN sensitive to window-length (best ~80-95 samples in their data). VERIFIED (arXiv 2103.14079); capstone comparison lower-authority but directionally consistent.

**Solo-scale verdict**: Don't build a PSI dashboard as primary defense. Build (a) a prediction-error-stream monitor using ADWIN or Page-Hinkley (cheap, off-the-shelf in `river` or `scikit-multiflow`), and (b) a DSR-gated promotion process. Treat PSI/KS as secondary sanity signal, not a gate.

## A2. Data quality gates

**Standard tiered pattern** (converges across TFX/TFDV, Chronon/Zipline, Deequ, multiple practitioner writeups — VERIFIED, cross-corroborated):
- Tier 0 — schema: required columns/types present.
- Tier 1 — basic quality: null-rate thresholds (Chronon's production rule: alert if null_count/total > 10% over 5-min window), numeric range/bounds, dedup on composite key.
- Tier 2 — distribution: histogram/JS-divergence drift, cardinality budgets.
- Tier 3 — semantic invariants: timestamp monotonicity per entity, "feature timestamp ≤ label timestamp" (leakage guard), non-negativity.

**Crypto-specific concrete pattern** (QuantForge, moderate confidence): DB-level unique constraint on `(exchange_id, symbol, timeframe, timestamp)` for dedup, enforced at the database not app code (survives concurrent/crashed fetchers); OHLC invariant checks (`high≥low`, open/close within `[low,high]`, `volume≥0`); gap detection distinguishing expected (maintenance) vs unexpected gaps. **Validate on write, not on read.**

**Tool verdict — blunt**: Great Expectations, Deequ, Evidently, Pandera, Soda Core are **all batch/DataFrame-oriented.** Confirmed by GE maintainers directly (GitHub issue #7337, 2023): *"Great Expectations does not support streaming use cases — we recommend producing cadenced batches from your streaming source... Closing this out for now as unsupported."* VERIFIED (github.com/great-expectations/great_expectations/issues/7337). A 2026 academic comparison of GE/Deequ/Evidently confirms none had native real-time validation. VERIFIED (arXiv 2604.09163).

None of these tools are built for gating an individual live trading decision in real time. Real solo/small-team trading builders (NexusFi community, several independent practitioner blogs) hand-roll DB constraints, OHLC invariants, and freshness watchdogs instead — consistent with the tools' actual batch architecture.

**Verdict**: at solo scale, do not adopt a dedicated data-quality framework for the live decision path. Hand-rolled assertions (a few hundred lines) outperform GE/Deequ/Evidently here. Use a framework only for offline jobs (backtest-data hygiene, feature-store validation before retraining) — a narrow, reasonable use for GE or Pandera; don't put either in the hot path.

**Cross-exchange sanity checks**: most concrete, credible pattern found (first-hand account aggregating 150+ exchange sources): hash price+volume payloads to detect a feed reporting stale-but-unchanged data with a moving timestamp; drop a source after N consecutive stale responses; use **median absolute deviation (MAD)**, excluding anything >3×MAD from the median, chosen over mean/Z-score because MAD requires manipulating a *majority* of sources to move it. Moderate-high confidence (iampavel.dev) — strong pattern to adopt.

## A3. Staleness detection

**Heartbeat/ping-pong tells you the socket is alive, not that data is fresh or correct.** All three major exchanges confirm by design:
- **Binance**: protocol-level ping every 20s, drops connection if no pong within 60s. VERIFIED.
- **Coinbase**: explicit `heartbeat`/`heartbeats` channel, 1 msg/sec with a sequence counter to detect *missed messages*, not just liveness. VERIFIED (docs.cdp.coinbase.com).
- **Kraken v2**: dedicated heartbeat channel ~once/sec **when no other traffic is flowing**, specifically to distinguish "alive, market quiet" from "dead." Also ships a dead-man's switch (`cancel_after`) cancelling all open orders if the client stops checking in. VERIFIED (docs.kraken.com) — a second, exchange-native layer worth stacking if trading there.

**The dangerous failure mode is a frozen order book on a live socket, or a silent in-band message gap** — the exchange skips a message without ever dropping TCP. Documented on KuCoin's public issue tracker per one source; independently flagged by NexusFi community as more dangerous than a disconnect because it looks normal. A naive "reconnect on disconnect" handler never notices it.

**Concrete detection heuristics** (cross-corroborated):
1. Sequence-gap detection — track last-seen sequence per symbol/channel; gap triggers resync (exchange-documented on Coinbase, Binance, not just heuristic).
2. Activity-adaptive staleness threshold, not a fixed timeout: `max(floor, k × rolling_avg_inter_tick_interval)` — tightens during volatility, loosens overnight. UNVERIFIED specific formula (single-source blog) but the principle is sound.
3. Dual-path check: if account/order-confirmation events still flow but market data has frozen, it's a data-path-specific failure (most common); if both freeze, it's connectivity.
4. REST-reconciliation loop on a fixed cadence comparing stream-derived vs REST-confirmed state, gated by K-consecutive-divergent-checks before forcing resnapshot.
5. N-consecutive-stale-before-alert on cross-exchange sources.

**Real incidents validating this as a real failure mode:**
- **Compound Finance, Nov 26 2020**: oracle sourced DAI price from Coinbase Pro only, Uniswap as anchor. DAI spiked to ~$1.30 on Coinbase while trading ~$1.03 elsewhere; Uniswap's anchor co-moved and failed too. **Result: $100M+ in forced liquidations of healthy positions.** VERIFIED (news.bitcoin.com, Compound governance forum, independent hack-database).
- **Mango Markets, Oct 11 2022**: attacker moved the oracle price ~1,300% across 3 thin, low-liquidity venues in 20-40 minutes, then borrowed ~$110-117M against inflated collateral. Lesson: naive multi-source averaging is defeated when all sources are simultaneously thin/manipulable — cross-exchange checks need liquidity weighting, not just N-source averaging. VERIFIED (Blockworks + corroborating writeups).
- **Knight Capital, Oct 2011** (inside the same SEC filing as the famous Aug 2012 event): Knight's LMM desk accidentally kept quoting off stale weekend test data into Monday's live market — genuine stale-data incident, ~$7.5M loss. SEC order: Knight "did not have a mechanism to test whether their systems were relying on stale data." VERIFIED (SEC Order 34-70694). Note: the famous $460M Aug 2012 event was a dormant-code deployment bug, not staleness — don't conflate.

No clean example of *pure passive staleness* (feed silently froze, zero manipulation) causing a large publicly-documented loss was found — closest cases are "manipulable single-source price accepted without adequate cross-check."

## A4. Skeptical — lead with what fails

**Noise, commonly recommended but mostly useless:**
- KS-test drift alarms at production tick volumes — flags 0.5% drift as "significant" continuously above 100k obs. Wire to a page and you get alert fatigue within a week. Route to a low-priority dashboard, never a page.
- PSI dashboards as a primary safety signal — empirically low sensitivity, 1994 credit-scorecard thresholds with no statistical grounding for this problem. Green PSI ≠ fine.
- Fixed-reference drift detection in general for financial features — the Window Dilemma result says no window choice is correct under continuous drift; it's not a tuning problem.
- Heartbeat/ping-pong treated as data-freshness proof — a live socket with a frozen order book is a documented, more-dangerous failure than disconnection and won't trip ping/pong.
- Great-Expectations-style "N validations passed, nightly green" dashboards for the live decision path — by the time a report catches an issue, capital's been at risk on every decision since.
- Generic ML metrics (accuracy, F1, latency percentiles) as trading-model health checks — don't capture calibration on the tail events that make/lose money.

**What actually matters, ranked:**
1. Sequence-gap counts / cross-source price divergence beyond a MAD-based threshold — catches the failure modes that actually caused real losses (Compound, Mango).
2. Prediction-error-stream change detection (ADWIN/Page-Hinkley), not input-feature drift.
3. Last-tick-age watchdog with activity-adaptive threshold, cross-checked against a second independent data path (REST reconciliation).
4. DSR-gated promotion so live decay can be separated into "expected regime-driven" vs "never real."

---

# Part B — Deployment Discipline for Swapping a Live Model

## B1. Concepts and trading equivalents

**Canary release** (Fowler/Google SRE): staged percentages (1%→10%→50%→100%), ≥24h bake time per stage (diurnal coverage), never step up more than ~2x prior population at once. VERIFIED (sre.google/workbook/canarying-releases).

**Dark launching** (Fowler): call new backend logic from real production traffic without exposing results — closest software analogue to **shadow trading**: real-time signal computed on live data, no capital placed. VERIFIED (martinfowler.com/bliki/DarkLaunching).

**Blue-green**: maps poorly onto trading (instant full-capital cutover is exactly the flag-day risk to avoid). Trading-relevant analogue institutions actually use: **champion/challenger with a traffic-split ramp**, not a binary switch.

### The realistic sequence

**Backtest → paper trading (simulated fills on live data) → shadow-live (real signals, no orders) → reduced-size live → full live.**

- **RustyBT's `ShadowTradingConfig`** (real open-source reference): explicit exit criteria — 7 consecutive stable days, ≥95% signal alignment rate, ≥90% execution-quality match, halt after 3 misalignments. Moderate confidence (real project, not institutional standard) but a concrete working shape.
- **"Shadow Before Swap" (SBS)**, arXiv 2607.28577: clone incumbent, warm-refit challenger off the serving path, evaluate both on the same forward window, promote only above a paired statistical-advantage threshold. Result: **78.4% fewer deployed-state changes vs. immediate-promote baseline across 48 weeks of crypto forecasting.** VERIFIED, directly on-topic.

### Dwell times

The one number backed by actual usage data: **Alpaca's telemetry** — 34.3% of users transition paper→live within 10 days, 57.1% within 30, 75.2% within 60; Alpaca's own guidance is "about 30 to 60 days" for most users. VERIFIED (alpaca.markets) — describes what users *do*, which the same source/community suggests is often too short to span multiple regimes.

Everything more specific (exact week-counts per stage, position-size ramp %) traces to a cluster of 2025-2026 SEO content sites with suspiciously convergent-but-uncited numbers — UNVERIFIED, folk heuristics.

**Verdict on dwell time — the one defensible principle every credible source converges on**: gate advancement on **regime coverage, not calendar time** — has the system observed a real drawdown/chop period and a real high-volatility event (macro print, exchange outage, weekend gap) at each stage. A model that paper-traded 60 days entirely in a trending bull regime has been validated against nothing that matters.

### Go/no-go metrics worth building

**Sharpe divergence, live vs backtest**: **Bailey & López de Prado, JPM 2017 — 215 commercially promoted strategies, median 73% Sharpe deterioration backtest→live**, complex strategies deteriorating further. VERIFIED (SSRN 2757113). Substantial live degradation is the norm, not proof of brokenness — a 40-60% Sharpe haircut alone is not a kill signal; a live Sharpe going negative, or diverging from a DSR-adjusted expectation, is. Use DSR as a pre-registration gate before paper trading, giving a real prior to compare live results against.

**Slippage realized vs modeled**: no rigorous academic threshold exists — specific numbers found (e.g. "realized >1.5x modeled = investigate") are UNVERIFIED, content-farm-sourced. Concrete implementable pattern: RustyBT's explicit `execution_quality_threshold` (90% fill-rate match) as a first-class shadow-stage metric.

**Signal correlation, live/shadow vs backtest**: strongest, most concretely implementable gate. RustyBT's `signal_tolerance_pct` (5%) + `max_misalignment_count` (halt after 3) + alignment-rate gate (≥95%, circuit-breaker below) — a real, working reference shape worth copying directly.

**Max drawdown, live vs backtest**: correct framing (converged, unverified specific multiplier): **the backtest's max DD is a lower bound, not an expectation.** Bootstrap/Monte Carlo reshuffling of the same historical trades typically shows a deeper tail. Size the kill-switch DD budget against the **p75-p90 percentile of a bootstrap/permutation DD distribution of your own backtest**, not the single historical max-DD number — methodologically sounder than a flat multiplier, and computable yourself.

## B2. Avoiding a "flag day" model swap

**Real, named-firm evidence — Man Group/Man Numeric**: public engineering blog describes migrating a **$30B platform from SAS to Python over ~5 years**, incremental component-by-component, **running old and new systems in parallel for ~3 years**, with automated cross-checking of new-platform outputs against legacy, **flagging large divergence in correlation**, plus formal Investment Committee sign-off gating each incremental swap. VERIFIED (man.com/why-we-rewrote-our-platform-in-python) — strongest institutional evidence of "no flag day," though a platform migration not a single alpha-model swap; the mechanics (parallel run + automated divergence flagging + staged sign-off) transfer directly.

**Champion/challenger with traffic-split ramping**: standard, regulator-formalized practice in adjacent decisioning domains (Fed SR 11-7, UK FCA Model Risk Management Principles) — typical starting split 5-20% of live volume to the challenger, sequential testing to stop early, ramp 10%→25%→50%→100%, **keeping old champion in reserve 30-90 days** for instant rollback. VERIFIED as documented banking-regulatory practice, not trading-specific, but the mechanics map directly.

**Concrete position-blending mechanism**: `weight_by_blend` in the open-source tradingstrategy.ai execution framework — linear shrinkage estimator, `w = alpha × old_weights + (1 − alpha) × new_weights`, explicitly grounded in James-Stein shrinkage literature. Real, usable reference code for gradual capital reallocation from old to new model.

More sophisticated approaches (Thompson-sampling blend selection, meta-learned mixture-of-policies, regime-adaptive continual learning) exist but are more machinery than a solo operation needs on day one.

---

## Overkill vs essential at solo scale — direct verdicts

| Practice | Verdict |
|---|---|
| Fixed-reference PSI/KS drift dashboards as primary safety net | Overkill / actively misleading. Theoretically broken for non-stationary finance data. |
| ADWIN/Page-Hinkley on prediction-error stream | Essential, cheap. Off-the-shelf in `river`. |
| Great Expectations / Deequ / Evidently in the live decision path | Skip. Maintainer-confirmed batch tools. Use only for offline backtest-data hygiene. |
| Hand-rolled DB constraints + OHLC invariants + freshness watchdog | Essential — what every real solo builder actually ships. |
| Cross-exchange MAD-based outlier rejection | Essential if trading spans venues — directly prevents Compound/Mango-class failures. |
| Exchange-native heartbeat/dead-man's switch | Essential but insufficient alone — must pair with sequence-gap and REST-reconciliation checks. |
| DSR-gated promotion | Essential, cheap, prevents shipping overfit backtests. |
| Shadow-live stage with formal signal-alignment gate (≥95%, RustyBT-style) | Essential. Catches most integration bugs before real money exposed. |
| Reduced-size live stage before full capital | Essential — backtest max-DD is a lower bound. |
| Position-blending (linear shrinkage) for model handoff | Worth building, low complexity, avoids flag-day risk. |
| Bayesian/meta-learned mixture-of-policies for transitions | Overkill at solo scale. |
| Regime-coverage-gated (not calendar-gated) promotion dwell time | Essential — the one number that actually matters. |

**Note on NautilusTrader**: none of the above (drift detection, data-quality gating, staleness detection, model-swap discipline) is solved by an execution/backtesting engine. This sits in a separate MLOps/monitoring layer regardless of execution stack — not a factor in the NautilusTrader-vs-alternatives decision. (General knowledge about NautilusTrader's scope, not independently verified this pass.)
