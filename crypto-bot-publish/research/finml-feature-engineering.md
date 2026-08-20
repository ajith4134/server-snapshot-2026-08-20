# Feature engineering for financial ML: what survives out-of-sample

Provenance: researched by Claude Sonnet 5 subagent, 2026-08-01, via WebSearch/WebFetch.
Part of parallel-research sweep: "Which ML/DL methods actually work in live trading."

## 1. Fractional differentiation (Lopez de Prado, *Advances in Financial Machine
Learning*, Wiley 2018, Ch. 5)

**Why naive differencing destroys signal — the specific argument, not generic intuition:**
The claim is about *memory*, not just "returns lose information." A price series is
non-stationary because each value depends on a long, unbounded history of prior levels
(unit root / long memory process). Integer differencing (returns = P_t - P_{t-1}, or
log-returns) is a d=1 operation that removes ALL memory beyond a one-period lookback — it
achieves stationarity by discarding the entire history, not just the non-stationary
component of it. Stationarity and memory are not a binary opposition; they're a continuum
indexed by a real-valued differencing order d in [0,1], and integer differencing (d=1) is
a blunt, maximal choice that overshoots what's needed for stationarity, throwing away
memory the ML model could have used as signal (mean-reversion levels, long-run trend info).

**The method:** generalizes the binomial-series expansion of the difference operator
(1-L)^d to non-integer d, producing a weighted sum of all past values with weights that
decay but never exactly vanish (true fracdiff), or truncated once weights drop below a
threshold — the Fixed-Width Window (FFD) variant recommended in practice (avoids the
infinite-length weight vector, computationally tractable). Binary-search/sweep d to find
the MINIMUM d such that the resulting series passes an ADF (Augmented Dickey-Fuller)
stationarity test — smallest d that achieves stationarity while preserving maximum memory
(maximum correlation with the original series).

**Library implementations:**
- **`fracdiff`** on PyPI (`pip install fracdiff`, GitHub `fracdiff/fracdiff`) — confirmed
  real, BSD-3-Clause, maintained by GitHub user `simaki` (real-name identity UNVERIFIED —
  do not assert a real name in code comments). Confirmed API: `fracdiff.fdiff()` (extends
  numpy.diff/torch.diff to fractional order), `fracdiff.Fracdiff` (scikit-learn
  transformer), `fracdiff.FracdiffStat` (Fracdiff + automatic search for minimum
  stationarity-inducing d), plus `fracdiff.torch.fdiff`/`fracdiff.torch.Fracdiff` for
  PyTorch. Vectorized, fast, the practical open-source option. **Recommended for
  production.**
