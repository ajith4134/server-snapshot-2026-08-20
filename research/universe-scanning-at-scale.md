# Scanning a large symbol universe — what real systems do, and what breaks

**Researched 2026-08-19** under RL-045. Binance `exchangeInfo` fetched live; bot source via
`gh` at HEAD; issues cited by number.

## Nobody else does this

**None of Freqtrade, Hummingbot, Jesse or OctoBot treats watching hundreds of symbols
concurrently as a normal live-trading mode.**

- **Freqtrade** — a pairlist pipeline (`VolumePairList` + `AgeFilter`, `SpreadFilter`,
  `VolatilityFilter`, `PrecisionFilter`...). Every example config in `docs/includes/
  pairlists.md` uses small `number_assets`: **20 appears ~9 times, 15 twice, 10 three times,
  5 once.** Explicit warnings the moment a config implies the whole universe ("time and
  resource consuming... downloads candles for all tradable pairs").
- **Hummingbot** — one pair per strategy instance. "Many markets" means many bot processes.
- **Jesse** — routes manually enumerated, all must share one quote asset. Their broad scanner
  (`coin-screener-script`, Ray-based) is deliberately **outside** the live loop.
- **OctoBot** — ships a hard-coded per-exchange capacity table and warns in the UI:
  *"`{exchange}` is overloaded by `{pct}`%... capacity is `{max_load}` simultaneous traded
  pair/timeframe couples."* Issue #1656: a user hit a documented **45 simultaneous REST
  pair/timeframe couples** on Binance.

**Their designs hit connection and rate-limit walls in the tens-to-low-hundreds of pairs,
well before the statistical questions become binding.** They are not informative as an upper
bound for us. The relevant comparison population is quant cross-sectional screening, not
retail bot frameworks.

## Binance limits, fetched live 2026-08-19

| | Spot | Futures (USDM) |
|---|---|---|
| REQUEST_WEIGHT | **6000/min** | **2400/min** (2.5x lower) |
| ORDERS | 100/10s, 200,000/day | 300/10s, 1200/min |
| RAW_REQUESTS | 300,000/5min | n/a |

Endpoint weights genuinely diverge — futures depth is *cheaper* at high depth (20 vs spot's
250 at `limit=5000`); futures klines scale to weight 10 vs spot's flat 2. **Do not port spot
weight assumptions to futures.**

**429 → 418**: 429 is "back off"; 418 is an automated IP ban. *"IP bans... scale in duration
for repeat offenders, from 2 minutes to 3 days."* The schedule between those points is
**UNVERIFIED**. Limits are IP-based, not key-based.

**WebSocket spot**: 5 incoming msg/sec/connection, 1024 streams/connection, 300 connection
*attempts* per 5 min per IP (caps handshake rate, not concurrent connections), 24-hour life.
**Futures fstream**: **10 msg/sec/connection — double spot**; same 1024-stream cap and 24h
life. (UNVERIFIED-RAW: `developers.binance.com` blocked raw curl via Cloudflare; fetched
verbatim through a summarizer.)

### Our own finding appears to be unreported anywhere else

We measured fstream working at **928 streams/connection**, failing with **HTTP 414 URI Too
Long above ~928–960** — well below the documented 1024, because the URL exceeds the server's
~16 KiB request-line limit first. Searches of `ccxt`, `python-binance`, `freqtrade`,
`Binance.Net` and `unicorn-binance-websocket-api` issue trackers **found zero other public
reports of this failure mode.** Our measurement is the best available source for it.

## What actually breaks — real postmortems

- **Rate limits are unpartitioned per IP.** freqtrade#12441: 6 containers (~288 pairs) on one
  IP got repeated 418s because each assumed it owned the full budget. Maintainer's practical
  ceiling: **3–4 bots per IP.**
- **Bulk REST fan-out is Binance's own named ban trigger.** freqtrade#7865/#7187: bulk
  `download-data` triggered a 418 whose error text literally said *"Please use the websocket
  for live updates to avoid bans."* **REST fan-out is the anti-pattern, not WS breadth.**
- **A correctly-throttled WS-only client was NOT found to cause a ban** (Binance.Net#165
  looked like one, resolved as a stray REST call). Useful negative result.
- **Instability arrives before the hard cap.** unicorn#104: one connection carrying all pairs
  and stream types was unstable; sharding by channel type was the fix. Matches our design.
- **Staleness under load is routine, not exceptional.** freqtrade#13459 (Aug 2026): ~1000
  "candle date > last refresh" warnings and 934 REST fallbacks in a day, concentrated at
  candle-close boundaries. Maintainer treats it as expected at scale.
- **Orderbook drift over uptime.** cryptofeed#604 (open): internal book diverges because the
  snapshot is only re-fetched on a sequence gap, never periodically.
- **Memory — we already hit this, with numbers.** From our own `DECISIONS.md`: bar-building
  for one symbol's busiest day (25.9M trades) was OOM-killed at **20.3 GB**. Streaming instead
  of batch-holding took peak to 4.09 GB then **0.25 GB**, and was *faster* (37.7s vs 48.6s).
- **Not found, said so**: no clean postmortem of asyncio queue backlog under Binance volume;
  no documented reconnect-storm incident from many shards hitting the 24h disconnect together
  and then meeting the 300-attempts/5min cap. Plausible mechanically, unwritten.

## Cross-sectional ranking — two correctives

**Crypto cross-sectional momentum is WEAKER than time-series momentum once costs are applied.**
Liu, Tsyvinski & Wu (2022, *J. Finance* 77(2)) establish momentum in a crypto three-factor
model, but the careful follow-up (Han/Kang/Ryu, "under Realistic Assumptions") finds that with
realistic transaction costs and correct significance testing, **cross-sectional evidence is
weak (best Sharpe 1.28, several test portfolios effectively liquidated) while time-series
absolute-threshold momentum is strong (best Sharpe 1.51).** This cuts directly against
assuming cross-sectional ranking is inherently more rigorous than per-symbol thresholds.

**Cross-sectional ranking as practiced is a PERIODIC-REBALANCE technique, not a
continuous-scan one.** Every implementation found — academic and practitioner — rebalances on
a fixed period (monthly in equities, weekly to daily in crypto; fastest found was 1-day
holding on a 14-day lookback). **No source computes cross-sectional rank at sub-daily
per-poll frequency.** The literature's guarantees do not transfer to a per-poll screen
without adaptation.

BTC-beta-neutralisation before ranking is **not** established practice. What is used: a BTC
regime filter, dollar-neutral (not beta-neutral) construction, and in one recent paper Louvain
community detection on the correlation network to rank within clusters.

## The statistical core — three risks that get conflated

**(a) Classic backtest overfitting** (deflated Sharpe, White's Reality Check, Hansen's SPA,
Harvey/Liu/Zhu's t>3.0). **This does not directly apply to a fixed, parameter-free rule
applied identically to every symbol.** One rule on 500 symbols is **one hypothesis with 500
correlated samples**, not 500 hypotheses. It becomes 500 hypotheses the moment per-symbol
fitting is allowed — which is why our own design note's "the setup definition must be
universal and parameter-free across symbols" is load-bearing.

**(b) Single-poll cross-sectional multiple comparisons** — real, bounded, well-studied.
Standard BH/Bonferroni either fail to control FDR under correlation or become overconfident
(arXiv 2102.07826). Solvable with a threshold calibrated once to the correlation structure.

**(c) Repeated testing over unbounded time — THE DOMINANT RISK, and neither (a) nor (b) fixes
it.** Johari, Pekelis & Walsh (2015, arXiv 1512.04922): a rule of "act whenever the statistic
crosses τ at any poll" has a probability of eventually firing under a true null approaching
**100%** as polls grow. Not 5%. Per-poll FDR says nothing about cumulative probability across
an unbounded sequence of looks.

The correct reframe: stop asking *"is this crossing significant"* — nothing crossing a
threshold under continuous monitoring is, in the one-shot sense — and ask *"what is the
tolerable long-run false-entry rate given infinite polling, and does the edge and position
sizing survive that base rate."* A risk-management framing, not a p-value one. Standard
mitigations, both already in our design note: **persistence requirements** (a condition must
hold for a duration, not fire instantaneously — Bax, Sarkar & Shtoff 2024 is the formal
version) and **corroboration across independent data types**.

## Effective breadth — measured on our own data

Grinold's law (IR ≈ IC × √breadth) defines breadth as **independent** forecasts, not universe
size. Clarke et al. (2002): naive 1000-stock IC=0.03 implies IR≈3.29, *"beyond even the most
optimistic portfolio manager's dreams"* — obviously wrong because it ignores correlation.

**We already ran this.** Per `DECISIONS.md`, over 1,331,980 reconstructed funding rows across
850 symbols, six configurations: **effective breadth 46–82 independent bets**, mean pairwise
correlation **0.03–0.06** — comfortably above the 5–15 collapse band. **Carry is not one BTC
factor wearing 850 hats.**

But the same measurement found triggers arrive **17–32× more unevenly than independent
firing**, a fifth of them in the busiest 5% of days. Symbols are less correlated in *outcome*
than feared and **more correlated in *timing*** than independence predicts. That is why the
rising-acceptance-threshold-with-opportunity-flow rule and dry-powder-as-a-held-option framing
are load-bearing, not optional.

## Top three failures at 500+ candidates per poll, and the mitigation

1. **Unbounded repeated testing → near-certain eventual false firing per symbol**, however
   tight the per-poll threshold. *Mitigation*: persistence across consecutive polls, plus
   corroboration across independent signal types (flow AND funding AND open interest).
2. **Correlated co-firing during regime shifts** makes many simultaneous confirmations look
   like independent evidence — our own measured 17–32× trigger clustering is direct evidence.
   *Mitigation*: exposure limits at the factor/cluster level, and size on **measured**
   effective breadth, not nominal symbol count.
3. **Rate-limit failures masquerading as data problems.** *Mitigation*: shard by measured byte
   budget (as we do), keep REST to low-frequency reconciliation, and — the one real gap —
   **instrument a loud first-class event for 414s and 418s**, since both are silent-failure
   shaped: a 414 looks like nothing happened, and a 418 can arrive as clean JSON *or* an HTML
   403 from the edge WAF, so error handling must catch both shapes.
