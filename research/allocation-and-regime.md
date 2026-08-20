# Capital allocation, regime change, and strategy decay

**Provenance**
- Researched by: subagent (`general-purpose`), model **sonnet**, per Rule 1
- Date: 2026-08-01 · Run via `parallel-research` (area 5 of 6)
- Brief: find what the user does NOT already know; the "starving" allocator was already decided

---

## Position sizing — the counterintuitive result

**Fractional Kelly is not a safety tax. It is a near-free lunch.**

Growth rate scales as `f(2-f)`; variance scales as `f²`. So **half-Kelly yields 75% of the growth
rate at 25% of the variance.** That asymmetry — not caution — is why practitioners use it.

- **Full Kelly implies ~50% peak-to-trough drawdowns as a routine, expected occurrence**, not a tail
  event. It falls out of the variance of the log-wealth process. Thorp ran ~half-Kelly at
  Princeton-Newport.
- **Overbetting is asymmetrically punishing.** The growth function is a downward parabola crossing
  zero again at `2f*` — bet twice the optimal fraction and **growth goes negative despite a genuinely
  positive edge**.
- **Kelly is brutally sensitive to error in μ**, and μ is the hardest quantity to estimate. A
  backtested edge is a noisy point estimate you should not trust to one significant figure.
  Fractional Kelly is doing double duty: hedging outcome variance *and* estimation error.

**What practitioners actually size with:** **volatility targeting**, not Kelly. Size so forecast
portfolio volatility hits a fixed target (e.g. 10% annualized). This sidesteps the μ problem
entirely — it needs only a **variance** forecast, which is far more stable and estimable than a mean.
Dominant approach at CTAs and systematic funds.

> **Use Kelly as a CEILING, not a target.** "Never bet more than this, even before the safety
> factor." That framing is the single most useful mental model here.

**Recommended shape:** volatility targeting as the primary sizer per strategy; a *shrunk*,
rolling-window quarter-Kelly as a sanity ceiling on top; never let a freshly-promoted strategy's
noisy live edge estimate drive sizing un-shrunk.

## Allocation across strategies — most of the literature does not apply at this scale

**Mean-variance is an "error-maximization" procedure** (Michaud 1989): it overweights exactly the
assets whose returns are overestimated and whose risk is underestimated. With 3–5 strategies and a
year of daily data, MVO will hand you 95% concentration in whichever strategy got fractionally
luckier — a difference indistinguishable from noise.

| Method | Verdict at 3–5 strategies |
|---|---|
| **Risk parity (equal risk contribution)** | **The right default.** Needs only covariance, no expected-return estimate |
| **HRP** (López de Prado, JPM 42(4) 2016) | Defensible, **not clearly better here**. Its advantage is robustness at large N; with 3–5 branches the covariance matrix is small and well-conditioned by construction. Skip the clustering/linkage/distance tuning |
| **Mean-variance** | **Don't bother** |
| **Black-Litterman** (Black & Litterman, FAJ 48(5) 1992) | **Don't bother** — its value is an equilibrium prior reverse-engineered from market caps. There is no equilibrium to recover from 3 internal branches |
| **Drawdown-constrained (CDaR)** | Don't build the LP. **Do keep the concept** — optimize against the drawdown path, not variance |

> **The empirical "starving" allocator already decided in `DECISIONS.md` is the right answer at this
> scale** — arguably *more* robust than any formal optimizer, because it does not require trusting a
> covariance estimate built on thin data. This is a legitimate engineering judgment, not a
> concession.

HRP is contested: it optimizes nothing in particular, and the clustering step is unstable under small
perturbations of the correlation matrix — ironic given robustness is the selling point. (Critique is
practitioner commentary, **UNVERIFIED** as a peer-reviewed rebuttal.)

## Correlation breakdown — mechanism, not bad luck

Strategies converge in crises for structural reasons:

1. **Shared liquidity exposure.** Two strategies with unrelated signals can both be implicitly short
   liquidity — both must exit when spreads widen. Correlation of *returns* says nothing about shared
   dependence on a *third factor* that only bites in the tail.
