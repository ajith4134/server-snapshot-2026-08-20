# Sub-second crypto trading on cloud infra + the ML "don't-build" list

Provenance: researched by Claude Sonnet 5 subagent, 2026-08-01, via WebSearch/WebFetch.
Part of parallel-research sweep: "Which ML/DL methods actually work in live trading."

## PART A — Sub-second/HFT feasibility on cloud infrastructure

### A1. Latency: cloud VM vs colocation — concrete numbers found

| Setup | RTT | Source |
|---|---|---|
| True colo, physical cross-connect at exchange (NY5) | <0.05ms raw network RTT, ~1ms end-to-end | AWS blog: Gemini + Local Zones |
| Crypto exchange matching engine self-test (One Trading, tested by AWS) | 112 microseconds | AWS blog: One Trading colocation |
| Deribit multicast feed at LD4 London colo | "a few hundred microseconds" | search-aggregated (Arbitron latency map) |
| Standard AWS public cloud region (us-east-1) -> Equinix NY financial hub | 8-12ms RTT via AWS Direct Connect, ~15ms end-to-end | AWS blog: Gemini + Local Zones |
| AWS Local Zone (NYC-2A), real purchasable product | <1ms raw, ~1.5-2ms end-to-end | same source — "4-5x improvement," still ~2x colo |
| Crypto WebSocket order-book updates, general cloud client | Binance 5-20ms, Bybit 10-30ms | search-aggregated |
| Region-matched cloud VM to exchange gateway | ~5-14ms, ~$245-280/mo per region | search-aggregated practitioner figures |
| Generic cross-country cloud VM, wrong region | 15-25ms | search-aggregated |

**Bottom line**: colocation is sub-100-microsecond to ~1ms; general-purpose public cloud
(wrong region or no Direct Connect) is 8-25ms; a well-chosen cloud region matched to the
exchange's own hosting provider gets single-digit-to-low-double-digit ms without
colocating. Roughly a 10-100x gap between "cloud, done right" and "true colo," and a
further 10x+ gap between "cloud, done right" and "cloud, wrong region/no optimization."

### A2. Consensus against small/retail shops competing at true HFT latency

Yes, on two independent legs:

- **Academic**: Budish, Cramton, Shim, "The High-Frequency Trading Arms Race: Frequent
  Batch Auctions as a Market Design Response," *QJE* 130(4), 2015, pp. 1547-1621.
  Confirmed citation. Core finding: latency arbitrage under continuous limit-order-book
  market design creates a mechanical, technology-based arms race — a symptom of market
  design, not a skill contest; races won by fastest pipe, not best model. Follow-up
  empirical paper: Aquilina, Budish, O'Neill, "Quantifying the High-Frequency Trading
  Arms Race," *QJE* 137(1), 2022 — on LSE data, latency-arbitrage races occur ~once per
  minute per symbol for FTSE 100 stocks, modal race lasts **5-10 microseconds**, and these
  races account for ~20% of trading volume. That timescale is categorically unreachable
  from any cloud VM (8ms+ minimum), let alone a strategy with any non-network computation
  in the loop.
- **Practitioner**: search-aggregated commentary converges on retail/non-colocated
  participants being structurally priced out of latency-arbitrage HFT. One dissenting
  voice — Headlands Technologies blog (an actual HFT market maker) — argues latency
  competition is not socially wasteful, contesting the Budish et al. "waste" framing at
  the market-structure level, but does **not** claim small/non-colocated shops can
  compete on latency.

**Net**: genuine mixed academic + practitioner signal converging on the same operational
conclusion even though the "arms race" framing itself is contested — nobody credible says
a small cloud-based shop should compete on microsecond latency arbitrage.

### A3. The realistic middle ground for a small/independent shop

- **AWS Local Zones** (Gemini case study) — real, purchasable, gets standard cloud
  tooling to ~2ms from an 8-12ms baseline (roughly colo-adjacent without full colo
  cost/complexity). Available in specific metros (NYC among them).
- **Crypto exchanges are themselves cloud-hosted**, unlike traditional finance — Binance
  on AWS Tokyo, Bybit on AWS Singapore, OKX on AWS Hong Kong (search-aggregated,
  consistent across sources). Renting a VM in the *same* AWS region as the exchange's
  own infra is a legitimate, cheap (~$250-300/mo) way to get single-digit-to-teens-ms RTT
  without colocation.
