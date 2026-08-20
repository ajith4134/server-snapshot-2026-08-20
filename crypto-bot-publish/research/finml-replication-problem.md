# The replication problem in financial ML / quant finance

Provenance: researched by Claude Sonnet 5 subagent, 2026-08-01, via WebSearch/WebFetch.
Part of parallel-research sweep: "Which ML/DL methods actually work in live trading."

## 1. Quantifiable replication/decay rates

**Hou, Xue, Zhang — "Replicating Anomalies"** (*Review of Financial Studies* 33(5), May
2020, pp. 2019-2133; NBER WP 23394; SSRN 2961979)

- Compiled 447 anomaly variables from the literature, re-tested using NYSE breakpoints
  (not all-exchange) and value-weighted (not equal-weighted) returns — corrections aimed
  at prior studies' distortion by tiny illiquid microcaps.
- Commonly cited result: roughly 64% of anomalies become statistically insignificant at
  conventional t>1.96, rising to ~85% at a stricter t>3 threshold; liquidity anomalies
  fared worst (~93-96% insignificant). NOTE: these specific percentages came from
  AI-assisted extraction of the NBER abstract page, not a personal read of the full RFS
  text — treat exact digits as likely-correct-but-not-independently-verified. The
  qualitative finding (majority fail under stricter methodology) is well corroborated.
- Explicit critique of prior literature: "infested with widespread p-hacking," over-reliant
  on equal-weighted returns/microcaps. Headline conclusion: "capital markets are more
  efficient than previously recognized."

**McLean & Pontiff — "Does Academic Research Destroy Stock Return Predictability?"**
(*Journal of Finance* 71(1), 2016, pp. 5-32; DOI 10.1111/jofi.12365)

- 97 characteristics previously shown to predict cross-sectional stock returns.
- Findings (via secondary sources, paywalled primary not read directly): returns ~26%
  lower out-of-sample (pre-publication, proxy for pure data-mining bias), ~58% lower
  post-publication. The ~32-point gap attributed to publication-informed trading — real
  capital arbitraging the effect away once known.
- Decay larger for predictors with higher in-sample returns and for anomalies in
  illiquid/high-idiosyncratic-risk stocks (limits to arbitrage).

**No single consensus "replication rate" number.** Two competing frameworks bracket the
honest answer:
- **Harvey, Liu, Zhu — "…and the Cross-Section of Expected Returns"** (RFS 29(1), 2016,
  pp. 5-68; NBER WP 20592). Given hundreds of tested factors, argues conventional t>2.0
  is far too lenient; proposes t>3.0. Implies most claimed findings are statistically
  indistinguishable from false positives under the old threshold.
- **Chen (Federal Reserve Board) — "Most Claimed Statistical Findings in Cross-Sectional
  Return Predictability Are Likely True"** (arXiv 2206.15365; SSRN 3912915; forthcoming
  *Journal of Finance: Insights*). Directly rebuts Harvey-Liu-Zhu, applying false-discovery-
  rate estimators to the Chen-Zimmermann dataset of 205 predictors: at least 75%, tightest
  bound at least 91%, of published findings are likely true (non-null). Argues
  Harvey-Liu-Zhu conflate "insignificant under a stricter hurdle" with "false."

**Honest working heuristic** (no single number exists): expect published return-
predictability effects to shrink by roughly a quarter out-of-sample and by more than half
once public/tradeable; expect a substantial minority-to-majority of individually tested
anomalies to fail a stricter significance bar. Do not quote one precise percentage as "the"
replication rate — the field disagrees on how to compute it.

## 2. Lopez de Prado's backtest-overfitting critique

**Bailey, Borwein, Lopez de Prado, Zhu — "The Probability of Backtest Overfitting"**
(*Journal of Computational Finance* 20(4), 2017, pp. 39-70, DOI 10.21314/JCF.2016.322;
SSRN 2326253, first posted 2013 — publication dating is inconsistent across sources,
2015/2016/2017 all appear; treat as the same paper with an unusually long lag).

- This is a **methodology paper**, not an empirical industry survey. Proposes
  combinatorially symmetric cross-validation (CSCV) to estimate Probability of Backtest
  Overfitting (PBO) for a given backtest, demonstrated via simulation. It does **not**
  contain a rigorous empirical claim like "X% of industry funds have overfit backtests" —
  the contribution is the tool, not a headline industry statistic.
