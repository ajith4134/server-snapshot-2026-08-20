# Crypto Execution Economics: Where Alpha Dies

Researched by: general-purpose subagent, model sonnet
Date: 2026-08-01
Method: web/Exa search, direct source fetches where possible; search budget exhausted mid-session for some lookups

---

# Crypto Execution Economics: Where Alpha Dies — Research Findings

**Method note:** Web search budget was exhausted mid-session; remaining lookups used Exa search/fetch. Several sources (Coinbase Institutional's actual slippage charts, Bybit's official fee table, Coinbase's official fee page) returned as images/JS or 403'd and could not be read as numbers — flagged below. Do not treat any unflagged number as more solid than its tag says.

## 1. Slippage / market impact magnitudes

The cleanest study found is Coinbase Institutional, *"Temporary market impact vs order book liquidity"* (Kilian Mie & David Duong, May 27 2022) — **VERIFIED** (fetched directly, coinbase.com/institutional/research-insights). Methodology: walked order books from Nomics/Cryptocompare snapshots, April 15–May 15 2022. Qualitative findings (the actual bps-vs-size curves are chart images I could not read numerically — **UNVERIFIED exact values**):
- Below $5M notional, slippage is "relatively balanced" across regulated venues.
- At $2M notional, cross-venue slippage differences are ~10bps; at $5M, ~30bps.
- One venue (labeled "Exchange A") runs only ~2.5–3.5bps above Coinbase Prime's aggregated-liquidity baseline.
- BTC/USD consistently has less slippage than ETH/USD at every size tested.

This study is stale (2022, pre-FTX-collapse liquidity regime) and doesn't isolate $1k/$10k/$100k — those are **UNVERIFIED, estimated**: given top-of-book depth on Binance/Coinbase BTC-USDT typically absorbs low-single-digit-bps for $1k–$10k clips, expect **<1bp** at $1k–$10k, **~1–5bps** at $100k, and **~5–15bps** at $1M for BTC; roughly 1.5–2x worse for ETH at the same notional (consistent with the "BTC more liquid" finding above). I could not find a source that publishes this curve numerically for 2025–2026 conditions.

Kaiko (**VERIFIED**, research.kaiko.com, multiple reports 2024): aggregated Bitcoin **1% market depth ≈ $120M** across 10 major exchanges in 2024 (up from post-FTX lows), and Binance alone averages **~$19B/day** volume vs Bybit ~$4B and Coinbase ~$2.8B (Aug 2024, "Moving Markets" report). Kaiko also reports depth fell ~30% from 2025 highs and that Aug 2025 and Oct 2025 sell-offs produced measurably worse fills even for standard $100k BTC clips — but I could not retrieve the specific bps figure from that report, only the qualitative claim.

## 2. Adverse selection / queue position

Best available academic source: **Tiniç, Şensoy, Akyildirim & Corbet, "Adverse Selection in Cryptocurrency Markets,"** SSRN 4175306, posted 2022 (peer-reviewed version circulating via Bilkent/Bradford repositories) — **VERIFIED** (abstract + body text fetched directly). Method: Huang-Stoll (1997) / Madhavan et al. (1997) spread decomposition on Bitfinex LOB data, Aug 2017–June 2018, 12 major cryptocurrencies. Findings:
- Adverse selection component averages **10% of the effective spread** across the 12 coins.
- **BTC specifically: only 7%** — the lowest in the sample despite BTC having the largest adverse-selection cost in raw dollar terms.
- XMR highest at 13%.

No direct crypto-vs-equity comparison in that paper. For rough context, equity market microstructure literature (Huang & Stoll 1997 original, on NYSE/NASDAQ) generally finds adverse selection at **~10–30% of spread** for liquid large-caps — so BTC's 7% is not obviously worse, but this is comparing different eras/methodologies and I did not verify the equity figure fresh (**UNVERIFIED**, from memory of the cited literature, not re-checked this session). The practical translation: if BTC/USDT quoted spread on a top venue is ~1–2bps, expected adverse-selection cost from resting a limit order is roughly **0.1–0.3bps** per fill — small in absolute terms for majors, but the multiplier gets much worse on illiquid alts where spreads run 10–50bps+.

## 3. Round-trip breakeven bps (built up, not asserted)

For a $100k–$1M account sizing $1k–$100k per trade, moderate frequency, BTC/ETH majors:

- **Fees**: Binance spot base tier **0.10% maker / 0.10% taker** (**VERIFIED**, fetched binance.com/en/fee/schedule directly). Coinbase Advanced Trade base tier reported as **0.40% maker / 0.60% taker** (**UNVERIFIED** — official page returned JS shell / 403 on two fetch attempts; this is a secondhand figure from fee-aggregator sites, consistent across two independent aggregators but not confirmed at source). Bybit spot base tier reported **0.10% / 0.10%** (same caveat — official page didn't render fee table on fetch).
  - Round-trip, two taker legs at Binance base tier: **20bps**. At Coinbase base tier: **120bps**. VIP/high-volume tiers compress this toward ~4–8bps round-trip.
- **Slippage**: using the estimates from §1, round-trip (2 legs) at $10k–$100k on BTC: roughly **2–10bps**.
- **Adverse selection**: if using maker/limit orders, add ~0.1–0.3bps per leg for BTC/ETH (§2) — call it **~0.5bps round-trip**, negligible next to fees.

**Sum, base-tier taker orders on Binance, $10k–$100k BTC/ETH clips: ~22–30bps round-trip breakeven.** Using maker orders + a mid VIP tier: closer to **10–15bps**. On Coinbase retail tier: **~125–135bps** — an order of magnitude worse, driven entirely by the fee schedule, not microstructure. This is arithmetic built from the tagged pieces above, not a separately-sourced number — treat the total as **UNVERIFIED-derived**, only the inputs are individually sourced.

## 4. Where TWAP/VWAP/Almgren-Chriss start to matter

Almgren & Chriss, *"Optimal Execution of Portfolio Transactions,"* Journal of Risk 3, pp. 5–39/40, 2000/2001 — **VERIFIED** citation (cross-confirmed via SCIRP reference records; full text not re-derived here). Core mechanism: trades off temporary+permanent impact against timing risk; matters when order size is large relative to the liquidity you can absorb without moving the book.

Industry heuristic (equities, commonly cited, **UNVERIFIED as a rigorous threshold** — it's practitioner convention, not a peer-reviewed number): don't exceed roughly **1% of ADV** in a single clip; participation algorithms (POV) typically run 5–10% of concurrent volume.

Applying this to your numbers: Binance BTC ADV ≈ $19B (§1, VERIFIED). 1% of that is **~$190M/day**. A $1k–$100k order is **0.0005%–0.05% of a single exchange's daily BTC volume** — five to ten thousand times below where execution-algorithm theory starts to bite in the equities heuristic. Even summing all top-10 exchanges doesn't change the order of magnitude.

**Honest assessment: no, it doesn't matter at your size, for BTC/ETH.** A $1k–$100k clip on BTC/USDT or ETH/USDT is noise relative to Kaiko's $120M 1%-depth figure and Binance's $19B ADV — you will not move the book enough for slicing logic, participation-rate throttling, or Almgren-Chriss risk-aversion tuning to produce a measurably better fill than a single market or marketable-limit order, or at most a crude 2–4 slice manual TWAP over a few minutes to avoid one bad print. This changes only if (a) you're trading illiquid alts with thin books, where even $10k-$50k can be a meaningful fraction of visible depth, or (b) your $1M account starts sizing single clips above roughly $200k-$500k on BTC in stressed/thin conditions (Aug/Oct 2025 depth drawdowns per Kaiko).

## 5. Backtesting traps — be skeptical of your own numbers

- **Survivorship bias**: real and directionally large, but the specific figures I found in casual searching ("inflates returns 200–400%," "Coinbase Institutional Research: 17–22% annually") come from SEO/marketing blog posts (StratBase.ai, Concretum Group) with no traceable primary source — **UNVERIFIED, likely inflated/fabricated attribution**, do not use these numbers. The mechanism is real (delisted coins vanish from most datasets; Binance delistings widen spreads 10–50x before removal per one blog's claim, also unverified) but I could not find a peer-reviewed magnitude.
- **Exchange downtime during exactly the volatile windows a strategy would profit from**: corroborated across multiple independent news outlets (CoinDesk, AmbCrypto, others) — Binance and Coinbase both degraded during the Oct 10 2025 sell-off (~$19B in liquidations in 24h), and Coinbase had a 7-hour AWS-linked outage separately. This is **VERIFIED as a recurring pattern**, not a one-off. Any backtest assuming fills during exactly these windows is fiction.
- **Look-ahead bias from close prices**: standard trap, not crypto-specific, but worse in crypto because many data vendors serve VWAP-smoothed or cross-exchange-blended "close" prices that were never tradable on any single venue at that instant — flagged qualitatively by one CoinAPI blog post, mechanism is sound even though the source is low-grade.
- **Optimistic slippage models**: given how thin the actual public bps-vs-size data is (§1), any backtest using a flat slippage assumption (e.g., "5bps always") is almost certainly wrong in both directions — too optimistic in stressed regimes (Aug/Oct 2025 depth collapse), too pessimistic for $1k–$10k clips in normal conditions.

**Bottom line for capital allocation**: at $1k-$100k per trade in BTC/ETH, execution-algorithm sophistication is not your edge or your risk — fee tier and exchange choice dominate the arithmetic by 5-10x over slippage/adverse-selection, and the real threat to paper alpha is survivorship-biased backtests plus assuming fills during the exact outage windows that would have made the trade profitable.

---

## UNVERIFIED items flagged by the researching agent
- Exact bps slippage figures for $1k/$10k/$100k/$1M clips (estimated, not sourced numerically)
- Coinbase Advanced Trade and Bybit spot fee schedules (secondhand aggregator data, official pages didn't render)
- Kaiko's Aug/Oct 2025 depth-degradation bps figure (qualitative claim only, number not retrieved)
- Round-trip breakeven bps totals (arithmetic built from tagged inputs, not independently sourced as a total)
- Survivorship bias magnitude claims (rejected as unverifiable marketing figures)
- 1% ADV execution-algorithm threshold (practitioner convention, not peer-reviewed)
