# Kronos — foundation model for K-line data

**Provenance**
- Source: `github.com/shiyu-coder/Kronos` — cloned and read directly, 2026-08-01
- Repo state at read: 35,359 stars · 5,893 forks · MIT · created 2025-07-01 · pushed 2026-04-13 · 92 files
- Paper: arXiv:2508.02739 · **accepted AAAI 2026** (announced 2025-11-10)
- Weights: Hugging Face `NeoQuasar/*` · Live demo forecasts BTC/USDT
- Found via an Instagram post; project identified and read at source rather than from the post

---

## Verdict

**Use it as the baseline your own models must beat — not as a signal source.**

It is the first open-source foundation model built specifically for financial candlesticks, it is
MIT-licensed, and the small variant is CPU-runnable. That makes it the cheapest decisive test
available of whether your own pipeline adds value. It is **not** a trading system, and its own
authors do not claim it is.

## What it actually is

A **decoder-only foundation model over K-line sequences**, trained across 45+ global exchanges.
Two-stage architecture:

**Stage 1 — `KronosTokenizer`.** Quantizes continuous OHLCV into **hierarchical discrete tokens**
via **Binary Spherical Quantization** (`BSQuantizer`), wrapped in encoder/decoder transformer
blocks. The codebook is split into two tiers — `s1_bits` (coarse) and `s2_bits` (fine) — and the
decoder is run twice, once on the coarse tier alone and once on the full codebook. Training
reconstructs both, so the coarse tokens must be independently meaningful.

**Stage 2 — `Kronos`.** An autoregressive transformer over those tokens. RoPE positional encoding,
RMSNorm, hierarchical embedding, optional learned time-embedding (`learn_te`). Decoding is
two-headed: `decode_s1` predicts the coarse token, `decode_s2` predicts the fine token *conditioned
on* the coarse one.

**Inference is LLM-shaped.** `top_k_top_p_filtering`, temperature `T`, and `sample_count` paths
averaged — probabilistic forecasting by sampling multiple futures. Default usage: **400 candles in,
120 out.**

### Model zoo

| Model | Tokenizer | Context | Params | Open |
|---|---|---|---|---|
| Kronos-mini | Tokenizer-2k | 2048 | 4.1M | ✅ |
| Kronos-small | Tokenizer-base | 512 | 24.7M | ✅ |
| Kronos-base | Tokenizer-base | 512 | 102.3M | ✅ |
| **Kronos-large** | Tokenizer-base | 512 | 499.2M | **❌ not released** |

Dependencies are light: `torch>=2.0`, numpy, pandas, einops, huggingface_hub, safetensors.

---

## Two findings that decide how it can be used

### 1. It models no trading costs whatsoever — verified, not inferred

Grepped the full repository for `commission|slippage|fee|transaction_cost|spread` across all Python
files. **Zero hits.** The bundled backtest (`examples/run_backtest_kronos.py`) generates a signal
from a raw `pred_return > threshold` comparison and executes at `current_price`.

**Against our own research this is decisive:** Binance round-trip breakeven is ~22–30bps and **fees
dominate slippage and adverse selection by roughly 5–10×** at our order sizes. A backtest with no
cost model is measuring the half of the problem that does not determine profitability.

The Instagram post that surfaced this project states the same caveat, and it is accurate — the
authors position Kronos as a research artefact, not a profit system. **Any performance figure from
this repo, or from anyone quoting it, is gross of costs.**

### 2. Its train/val/test splits deliberately overlap, and there is no purging

From `finetune/config.py`, verbatim ranges:

```
train:     2011-01-01 → 2022-12-31
val:       2022-09-01 → 2024-06-30    # begins ~4 months before train ends
test:      2024-04-01 → 2025-06-05    # begins ~3 months before val ends
backtest:  2024-07-01 → 2025-06-05
```

The config carries a comment acknowledging the overlap. Grepping for `purge|embargo|leak|lookahead`
returns **one** hit — a narrow one in `finetune/dataset.py`: normalization statistics are computed on
the lookback window only.

**There is no purging and no embargo.** With a 120-candle prediction horizon, label windows straddle
those split boundaries by construction. This is precisely the failure the validation research
identified: **temporal ordering is not the same as non-overlapping.** Walk-forward without purging is
naive k-fold wearing a disguise.

Not a criticism of the paper's contribution — a constraint on how its numbers transfer.

---

## How to use it here

**As the baseline gate.** Run **Kronos-small zero-shot** through *our* Cost Engine and *our*
purged/embargoed CPCV harness on our own data. Then:

- If our pipeline cannot beat a 24.7M-parameter off-the-shelf model that never saw our data, that is
  a decisive, very cheap finding — and it arrives before we have built anything expensive on top.
- If it can, the margin over Kronos is a far more honest statement of edge than a standalone Sharpe.

**It fits our constraints:** MIT-licensed (no `mlfinlab`-style trap), CPU-runnable at small size,
light dependencies, and `predict_batch` handles multiple assets in parallel.

**Fine-tuning exists** (`finetune/`, `finetune_csv/`) with tokenizer and predictor training scripts
and a Qlib integration — but fine-tuning it on our data makes it a searched candidate, so **it must
then be counted in the Trial Registry like any other trial.** Zero-shot use as a baseline does not.

**The tokenizer idea is independently interesting.** Discrete hierarchical tokens for OHLCV is a real
representation-learning contribution, and it composes with the path-signature and contrastive
regime-embedding ideas in `IDEAS-ADVANCED.md`. Worth understanding even if the model itself is only
ever a baseline.

## What not to do with it

- **Do not treat published or quoted Kronos performance as achievable net of costs.** No cost model exists.
- **Do not reuse its split scheme.** Overlapping ranges with no purge/embargo.
- **Do not fine-tune and promote without registering the trials.** Fine-tuning is search.
- **Do not assume the large model.** The 499.2M variant is not released; results quoted from it are
  not reproducible with public weights.

## Open questions

- Reported paper metrics were not read — only the repository. **The AAAI paper's own evaluation
  protocol is unverified here**; worth reading before citing any number.
- Crypto coverage within the "45+ exchanges" pretraining mix is unquantified in the README.
- Whether the tokenizer alone (without the predictor) is useful as a feature extractor is untested
  and would be a cheap experiment.
