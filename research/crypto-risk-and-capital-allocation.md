# Position sizing, capital allocation and portfolio risk in real crypto systems

**Researched 2026-08-19** under RL-045. Sources: freqtrade and hummingbot read via `gh`,
Binance docs scraped live (dated), plus prior `~/research/allocation-and-regime.md`.

## The answer to our USDC/USD failure: a VOLATILITY FLOOR

Standard term, from Robert Carver (ex-AHL desk head; *Systematic Trading*,
*Leveraged Trading*; `pysystemtrade`, `systems/positionsizing.py`):

```
leverage = target_vol / max(realized_vol, volatility_floor)
```

Carver states our exact failure mode almost verbatim: *"when volatility is very low,
position sizes grow large because your model says the market is calm. But historically,
very low-volatility environments tend to end suddenly and violently."* His canonical
example is **EUR/CHF** — pinned near zero vol for years by the SNB, then a single-day
~20-sigma break in January 2015.

**USDC/USD at 0.1996% annualised is structurally the same shape: a PEGGED instrument, not
a genuinely low-risk one.**

The floor is set as **a fraction of the instrument's own long-run average volatility** (if
it normally runs 10% and currently reads 1%, size as if ~5%), NOT as one fixed constant —
because a single constant safe for a stablecoin is not safe for something whose real
budgeted vol is 40%+.

**Robust practice is the floor PLUS an independent hard cap on the leverage multiple.**
Carver does both (forecasts capped at ±20, diversification multiplier capped at 2.5).

This distinction matters directly for us: **we already have a per-segment ceiling and
USDC/USD still got maximum leverage** (40%/0.1996% ≈ 200x, clamped to 5). A per-segment
ceiling depends on every instrument being correctly *classified*; a vol floor guards the
*division operation itself* and does not care how the instrument was classified. Our bug
is precisely a misclassification failure, which is why the floor is the standard fix and
the ceiling is not a substitute.

## Sizing methods, and who uses what

| Method | Formula | Reality |
|---|---|---|
| Fixed fractional | `(equity × risk%) / stop_distance` | Retail/prop baseline; ignores cross-instrument vol |
| ATR off stop | `(equity × risk%) / (ATR × k)` | The crypto-practical version — stop and size from the same number, so it is "free" |
| **Vol targeting** | `target_vol / instrument_vol` | **Dominant at CTAs and systematic funds.** Needs only a variance forecast, not a mean forecast — sidesteps the hardest quantity. Our method. |
| Kelly / fractional | `f* = edge/odds` | A **ceiling, never a target.** Thorp ran half-Kelly. Full Kelly implies ~50% drawdowns as ROUTINE, and is brutally sensitive to error in the mean — the one thing a backtest cannot pin down. |
| Risk parity | weight ∝ 1/σ, equal risk contribution | Right default at small N; needs only covariance. Mean-variance is an "error-maximization" procedure (Michaud 1989). |

## Freqtrade stake management (read from source, `develop`)

- `available_capital` is a **hard override** of `tradable_balance_ratio` — they do not
  compose (`wallets.py:301,316`).
- `get_available_stake_amount()` = pool minus committed, floored by free balance.
- **No concurrency problem because it is single-threaded**: `enter_positions()` iterates
  the whitelist sequentially decrementing a local slot counter. The one real lock guards
  the Telegram RPC thread against `force_exit`, not entry. *Our two-process design does
  need the flock; theirs does not.*
- **Grepped the whole tree for `correlation`, `portfolio heat`, `exposure`: none exist.**
  The Protections framework (`CooldownPeriod`, `LowProfitPairs`, `MaxDrawdown`,
  `StoplossGuard`) is all **time-based entry locks keyed on past trade outcomes**, not
  real-time exposure. `MaxDrawdown` is the closest to a circuit breaker.

## Hummingbot budget checker (read from source)

- `_locked_collateral` is **in-memory, per-tick, non-persisted**, one per connector. It
  prevents double-spend *within one tick* only; explicitly not cross-process atomic.
- **Has a real drawdown circuit breaker, which freqtrade lacks**:
  `max_global_drawdown_quote` / `max_controller_drawdown_quote`, checked every tick against
  a running high-water mark; breaching the global one stops the bot.
