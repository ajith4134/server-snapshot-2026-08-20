# Risk, Failure Modes & the Math of Knowing When You're Wrong

**Researched:** 2026-08-01 by a Sonnet 5 subagent (Rule 1). First attempt stalled;
this is the retry. Primary papers fetched and text-extracted directly.

**The most decision-relevant research in the whole set.** It supplies the actual
math for when to kill a strategy and how many experiments it takes to manufacture
a fake edge.

---

## 1. THE NUMBER THAT SHAPES THE WHOLE SYSTEM

Bailey, Ger, López de Prado, Sim & Wu — *Statistical Overfitting and Backtest
Performance*:

> **"If only five years of daily market data are available, and if 45 or more
> independent variations of a strategy are tried, it is more than likely that the
> best strategy selected... has a Sharpe ratio of 1.0 or better"** — with **zero
> true edge.**

Their 400-run simulation on **pure random-walk data** (55,000 parameter combos):
in-sample Sharpe centred ~0.9; one illustrated run showed **in-sample SR = 1.59
("looks like a promising strategy"), out-of-sample SR = −0.18** on the same
parameters.

**45 variants.** An unrestricted experiment engine will exceed that before lunch.

> **This is why the experiment ledger must count failures.** Without an honest N,
> the Deflated Sharpe correction cannot run, and the system becomes a very
> efficient noise generator that bets real money on its own luck.

**DSR formula** (Bailey & López de Prado 2014, extracted from the PDF):
```
DSR = Z[ (ŜR − SR₀)·√(T−1) / √(1 − γ̂₃·ŜR + ((γ̂₄−1)/4)·ŜR²) ]
```
where `SR₀` is the **expected maximum** Sharpe across N tried variants under the
null (via Extreme Value Theory), and γ̂₃/γ̂₄ are sample skew/kurtosis.

---

## 2. How long before you can trust a Sharpe — Lo (2002)

*The Statistics of Sharpe Ratios*, Financial Analysts Journal 58(4).
Under i.i.d. returns: **SE(ŜR) = √[(1 + ½·SR²)/T]**

Days of daily data needed for 95% confidence the Sharpe isn't actually zero:

| True annualised Sharpe | Days | **Years** |
|---|---|---|
| 0.5 | ~3,874 | **~10.6** |
| 1.0 | ~970 | **~2.7** |
| 1.5 | ~432 | ~1.2 |
| 2.0 | ~244 | ~0.7 |

> **A Sharpe-1.0 strategy needs ~2.7 years of daily data before you can be 95%
> confident it beats zero** — and that's the *optimistic* i.i.d. case. Real crypto
> returns are autocorrelated, fat-tailed and regime-dependent, which lengthens it.

Note: higher-Sharpe strategies have *larger* absolute SE. Also, annualising monthly
Sharpe by √12 is only exact under i.i.d. — real autocorrelated series need a
smaller, series-specific factor.

---

## 3. Losing streaks are normal — the kill-switch trap

Exact binomial math, 55% win rate, probability of **at least one 10-loss streak**:

| Trades | P(≥1 ten-loss streak) |
|---|---|
| 100 | 1.7% |
| 252 (~1yr daily) | 4.5% |
| 1,000 | **17.0%** |
| 5,000 | **60.8%** |

> **A kill switch set to "N consecutive losses" without this calculation will
> shut down healthy strategies on normal variance.**

This and Lo's formula are the same statistical problem from two directions: don't
trust a short track record, and don't panic-kill on a streak inside its expected
range.

---

## 4. Position sizing — why fractional Kelly

Continuous Kelly: `f* = (μ − r)/σ²`, growth `g = r + SR²/2`.

Two independent reasons practitioners halve it:
1. **Estimation error.** `g(f) = r + fμ − ½f²σ²` is concave, so *overbetting past
   f\* costs more growth than the symmetric underbet*. Half-Kelly gives up ≤25% of
   theoretical growth as insurance.
