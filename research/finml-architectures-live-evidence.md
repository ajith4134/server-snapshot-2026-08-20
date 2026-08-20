# Specific DL architectures: live-trading evidence vs backtest-paper-only

Provenance: researched by Claude Sonnet 5 subagent, 2026-08-01, via WebSearch/WebFetch
cross-checked against arXiv/publisher pages (IEEE, ACM, ScienceDirect, Taylor & Francis).
Part of parallel-research sweep: "Which ML/DL methods actually work in live trading."

## 1. Temporal Fusion Transformer (TFT)
Lim, Loeff, Arık, Pfister, "Temporal Fusion Transformers for Interpretable Multi-horizon
Time Series Forecasting," *International Journal of Forecasting* 37(4):1748-1764, 2021.
DOI 10.1016/j.ijforecast.2021.03.012. VERIFIED (ScienceDirect + arXiv 1912.09363).

Evaluated on Electricity, Traffic, Retail (Favorita), and Volatility (Oxford-Man Institute
realized-volatility library, 31 stock indices, 5-min RV) — predicts the volatility number
itself, no trading strategy or PnL attached. Downstream finance applications are third-party
backtest-only papers, none from original authors.

**Verdict: backtest-paper evidence only. No known live trading evidence.**

## 2. N-BEATS / N-HiTS
- N-BEATS: Oreshkin, Carpov, Chapados, Bengio, ICLR 2020, arXiv:1905.10437. VERIFIED.
- N-HiTS: Challu, Olivares, Oreshkin, Garza Ramírez, Mergenthaler Canseco, Dubrawski,
  AAAI 2023. VERIFIED (dl.acm.org/doi/10.1609/aaai.v37i6.25854).

Benchmarked on M3/M4/TOURISM (N-BEATS) and ETT/Electricity/Traffic/Weather/ILI/
Exchange-Rate (N-HiTS) — pure point-forecast accuracy, no trading logic. Only finance-specific
paper found (arXiv:2409.00480) is an unaffiliated arXiv-only comparative study, no confirmed
peer-reviewed venue.

**Verdict: backtest-paper evidence only. Not finance-native architectures at all.**

## 3. TCN (Bai, Kolter, Koltun)
"An Empirical Evaluation of Generic Convolutional and Recurrent Networks for Sequence
Modeling," arXiv:1803.01271, 2018. VERIFIED as citation — but note: this stayed an
arXiv report, never published at a venue (commonly miscited as a conference/journal paper).

Finance applications exist in peer-reviewed venues, e.g. "Increasing the Hong Kong Stock
Market Predictability: A Temporal Convolutional Network Approach," *Computational
Economics* (Springer), 2024. All backtest accuracy/return studies on historical data;
none report live or paper-trading deployment.

**Verdict: backtest-paper evidence only.**

## 4. State-space models: S4 / Mamba
- S4: Gu, Goel, Ré, "Efficiently Modeling Long Sequences with Structured State Spaces,"
  ICLR 2022, Outstanding Paper (Honorable Mention). VERIFIED (arXiv:2111.00396).
- Mamba: Gu & Dao, "Mamba: Linear-Time Sequence Modeling with Selective State Spaces,"
  arXiv:2312.00752, Dec 2023 (v2 May 2024). Citation VERIFIED. Venue UNVERIFIED this
  session — commonly said to be rejected at ICLR 2024 then accepted at COLM 2024, but
  this was not independently confirmed by a fetched source; arXiv page lists no venue.

Finance applications found are thin and recent (2024-2025), unreplicated: MambaStock
(arXiv:2402.18959, solo author, arXiv-only), Graph-Mamba stock prediction
(arXiv:2410.03707), T-Mamba (ACM ICCIBDA 2025, minor conference), CMDMamba (PMC-indexed).
None report live trading.

**Verdict: backtest-paper evidence only, and thinner than TCN — mostly unreplicated
2024-2025 preprints, not an established literature.**

