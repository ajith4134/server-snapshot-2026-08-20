# Cloud-VM Crypto Latency Research — Findings

Researched by: general-purpose subagent, model sonnet
Date: 2026-08-01
Method: web/Exa search for exchange docs and independent benchmarks; explicitly flagged as a sparsely-documented space

---

## 1. Cloud VM → exchange API round-trip numbers

**Binance** is the best-documented case. Multiple independent sources converge: Binance's matching engine responds fastest from **AWS Tokyo (ap-northeast-1)**.
- Arbitron (vendor benchmark, methodology not fully disclosed) reports REST ticker RTT: Tokyo ~23ms, Seoul ~72ms, Hong Kong ~75ms, N. California ~160ms, Singapore ~206ms, Frankfurt ~268ms, London ~269ms, **N. Virginia (us-east-1) ~424ms**. [VERIFIED as a documented vendor claim; not independently reproducible — arbitron.app/learn/binance-server-location]
- Independent confirmation: Viktoria Tsybko's Hummingbot-based study (real bots placing ~4,000 orders/24hr across 7 Asian AWS regions) found **Osaka edged out Tokyo**, with Seoul close behind — i.e., "Tokyo" isn't even precise enough; AZ/region choice within Asia matters. [VERIFIED independent — viktoriatsybko.substack.com]
- Ember/Deltix measured raw WebSocket market-data feed latency from AWS Tokyo (apne1-az1): **average 4ms, 99th percentile <13ms**, tail spikes to 50+ms. This is one-way feed latency, not order RTT. [VERIFIED, vendor-measured with disclosed methodology — ember.deltixlab.com]
- AWS's own reference architecture doc (aws-samples/sample-cap-quant) gives generic cloud latency floors: same-AZ 10–50µs, cross-AZ 1–2ms, cross-region over AWS backbone 20–100ms. [VERIFIED, AWS-published]

**Other exchanges** (from the same Arbitron multi-region sweep, tag: documented vendor claim, not independently reproduced): Bybit fastest from Singapore ~16ms; OKX fastest from Hong Kong ~35ms; Coinbase fastest from Singapore ~19ms; Kraken fastest from Frankfurt ~18ms. Worst-region figures for all of these land in the 300–500ms+ range from the wrong continent (e.g., Coinbase from wrong region ~84ms only, because it partly serves cached data from multiple regions; Bybit worst-case ~304ms).

**us-east-1 specifically**, since it's a natural default choice: it is a *bad* region for most Asia-hosted matching engines (Binance ~424ms, similar penalty for Bybit/OKX) and a *good* region only for US-based venues like Coinbase's institutional/Prime infrastructure and Kraken's US matching. One independent blog (nikhilpadala.com) reports **Dubai→us-east-1→Binance USDT-M futures at 168–174ms avg/198ms p99** — a different vantage point than the AWS-region sweeps above, and it asserts Binance futures matching sits in us-east-1, which conflicts with the Tokyo-hosting claim from Arbitron/Zenlayer/NYXANCE. **This is a genuine unresolved conflict in public sources** — spot vs. futures matching engines may simply live in different regions, but no authoritative disambiguation was found. [Flagged as UNVERIFIED/conflicting]

