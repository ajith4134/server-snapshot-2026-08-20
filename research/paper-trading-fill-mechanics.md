# How crypto bots model fills in paper/dry-run mode, and where it flatters

**Researched 2026-08-19** under RL-045. Every project cloned and grepped; issues quoted via
`gh issue view`. Not summarized.

## The one hard number in the whole survey

**nautilus_trader issue #3596.** Before a fix, fills triggered by a live trade tick were
simulated against the **pre-trade** order-book snapshot instead of the post-trade one. A user
measured the bias on **96 real ETHUSDT-PERP stop-market fills**:

| | pre-trade book (buggy) | post-trade book (fixed) |
|---|---|---|
| mean slippage | **−4.80 bp (favourable)** | **+0.19 bp (realistic)** |

Direct quantitative evidence of the direction paper trading flatters: **a fill priced against
a book that predates the moment a real order would land is optimistic, by multiple bp per
fill, compounding across thousands of fills.** Residual, still-unfixed bias flagged by the
maintainer: *"cancelled orders are invisible to trade-based interpolation... which overstates
available depth."*

## Per project

**Freqtrade** — two engines of very different fidelity.
- *Backtest*: fills at candle open, valid anywhere in `[low, high]`. **No slippage at all**;
  docs say so: *"All orders are filled at the requested price (no slippage) as long as the
  price is within the candle's high/low range."*
- *Dry-run*: market orders walk `fetch_l2_order_book` (`get_dry_market_fill_price`), capped at
  a hardcoded 5% slippage bound. Limit orders fill on touch — **instant and total** the moment
  price crosses. No queue position.
- **Funding on perps genuinely modelled** with real historical funding-rate/mark-price data
  (`_run_funding_fees`). One of only two projects that does this well.
- Margin borrow interest: field exists, margin trading disabled, the interest line is
  **commented out**.
- Maintainer `xmatthias`, issue #10591, on market impact: *"That's something dry-run can't
  simulate, either... Just because volume in a candle is low doesn't mean there were not 10M
  on both bid and ask spots... the pure presence of an 1M order in the orderbook on a small
  market will make price move."* A maintainer of the best-of-breed OSS dry-run engine stating
  on the record that market impact is out of scope for all of them.

**Hummingbot** — `paper_trade_exchange.pyx`.
- Market orders: genuine book-walk against the **live** book. Better than flat bps.
- Limit orders: **worse than touch** — the entire order fills at the exact limit price the
  moment price crosses, no queue, no partial. Hardcodes `is_maker=True` for every limit fill
  regardless of whether it rested — a real maker/taker mislabelling bug.
- A fixed **`TRADE_EXECUTION_DELAY = 5.0` seconds** on every market order — a constant, not
  derived from measured latency. Limit orders get zero delay.
- **No perpetual paper-trade connector at all** (spot only).
- Issue #4877 proposing book-aware limit fills was closed "completed" in 2025; **verified
  against current source that the fix was never applied.** Stale closure.
- Maintainer, #8414: *"Paper trade only works with V1 strategies and does NOT work with V2."*
  Effectively legacy.

**Jesse** — **the paper/live trading code is closed-source**, a licensed binary plugin behind
`LICENSE_API_TOKEN`. Cannot be inspected. The open core it calls is naive: `filled_qty =
qty` unconditionally, fill price is just the order price. **`grep -rl "slippage"` across the
entire OSS repo returns zero matches.** No maker/taker split. Docs have no limitations
section despite marketing backtest-to-live parity.

**OctoBot** — market orders fill at `created_last_price` with **literally zero slippage**.
Limit orders touch-triggered at the exact limit price. **`grep -rn "slippage|latency"` across
the whole repo: zero hits.** Partial fills explicitly disabled for simulated orders. Maker/
taker is a heuristic with the admission in the source comment: *"true 90% of the time:
impossible to know for sure the reality"*. Funding modelled in backtest only. Issue #294
(2018, still open): a simulated stop fired at 6412.05 while real BTC/USDT traded 6632–6709 —
the trigger has no defence against firing outside the actual traded range.

