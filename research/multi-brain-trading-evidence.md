# Does splitting a trading decision across specialised models work?

**Researched 2026-08-19** under RL-045. Primary-source fetches (arXiv PDFs, SSRN, Hudson &
Thames, QuantConnect). WebSearch quota exhausted mid-session; last lookups on Exa.

> **The agent caught itself fabricating.** Its first-pass WebFetch summary of TradeTrap
> (arXiv:2512.02261) described it as a backtest-bias paper. Re-fetching the primary abstract
> showed it is an adversarial-security paper — perturbation, tool hijacking, memory poisoning.
> The summary was wrong. This is a live instance of the standing finding that summarizers
> drop and fabricate, caught only because the agent re-read the source.

## 1. Meta-labelling — thin, and the one independent test is negative

- **Hudson & Thames** (Joubert et al.) report gains: S&P 500 E-mini 2018-19, mean-reversion
  accuracy 17%→63%, trend-following 48%→55%. **NOT INDEPENDENT** — Hudson & Thames is the
  commercial entity built around Lopez de Prado's own methods (`mlfinlab`). The originating
  ecosystem grading its own idea. Their own caveat: *"meta-labeling also needs a good primary
  algorithm... if the algorithm is bad, meta-labeling would likely only reduce the downside."*
- **Baldisserri**, "Why Meta-Labeling Is Not a Silver Bullet" (QuantConnect, practitioner, not
  peer-reviewed) — **the closest thing to an independent replication, and it disagrees.**
  Grid-search across seeds: meta-labelled cascades produced **lower average Sharpe** than the
  single model, wider variance. The structural argument matters more than the numbers:
  *"There is no logical reason for which the meta model should find more information in the
  data than the main one."* A secondary model on the same feature space cannot extract signal
  the primary missed — only re-weight what is already there. Plus an infinite-regress
  objection: if cascading added information you could stack it indefinitely; nobody does.
  His concession: it may help a **discretionary** primary (a human is not an end-to-end model
  on the same data). **That is not our case — our primary is also a trained model.**
- Failure modes converging across sources: inherited bias (too few true positives in a regime
  for the secondary to learn from); precision-recall mismanagement (ROC thresholds unreliable
  under the imbalance meta-labelling creates); degenerate collapse to a majority-class trivial
  classifier where precision/recall/F1 go to zero while **accuracy rises**.
- **No literature tests meta-labelling under CPCV + purging + embargo** — everything uses
  simpler walk-forward or single-split. Even the positive results may not survive our setup.

## 2. Separate long-model / short-model — the literature does not exist

Multiple searches, web and Exa. Found only: long/short as a *strategy category* (not an
architecture), and papers on long/short **return asymmetry** (short-selling costs, borrow
constraints, anomalies not surviving short fees — relevant context, silent on the design).

**No paper studies whether separately-trained long/short specialists collapse into mirror
images, or compares that design against one signed model. "The literature is weak" IS the
finding.**

Reasoning from adjacent material: two LightGBM models on largely the same feature set have
**no architectural reason for their decision boundaries to diverge** — a feature predicting
"up" predicts "not down" almost as strongly on the same data, especially through overlapping
triple-barrier events. Mirror-image collapse is the mechanically expected outcome unless
something *forces* asymmetry (different losses, different feature subsets, different
negative-example construction).

**Coordination Primacy Hypothesis** (Nguyen & Pham, arXiv:2603.27539, **unreviewed preprint,
both authors h-index 0 — weight accordingly**): inter-agent coordination protocol design is a
primary driver of decision quality, *often exceeding the quality of the individual agents*.
The authors explicitly present this as **unvalidated and falsifiable**, stating definitive
validation "requires evaluation infrastructure that does not yet exist." A named hypothesis
that the arbitration layer becomes the real model — honest enough to say it is unproven.

## 3. Exit as its own model — no rigorous evidence either way

Practitioner blog content only (unverified, marketing-adjacent); an options-specific academic
paper whose results could not be fetched; quantile regression appearing mainly in LOB
microstructure and distributional RL — methodologically close to our PROFIT-TAIL but about
*how* to build a quantile model, not whether a dedicated exit model beats a fixed rule.

**Nobody has published fixed-rule vs joint-model vs dedicated-exit-model on the same data with
costs.** A genuine literature gap. The defensible argument is mechanistic, not empirical:
post-fill position management is a different prediction target (forward P&L distribution
conditional on being in the trade) from entry (should we take this at all), so there is no a
priori reason one model is well-calibrated for both.