- **Crypto colocation exists but is uneven across venues**: Kraken launched retail-
  accessible colocation in 2025 (via Beeks Exchange Cloud or physical rack space at
  Kraken's EU datacenter), targeting sub-millisecond for well-positioned clients — no
  public pricing found. Deribit offers LD4 London colocation. Binance has explicitly said
  it is NOT pursuing colocation (stated reason: regulatory/jurisdictional exposure).
  Coinbase shut down its Chicago HFT-services/colocation division.
- **Conclusion for a "sub-second band"**: on cloud infra, region-matched VM + exchange
  WebSocket/FIX feed + application-level latency discipline realistically lands in the
  single-digit-to-tens-of-milliseconds band. That is a legitimate, defensible "sub-second"
  tier — nowhere near true HFT (microseconds). Design and think of it internally as such,
  not as latency arbitrage. If a venue offers colocation (Kraken, Deribit) and the
  strategy's edge genuinely depends on sub-millisecond reaction, that's a distinct, much
  more expensive build (rack rental, FPGA/kernel bypass engineering) to scope separately.

---

## PART B — The don't-build list

### B1. LSTM/RNN on raw past price -> future price, no engineered features
UNVERIFIED as a specifically-named documented phenomenon — no single authoritative paper
found making exactly the "predicts next ~ last" claim with data in hand. What was found:
(a) pervasive community folklore across ML/quant forums, not peer-reviewed; (b) adjacent
solid academic support: Zeng et al., "Are Transformers Effective for Time Series
Forecasting?" (AAAI 2023, arXiv:2205.13504) — a single-layer linear model ("DLinear")
beats Transformer/LSTM-class architectures on long-term forecasting benchmarks across the
board, showing complex sequence models add no signal over trivial baselines on raw series.
Doesn't prove the exact "lag-1 predictor" trap, but strongly supports the underlying claim.
**Verdict: don't bother.** Cheap self-check: compare trained model's MSE against a naive
"predict last observed price" baseline on held-out data — if within noise, you've
reproduced the trap yourself.

### B2. GANs for synthetic financial data as a source of trading edge
VERIFIED as a research area (Quant-GAN, Stock-GAN, TimeGAN-style, evaluated on
statistical-fidelity metrics and downstream backtest utility); UNVERIFIED/absent as a
source of live trading edge — no source, academic or practitioner, found claiming a
GAN-generated-data pipeline delivered real live capital-at-risk edge over simpler
approaches (block bootstrap, regime-conditional resampling, more real data).
**Verdict: don't build this as an "edge" project.** For genuine data-scarcity problems
(thin order-book history, new listing), block-bootstrap or historical-regime-splicing is
cheaper and just as defensible; GANs are a research curiosity here, not a shortcut to edge.

### B3. End-to-end RL for execution/strategy without heavy reward-shaping/feature engineering
VERIFIED, both practitioner and academic. RL's core premise (agent actions affect
environment, reward delayed/sparse) is structurally mismatched to trading (single trader
has ~zero market impact; reward is immediate, not sparse) — off-the-shelf RL formulations
solve the wrong problem shape. Reward hacking against simulator artifacts is a documented
general RL failure mode (agents exploit whatever the simulator allows — e.g. trading at
mid-price assuming infinite liquidity); RL is broadly known to be severely
sample-inefficient relative to supervised learning, worse in the low-signal, non-stationary
trading domain.
**Verdict: don't build naive end-to-end RL.** If RL is used at all, it belongs inside a
heavily constrained, reward-shaped sub-problem (e.g. execution scheduling within a
strategy that's already decided direction/size via other means) — not as the top-level
"learn to trade" system. Extend the same "no exotic ML in the fast path" discipline
already applied to LLMs.

### B4. Generic pretrained sentiment models (no domain adaptation) on financial text
VERIFIED, confirming the hypothesis. FinBERT paper (arXiv:1908.10063) and follow-on work
consistently show domain-adapted models (further pretrained on financial corpora, then
fine-tuned on financial sentiment labels) outperform generic BERT/generic sentiment
models on financial sentiment tasks — financial language ("aggressive growth," "beat,"
"miss," "guidance") carries polarity that differs from general-domain usage. Peer-reviewed.
**Verdict: don't bother with an off-the-shelf, non-finance-tuned sentiment model** and
treat its output as signal. Either use an already domain-adapted model (FinBERT and
derivatives are open-weight, zero-training-cost to adopt) or skip a sentiment signal
entirely — building your own domain adaptation from scratch is the expensive, low-ROI
version; using an existing adapted model is nearly free and evidence-backed.

### B5. Wavelet transforms / exotic signal processing on price series
Mixed evidence, UNVERIFIED as reliable edge, with one well-grounded technical trap worth
naming (this part is the agent's own technical reasoning from DSP fundamentals, not a
single cited source): search results contain the tell — "in financial trading, simpler
methods are more robust; complex models are prone to overfitting," alongside
acknowledgment that wavelet feature pipelines need bio-inspired feature-selection add-ons
"to avoid overfitting" — i.e. the base technique overfits badly enough that papers bolt on
extra machinery just to contain it. Concrete mechanism to watch for: standard
(non-causal) discrete wavelet transform implementations compute coefficients using
boundary padding/reflection across the *whole* series, so "past" wavelet features
computed in a backtest can leak future-sample information at each window boundary unless
you implement a strictly causal, streaming wavelet decomposition (rare in tutorial code,
easy to get wrong, invisible in your own backtest because it makes results look
artificially good).
**Verdict: don't build this as an early-stage feature-engineering investment.** Exactly
the profile of "looks sophisticated, reliably eats months" — even done correctly it
hasn't been shown to reliably beat simpler momentum/volatility features; done incorrectly
(the common case) it silently manufactures lookahead bias that makes the backtest lie.
If pursued at all, late-stage only, after simpler features are exhausted, with an
explicit causality unit test on the transform.

### B6. Exotic/custom loss functions as a substitute for fixing labels/features
UNVERIFIED as a trading-specific finding — no paper or named practitioner found explicitly
making "custom losses are a common misallocation vs fixing data" as a documented critique;
found instead papers *advocating for* custom losses in trading. Classified as general ML
community consensus/folklore ("garbage in, garbage out"), not trading-specific
peer-reviewed consensus.
**Verdict: directionally right by general ML engineering logic, weaker evidence than
B1-B5.** Actionable version: before reaching for a custom loss, verify labels/features
aren't the actual bottleneck (cheap check — swap in a standard loss, see if a feature/label
fix alone gets most of the way there). Don't rule out custom losses outright; rule out
reaching for one first.