- **`mlfinlab`** (`hudson-and-thames/mlfinlab`) — IMPORTANT: the public GitHub repo is NOT
  usable open source. `mlfinlab/features/fracdiff.py` fetched directly — every function
  body is a bare `pass`, a stub kept only for signature/docstring reference. Per the
  repo's README and a 2020 maintainer comment (GitHub issue #443), Hudson & Thames moved
  to an "open-core" model: real implementations ship only via a paid subscription wheel
  (`hudson-and-thames-clients` private repo), and per a 2024 issue thread (#541) users
  were hitting 404s even on the paid install path. License is "all rights reserved" —
  explicitly not open source. **Do not plan on `pip install mlfinlab` giving working code
  for free.** Documented (stub-confirmed) signatures matching Ch. 5's pseudocode exactly:
  `FractionalDifferentiation.frac_diff_ffd(series, diff_amt, thresh=1e-5)`,
  `.frac_diff(series, diff_amt, thresh=0.01)`, `.get_weights_ffd(diff_amt, thresh, lim)`,
  `.get_weights(diff_amt, size)`, module-level `plot_min_ffd(series)` — names are real,
  paid-package internals unverifiable.
- **`mlfinpy`** (PyPI `mlfinpy`, GitHub `baobach/mlfinpy`) — free, independent open-source
  reimplementation of mlfinlab's API surface. Confirmed path:
  `mlfinpy.util.frac_diff.frac_diff_ffd(series, diff_amt, thresh=1e-5)` and
  `mlfinpy.util.frac_diff.plot_min_ffd(series)`. Likely best free mlfinlab-compatible
  option — correctness/test coverage NOT independently verified, only that the API exists.

## 2. Triple-barrier labeling and meta-labeling (same book, Ch. 3)

**Problem solved:** naive fixed-horizon labeling (label = sign of return over next k bars)
ignores path — can label a trade "profitable" even though it breached the actual stop-loss
mid-window, and ignores that volatility (hence appropriate holding time/target sizing)
varies over time, so fixed k is too short in high-vol regimes or too long in low-vol ones.
Triple-barrier labeling sets three barriers — profit-take, stop-loss, max holding period —
scaled to a rolling volatility estimate, labels by whichever barrier is touched first.
Produces labels reflecting actual realizable trade outcomes under real risk management.
Meta-labeling adds a secondary model that only decides bet size/whether to act on a
primary model's directional call — reframes the problem as "was the primary signal right"
(precision-focused binary classification) rather than predicting direction from scratch,
decoupling recall (primary model, cast wide net) from precision (secondary model, filter
false positives) — improves Sharpe/Calmar/drawdown even without improving raw hit rate.

**Independent evidence — weaker than it first looks.** Four peer-reviewed papers in
*Journal of Financial Data Science* extending meta-labeling, none with Lopez de Prado as
co-author:
- Joubert, J.F. (2022), "Meta-Labeling: Theory and Framework," JFDS 4(3), 31.
- Meyer, Joubert, Alfeus (2022), "Model Architectures," JFDS Fall 2022.
- Meyer, Barziy, Joubert (2023), "Calibration and Position Sizing," JFDS Spring 2023.
- Thumm, Barucca, Joubert (2022), "Ensemble Meta-Labeling," JFDS Winter 2022 (Barucca is
  UCL faculty — the most independent name here).

BUT all four are from **Hudson & Thames**, the commercial entity productizing Lopez de
Prado's book into `mlfinlab` — "independent of Lopez de Prado personally" (true) is not
the same as "independent of the ecosystem with a commercial incentive to validate the
technique." No validation found from research groups with no connection to that ecosystem.
The often-cited headline numbers (meta-labeling lifting accuracy 20%->77% in validation,
17%->63% OOS) come from a **Hudson & Thames blog post**, not a peer-reviewed paper — a
single case study on S&P 500 E-mini futures with Bollinger Band/trend-following primary
models. Treat triple-barrier/meta-labeling as a sound methodological fix to a real
labeling flaw (basically definitional), but treat the MAGNITUDE of improvement as
evidence from an interested party, not an independently replicated result.

## 3. Feature families with credible documented edge

**Most credible:**
- **Volatility-based features** (realized volatility, GARCH-family, HAR-RV): Corsi, F.
  (2009), "A Simple Approximate Long-Memory Model of Realized Volatility," *Journal of
  Financial Econometrics* 7(2), 174-196 — seminal HAR-RV paper, confirmed. Recent
  crypto-specific studies (MDPI *Risks* 2023, MDPI *Economies* 2026) found HAR models on
  realized variance from high-frequency data generally beat GARCH-family for short-term
  crypto volatility forecasting OOS, no single model dominating universally. Volatility is
  the most consistently useful, least controversial feature family in this literature.
- **Order flow imbalance (OFI)** at microstructure level: Cont, Kukanov, Stoikov (2014),
  "The Price Impact of Order Book Events," *Journal of Financial Econometrics* 12(1),
  47-88, DOI 10.1093/jjfinec/nbt003 — robust linear relationship between OFI (imbalance
  of order flow at best bid/ask) and short-horizon price changes, stable across 50 NYSE
  stocks, time scales, controlling for intraday seasonality. One of the most
  independently-replicated microstructure findings.
- **Cross-sectional/relative features**: momentum/reversal literature (Jegadeesh-Titman
  style) is long-established outside this search pass — credible by broad academic
  consensus, though not re-verified with a live citation this session.

**Widely criticized as noise-mined — permission to say this plainly:** the
technical-indicator zoo (RSI/MACD/Bollinger and combinatorial variants, chart-pattern
recognition) has a strong critical literature, not just informal skepticism:
- Sullivan, Timmermann, White (1999), "Data-Snooping, Technical Trading Rule Performance,
  and the Bootstrap," *Journal of Finance* 54(5), 1647-1691, DOI 10.1111/0022-1082.00163.
  Tested 7,846 technical trading rules on 100 years of Dow Jones data using White's
  Reality Check bootstrap to correct for data-snooping bias; the best rule looked good
  in-sample but **failed to outperform in the subsequent 10-year out-of-sample period** —
  direct quantitative demonstration that mining a large indicator/rule universe produces
  results that don't survive OOS once corrected for having searched thousands of rules.
- Park, Irwin (2007), "What Do We Know About the Profitability of Technical Analysis?,"
  *Journal of Economic Surveys* 21(4), 786-826, DOI 10.1111/j.1467-6419.2007.00519.x.
  Survey of 95 "modern" studies: 56 positive, 20 negative, 19 mixed — concludes most
  positive results are compromised by data-snooping, ex post rule selection, inadequate
  transaction-cost/risk accounting; calls for more rigorous testing.

Together, about as close as this literature gets to a documented indictment of "build a
library of 200 technical indicators and let the model find signal": base rate of false
discovery from a large, correlated indicator zoo is high, and the one study that
specifically corrected for that bias found the apparent edge vanished OOS. A secondary,
lower-confidence source suggested RSI/Bollinger/EMA contribute only 14-18% to model
decisions without improving OOS accuracy — flagged as suggestive only, not as strong as
the two peer-reviewed papers above.

**Honest read:** don't build a large technical-indicator library. Volatility (realized
vol/HAR-RV/GARCH residuals) and order-flow/microstructure imbalance have the most
credible, independently-replicated OOS evidence. Cross-sectional/relative features rest
on a broad, generally credible separate literature. RSI/MACD/Bollinger/chart-pattern
combinatorial zoo is the weakest, most-criticized part of feature engineering once
data-snooping is corrected for.