## 4. LLM multi-agent trading — harshly negative once methodology is corrected

**FINSABER** (Li, Kim, Cucuringu, Ma; arXiv:2505.07078; **accepted KDD 2026 Datasets &
Benchmarks, Oral — the one real peer-reviewed venue in this set, weight it highest**). Built
to fix survivorship bias (includes delisted constituents), look-ahead, and data-snooping:
rolling windows, 20+ years, 100+ symbols instead of months on a handful of megacaps.

- Over the original papers' short windows, FinMem looked strong (Sharpe ~0.93 on TSLA).
- Extended to 2004-2024: **buy-and-hold beats FinMem and FinAgent on most slices.**
  Random-five composite Sharpe **0.315 buy-and-hold vs −0.253 FinMem**; momentum slice 0.542
  (ARIMA) vs 0.025; volatility slice 0.703 vs −0.228.
- Regime asymmetry: too conservative in bull markets (0.12 vs 0.61), **too aggressive in bear
  markets (−0.38 vs −0.97 — they lose MORE when it counts).**
- **Paired t-tests: no statistically significant alpha, all p > 0.34.**

**TradingAgents** (arXiv:2412.20138) — bull/bear researcher agents, risk team. Backtested
**3 months on five megacap tech names.** Close to worst-case for generalisability: short,
cherry-pickable, and the stocks where LLM training corpora are richest (maximising
memorisation risk).

**Look-Ahead-Bench** (Benhenda, arXiv:2601.13770) confirms the mechanism: LLMs trained on
web-scale corpora containing post-hoc narratives ("NVIDIA surged 190% in 2023 on AI boom")
recite memorised outcomes rather than learning predictive relationships. **Effect size
UNVERIFIED** — PDF numerics did not render. Note the author co-wrote FinRL-DeepSeek, so not
a disinterested outsider.

**UNVERIFIED and flagged**: a widely-repeated claim that FinMem's 23.26% cumulative return on
MSFT became −22.04% under a different defensible window with costs. Only from a secondary AI
summary; could not be re-verified before quota ran out. Plausible given FINSABER's
independently documented sign reversals, but do not cite it.

## Cross-cutting judgment

- **Meta-labelling**: thin and contested in its home literature; the one independent test says
  it does not beat a well-trained single model. Where it plausibly helps is sizing a signal
  that cannot size itself — a discretionary primary. Not our case.
- **Bull/bear split**: no direct evidence either way. Mechanically, expect **redundancy, not
  independence**, absent forced asymmetry.
- **Exit-as-own-model**: mechanistically defensible, empirically untested.
- **LLM multi-agent**: mostly decoration. Elaborate bull/bear/risk-committee framing, no
  significant alpha once biases are fixed.

**The common thread, and it applies to our fixed architecture:** adding structure creates more
places for a backtest to look good for reasons unrelated to edge — and the rigour investment
(CPCV, purging, embargo) goes into the individual models, **never into the arbitration layer
between them.** Both FINSABER and the CPH hypothesis point at the same place.

## The single most likely pathology of OUR design

**BULL and BEAR converge into anti-correlated mirror images of one underlying signal** —
shared features, shared triple-barrier regime, no forced asymmetry — so the "specialisation"
is cosmetic, and the real discriminating work *and the real overfitting* concentrate in the
selection step, which is the part of the pipeline getting the least CPCV-grade validation.

### Four concrete tests against our own journals

1. **Mirror-image check.** Correlate `bull_score` against `bear_score` **conditioned on
   instrument and volatility regime** — a pooled correlation near −1 could be a labelling
   artefact. Strong negative correlation *within* narrow buckets is the collapse signature.
2. **Feature-attribution check.** Compare SHAP / gain importance for BULL vs BEAR. Near-
   identical top-N with flipped sign means one model with the target relabelled.
3. **Variance decomposition on the decision.** Regress the realised decision against (a)
   `bull_score − bear_score` and (b) selection-step-only variables. If (b) dominates, the
   selection layer is the real model — undocumented and under-tested.
4. **Veto-independence on PROFIT-TAIL.** If veto rate correlates more with market-wide
   volatility than with trade-specific expectancy, it is a blunt regime filter wearing the
   appearance of a per-trade risk model.