2. **Variance even when the edge is right.** Kelly's square-root property: an X%
   chance the bankroll eventually falls to X% of a prior peak. **Full Kelly
   produces 50–60% drawdowns roughly 20% of the time over 1,000 bets.** Ed Thorp
   bet half-Kelly even with statistically solid edges.

**Calibration is a prerequisite for confidence-scaled sizing.** Guo et al.
(ICML 2017, arXiv:1706.04599) verified modern neural nets are **systematically
overconfident**. Feeding a raw softmax into a Kelly formula as "edge" systematically
overbets. Temperature/Platt/isotonic calibration first, always.

---

## 5. Kill switches — real implementations with real numbers

**Dead man's switch is a named, production exchange feature:**

| Exchange | Mechanism | Recommended pattern |
|---|---|---|
| **Kraken** | literally "Dead Man's Switch" | refresh every **15–30s**, **60s** timeout (<86,400s max) |
| **Binance Futures** | `countdownCancelAll` | call every **30s**, **120s** countdown |
| **Coinbase Intl** | cancel-on-disconnect | fixed **10-min** inactivity, WebSocket only; graceful logout does NOT trigger |

**This is the answer to "what if the main process wedges":** a watchdog refreshes an
**exchange-side** countdown. If the strategy hangs and stops refreshing, *the
exchange* cancels resting orders — independent of our process state.

Market-wide circuit breakers (US): Level 1 = 7%, L2 = 13%, L3 = 20% S&P decline.

---

## 6. Documented blow-ups

- **Knight Capital (2012)** — $440–460M/45min. Deployed to **7 of 8 servers**;
  the 8th ran old code containing dormant "Power Peg" test logic the new release
  repurposed a flag for. 4M+ erroneous orders, 397M shares. First-ever SEC
  enforcement under Rule 15c3-5 ($12M). No order-vs-intent comparison, no capital
  threshold check, **no kill switch**.
- **Flash Crash (2010)** — a sell algorithm using volume-participation logic with
  **no price or time sensitivity** dumped $4.1B of E-minis in ~20 min. Led to
  Limit Up-Limit Down.
- **MakerDAO "Black Thursday" (2020)** — liquidation keeper bots ran **static gas
  settings**; a 10× gas spike stranded their bids, letting bidders win collateral
  auctions at **$0**. One bot took **$8.32M of ETH for zero DAI**; ~36% of auctions
  went zero-bid; ~$5.67M protocol deficit. *Config that's fine in normal conditions
  becomes fatal in the exact conditions you built the bot for.*
- **BitMEX (same day)** — DDoS traced to an inefficient query from its **chat
  feature** hitting the same DB as the matching engine. 20–25 min offline during the
  crash; ~$1.1B liquidated with users unable to add margin.
- **Oct 10–11 2025** — **$19.13B** liquidated in 24h, largest ever. Reported trigger:
  Binance's Unified Account collateral valuation used its **own internal price feed**
  rather than external oracles; a targeted USDe sell-off crashed its internal quote
  to $0.65 while other venues stayed stable. Attack vs. design flaw is contested
  (UNVERIFIED); the $19.13B is solid.

---

## 7. Reconciliation

**Why state diverges:** WebSocket drops updates *silently without firing a
disconnect*; sequence gaps on reconnect; out-of-order delivery (fills before status);
duplicate IDs after retry; partial-fill races. Named failure mode: **"the bot is
trading on a frozen order book"** — a feed that died an hour ago while looking connected.

**Practice:** exchange is source of truth. Rebuild local state on every startup
before trading. Continuous REST polling at **500ms–1s** as authoritative, WebSocket
as a fast-but-unverified hint. Use a **K-consecutive-mismatch gate** before resyncing
to avoid thrashing.

