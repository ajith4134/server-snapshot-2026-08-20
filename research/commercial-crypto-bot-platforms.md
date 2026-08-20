# Commercial crypto bot platforms — what they offer, claim, and actually deliver

**Researched 2026-08-19** under RL-045. **CLAIM** = vendor marketing · **FINDING** =
independently corroborated · **UNVERIFIED** = flagged with reason.

## One line

A subscription software business selling **parameterised rule templates** — grid ladders,
martingale-style averaging, IFTTT indicator triggers, TradingView-webhook execution — with
"AI" as a marketing label over conventional statistics. Revenue is decoupled from user
profitability in every case examined.

## "AI", decomposed across ten platforms

Every claim resolves into exactly one of three things:
- **(a) an LLM generating or editing strategy CODE** — Gunbot ("same technology as ChatGPT",
  converts English to JS, which the docs then say to backtest because it is unvetted)
- **(b) an LLM/statistical layer SELECTING among fixed rule templates** — Bitsgap admits its
  AI-chosen bot then runs on *"the same deterministic rule-based logic any Bitsgap bot uses"*;
  Cryptohopper's help centre says outright **"it's not true Artificial Intelligence (well not
  yet)"** — "AI" means "Algorithm Intelligence", an auto-backtester picking the best-scoring
  member of a fixed strategy library
- **(c) an LLM OPERATING THE UI** — Altrady and Coinrule MCP servers let Claude drive the app;
  every order still needs manual approval

**The cleanest evidence is Binance's own documentation.** Its grid "AI parameters" feature is
documented as: pull 1-day candles over a 7/30/180-day window, compute `(O+C+H+L)/4`, apply
**Bollinger Bands** to suggest a range. Textbook technical analysis, from a public company's
own docs, contradicting its own "AI" label. The Rebalancing Bot's "AI" is asset selection off
a market-cap/volume heatmap.

**None of the ten has published evidence of a trained predictive model making autonomous trade
decisions.** No triple-barrier labelling, no purged CV, no walk-forward discipline anywhere.

## What their backtests actually simulate

- **3Commas** self-discloses: 1-minute candles, fills at the *next* candle's close, not the
  signal instant — a structural, admitted divergence source.
- **Bitsgap** is most rigorous: pulls the user's *actual* maker/taker schedule via API. But its
  own blog tells users to manually add 0.05–0.30% slippage.
- **Kryll** is unusually candid: backtests run in "ideal conditions" and **explicitly exclude
  the impact of the user's own order flow on the book.**
- **Altrady**: backtesting "fills orders based solely on chart price, without an order book",
  and paper fills occur "regardless of whether there would have been enough liquidity."
- **Pionex** republished a user complaint on its own blog: backtest showed **175% return while
  the same "AI" grid strategy lost money over 30 days live.**
- An independent 4-year multi-exchange backtest (dev.to/aduenasdev) found exchange grid
  leaderboards use **survivorship-biased 7-day windows** ("+0.59% in 20 days") while honest
  full-cycle testing shows max drawdowns of **30–58% in a crash** and **+7% grid vs +127%
  buy-and-hold** across the 2023–24 bull run.

**None of the ten models order-book depth or market impact in its default backtest.**

## Grid trading — the technically important part

**Zero expected value, proven.** Chen, Chen & Jang (NTU, arXiv:2506.11921, 2025) prove that
under a symmetric random walk a finite geometric grid's **expected value is exactly zero**,
with a closed-form *negative* correction if price trends through the range:
`E(G) = −(M/n)(n²/8 − n/4)`. Their own 2021–24 BTC/ETH backtest shows "60–70% IRR" and they
explicitly attribute it to the window's secular bull drift, not the grid mechanic.

**Any grid backtest that does not disclose the trend of its test window is not evidence of
edge.**

Correct framing: a grid is structurally a **short-volatility / short-gamma** position — its
payoff can be *replicated* by selling a strip of calls and puts across the range. It is also
market-making **without inventory skewing**: the professional benchmark, Avellaneda-Stoikov
(2008), skews the reservation price with accumulated inventory, realised vol and horizon. A
static grid has none of that and cannot reprice against informed flow.

Empirically (kpaulsen97/dynamic-grid-trading): beats buy-and-hold in bear markets by +5.7%,
**underperforms in bull by −31.4%**, roughly breakeven sideways, **18.8% win rate**, average
loss −26.6% against average win +5.7%. Small frequent gains, occasional large losses — the
short-strangle shape exactly.

**The displayed metric is flattering by construction.** Bybit's and Altrady's own docs
distinguish "Grid Profit" (realised, completed pairs only) from "Total PnL" (including
unrealised mark-to-market on held inventory), and state plainly that **positive Grid Profit
with negative Total PnL is possible.** The dashboard shows the first one.

**No commercial platform has automated regime detection.** Block Research: *"The bot does not
know whether the market is bullish, bearish, or sleeping."*

## DCA bots are capped martingales