2. **Deleveraging cascades.** The **August 2007 quant meltdown**: fundamentally unrelated quant
   strategies crashed together because they shared **investors** forced to delever in tandem — not
   shared signals.
3. **Regime-conditional correlation.** Correlations rise sharply in high-vol regimes. A matrix
   estimated over a calm window systematically understates crisis correlation.

**The cheapest high-value check, and it is underused: compute strategy correlations split by
volatility regime** — correlation during the worst 5% of market-vol days vs the rest. If they spike
in the tail, no amount of unconditional-correlation math will show it.

Also: **audit liquidity/leverage overlap qualitatively.** Same venue, same collateral, same lending
counterparty? Then the tail dependency lives in the operational plumbing and backtest correlation is
irrelevant.

**Defense:** size on tail-dependence measures rather than Pearson correlation; add an explicit
**correlation-spike circuit breaker** — if realized cross-strategy correlation over a rolling 5–10 day
window jumps above baseline, de-risk across the board, because the diversification assumption has
just failed in real time. This is a *portfolio-level* trigger, distinct from any strategy-level one.

Accept that this is partially irreducible. Goal is faster detection and a pre-committed response,
not prevention.

## Regime detection — blunt assessment

**Mostly hindsight-fit. Do not give it veto power.**

- **HMM state labels are assigned after fitting, by a human looking at the output.** The model has no
  concept of "bear" — it finds statistically distinct clusters. Interpretability is retrofitted, which
  is exactly how hindsight bias enters: you tune state count, features, and window until the states
  "make sense" against history whose outcome you already know.
- **Detection is laggy by construction** — several observations of the new regime are needed before
  confident reclassification, so it confirms the change *after* a meaningful chunk of the move.
- State count and transition priors are free parameters fit on history — they overfit to the backtest
  window, and a novel regime is precisely when that matters.

**Volatility regime is the exception** — the one with the best reliability-to-complexity ratio,
because volatility clustering is among the most robustly replicated stylized facts in finance. It
needs no hidden-state inference: measure trailing realized vol, threshold it, scale exposure down in
the high decile. Actionable without claiming to know *why*.

Change-point detection: **CUSUM** is the most defensible method in this section precisely because it
claims only that *something changed*, not what. **BOCPD** — Adams & MacKay, arXiv:0710.3742 (2007),
verified — is more principled about uncertainty in *when*.

> **Design implication, and it validates the existing design:** do not add a standalone regime
> detector as an authority in the decision chain. Feed volatility regime as **one weak feature** into
> the meta-model over the experiment ledger, where a wrong regime read gets corrected by realized
> performance. BULL/BEAR agents + arbiter + promotion gate is already the robust form of
> regime adaptation; a dedicated HMM module dictating allocation is the fragile form.

## Strategy decay — the hardest live judgment

**A strategy in a normal drawdown and a strategy whose edge is gone produce statistically
indistinguishable P&L in the short-to-medium run.** A true Sharpe of 1.0 still yields losing weeks,
months, even quarters. This is a **fundamental signal-to-noise limit**, not a
solvable-with-cleverer-stats problem. Anyone claiming a crisp test is overselling.

What serious operations do, ranked:

1. **Monitor the MECHANISM, not the P&L.** If the edge is causally tied to something understood — a
   microstructure inefficiency, a cross-exchange latency gap — measure *that* directly: spread
   compression, opportunity frequency. Mechanism decay is far stronger and faster evidence than
   waiting for P&L significance. **Highest-value practice here, and it requires knowing why each
   strategy makes money, not just that it does.**
2. **Sequential tests, not repeated t-tests.** Re-running a fixed-window t-test daily on expanding
   data triggers constantly — the peeking problem. CUSUM-style sequential monitoring of Sharpe is
   built for exactly "watch continuously, tell me on real evidence, without inflating false positives."
