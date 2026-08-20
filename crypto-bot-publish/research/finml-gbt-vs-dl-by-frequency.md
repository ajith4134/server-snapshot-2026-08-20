# GBT vs deep learning by frequency band — empirical evidence

Provenance: researched by Claude Sonnet 5 subagent, 2026-08-01, via WebSearch/Exa/WebFetch
(native WebSearch quota exhausted mid-session, later citations lean on Exa). Part of
parallel-research sweep: "Which ML/DL methods actually work in live trading."

## 1. Gu, Kelly, Xiu (2020), "Empirical Asset Pricing via Machine Learning," Review of
Financial Studies 33(5):2223-2273

Models compared: OLS(+Huber)/OLS-3, PLS, PCR, Elastic Net, GLM w/ splines, Random Forest,
GBRT, and NN1-NN5 (1-5 hidden layers), on monthly individual US stock return prediction
(OOS R^2, 1987-2016 test period).

Finding: NN3 (3 hidden layers) achieved the highest monthly R^2_oos at 0.40%, edging out
GBRT at 0.34%. Random forest close to GBRT. NN performance peaks at 3 layers and degrades
at NN4/NN5 — deeper is not better here. All tree/NN methods vastly outperformed linear
methods (OLS-3 ~0.16%, PLS/PCR ~0.26-0.27%). Attributed to trees/NN capturing nonlinear
interactions linear/regularized-linear methods miss.

Caveat: the 0.40%/0.34% figures could not be extracted directly from primary PDF/HTML
(tools returned unreadable content) — corroborated via convergent secondary sourcing
(GitHub replication project, secondary summaries) matching the widely-cited consensus
figure, not verified against the literal Table 2.

Bottom line: at monthly horizon (lower frequency than any hours-to-minutes/minutes-to-
seconds/sub-second band), NN edges GBRT, but the margin (0.40 vs 0.34) is small relative
to the gap over linear methods (~0.16-0.27). A mild counter-data-point to "trees always
win," noted honestly.

## 2. M4 and M5 (Makridakis et al.)

**M4** — Winner: Slawek Smyl (Uber), hybrid ES-RNN (exponential smoothing + LSTM),
published as "A hybrid method of exponential smoothing and recurrent neural networks for
time series forecasting," International Journal of Forecasting 36(1):75-85 (2020). This
is deep learning, not GBT. Second place: FFORMA (Montero-Manso, Athanasopoulos, Hyndman,
Talagala, IJF 36(1):86-92, 2020) — uses XGBoost, but only as a meta-learner assigning
combination weights to 9 classical statistical methods (ARIMA, ETS, TBATS, etc.), not as
the forecaster itself. **M4's winner was DL-based; the GBT-using runner-up used GBT for
model-selection, not raw forecasting.**

**M5** — "M5 accuracy competition: Results, findings and conclusions," Makridakis,
Spiliotis, Assimakopoulos, IJF (2022). Official winner: a diverse 6-model equal-weighted
ensemble; 2nd place blended per-store LightGBM models with N-BEATS-derived multipliers.
LightGBM was the single most common base algorithm among top performers; M5 was "the
first competition where all top-performing methods were both 'pure' ML ones and
significantly better than all statistical benchmarks" — but this is GBT+DL hybrids
beating statistical baselines, not a clean GBT-vs-DL horse race. Pure N-BEATS/DeepAR
entries existed but did not top the leaderboard alone.

**Net**: M4/M5 does NOT cleanly say "GBT beat DL." M4's outright winner was DL (hybrid
ES-RNN); M5's winner favored LightGBM-heavy ensembles with DL as an adjustment layer.
Honest read: for general retail/demand time-series forecasting, both GBT (LightGBM) and
DL (hybrid RNN) are winning-class approaches; hybrids/ensembles beat single-model-class
approaches of either kind. Doesn't map cleanly onto financial return prediction — M4/M5
are demand forecasting (positive, seasonal, hierarchical series), a different problem
than noisy near-random-walk financial returns.

## 3. Numerai

Documented fact (Numerai's own docs, docs.numer.ai/numerai-tournament/models): all
official Numerai "benchmark models" are trained "in the standard walk-forward way, with
standard LGBM [LightGBM] parameters." Numerai's example-predictions model (historically
top-30 in the live tournament) is "built from a simple XGBoost model."

Documented backtest (Numerai blog, "Achieving Meta Model Supremacy At Numerai," Oct 2019):
internal blind OOS backtest gave linear regression Sharpe 0.13 vs XGBoost Sharpe 0.91 vs
combined Meta Model 1.55 — official confirmation GBT crushes linear on their data, from
Numerai itself.