- Stronger claims ("most discoveries in finance are likely false," "the majority of
  investment strategies promoted by academics and quantitative practitioners are false")
  come from Lopez de Prado's public commentary/interviews, not peer-reviewed empirical
  estimates. Confirmed direct quotes from a Forbes interview (Steenbarger, "The Growing
  Crisis In Modern Finance," May 25, 2018) — framed as logical implications of the
  multiple-testing/selection-bias problem, not citations to an empirical audit of fund
  performance. He also calls the pattern "scientific fraud" enabled by finance's lack of
  a "laboratory" for independent replication.
- **Evidentiary basis, plainly stated**: the mathematical argument for why extensive
  unadjusted backtesting must generate false positives (multiple-comparisons logic) is
  rigorous, well-established statistics. The magnitude claims about industry-wide impact
  are his professional opinion, not backed by an empirical census of hedge fund backtests
  — no such census exists in the public literature (fund backtest data is proprietary).

## 3. Deflated Sharpe Ratio

**Bailey & Lopez de Prado — "The Deflated Sharpe Ratio: Correcting for Selection Bias,
Backtest Overfitting and Non-Normality"** (*Journal of Portfolio Management* 40(5), 2014,
pp. 94-107; SSRN 2460551).

Corrects the classical Sharpe ratio significance test for: (1) selection bias under
multiple testing — picking the best of N trials upward-biases the "winner's" Sharpe purely
from the selection process (winner's curse); (2) non-normality — skewness/kurtosis break
the standard Sharpe-to-normal-distribution mapping. Mechanically: compares observed Sharpe
against an expected maximum Sharpe (SR0) that would arise by chance from N trials given
their Sharpe-ratio variance, converts the gap to a normal-CDF probability, adjusted for
skewness/kurtosis/sample length T. Practical purpose: raw backtested Sharpe ratios after
searching many parameter/strategy variants are near-meaningless without this correction.

## 4. Data-snooping / reality-check literature

- **White — "A Reality Check for Data Snooping"** (*Econometrica* 68(5), Sept 2000,
  pp. 1097-1126). "White's Reality Check" — bootstrap test for whether the *best* of many
  candidate models/trading rules genuinely beats a benchmark, correcting for multiple
  comparisons. Foundational data-snooping-bias test in empirical finance.
- **Hansen — "A Test for Superior Predictive Ability"** (*Journal of Business & Economic
  Statistics* 23(4), 2005, pp. 365-380). Refinement of White's test — Hansen's SPA test is
  more powerful/less conservative because it better handles poor/irrelevant models in the
  comparison set (White's version loses power when many bad alternatives are included).
- **Relevance**: both answer "did my best backtested strategy actually beat a benchmark, or
  did I just get lucky after trying enough variants?" — the same failure mode PBO/DSR
  target from a different angle. Any pipeline doing parameter sweeps, walk-forward
  optimization, or multi-signal search should run some multiple-testing correction
  (Reality Check, SPA test, DSR, or PBO/CSCV) rather than reporting the single best
  backtest's raw Sharpe.

## 5. Documented cases of famous results failing in practice

- **Bollen, Mao, Zeng — "Twitter mood predicts the stock market"** (*Journal of
  Computational Science* 2(1), 2011; arXiv 1010.3003). Claimed 86.7% directional accuracy
  predicting DJIA moves from Twitter mood (GPOMS "Calm" dimension) via Granger causality +
  neural network. 2,500+ citations within 6 years. Directly spawned **Derwent Capital
  Markets**, a real hedge fund launched 2011 trading the signal, raised tens of millions,
  **shut down within about a year (2012)**, auctioned assets for ~£120k against a ~£350k
  break-even. Formal non-replication: **Lachanski, "Shy of the Character Limit: 'Twitter
  Mood Predicts the Stock Market' Revisited"** (*Econ Journal Watch* 14(3), 2017) — effect
  did not replicate on extended sample, consistent with data snooping, no out-of-sample
  predictive power. A Stanford CS class (under Andrew Ng, 2011) had multiple student teams
  attempt replication; none matched original accuracy, most well below 70-80%. About as
  clean a "published financial-ML result -> real capital -> fund failure -> formal
  non-replication" chain as exists.
- **Khandani & Lo — "What Happened to the Quants in August 2007?"** (*Journal of
  Investment Management* 5(4), 2007, pp. 5-54; extended in *Journal of Financial Markets*
  14(1), 2011, pp. 1-46). Not a replication failure per se — a documented case of crowded,
  similarly-constructed quant equity market-neutral strategies (value/contrarian factors)
  simultaneously blowing up during the week of Aug 6, 2007 (Goldman's quant desk reported
  "25-standard-deviation moves, several days in a row"). "Unwind Hypothesis": forced
  liquidation by one or more large funds triggered a deleveraging cascade across funds
  running correlated factor strategies. Relevant to crypto: individually-robust-looking
  backtests failed together live because backtests didn't model crowding — a structural
  blind spot distinct from pure overfitting, and directly relevant given how correlated
  many public/quant crypto strategies already are.
- Minor/illustrative: several retracted DL stock-prediction papers exist (e.g. Zhao, Lei,
  Zhao, *Frontiers in Energy Research* 2024, retracted 2025; Xu, Zhang, Wang, *Soft
  Computing* 2020, retracted 2022) — not landmark cases, just evidence low-quality
  financial-ML papers get published and retracted.
- **LLM-era lookahead bias** (2023-2026, arXiv): Glasserman & Lin, "Assessing Look-Ahead
  Bias in Stock Return Predictions Derived from Large Language Models" (2023, arXiv
  2309.17322), and later "Lookahead Propensity" papers — LLMs trained on historical text
  can "know" outcomes within their training window, contaminating backtests evaluated on
  dates inside that window. Not yet a famous failure in the LTCM/Derwent sense, but
  directly relevant if the trading system uses any LLM-based signal — an emerging,
  not-yet-fully-solved trap specific to financial ML with LLMs.

---

## VERIFIED
- Hou, Xue, Zhang, "Replicating Anomalies," RFS 33(5), 2019-2133 (2020) — citation and
  core qualitative finding confirmed via NBER/SSRN.
- McLean & Pontiff, "Does Academic Research Destroy Stock Return Predictability?," JoF
  71(1), 5-32 (2016) — citation confirmed via Wiley DOI; core finding confirmed via
  multiple secondary summaries (paywalled primary not read directly).
- Bailey, Borwein, Lopez de Prado, Zhu, "The Probability of Backtest Overfitting," JCF
  20(4), 39-70 — abstract fetched from SSRN; confirmed methodology (CSCV) paper, not an
  empirical industry survey.
- Bailey & Lopez de Prado, "The Deflated Sharpe Ratio...," JPM 40(5), 94-107 (2014) —
  citation and mechanism confirmed.
- White, "A Reality Check for Data Snooping," Econometrica 68(5), 1097-1126 (2000).
- Hansen, "A Test for Superior Predictive Ability," JBES 23(4), 365-380 (2005).
- Harvey, Liu, Zhu, "...and the Cross-Section of Expected Returns," RFS 29(1), 5-68 (2016)
  — t>3.0 hurdle claim confirmed.
- Chen, "Most Claimed Statistical Findings in Cross-Sectional Return Predictability Are
  Likely True," arXiv 2206.15365 — 75%/91% FDR bound figures and rebuttal confirmed.
- Bollen, Mao, Zeng, "Twitter mood predicts the stock market," JCS 2(1) (2011) — abstract
  fetched directly (arXiv 1010.3003); 86.7% accuracy confirmed from primary abstract.
- Lachanski, "Shy of the Character Limit..." Econ Journal Watch 14(3) (2017) —
  non-replication finding confirmed via the paper's own abstract.
- Derwent Capital Markets' 2011 launch / 2012 closure — confirmed via news coverage.
- Khandani & Lo, "What Happened to the Quants in August 2007?" — confirmed via NBER/SSRN
  and direct PDF fetch.
- Lopez de Prado's direct quotes on false-discovery prevalence — confirmed via direct
  fetch of the Forbes interview; confirmed these are opinion/logical-implication framing,
  not citations to an empirical audit.

## UNVERIFIED
- Exact 64%/85%/93% Hou-Xue-Zhang figures — from AI-assisted extraction of the NBER
  abstract page, not personally line-checked against RFS tables.
- Exact 26%/58% McLean-Pontiff decay figures — from search-result summaries of a paywalled
  paper, not read directly.
- Any specific numeric industry-overfitting claim from Lopez de Prado's *Advances in
  Financial Machine Learning* (2018) book itself, as opposed to interviews — could not
  locate one; this quantity may simply not exist in citable form.
- Whether any rigorous, data-backed (not opinion-based) estimate exists of what fraction
  of real live quant funds' backtests are overfit — none found; likely genuinely
  unmeasured/unmeasurable given proprietary fund data. Do not treat any single-number
  claim about this as empirically established.
- Exact publication-date lineage of the PBO paper — inconsistent across sources (2013
  SSRN post, "2015 forthcoming," 2016 DOI stamp, 2017 print) — reporting the inconsistency
  rather than resolving it.