GCP-specific exchange-latency benchmarks are essentially absent from public sources — no GCP-region-to-Binance/Bybit/OKX measured RTT table was found. What exists is generic cloud-networking benchmarks (a GCP c3 HFT-infra repo showing same-zone RTT of 30–60µs and AWS↔GCP cross-cloud RTT of 30–80ms; Google's own C3/28Stone benchmark, which is CME-equities-focused, not crypto). **Given AWS and GCP both ride the same public internet backbone for the "last mile" to an exchange's actual matching-engine datacenter, GCP asia-northeast1 (Tokyo) numbers should be order-of-magnitude comparable to AWS ap-northeast-1** — but this is an estimate, not a measurement. [UNVERIFIED — no GCP-specific crypto benchmark found]

## 2. Colocation / proximity latency vs. cloud baseline

This space is genuinely thin on public numbers.
- **Kraken** announced (2026) a colocation service via Beeks Exchange Cloud at its European datacenter; Kraken's own press release states London-based clients get "sub-millisecond" latency. [VERIFIED, official press release, but no exact figure given]
- **Equinix TY11 (Tokyo)** hosts Bybit's and other venues' matching infrastructure; measured inter-datacenter RTT Tokyo↔Singapore (Equinix TY11↔SG3) runs **19–28ms** depending on carrier (Equinix's own IX fabric ~19–21ms). Same-facility colocation RTT to a matching engine is characterized as **roughly 1–3ms** for crypto (vs. **~5µs** for CME equities colocation in Aurora, IL) — crypto colocation means "same Equinix building," not "same rack/cage" the way legacy equities colo does. [Independent blog, plausible and detailed but single-sourced — nikhilpadala.com; treat as UNVERIFIED precision, directionally credible]
- Specialized providers (BSO, Zenlayer, "TheHUB"/Fogo at Equinix Tokyo) advertise "sub-microsecond" or "~2ms" proximity hosting, but published figures are marketing claims without disclosed methodology (Zenlayer claims ~2ms bare-metal-to-AWS-Tokyo; BSO claims sub-µs on RF routes generally, no crypto-specific number given). [UNVERIFIED — vendor marketing, no reproducible benchmark]

**Directionally**, the gap is consistent across sources: colocated/proximity ≈ **low single-digit ms or less**; cloud-VM in the *right* region ≈ **20–75ms**; cloud-VM in the *wrong* region ≈ **200–500ms+**. That is roughly a **10–20x** gap between "cloud VM, correct region" and "colocated," and another **10x** on top of that if you're also in the wrong region.

## 3. DEX app-chain latency: dYdX v4 and Hyperliquid

**dYdX v4**: block time is **~1.0–1.2 seconds** (Cosmos SDK/CometBFT), with single-block finality — once ⅔ of validators commit, there are no reorgs. Network RTT to a validator (a few to tens of ms) is dwarfed by the ~1s block cadence; the dominant latency term is **consensus, not network**. [VERIFIED — docs.dydx.community, docs.dydx.exchange]

**Hyperliquid**: HyperBFT (HotStuff-derived) end-to-end order latency, per official docs, is **median 0.2s, p99 0.9s for a geographically co-located client**. [VERIFIED, official docs — hyperliquid.gitbook.io; note an older/unofficial wiki cites median 0.1s/p99 0.5s, a discrepancy possibly reflecting an earlier network version]. A third-party measurement (Glassnode's "Hyperlatency," reported via Invezz) found order round-trip from **AWS Tokyo at 884ms median (only ~5ms network, ~879ms server-side processing)** vs. **~1,079ms from Ashburn, VA** — a ~200ms non-colocated penalty on roughly a 1-second cycle, and notably showing that *server-side/consensus processing*, not the network leg, is the larger term even from the best location. [VERIFIED as reported by a named research source, secondhand via a news outlet]. All 24 Hyperliquid validators are reported concentrated in AWS Tokyo. Bottom line: **for both chains, block time/consensus dominates over WAN RTT** — a cloud VM anywhere reasonably close still pays mostly the same ~1s (dYdX) or ~0.2–0.9s (Hyperliquid) consensus tax; region choice shifts you by tens to a couple hundred ms, not orders of magnitude.

## 4. Strategy-class verdicts given these numbers

- **Passive market making for queue priority at best bid/ask (CEX)**: **don't bother.** Colocated firms operate at ~1–3ms; a cloud VM in the correct region is 20–75ms, wrong region 200–500ms. You lose queue priority on effectively every contested tick.
- **Latency arbitrage (cross-exchange or spot/perp)**: **don't bother.** Same math — this requires beating colocated bots on a race measured in single-digit ms; structurally 10–100x slower from a cloud VM.
- **Statistical arb / pairs trading at sub-second-to-few-second horizons**: **degraded but not flatly closed** if your holding/rebalance horizon is toward the multi-second end and you're in the *correct* region (e.g., Tokyo for Binance/Bybit). At sub-second horizons it converges to the latency-arb case above and should be abandoned; at few-second horizons, 20–75ms of cloud RTT is a small fraction of the holding period and mainly costs you fill-price slippage, not structural exclusion.
- **Momentum/signal trading at minute-to-hour horizons**: **not meaningfully affected.** 20–500ms is 0.001–0.01% of a one-minute holding period; region choice barely matters here beyond avoiding pathological worst-case regions.
- **Funding-rate arbitrage and other carry/structural trades**: **not latency-sensitive by construction** — no source found had anything to say about latency mattering here; these strategies rebalance on funding-interval or hourly timescales, so cloud-VM latency is irrelevant. This is the strategy class cloud-VM constraints don't touch at all.

For a sub-second-frequency component specifically: if it's meant to compete for queue priority or race other bots tick-by-tick, the numbers above say plainly it's not winnable from a cloud VM, colocated-or-not-quite-colocated proximity hosting notwithstanding (which itself only gets you to ~1–3ms, still behind true rack-level colo). If a "sub-second" band is redefined toward multi-second stat-arb, or is really consensus-bound DEX activity (dYdX/Hyperliquid), region selection (Tokyo/ap-northeast-1 for Hyperliquid; nearest low-latency path to whichever validator set dYdX uses) yields a real but bounded improvement — tens to ~200ms — since block time/consensus, not network RTT, sets the floor.

---

## UNVERIFIED items flagged by the researching agent
- GCP-region-to-exchange latency (no benchmark found at all; estimated as comparable to AWS by backbone-sharing logic only)
- Whether Binance futures matching lives in Tokyo or us-east-1 (two source families conflict directly)
- Exact colocation RTT figures (~1-3ms same-Equinix-building claim; single-sourced blog, directionally credible not confirmed)
- Vendor proximity-hosting marketing claims (Zenlayer ~2ms, BSO sub-µs — no disclosed methodology)
- Hyperliquid median/p99 latency discrepancy between official gitbook and an older unofficial wiki