**Not documented**: no rigorous, citable, Numerai-published or third-party head-to-head of
GBT vs deep learning on the live leaderboard. Forum threads show community members using
both XGBoost and neural nets with comparable in-sample Sharpes, but explicitly flagged by
posters as likely overfitting, not OOS-validated. **"GBT is the default/standard tool at
Numerai" is verified fact; "GBT beats DL specifically on the live leaderboard" is
community folklore, not rigorously sourced — say so plainly.**

## 4. Where DL genuinely earns its keep

**(a) LOB microstructure — mixed, genuinely contested:**
- DeepLOB (Zhang, Zohren, Roberts, IEEE TSP 67(11):3001-3012, 2019) — CNN+LSTM beats
  prior SOTA on FI-2010 (F1 83.4% vs next-best C(TABL) 77.6%) — but comparisons are other
  shallow/linear/bag-of-features ML methods, NOT a tuned GBT baseline.
- Informal (non-peer-reviewed) GitHub reproduction on FI-2010 with direct GBT-vs-DL:
  LSTM macro-F1 0.765 vs XGBoost 0.564 vs Random Forest 0.552 vs MLP 0.487 — real gap
  favoring the sequence model, but course-project-grade, not refereed; flag confidence
  accordingly.
- Counter-evidence: "Deep Learning modelling of the Limit Order Book: a comparative
  perspective" (arXiv:2007.07319) — a plain MLP performs comparably to or better than
  CNN-LSTM across horizons, undercutting the claim that spatial/temporal architecture is
  what earns the edge.
- Most relevant to crypto: Wang, "Exploring Microstructural Dynamics in Cryptocurrency
  Limit Order Books: Better Inputs Matter More Than Stacking Another Hidden Layer" (arXiv
  2506.05764, crypto/Bybit data) — well-engineered features + GBT (XGBoost) match or
  exceed DL on raw inputs. A direct, recent, crypto-specific pushback on "DL wins at LOB."
- **Verdict: real evidence DL can win at raw-LOB-snapshot microstructure prediction
  exists but is not uniform, and the crypto-specific evidence currently argues the other
  way when feature engineering effort is matched.** The most legitimate niche for DL in
  this whole review, but not settled.

**(b) NLP/alt-data — DL's role is representation learning feeding a GBT, not end-to-end
replacement:**
- MDPI 2025 (FinBERT-Enhanced Sentiment with SHAP): pipeline is FinBERT (DL) -> sentiment
  features -> XGBoost classifier. Win is FinBERT-features-into-XGBoost beating
  technical-only/lexicon-only baselines — supports "DL earns its keep at turning
  unstructured text into structured features," with GBT still doing final prediction.
- Stanford CS224N project ("News to Numbers: NLP Stock Return Predictions") compares
  embedding types (OpenAI text-embedding-3-large, FinBERT, DeBERTa) directly as
  predictors; best Sharpe ~7.6% per prediction — modest, not benchmarked against a
  GBT-on-engineered-features baseline, doesn't establish DL > GBT, just that embeddings
  carry signal.
- **Verdict: no paper found claiming end-to-end DL beats GBT-on-engineered-features for
  NLP/alt-data prediction.** Repeated pattern: DL for raw-text representation learning,
  GBT for the downstream decision — exactly the "DL where representation learning is the
  genuine need" thesis, not phrased as a DL-vs-GBT contest.

**(c) Other niches**: general tabular-ML literature — McElfresh et al., "When Do Neural
Nets Outperform Boosted Trees on Tabular Data?" NeurIPS 2023 (arXiv:2305.02997), 176
datasets, 19 algorithms — found the NN/GBDT gap is negligible on most datasets, predicted
by dataset size, size-to-feature ratio, and "irregularity." Supports the general prior
rather than identifying new DL niches.

## 5. Lower-frequency band (hours-to-minutes): strongest evidence for trees

**Krauss, Do, Huck, "Deep neural networks, gradient-boosted trees, random forests:
Statistical arbitrage on the S&P 500," European Journal of Operational Research
259(2):689-702 (2017).** Single best direct three-way comparison found — same features
(lagged returns of all S&P 500 stocks), same task (daily one-day-ahead long/short signal,
1992-2015), same evaluation. Individual-model results, before transaction costs, k=10
portfolio, daily mean return: Random Forest 0.43%, GBT 0.37%, **DNN 0.33% (worst of the
three)**. Annualized Sharpe before costs: RAF 5.12, GBT 3.94, ENS(all three) 4.71, **DNN
2.44 (worst)**. After transaction costs ranking holds: RAF 67% annualized, GBT 46%, DNN
27%. Clean, load-bearing, directly-comparable result: **trees (both RF and GBT) beat DNN
at daily/statistical-arbitrage frequency** — exactly the hours-to-minutes band.