3. **Graduated probation ladder, never a binary kill.** A binary kill on first significance
   systematically biases the surviving strategy pool toward the noise-lucky rather than the genuinely
   good. Throttle first; require sustained multi-window evidence to retire.
4. **The cost asymmetry is not stable.** False-negative cost scales with allocation — so throttling
   automatically shrinks the cost of being wrong while evidence accumulates. That is the real
   argument for the ladder.
5. **Design for being wrong.** You *will* kill good strategies and keep dead ones too long. Make that
   survivable — small per-branch allocation, capped downside — rather than pursuing perfect detection.
   Marginal value of a smarter kill statistic drops fast; marginal value of "no single failure hurts
   much" stays high.

## Risk measures

- **VaR alone is false comfort.** Says nothing about magnitude beyond the threshold, and is **not
  sub-additive** — a portfolio's VaR can exceed the sum of its parts', violating the basic intuition
  that diversification reduces risk (Artzner/Delbaen/Eber/Heath 1999, coherent risk measures).
- **CVaR / Expected Shortfall** — Rockafellar & Uryasev, *J. Risk* 2, 21–41 (2000), verified. Coherent,
  looks into the tail, and **convex — optimizable by LP**, which VaR is not. If you act on one tail
  number, use this. Implementations: `cvxpy`, `PyPortfolioOpt` `EfficientCVaR`, `riskfolio-lib`.
- **EVT / GPD tail fitting** — real and respected, **wrong data regime**. Needs many tail exceedances;
  at months-to-a-few-years of history you will not have them. Revisit much later.
- **Bootstrap the max-drawdown DISTRIBUTION** (block bootstrap to preserve autocorrelation) rather
  than quoting one realized worst case. A few dozen lines, cheap, directly actionable, **underused
  relative to its value** — and it is what makes circuit-breaker thresholds non-arbitrary.

## Circuit breakers — making thresholds defensible

Most industry thresholds are round numbers and committee judgment. Principled anchors:

1. **Anchor limits to the simulated drawdown distribution**, e.g. daily-loss limit = 1st percentile of
   simulated 1-day P&L. Traceable to an inspectable assumption rather than vibes.
2. **Graduated ladder** — e.g. −5% trailing → cut gross 25%; −10% → cut 50%; −15% → flat; each rung
   requiring short-window confirmation so a single bar cannot trip it.
3. **Make the ladder consistent with the Kelly fraction.** Sizing already encodes an implicit claim
   about tolerable drawdown. **Sizing that implies 15% drawdowns are routine, paired with a kill
   switch at 10%, is a design bug** — the breaker will trip on strategies behaving exactly as
   designed. Check for this explicitly.
4. **Correlation-breakdown trigger as a separate, faster portfolio-level breaker** — it fires on a
   leading structural signal rather than a lagging realized loss.
5. **Log every trigger, true and false, in the same experiment ledger.** Calibration of the breaker is
   itself subject to empirical tracking.

## Don't bother — consolidated

Full MVO · Black-Litterman · full HRP with tuned clustering · EVT tail fitting (for now) · a
standalone regime detector with decision authority · a single binary drawdown kill switch instead of
a ladder.

## Verified vs from-training

**Verified this session:** López de Prado HRP (JPM 2016) · Adams & MacKay BOCPD (arXiv:0710.3742) ·
Rockafellar & Uryasev CVaR (J. Risk 2000) · MacLean/Thorp/Ziemba Kelly volume · HRP's contested
standing.

**From training, high confidence, not re-verified:** Kelly (1956) · Michaud (1989) error-maximization
· Hamilton (1989) regime-switching · Chekhlov/Uryasev/Zabarankin CDaR · Artzner et al. (1999) ·
the `f(2-f)` growth relation as textbook-standard.

**Flagged UNVERIFIED inline:** HRP clustering-instability critique (practitioner commentary) ·
"academic HMM regime backtests are broadly unimpressive" (widely shared view, no single meta-analysis)
· volatility-targeting as dominant practice (industry standard, no primary source re-checked).