## 4. Crypto/microstructure OFI specifically

- Cont/Kukanov/Stoikov (2014) is equities/NYSE, not crypto — cite for methodology/
  mechanism (linear OFI -> price impact, robust across assets/timescales), not as direct
  crypto evidence.
- Crypto-specific: Anastasopoulos, Gradojevic, Liu, Maynard, Tsiakas, "Order Flow and
  Cryptocurrency Returns," *Journal of Financial Markets*, online 15 Jan 2026, DOI
  10.1016/j.finmar.2026.101047 (SSRN working paper posted Nov 2024). Important nuance:
  this paper's "order flow" is **international FX order flow across 11 major currencies**
  predicting the cross-section of crypto returns at daily/weekly horizons via nonlinear
  ML — NOT exchange-level limit-order-book imbalance at tick/microstructure level like
  Cont-Kukanov-Stoikov. Found genuine OOS predictive power, dominates fundamentals-based
  benchmarks, but it's a macro/cross-asset signal, not a high-frequency microstructure
  one. Don't conflate the two.
- For genuine tick-level LOB imbalance in crypto (bid/ask queue imbalance, trade-flow
  imbalance): search hints of relevant work (a Springer paper on Hawkes-process BTC
  return-sign forecasting from LOB data; an arXiv paper on cross-asset stability of
  engineered LOB features across BTC/LTC/ETC/ENJ/ROSE) were found but NOT fetched/verified
  — flagged UNVERIFIED, worth a dedicated follow-up pass if tick-level crypto OFI is the
  actual target.

---

## VERIFIED
- Lopez de Prado, *Advances in Financial Machine Learning*, Wiley 2018 — Ch. 5 fracdiff,
  Ch. 3 triple-barrier/meta-labeling. Core argument confirmed via multiple secondary
  sources plus the book's own TOC.
- Cont, Kukanov, Stoikov (2014), JFE 12(1), 47-88, DOI 10.1093/jjfinec/nbt003.
- Sullivan, Timmermann, White (1999), Journal of Finance 54(5), 1647-1691, DOI
  10.1111/0022-1082.00163.
- Park, Irwin (2007), Journal of Economic Surveys 21(4), 786-826, DOI
  10.1111/j.1467-6419.2007.00519.x.
- Corsi (2009), Journal of Financial Econometrics 7(2), 174-196, DOI
  10.1093/jjfinec/nbp001.
- Anastasopoulos, Gradojevic, Liu, Maynard, Tsiakas, Journal of Financial Markets (2026),
  DOI 10.1016/j.finmar.2026.101047.
- `fracdiff` PyPI package: real, BSD-3-Clause, API = `fdiff()`, `Fracdiff`,
  `FracdiffStat` (+ `torch.fdiff`/`torch.Fracdiff`). Maintainer GitHub handle `simaki`.
- `mlfinlab` public repo is stub-only (`pass` bodies), "all rights reserved" license, real
  code gated behind a paid wheel that itself 404'd in a 2024 issue thread — do not plan
  production code around free `pip install mlfinlab`.
- `mlfinpy` reimplements the same API:
  `mlfinpy.util.frac_diff.frac_diff_ffd(series, diff_amt, thresh=1e-5)`.
- JFDS meta-labeling papers exist, peer-reviewed, no Lopez de Prado authorship — but all
  Hudson & Thames-affiliated, not an unconnected research group.

## UNVERIFIED
- "Yuya Takahashi" as `fracdiff`'s author's real name — GitHub only exposes handle
  `simaki`; do not put this name in code comments as fact.
- Exact correctness/test-coverage of `mlfinpy`'s reimplementation — API signature
  confirmed, output-matches-reference-algorithm not confirmed.
- "RSI/Bollinger/EMA contribute only 14-18%" claim — lower-tier secondary aggregation,
  not a paper read directly; suggestive, not load-bearing.
- Tick-level crypto LOB-imbalance papers (Hawkes-process BTC forecasting; cross-asset LOB
  feature stability BTC/LTC/ETC/ENJ/ROSE) — titles surfaced in search, not fetched/read;
  citations and findings unconfirmed.
- General cross-sectional/momentum literature credibility — asserted from background
  knowledge, not re-verified with a live citation this session (search budget exhausted).