Counter-evidence at slightly lower (monthly) horizon: Gu-Kelly-Xiu (above) and a European
replication (Drobetz & Otto, "Empirical Asset Pricing via Machine Learning: Evidence from
the European Stock Market," Univ. Hamburg working paper) — both find neural nets slightly
ahead of trees at monthly horizon (GKX: NN3 0.40% vs GBRT 0.34%; Drobetz & Otto: NNs and
an SVM classifier outperform trees on European equities, including after transaction
costs). These are outside the hours-to-minutes band (monthly) but are the closest genuine
counter-evidence found, and margins are small in both cases.

**Net for this band**: the one apples-to-apples daily-frequency comparison on directly
comparable inputs (Krauss et al.) says trees win outright and by a clear margin.
Counter-evidence (GKX-family) is at a different, longer horizon with a much smaller NN
edge. No rigorous head-to-head found at monthly-and-below with trees losing by a wide
margin, nor at daily-and-below with DL winning — for the hours-to-minutes band, Krauss et
al. is close to the strongest and most direct evidence available.

---

## VERIFIED
- Gu, Kelly, Xiu (2020), RFS 33(5):2223-2273 — NN3 R^2_oos=0.40% (monthly) beat GBRT's
  0.34%; both crushed linear methods; NN peaks at 3 layers. (corroborated via secondary
  sources, not direct primary-PDF extraction.)
- M4 winner = hybrid ES-RNN (Smyl, Uber), IJF 36(1):75-85 (2020) — deep learning. M4 2nd
  place = FFORMA (Montero-Manso et al., IJF 36(1):86-92, 2020) — XGBoost as meta-learner
  over classical statistical methods, not the forecaster.
- M5: LightGBM dominant single algorithm among top performers; winner a 6-model ensemble;
  2nd place blended LightGBM with N-BEATS-derived multipliers (Makridakis, Spiliotis,
  Assimakopoulos, IJF 2022).
- Numerai's official benchmark models built with "standard LGBM parameters"
  (docs.numer.ai); Numerai's 2019 backtest blog post shows XGBoost (Sharpe 0.91) crushing
  linear regression (Sharpe 0.13) (blog.numer.ai).
- Krauss, Do, Huck (2017), EJOR 259(2):689-702 — RF (0.43%/day) > GBT (0.37%/day) > DNN
  (0.33%/day, worst) before costs; same ranking after costs and on Sharpe.
- DeepLOB (Zhang, Zohren, Roberts), IEEE TSP 67(11):3001-3012 (2019) — CNN+LSTM beats
  prior (non-GBT) SOTA on FI-2010.
- Wang, "Exploring Microstructural Dynamics in Cryptocurrency Limit Order Books..."
  (arXiv:2506.05764) — crypto-specific finding: engineered features + GBT match/beat DL
  on raw inputs.
- McElfresh et al., "When Do Neural Nets Outperform Boosted Trees on Tabular Data?"
  NeurIPS 2023 (arXiv:2305.02997) — NN/GBDT gap negligible on most of 176 datasets.

## UNVERIFIED
- "GBT beats DL on the live Numerai tournament leaderboard specifically" — only that
  GBT/LightGBM is Numerai's default/benchmark tooling and beats *linear* models in their
  backtests; no rigorous public GBT-vs-DL leaderboard comparison found. Community
  folklore, not documented fact.
- "DL beats GBT on LOB microstructure prediction, full stop" — papers exist on both
  sides; no rigorous, widely-agreed head-to-head GBT vs DL benchmark on the same LOB
  dataset with comparable feature-engineering effort on both sides found. Closest is the
  informal GitHub FI-2010 comparison — directionally suggestive, not citation-grade.
- "End-to-end DL beats GBT-on-engineered-features for NLP/sentiment trading signals" — no
  such paper found; what exists is DL-embeddings-feeding-GBT hybrids beating non-DL
  baselines, a different (weaker) claim.
- Exact Gu-Kelly-Xiu Table 2 values (OLS/PLS/PCR/ENet/GLM/RF, portfolio-level Sharpes by
  model class) — primary PDF/HTML table contents not extractable; only headline
  NN3/GBRT R^2 confirmed via convergent secondary sources.