**NautilusTrader's invariant:** position quantity must match within instrument
precision, average price within **0.01%** — and **if reconciliation fails at startup,
it logs an error and refuses to start.** Hard halt beats trading unreconciled.
Stale-feed age is itself a circuit-breaker signal, independent of price.

---

## 8. Drift monitoring thresholds

**PSI (verified, two independent sources):** <0.1 no shift · 0.1–0.2 moderate ·
**≥0.2 significant**. (A sometimes-quoted 0.25 is UNVERIFIED.) `PSI = KL(P‖Q) + KL(Q‖P)`.

**KS test is too sensitive at scale** — false positives on >100k rows at just 0.5%
shift. Recommended only under ~1,000 rows.

No trading-specific drift literature exists publicly — this is generic MLOps applied
by inference.

---

## 9. Promotion gates — there is no magic number

**No "N months of paper trading" figure exists from any named authority.** This was
searched for specifically and came up empty. The real answer is **statistical
criteria**: DSR with honest N, CPCV regime coverage (have you actually observed
independent market regimes, not just accumulated trade count), permutation tests,
walk-forward efficiency. Then start live with the minimum size that lets the strategy
function, for 1–2 weeks, before scaling.

**Real backtest-live gap, documented:** 20 weeks live on IB, a 3× leveraged-ETF
rotation strategy underperformed backtest by **≈−2.7% total** — −30.8 bps/week
execution slippage, partially offset by +21.0 bps/week rounding effects. Notably the
**higher-volume instrument sometimes had worse slippage** due to rebalance crowding —
liquidity alone doesn't predict slippage.

---

## Flagged UNVERIFIED

Expected-max-drawdown-as-f(Sharpe) formula (dead links); Binance's "125x up to $50k"
bracket (bot-gated); real firms' actual daily-loss thresholds (proprietary,
unpublished); Perold 1988 as implementation-shortfall origin; property-based testing
applied to matching-engine code specifically (Jane Street known for it, not verified).

---

# ADDENDUM — second research pass (2026-08-01)

The retry surfaced primary sources the first pass could not reach.

## The drawdown formula (previously flagged UNVERIFIED — now found)

**Magdon-Ismail, Atiya, Pratap & Abu-Mostafa (2004), "On the Maximum Drawdown of a
Brownian Motion"** — read directly from source PDF:

```
E[D̄] = (2σ²/μ)·Q_p(α²),   α = SR·√(T/2)
```

**The underappreciated result:**
- **Zero-Sharpe strategy:** expected drawdown grows **unboundedly as √T**
- **Positive-Sharpe strategy:** expected drawdown grows only **logarithmically in T**

A genuinely profitable strategy's expected drawdown does *not* keep scaling with
track-record length the way a no-edge strategy's does. **That difference is itself a
detector.**

Illustrative (σ=15% annualised, T=10yr — applied asymptotic form, not the paper's own
table):

| True Sharpe | Expected max drawdown |
|---|---|
| 0.5 | ~33% |
| 1.0 | ~27% |
| 1.5 | ~22% |
| 2.0 | ~19% |

**Decision rule:** treat a drawdown as normal variance while its depth stays inside
the logarithmic envelope implied by the claimed Sharpe. Call it broken only when
(a) PSR against the prior Sharpe drops with confidence, or (b) depth materially
exceeds that envelope. **Never on elapsed time alone.**

## Observation frequency beats calendar time — a design-shaping finding

**Bailey & López de Prado, "The Sharpe Ratio Efficient Frontier"** (Journal of Risk
2012), Probabilistic Sharpe Ratio + Minimum Track Record Length, skew/kurtosis adjusted:

```
σ(ŜR)  = √[(1 − γ₃·ŜR + ((γ₄−1)/4)·ŜR²)/(n−1)]
n*     = 1 + [1 − γ₃ŜR + ((γ₄−1)/4)ŜR²]·(z₁₋α/(ŜR−SR*))²
```

Their worked example — confirming an observed **Sharpe 2.0 really exceeds 1.0** at 95%:

