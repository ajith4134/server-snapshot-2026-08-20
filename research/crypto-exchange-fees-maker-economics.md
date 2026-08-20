# Exchange Maker/Taker Fee Research — Findings and Viability Assessment

Researched by: general-purpose subagent, model sonnet
Date: 2026-08-01 (fee numbers checked this date — fee schedules change; re-verify before sizing capital)
Method: direct fetch of official fee pages where possible; secondary-source convergence where official pages blocked/JS-rendered

---

**Methodology note:** I attempted live fetches of every official fee page below. Binance spot and both Kraken pages loaded with full numeric tables (tagged VERIFIED). Binance futures, Bybit derivatives, OKX (both fee pages), and Coinbase (both endpoints) either required an authenticated session, returned only page metadata (JS-rendered SPA that WebFetch's markdown converter can't execute), or returned HTTP 403. For those I report the converged figures from multiple independent secondary sources found via search today (2026-08-01), tagged UNVERIFIED. Do not size capital off UNVERIFIED numbers without confirming from a logged-in account dashboard or the exchange API's `/fee` endpoint first.

## Binance
- **Spot** — VERIFIED, https://www.binance.com/en/fee/schedule (checked 2026-08-01): Regular/non-VIP: maker 0.100%, taker 0.100% (<$1M 30-day volume). VIP1 (≥$1M vol, ≥5 BNB): 0.090%/0.100%. VIP2 (≥$5M, ≥25 BNB): 0.080%/0.100%. VIP3 (≥$20M, ≥100 BNB): 0.040%/0.060%. BNB-payment discount: 25% off, at every tier.
- **USDS-M Futures** — UNVERIFIED (live page returned "No records found" logged out). Convergent secondary sources (bitdegree.org, trade-reclaim.com) cite base/VIP0: maker 0.0200%, taker 0.0500%, BNB discount 10%, scaling toward 0% maker / ~0.017% taker only at VIP9.
- No maker rebate (negative fee) documented at any reachable tier for a retail-size account on either market.

## Bybit
- **Spot** — VERIFIED, https://www.bybit.com/en/help-center/article/Bybit-Spot-Fees-Explained (checked 2026-08-01): non-VIP maker 0.1%, taker 0.1% — flat, identical rate. No base-tier maker discount at all on spot.
- **USDT Perpetual** — UNVERIFIED (official VIP-structure article returned "not supported on this site"). Secondary sources (bitdegree.org, cointribune.com, trade-reclaim.com) converge on non-VIP: maker 0.02%, taker 0.055%.
- No maker rebate confirmed at any tier reachable without institutional-scale volume ($1M–$50M+/month for early VIP tiers per secondary sources).

