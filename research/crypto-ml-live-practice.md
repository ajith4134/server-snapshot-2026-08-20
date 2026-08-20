# How live crypto systems actually do ML — and whether it beats rules

**Researched 2026-08-19** by a sonnet agent under RL-045, sources fetched directly
(freqtrade cloned and grepped, papers as PDF, GitHub issues via API) rather than via
summarizers. Synthesis and the statistical read done on the main thread.

## FreqAI's real architecture (verified from source at `develop` HEAD)

- **Features**: four strategy callbacks; `%-` prefix for features, `&-` for targets,
  enforced not cosmetic (unprefixed columns dropped). `docs/freqai-feature-engineering.md`.
- **Labels**: left entirely to the user. The shipped example is plain fixed-horizon
  forward-return regression. **Triple-barrier appears nowhere in FreqAI source or docs
  — zero grep hits.**
- **Retrain**: `live_retrain_hours` default 0 ("as often as possible"), pairs retrained
  round-robin off a queue, so with many pairs the oldest serving model can be hours
  stale. The docs say so outright.
- **Validation**: plain chronological `train_test_split(shuffle=False)`. **No purge, no
  embargo, no CPCV, no walk-forward CV anywhere** — confirmed by grep.
- **Model lifecycle — the important negative finding**: there is **no champion/challenger
  gate, no shadow deployment, no A/B mechanism**. Docs state flatly: *"FreqAI will always
  use the most recently trained model."* `continual_learning` is described in their own
  docs as *"a naive approach... high probability of overfitting."* GitHub issue #8409 asks
  maintainers how to trust a new model before it serves; unanswered in current docs.
- **Drift**: zero drift-detection machinery (no ADWIN/DDM/Page-Hinkley, confirmed by
  grep). Only per-prediction outlier rejection (Dissimilarity Index, SVM, DBSCAN), which
  rejects individual out-of-distribution rows, not market-wide regime shifts.

## Label construction in practice

Triple-barrier exists as real code in many repos, but repeatedly flagged "RESEARCH-ONLY
— not for live trading", while the live path uses something simpler. `mlfinlab`/`mlfinpy`
TBM has years of open bug reports, consistent with study use rather than production.
**Evidence of triple-barrier running in live-capital crypto systems is thin to absent.**
Fixed-horizon labelling is the dominant practical default. Meta-labelling has research-code
presence but **zero primary sources confirming live outperformance**; the one honest
example found is a harness built specifically to show a great-looking split failing purged
walk-forward CV.

## Validation

**No verifiable evidence of CPCV running in a live crypto pipeline was found anywhere.**
It exists in reputable code (`skfolio`) and academic reproductions. Walk-forward is the
de-facto standard — one computational path, intuitive — at the cost of being a single
regime-dependent draw with high variance.

## Promotion

**"Latest retrain wins" is the unexamined default, not a considered practice** — confirmed
across FreqAI and the broader search. One single-author 2026 arXiv preprint (Dutta,
arXiv:2607.28577, **UNVERIFIED as peer-reviewed**) proposes a "Shadow Before Swap" gate and
in simulated replay promoted only 114/528 challengers (78% fewer swaps) while improving
forecast likelihood versus calendar-based replacement. One paper's simulation, not a
live-capital result.

## Does ML beat rules, live?

- **Lopez de Prado / Bailey**, fetched as PDF: naive backtesting across many configurations
  produces false positives "almost certain[ly]". Worked example: overfit strategy **PBO =
  74%** (78% of out-of-sample Sharpes negative despite 100% in-sample positive) against a
  genuine strategy at **PBO = 0.04%**. The framework validates real edges too — it is not
  purely destructive.
- **Real FreqAI live-vs-backtest reports** (GitHub, fetched directly): issue #8518 —
  backtest −8.97% over Jan–Apr 2023; live the same months +9.6%, −10.95%, −13.42%, −3.7%.
  **Sign flipped month to month.** Issue #8248 — backtest 1,975% profit / Sharpe 183 over
  19 days (itself a red flag); live "completely different".
- **Zero controlled, sustained, live-capital ML-vs-rules horse races found anywhere.**
  Academic crypto ML papers checked are all backtest or simulated-live-on-historical.

**Don't bother** searching further for a credible published live study showing crypto ML
beats rules; extensive search found none. What exists is warnings from the method's own
inventors plus anecdotal backtest-live divergence, several with sign flips.

## UNVERIFIED / caught fabrication

- A search returned "over 90% of backtested strategies fail in live trading, per Lopez de
  Prado" **with no traceable source. It does not appear in the actual PDFs read. Discard
  it; do not use it.** Consistent with this box's standing finding that summarizers drop
  and fabricate.
- Dutta arXiv:2607.28577 — UNVERIFIED as peer-reviewed, single author.
- "CPCV too expensive for crypto" — UNVERIFIED, reasoned by analogy, no crypto-specific
  primary source.
- No rigorous quantitative minimum-sample-size threshold for crypto found in the
  literature — only qualitative warnings.

## Verdict on our measured 1.2pp out-of-fold edge

Naive Bernoulli maths on ~100k rows gives SE ≈ 0.16pp, making 1.2pp look like 7–8 sigma.
**That is exactly the trap purging, embargo, CPCV and uniqueness weighting exist to
prevent.** Two dependence structures destroy it:

1. **Cross-sectional correlation** — 570 crypto symbols are not 570 independent bets; alt
   beta to BTC/ETH is commonly 0.7–0.9+. One correlated trend dressed as hundreds of
   independent correct calls.
2. **Serial/label correlation** — overlapping triple-barrier horizons are dependent by
   construction. Weighting reduces the bias; it does not manufacture independent
   information.

If effective independent sample size is a few hundred regime-days rather than 100k rows,
SE swells toward ~2pp and 1.2pp is **sub-1-sigma**.

**Conclusion: not yet distinguishable from noise, and not disproven either — underpowered,
not negative.** Four days cannot tell you which.

**What is demanded before trusting it:**
1. Weeks to months spanning a full volatility/trend/chop cycle — not more rows in the same
   4-day regime.
2. Stability across successive retrain cycles: does 1.2pp hold, grow, or oscillate around
   zero?
3. An effective-sample-size-corrected significance test — block bootstrap or PBO/deflated
   Sharpe over the actual OOF folds, not a naive proportion test.
4. A **P&L-based** metric, not accuracy — crypto perp fees, slippage and funding commonly
   eat 1–2% straight away.
5. Shadow confirmation before capital.

## What this says about our system, specifically

We are **ahead of the most-used open-source live crypto ML framework** on three axes:
purged CPCV vs plain chronological split; a champion-promotion gate vs "latest wins"; and
three specialised brains vs one model. The champion gate defect fixed on 2026-08-19 is the
**same defect FreqAI still ships**, and their issue #8409 is a user asking for exactly the
thing we now have.

We are **behind or absent** on: drift detection (they at least have per-prediction outlier
rejection — DI, SVM, DBSCAN — we have none), and shadow deployment before capital.