**Backtrader** — dead (last commit April 2023), no crypto integration in-repo. Notable only
for shipping **opt-in, off-by-default volume-based partial-fill fillers** that carry unfilled
remainder to later bars.

**vectorbt** — **backtest only, no live or paper capability.** Maintainer: *"There is no
built-in order management; vectorbt is a raw processing engine."* Flat-percentage slippage,
no depth dependence (open unanswered request #760), and **slippage not applied to stop orders
by default** (#695). Does model partial fills, but cash/size-driven, not liquidity-driven.

**nautilus_trader** — the most sophisticated, and carrying the most important finding.
- Real book-walk fills against L2/L3. **But with L1 top-of-book data — the tier most crypto
  live feeds give you — it degrades to touch matching plus "fill residual one tick worse".**
- **Genuine queue-position modelling exists** (`queue_position: bool`), FIFO. Real, not a
  stub — but **off by default**, and a bug was just fixed there (#4370: a stranger's unrelated
  cancel zeroed an order's queue-ahead count, causing premature fills).
- Open request #3943: none of the 11 built-in fill models require N-tick penetration —
  *"treat a limit order as filled the instant a synthetic tick touches the limit price — zero
  penetration required."*
- `LatencyModel` exists **in backtest** but is **confirmed absent from their own live-data
  sandbox mode**. Maintainer, #1677 (open): *"practically no latency in either direction...
  relatively unrealistic."* RFC #4631: *"Backtests systematically overstate maker edge when
  fill physics are incomplete... backtest has LatencyModel, but real-time sandbox does not."*
- Funding on perps modelled properly. **Borrow/margin interest not modelled anywhere.**

## Where our system sits

**Ahead** of every project surveyed on refusing a single-point fill estimate. Freqtrade
backtest, Jesse, OctoBot and vectorbt all single-point-estimate. Only nautilus does anything
resembling a bracket, and that came from fixing a bug rather than from design. We are also
ahead of everyone except nautilus (and weakly Hummingbot) on using **real live depth** rather
than candle-derived or last-trade price.

**Behind** on:
1. **Funding-payment simulation** — freqtrade and OctoBot both apply real funding to
   positions. With 570 perp symbols this is not a rounding error.
2. **Maker/taker distinction tied to actual fill mechanics** rather than a flat bps rate. Even
   OctoBot's crude 90%-right heuristic beats a single blended rate.

## The one mechanism we are missing

**Latency between signal and order arrival — re-pricing the fill at
`signal_time + realistic round-trip latency` rather than at `signal_time`.**

Missing everywhere, including from the most sophisticated project surveyed. Every project
either has no latency model (Jesse, OctoBot, vectorbt, Backtrader), bolts on an unmeasured
constant (Hummingbot's flat 5s), or has a real one and **explicitly does not apply it in the
mode architecturally comparable to ours** (nautilus's sandbox).

Our optimistic/pessimistic bracket varies the *fill mechanism* (rest vs cross) at a single
instant. It never asks *what the book would look like by the time an order placed now would
land*. Nautilus's #3596 measurement is direct evidence that this gap has a consistent,
non-random sign — **it favours us**, because we price against a book the market has not yet
had time to react to. Across 1,900 symbols scanned per poll, our own scan latency compounds
with it.

**The fix is not more fill sophistication (queue position, partial fills). It is a time
offset: price the fill using the book state at `signal_time + measured_latency`.**

## UNVERIFIED

- OctoBot live-mode funding scheduling on the real 8h cadence — updater exists, loop not traced.
- Jesse's actual paper-trade fill logic — proprietary, unconfirmable from any source.
- nautilus `SizeAwareFillModel` / `VolumeSensitiveFillModel` internals — existence confirmed,
  implementation not read line by line.
- OctoBot #3027 root cause — no maintainer comment, likely fee/rounding, unconfirmed.