## OKX
- Live numeric fee table not obtainable — okx.com/fees and the help-center fee-detail pages are client-rendered; WebFetch retrieved only page titles/metadata. **All OKX numbers below are UNVERIFIED.**
- The official FAQ (https://www.okx.com/help/trading-fee-rules-faq, checked 2026-08-01) does textually confirm the rebate mechanism exists — its worked example shows a maker fee of "-0.002%" — but this is an illustrative example, not confirmation of the current base-tier rate.
- Commonly cited (secondary, unverified today): Lv1 regular spot ≈ 0.08%/0.10% maker/taker; Lv1 perpetual swap ≈ 0.02%/0.05%. OKB holdings give an additional discount. VIP1 needs roughly $100K–$5M/month depending on product; genuine rebate tiers are far higher.

## Coinbase
- Both https://www.coinbase.com/advanced-fees and https://help.coinbase.com/.../fees returned HTTP 403 to automated fetch — **no live numbers obtained; everything below is UNVERIFIED**, drawn from converging secondary summaries (bitget.com, datawallet.com, cryptsy.com, checked 2026-08-01).
- **Coinbase Advanced Trade**: base tier (<$10K 30-day volume) ≈ maker 0.40%, taker 0.60%. Fees step down through ~8 tiers to maker 0.00%, taker ≈0.04–0.05% only above ~$400M/30-day volume — completely out of reach for this account size. No maker rebate (floor is 0%, not negative) at any publicly known tier.
- **Retail/simple Coinbase app** (distinct product, same company): historically carries a spread markup plus a separate flat/percentage fee, commonly cited at an effective 1–4% all-in for small trades — dramatically worse than Advanced Trade for the identical asset. This is the classic Coinbase quirk: never route algo/automated flow through the retail app pricing; it must use Advanced Trade / Exchange API pricing. I could not confirm the current retail number against the live legal/fees page (403), so treat this as directionally correct but not load-bearing for sizing.

## Kraken
- **Spot** — VERIFIED (fetched twice, consistent both times), https://www.kraken.com/features/fee-schedule (checked 2026-08-01): Tier 1 ($0+): maker 0.40%, taker 0.80% — the highest base-tier maker fee of any exchange reviewed. Scales down through Tier 12 ($10M+ 30-day volume): 0.00%/0.10%, to Pro 5 ($500M+): 0.00%/0.05%. The table shows a 0.00% floor, not negative, at every tier disclosed. (A separate Kraken support article states fees range "‑0.02% to 0.40%," implying a rebate exists somewhere — possibly a market-maker program not shown in the standard tier table. This is a real discrepancy between two official Kraken pages; treat the tier-table 0.00% floor as authoritative for a retail account and the rebate claim as unresolved.)
- **Futures/Derivatives** — VERIFIED, https://support.kraken.com/articles/360048917612-fee-schedule (checked 2026-08-01): Tier 1 ($0+): maker 0.0200%, taker 0.0500%. Rebates begin at $250M+/30-day volume: maker ‑0.0030%, taker 0.0175%, deepening to ‑0.0060% maker at $1B+.

## Post-only mechanics
All five exchanges document a true post-only order type (Binance `LIMIT_MAKER`, Bybit `PostOnly` TIF, OKX `post_only`, Coinbase Advanced `post_only` flag, Kraken `post` flag) that is rejected — not executed as taker and not auto-repriced — if it would cross the book at submission. Not re-fetched against today's docs in this session, so tag UNVERIFIED-but-high-confidence; it is standard, long-standing behavior on all five.

## Realistic tier for a $100k–$1M account
Every VERIFIED and converged-secondary number above shows meaningful tier improvement requires $5M–$250M+ in 30-day volume, and true rebates require $250M–$1B+ (Kraken futures) or effectively unreachable volume elsewhere. A $100k–$1M account trading moderately — not wash-trading, not HFT — will realistically sit at base tier (VIP0/Lv1/Tier1) on every exchange, indefinitely. The only exception is Binance spot VIP1 ($1M/30-day volume), reachable with sustained ~$35k/day turnover, which buys a mere 1bp maker improvement (0.100%→0.090%).

## Direct answer on viability
No — a rebate-capturing maker strategy is not viable for this account from a cloud VM, and the reasoning doesn't require hedging. First, there is no rebate to capture: at every exchange, the fee tier this account will actually occupy is strictly positive on the maker side (2bps on perps at Binance/Bybit/OKX base tier, 40bps on Kraken spot, 10bps on Binance/Bybit spot). The entire available edge is the maker-vs-taker *differential* — roughly 2–5bps on liquid perps, 0–30bps on spot depending on venue — not a rebate. Second, that thin differential is exactly the amount competed away by colocated market makers on the pairs where this differential matters most (BTC/ETH perps on Binance/Bybit/OKX), which are the most latency-contested order books in crypto. A cloud VM, even a well-placed one, loses queue priority by single-digit to double-digit milliseconds against colocated infrastructure; the practical effect is that your resting maker orders get filled disproportionately on the *adverse* side — informed flow arrives, price moves, colocated makers cancel in microseconds, you don't, and you get run over. Adverse-selection cost on liquid majors routinely exceeds 2–5bps per fill during normal volatility and spikes far higher during moves — enough to fully erase and invert the fee-tier advantage this account can actually reach.

**Practical recommendation**: treat post-only limit orders as an execution-cost-reduction tool on trades you'd make anyway (saving the maker/taker spread when you have directional conviction and can tolerate not being filled), not as a standalone rebate-farming strategy. If pursuing genuine liquidity provision, look at less latency-contested pairs (smaller-cap perpetuals, less popular spot pairs) where colocated competition is thinner — but that trades queue-position risk for thinner/more volatile books, a different risk, not a free lunch. Do not build a P&L model around capturing negative fees; at this account size, on major pairs, from non-colocated infra, that tier is not reachable and the attempt to act like a market maker without market-maker infrastructure will likely lose money to adverse selection even before considering the (non-existent, at this size) rebate.

---

## UNVERIFIED items flagged by the researching agent
- Binance USDS-M Futures fee schedule (secondary sources only, official page didn't render logged-out)
- Bybit USDT Perpetual fee schedule (official page returned "not supported")
- All OKX fee numbers (client-rendered pages, only textual rebate-mechanism confirmation obtained)
- All Coinbase fee numbers, both Advanced Trade and retail app (403 on official pages)
- Kraken's separate "-0.02% to 0.40%" rebate claim vs the tier table's 0.00% floor (unresolved discrepancy between two official Kraken pages)
- Post-only mechanics across all 5 exchanges (standard/high-confidence but not re-verified against current docs this session)