| Data frequency | Time required |
|---|---|
| Daily | 2.73 years |
| Weekly | 2.83 years |
| Monthly | 3.24 years |
| **With real hedge-fund skew/kurtosis** | **4.99 years** |

> **"Frequency of observation, not calendar time, is what buys you statistical power."**

**Direct implication for the three-brain tree:** the fast brains (seconds→minutes)
accumulate `n` orders of magnitude faster than the slow brain, so they reach
statistical significance in far less wall-clock time. That is an argument for the
multi-brain design **beyond diversification** — the fast branches are the ones that
can actually be *validated* quickly, and they can inform priors for the slow branch.

Negative skew and fat tails **inflate apparent Sharpe relative to its reliability** —
crypto has both. Budget for the 4.99-year case, not the 2.73-year one.

## More documented blow-ups

| Case | Loss | Root cause | Missing check |
|---|---|---|---|
| **Wintermute** (Sep 2022) | ~$160M | Hot-wallet keys from the "Profanity" vanity-address tool — weak entropy, brute-forceable | Never use vanity generators for operational keys |
| **Mango Markets** (Oct 2022) | $116M | Attacker spent ~$4M pumping a thin market (<$100k ADV) 10–30×; the on-chain oracle read manipulated spot **directly** as collateral value | TWAP oracles; limits scaled to *real liquidity depth* |
| **FTX/Alameda** (Nov 2022) | Billions | **Alameda was hardcoded-exempt from FTX's own auto-liquidation engine** | **No account is exempt from automated risk checks** |
| **Everbright Securities** (2013) | ~$3.8B erroneous orders | ETF-arb system **repeatedly resubmitted orders on failure instead of stopping** | Idempotent retry + hard order-rate kill |
| **bZx** (Feb 2020) | ~$918K | Logic bug **exempted "overcollateralized" loans from sanity checks entirely** | Apply checks on *all* paths, no exemptions |

> **The common thread across all ten cases: a single missing hard check is what
> failed — not "the market moved a lot."**

Two of them (FTX, bZx) failed on an **explicit exemption** carved into the risk
layer. That yields a rule with no exceptions: **no strategy, however trusted or
however well it has performed, bypasses the risk gate.**

## Halt policy — refined

- **Flatten** — default for any *system-integrity* fault (stale data, wedged process,
  watchdog timeout). Caps risk deterministically while the system is known-broken.
- **Hold** — preferred when the trigger is a *market-wide* halt. Forcing liquidation
  into a halted/illiquid market can be worse than waiting.
- **Hedge** — stopgap when unwinding directly is too costly.

> *"Anything more clever is itself a failure mode (see: FTX's Alameda exemption,
> Knight's stale flag)."* Halt logic must be simple enough to execute correctly
> under degraded conditions.

## Kelly — the growth/variance tradeoff, quantified

Betting fraction `c` of full Kelly yields growth ≈ **c(2−c)** of maximum.
**c = 0.5 → 75% of maximum growth at ~50% of the variance.** Practical consensus:
**quarter- to half-Kelly.** Thorp has stated he personally used half-Kelly or less.

## Reconciliation on divergence — refined

Within tolerance: auto-correct and log. Beyond tolerance: alert a human.
Unexplained mismatch: **halt new order submission — but do not necessarily
force-close existing positions.** Trading on unreliable position state compounds the
error; blind flattening on a *bookkeeping* fault can realise losses unnecessarily.

## Regulatory anchors (verified)

- **SEC Rule 15c3-5** (Market Access Rule) and **FINRA Notice 15-09** — both require
  a **"quick disable"** capability built into algo software. Principles-based, no
  numeric thresholds.
- **LULD** (verified): Tier 1 NMS ±5% above $3.00; ±20% between $0.75–$3.00; bands
  **double in the final 25 minutes**; reference is a 5-min rolling average.