---

## VERIFIED
- Cloud vs colo latency figures (table above) — AWS/Gemini blog, AWS/One Trading blog.
- Budish, Cramton, Shim, *QJE* 130(4), 1547-1621 (2015) — citation and core finding
  confirmed.
- Aquilina, Budish, O'Neill, *QJE* 137(1) (2022) — LSE latency-race figures (~1/min/symbol,
  5-10 microsecond modal duration, ~20% of volume) confirmed.
- Binance=AWS Tokyo, Bybit=AWS Singapore, OKX=AWS Hong Kong hosting; region-matched cloud
  VM achieves single-digit-to-teens-ms without colocation (search-aggregated, internally
  consistent across multiple sources).
- Kraken launched retail-accessible colocation in 2025; Binance explicitly declined
  colocation (jurisdictional exposure); Coinbase shut down its HFT-services/colocation
  effort.
- FinBERT (arXiv:1908.10063) beats generic BERT on financial sentiment — peer-reviewed.
- Zeng et al., "Are Transformers Effective for Time Series Forecasting?," AAAI 2023
  (arXiv:2205.13504) — simple linear model beats Transformer/LSTM-class models.
- RL reward hacking against simulator artifacts and RL sample inefficiency — documented
  general findings, applicable to trading environment design.
- No credible source found claiming GANs deliver live trading edge (absence-of-evidence,
  deliberately checked) — literature stops at fidelity/statistical-similarity metrics and
  downstream backtest utility, not live P&L.

## UNVERIFIED
- "LSTM predicts next ~= last price" as a specifically-documented, named trap: community
  folklore, not peer-reviewed — widely repeated, not pinned to one authoritative source
  despite search effort.
- CoinAPI's latency-tiering blog: inaccessible (HTTP 403) — excluded rather than guessed.
- Headlands Technologies' "latency competition is not wasteful" counter-argument: verified
  as an existing practitioner opinion, but the aggregate-social-value claim is contested
  territory (Budish et al. disagree) — not resolved here; neither side claims retail/
  small-shop feasibility at microsecond latency.
- "Custom loss functions as a common misallocation of engineering time" (B6): general
  ML-community folklore, not trading-specific consensus — no trading-specific critique
  located.
- Wavelet lookahead-bias mechanism (B5): the agent's own technical reasoning from DSP
  fundamentals, not a cited source — flagged explicitly; the overfitting concern itself is
  source-backed from search results.
- Exact pricing for Kraken colocation and for true HFT-grade colo generally: not disclosed
  in any source found; cloud-VM cost figures given are not colocation-rack/cross-connect
  pricing, which is categorically more expensive and unquantified here.
