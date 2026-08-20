# Dual Directional Agent Architecture (BULL / BEAR)

**Decided with user 2026-08-01.**

Two specialist agents, opposite directions, both with learned pattern-recognition:

| | **BULL agent** | **BEAR agent** |
|---|---|---|
| Thesis | price will **rise** | price will **fall** |
| Spot | buy / hold | (sell held inventory only) |
| Spot margin | long, borrowed | short, borrowed |
| Futures / perps | **LONG** | **SHORT** |
| Options | **CALL** (and short put) | **PUT** (and short call) |

---

## 1. The "pizza / not pizza" capability — what it actually is

The user's analogy: a vision model learns to identify a pizza without being told the
rules of pizza-ness. It learns **its own features** from raw pixels.

The market equivalent is **representation learning** — the model discovers
predictive structure rather than being handed hand-written indicators.

Two legitimate implementations, both real:

**(a) Learned features from raw/derived market data.** A network over order book
levels, trade flow and time-series windows learns its own internal representation.
This is the standard deep-learning approach.

**(b) Time-series → image → CNN.** A genuinely published family of techniques that
takes the analogy literally:
- **Gramian Angular Field (GAF)** — encodes temporal correlation as a 2D image
- **Markov Transition Field (MTF)** — encodes state-transition probabilities
- **Recurrence Plots** — encodes when a system revisits prior states
- **Rendered candlestick charts** fed directly to a CNN

Then a standard vision architecture (ResNet/EfficientNet-style) classifies the image
as up / down / no-move. **This is exactly "is it a pizza" applied to price.**

> ⚠️ **Honest caveat, consistent with our ML research:** gradient boosting on
> well-engineered tabular features usually matches or beats deep learning on
> financial data, and transformers underperformed a one-layer linear model on
> standard forecasting benchmarks. So the image-CNN path is **built and tested,
> not assumed** — it must beat a LightGBM baseline and a linear baseline on our
> data before it's allowed near capital. Same gate as everything else.

Both approaches get built. The evaluator decides which survives.

---

## 2. The critical design flaw to avoid: two agents, always in a trade

Naive version: BULL says buy, BEAR says sell, and the system is *always* holding
something. That is a machine for paying fees.

**Three states, not two.** The correct output space is **LONG / SHORT / FLAT** — and
*flat is frequently the correct, profitable answer.*

### The arbiter (meta-labeling)

Both agents emit a **calibrated probability plus a conviction score**. A third
component — the **arbiter** — decides whether to act at all and at what size.

This is **meta-labeling** (López de Prado, AFML ch. 3): the primary model predicts
*direction*; a secondary model predicts *whether acting on that signal is profitable
net of costs*. It decouples "is there a signal" from "is this signal worth trading."
One of the few genuinely production-proven techniques in the research set.

Arbiter logic:

| BULL | BEAR | Action |
|---|---|---|
| high | low | Consider LONG — arbiter sizes it |
| low | high | Consider SHORT — arbiter sizes it |
| high | high | **FLAT.** Both fired = the model disagrees with itself. Never trade a contradiction |
| low | low | **FLAT.** No edge |

**Agreement is not confidence.** Two agents trained on the same data with the same
features will correlate; genuine disagreement is information, and the arbiter must be
trained on the *joint* distribution, not on either agent alone.

**Calibration is mandatory before sizing.** Guo et al. (ICML 2017) showed modern
neural nets are systematically overconfident. Feeding a raw softmax into a
Kelly-style sizing formula systematically **overbets**. Temperature / Platt /
isotonic calibration first, always.

---

## 3. ⚠️ Options are NOT a directional bet — the expensive misconception

**A call is not "long." A put is not "short."** This is the single most likely way
this design loses money while the direction call is *correct*.

Buying a call gives you:
- **+ Delta** — the directional exposure you wanted
- **+ Vega** — long implied volatility. **IV falls → you lose, even if price rises**
- **− Theta** — time decay. **Every day that passes costs you, even if price rises**
- **+ Gamma** — delta accelerates in your favour

**You can be exactly right on direction and still lose the whole premium**: price
rises slower than theta burns it, or IV collapses after the event you predicted.

### What the options agents actually require, beyond direction

1. **An implied-volatility surface** — IV by strike and expiry, not a single number.
2. **Greeks computed and risk-managed** — delta, gamma, vega, theta at position and
   portfolio level. Aggregate vega is a real exposure that must sit under the risk gate.
3. **A volatility forecast independent of the direction forecast** — the trade is
   only good if the option is *cheap relative to realised vol you expect*. That means
   forecasting realised vol and comparing to IV.
4. **Strike and expiry selection** as an explicit decision — a correct direction call
   with the wrong strike/expiry loses.
5. **Liquidity awareness** — crypto options are thin outside BTC/ETH near-the-money.
   Deribit is ~85-90% of BTC/ETH options volume; everything else has wide spreads.

**Design consequence:** the options agents are **not** the futures agents with a
different order type. They need a separate volatility model and a Greeks-aware risk
layer. Treating "CALL = LONG" is the classic way to be right and still lose.

---

## 4. Margin and liquidation — the asymmetry that matters

| Instrument | Margin | Max loss |
|---|---|---|
| Spot (unlevered) | none | 100% of position |
| Spot margin | borrowed, interest accrues | liquidation |
| Futures / perps | initial + maintenance | **liquidation; can exceed deposit** |
| **Long option** | pay premium up front | **capped at premium paid** |
| **Short option** | margin posted | **potentially unbounded** |

Two hard rules from this table:

1. **The BEAR agent's short futures exposure is unbounded on the upside.** A short
   squeeze has no ceiling. Position limits and liquidation-distance monitoring on the
   short side must be *stricter* than on the long side — the risk is not symmetric,
   even though the architecture looks symmetric.
2. **Short options (selling calls/puts) carry unbounded risk.** They are excluded
   from the default action space and require an explicit, separately-gated
   promotion — they are not "the other side" of buying options.

Also: **perp funding is a real P&L line.** A long perp held through positive funding
pays continuously. Funding must be in the cost model, charged at actual settlement
times (1h/4h/8h by venue), not smoothed.

---

## 5. Where this sits in the tree

```
ROOT
├── BRAIN 1 (hours→minutes)
│   ├── BULL agent ──┐
│   │                ├── ARBITER (meta-label) → LONG / SHORT / FLAT → RISK GATE → EXEC
│   └── BEAR agent ──┘
├── BRAIN 2 (minutes→seconds)   [same BULL/BEAR/ARBITER triad]
└── BRAIN 3 (sub-second)        [same triad]
```

Each brain runs its **own** BULL/BEAR/arbiter triad, because the features that
predict a 4-hour move are not the features that predict a 4-second move. Each triad
is independently validated through the full promotion pipeline, and the capital
allocator funds brains by measured out-of-sample performance.

**Every path — every brain, every direction, every instrument — passes through the
same pre-trade risk gate. No exemptions** (FTX's Alameda exemption and bZx's
"overcollateralized" carve-out are the two documented cases of exactly this failure).