3Commas' own documented structure: safety-order deviation scales by `step_scale^(n−1)`, size
by `volume_scale^(n−1)`, take-profit measured off the volume-weighted average of the *whole*
position. A "disciplined" 10k config reaches **24.5% of total capital in one trade by the 7th
safety order**, ~22% below entry. A 3Commas community thread is literally titled *"Martingale
style for DCA bots"*. Capped (finite max orders) so not true gambler's ruin — but the same
directional logic: add risk after losing. Past the ladder's depth it is a static bagholder at
maximum committed capital and worst average price.

## The 3Commas incident — still live litigation

- Oct–Nov 2022: users report unauthorised trades. 3Commas states it is *"pretty sure it wasn't
  breached"* and blames phishing.
- **Dec 28, 2022**: ~100,000 API keys published on Pastebin. CEO confirms next day: *"We have
  seen the hacker's message and can confirm that the data in the files is true."* A month of
  denial reversed within a day of public proof.
- **Mechanism, and the transferable lesson**: keys had **trade-only, no-withdrawal**
  permissions — the industry-standard "safe" configuration. Attackers forced victims to buy
  low-liquidity altcoins they already held, pumped, and dumped. **Trade-only keys did not
  protect anyone.**
- Scale: Halborn ~$20M; ZachXBT verified **44 named victims totalling $14.8M**; the class
  action alleges $22M.
- **Root cause was never publicly proven** — breach, phishing, or both. No attacker identified.
- ***Freeman et al. v. 3Commas Technologies OÜ*, No. 3:23-cv-00101 (N.D. Cal.) — dismissed for
  jurisdiction, and on 2026-03-02 the Ninth Circuit REVERSED and revived it. Active federal
  litigation.**
- From audited Estonian filings: monthly active clients **−40% YoY** to 72,000, revenue −11%
  to €20.5M, swing from €11.9M profit to a €12.5–13.8M loss, explicitly attributed to *"a
  high-level hacker attack"*. 2023 revenue fell a further 49%. Headcount 9 by 2026. Same CEO
  throughout.

Contrast: Cryptohopper's Jan 2024 incident (employee token compromised, no funds or keys lost)
was disclosed the same day.

## Regulatory

Pionex has the deepest record: South Dakota consent order (2025, unlicensed money
transmission), AMF blacklist (Apr 2025), Philippines SEC (Aug 2025), Malaysia SC alert (2023),
plus a 2023 breach exposing ~241,720 users. Binance **Copy Trading was force-shut for all EEA
users in June 2024 under MiCA** — the one bot-specific regulatory casualty.

Separately, the outright-fraud category: **SEC v. Nathan Fuller** (May 2026) — $12.3M raised on
claims of proprietary "AI-based" HFT arbitrage; ~3% ever touched crypto. **CFTC Advisory
8854-24** cites **Mirror Trading International — $1.7B from 23,000+ victims**, marketed as
AI/automated arbitrage. "AI-powered crypto trading bot" is a phrase with a regulator-confirmed
fraud problem attached.

## Does anyone make money?

**No rigorous academic study of retail bot-user profitability exists.** That absence is the
finding — any specific "X% of bot users lose money" claim is very likely unsourced.

By analogy only, and flagged as such: Barber, Lee, Liu & Odean (Taiwan, near-population data)
— **under 1% of day traders** reliably earn positive net-of-fee abnormal returns. Chague,
De-Losso & Giovannetti (Brazil, near-census) — of those persisting ≥300 days, **97% lost
money**; 0.4% earned above minimum wage; no learning effect.

**Structural gap**: ESMA mandates CFD brokers disclose the % of retail accounts losing money
(compiled: **74–89%**). **No crypto bot platform discloses an analogous figure** — they are
sold as software, not as counterparty, so the trigger never applies.

Apesteguia, Oechssler & Weidenholzer, *Management Science* 2020 confirms the copy-trading
dynamic experimentally: visible high returns plus direct copying causes **excessive
risk-taking**, with platform visibility amplifying winners while losers disappear from view.

One named five-year account (Felix Götz, uncoded.ch): net return after Cryptohopper's ~$130/mo
fee was **worse than simply holding Bitcoin**.

## Is anything here worth borrowing?

**Mostly no, and the "no" is informative.** There is nothing resembling triple-barrier
labelling, purged CV, or walk-forward discipline in the entire category. Our approach is not
reinventing what they do better — it is a different technical universe.

What IS worth taking, all on the **risk-accounting and skepticism** side:

1. **The Grid-Profit vs Total-PnL split is a real accounting discipline worth stealing.** Never
   report a headline P&L that excludes floating loss on open inventory. This is our own Rule 8,
   and the grid-bot industry is the case study in the failure it exists to prevent.
2. **Chen/Chen/Jang's zero-EV proof and Avellaneda-Stoikov's inventory skewing** are genuine
   quant literature — the correct starting point if we ever add mean-reversion or
   market-making, not a vendor page.
3. **The backtest-vs-live divergence taxonomy** (idealised fills, no book depth, wrong candle
   resolution, survivorship-biased short windows) is a checklist to verify our own paper
   trading against — including our own future numbers.
4. **The capped-martingale capital-exhaustion model** is a named failure mode worth knowing if
   any of our position sizing ever averages into a position, even unintentionally.
5. **The 3Commas API-key lesson**: trade-only, no-withdrawal permissions are **necessary but
   not sufficient**. That is the threat model for any future live execution.