## 5. Neural SDEs
Kidger, Foster, Li, Oberhauser, Lyons, "Neural SDEs as Infinite-Dimensional GANs,"
ICML 2021 (PMLR v139). VERIFIED (proceedings.mlr.press/v139/kidger21b). Own evaluation
is generic time-series generation, not finance-specific.

Finance-adjacent Neural SDE work is a separate line: Arribas, Salvi, Szpruch, "Sig-SDEs
model for quantitative finance," ACM ICAIF 2020; various market-simulator/calibration
papers (e.g. arXiv:2409.06551 on robust neural-SDE calibration; Journal of Computational
Finance work on pricing/hedging via neural SDEs). These target derivatives
pricing/hedging/calibration and market simulators, not directional trading signals.
No live-trading claims found anywhere in this line.

**Verdict: applied to finance in credible literature (pricing/hedging/calibration/
market-generator use) but purely backtest/simulation evidence — no live trading evidence.**

## 6. DeepLOB
Zhang, Zohren, Roberts, "DeepLOB: Deep Convolutional Neural Networks for Limit Order
Books," *IEEE Transactions on Signal Processing* 67(11):3001-3012, 2019. VERIFIED.

Original claims: SOTA on FI-2010 (5 Nasdaq Nordic stocks, 10 days — small, dated
benchmark) predicting mid-price movement direction; also one year of LSE quotes claiming
accuracy transfers to instruments outside the training set.

**Important independent critical follow-up**: Briola, Bartolucci, Aste, "Deep Limit
Order Book Forecasting: A microstructural guide," arXiv:2403.09267 (2024), published in
*Quantitative Finance* (Taylor & Francis) 2025, DOI 10.1080/14697688.2025.2522911.
VERIFIED. Evaluating DeepLOB-class models on 15 NASDAQ stocks, their explicit finding:
**"high forecasting power does not necessarily correspond to actionable trading signals"**
— good classification accuracy/F1 does not survive the operational question of whether a
full round-trip trade is executable/profitable. Direct rebuttal of "backtest accuracy =
trading edge" for exactly this model family.

Co-author Stefan Zohren is Deputy Director, Oxford-Man Institute, and Principal Quant at
Man Group — real industry proximity of the *author*, not evidence DeepLOB itself runs
live in production. Don't conflate the two.

**Verdict: most finance-native architecture on the list, with unusually good
documentation — but the strongest independent follow-up specifically argues accuracy
does not equal tradeable signal. No live trading evidence found.**

---

## VERIFIED
1. TFT — Lim, Loeff, Arık, Pfister, IJoF 2021
2. N-BEATS — Oreshkin et al., ICLR 2020; N-HiTS — Challu et al., AAAI 2023
3. TCN — Bai, Kolter, Koltun, arXiv 2018 (never published at a venue — fact about the paper)
4. S4 — Gu, Goel, Ré, ICLR 2022; Mamba — Gu & Dao, arXiv:2312.00752 (citation only)
5. Neural SDEs — Kidger, Foster, Li, Oberhauser, Lyons, ICML 2021
6. DeepLOB — Zhang, Zohren, Roberts, IEEE TSP 2019; critique — Briola, Bartolucci, Aste,
   Quantitative Finance 2025 (arXiv:2403.09267)

## UNVERIFIED
- Mamba's COLM 2024 acceptance — recollection from training data, not confirmed this
  session; arXiv page lists no venue.
- Whether arXiv:2409.00480 (N-HiTS/N-BEATS finance comparison) has appeared in any
  peer-reviewed venue — confirmed only as arXiv preprint.

## Bottom line
Every architecture on this list has backtest-only evidence for finance applications —
zero credible published claims of live/production trading value for any of them, from
original authors or anyone else. The closest thing to a red flag *against* trusting even
the backtests is the Briola/Bartolucci/Aste DeepLOB critique. Treat all six as "promising
on paper, unproven in the market" — budget for your own live/paper-trading validation
regardless of which one you pick.