- No correlation-aware exposure limiting, no portfolio heat.

## Portfolio heat (Van Tharp)

```
Portfolio Heat % = Σ[(entry − stop) × size] / equity × 100
```
Commonly cited: 2% max per position, 6% max total open heat. **The 6% could not be traced
to a specific page of the primary text — UNVERIFIED at source-page level**, though widely
corroborated. Tharp explicitly counts **correlated positions as one position** for heat.

## Correlation caps

No single canonical crypto paper. Two converging real mechanisms: (a) **beta-weighting**
(tastytrade's documented method) — rescale each position's notional by its beta to a
benchmark (BTC), sum into one benchmark-equivalent number, cap that; (b) Carver's
diversification multiplier, floored and capped, over a correlation matrix. BTC-ETH
correlation exceeds 0.85 in stress and alts fall harder than BTC in drawdowns. **No
canonical numeric threshold exists — any specific number is implementation-specific.**

## Binance perpetuals — exact, dated numbers

Maintenance margin tiers BTCUSDT/ETHUSDT, page dated 2025/08/19, scraped 2026-08-19:

| Tier | Position value (USDT) | Max lev | MMR | Maint. amount |
|---|---|---|---|---|
| 1 | 0–300,000 | 150x | **0.40%** | 0 |
| 2 | 300,000–800,000 | 100x | 0.50% | 300 |
| 3 | 800,000–3,000,000 | 75x | 0.65% | 1,500 |
| 4 | 3,000,000–12,000,000 | 50x | 1.00% | 12,000 |

`MM = notional × MMR(tier) − maint_amount(tier)`. **Tiers change without notice for moves
<0.5% — re-fetch before hardcoding.** Our `capital.json` uses a flat 0.005 (0.50%); real
tier 1 is 0.40% and it is *position-size dependent*, so a flat constant is an
approximation, conservative at tier 1.

Liquidation price: one unified formula for both margin modes; isolated sets `TMM₁ = 0,
UPNL₁ = 0` so other positions do not affect it. **The simplified long/short closed forms
are not published by Binance — treat any such formula as derived/UNVERIFIED.**

Funding: `notional × funding_rate`, default 8h (00:00/08:00/16:00 UTC), **escalates to
hourly when the rate hits its cap/floor** — confirmed live: BTCUSDT hit −0.3% on
2025-04-22 and switched to hourly. Interest component 0.01% per 8h default; general
symbols capped ±2%, floor `−0.75 × MMR`.

Margin borrow interest: `principal × hourly_rate × hours`, **accrued at the start of every
clock hour with no grace period** — under an hour still bills a full hour. **UNVERIFIED**:
live numeric rates (the margin fee page is JS-rendered and returned only a nav shell).

## Ranked: the three absences most likely to cause a large loss

1. **Minimum volatility floor.** Already demonstrated here, not hypothetical. A single
   mis-sized entry on one pegged instrument can consume its full margin-to-liquidation
   distance alone. Fix: `target_vol / max(realized_vol, floor)` with the floor as a
   fraction of that instrument's own long-run vol, plus an independent hard cap on the
   multiple.
2. **Correlation cap / beta-weighted exposure.** Two bots sharing one pool with only a
   per-bot cap *fraction*; nothing stops both going long correlated crypto risk while each
   stays inside its cap. Fix: rescale each position's notional by beta to BTC, sum across
   both bots, cap the aggregate.
3. **Portfolio heat cap.** Catches what per-trade leverage logic structurally cannot —
   enough positions each individually fine summing to an equity-threatening total.
   Correlated positions counted once.

*(Drawdown circuit breaker ranks fourth — not unimportant, but reactive: it fires after the
other three have failed and the capital is already gone.)*

## The blunt version

Most systems get the vol-targeting *division* right and never think about the
*denominator's domain*. A volatility estimator cannot tell "genuinely low-risk" from
"pegged and about to unpeg violently" — division by near-zero is indifferent to which.
The fix is not cleverer estimation, it is bounding the input. Most systems lack this guard
because it only looks necessary after it has blown up once.

Correlation caps and heat get skipped for the same reason people skip flood insurance:
single-position checks pass every time, right up until several correlated ones fail
together. A per-bot cap checks *how much* each bot commits, not *what direction* they are
collectively pointed.
