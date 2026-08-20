# Instagram links — per-link findings

**57 unique shortcodes** across both batches (not 56 — the canonical list was re-extracted from the
session transcripts, and one link appeared in both batches).

Raw material is preserved at **`~/research/instagram-raw/`** — 92 MB, 470 images, transcripts, and
captions. `batch2-posts/`, `batch1/`, `reels/`, plus the two driver scripts. Nothing here depends on
a session staying alive.

**Method** (the `instagram-content` skill): `instaloader` for images/captions, `ytgrab --every 3` for
reels (frames + local Whisper), `ffmpeg` for carousel video-slides. Status per link is recorded
honestly below — `IMAGES READ`, `TRANSCRIPT READ`, `CAPTION ONLY`, or `FAILED`.

## Final coverage — counted from disk, not from memory

| | Count |
|---|---|
| Links read at media level (images and/or video frames and/or speech) | **49 / 57** |
| Caption only — no media published | 2 (`Da0EeF1DTZ-`, `Dax2J2LEl5G`) |
| Unrecoverable | 6 |
| Carousel images read | 144 |
| Video frames extracted | 445 |
| Real Whisper transcripts (excluding "no audio" stubs) | 19 |

The 6 unrecoverable are `DaqrnR3j8oM`, `DatgKiljpXS`, `DXZX8JYDZZt`, `DYSAzzpAZH9`, `DYNEuorDrLy`,
`DT1WyeYjEnL`. Retried through a second, independent path (`yt-dlp` direct + `ffmpeg`, bypassing
`ytgrab`) and all six returned the same error:

```
ERROR: [Instagram] <code>: Instagram sent an empty media response.
```

That is login-gating or removal at Instagram's end, **not a tooling failure** — anonymous fetch cannot
reach them. To read these, open them signed-in and paste the caption or a screenshot.

---

## The two headline findings

### 1. `@seb.ai` fabricates its source material — 5 links affected

The "5 GitHub repos" carousel (`DagUfJzgeTx`) names six repos with star counts:
`ai-market-scanner` 3.9k★ · `ai-trading-agent` 4.2k★ · `backtesting-engine` 5.1k★ ·
`ai-news-sentiment-bot` 3.7k★ · `ai-trade-journal` 4.3k★ · `my-trading-workflow` 4.7k★.

**`gh search repos` finds none of them at those counts.** The dashboards, equity curves, Sharpe
figures and star badges are AI-generated mockups. Every post ends gated behind a comment keyword.

Affected: `DagUfJzgeTx`, `DazZdo6Dv-S`, `Da6C_ajgZ2B`, `DauS_vfFCHE`, `DbMx1AUlBo7`.

**This retracts a batch-1 conclusion.** `instagram-sources.md` recorded `DbMx1AUlBo7` ("AI hedge fund,
RESEARCH → DEBATE → BACKTEST → RISK → EXECUTE → REVIEW") as *"structurally the same shape as
DECISIONS.md — independent convergence is mildly reassuring."* It is not independent convergence. It
is one marketing account posting the same fabricated template under four different names
(OPUS 5 AI HEDGE FUND, CITADEL OS, 24/7 AI TRADER, Fable 5 × Kalshi), with invented metrics
(VaR 95% −1.89%, beta 0.67, max DD −12.4%). **Carries zero evidential weight.**

### 2. Caption-only reading produced at least one false claim, and buried the best material

`DbDbx6onUOI` was recorded in batch 1 as *"content gated behind comments — the actual material is not
in the post."* **False.** All 30 formulas are printed in the slides. The "gated" claim was an artifact
of never looking at the images.

The same failure hid the most useful content in the whole corpus — see Kronos, Zomma, delta/absorption
and MacroHFT below. Caption text described none of it.

---

## Genuinely useful — actionable

| Link | What the images/audio actually contained | Where it lands |
|---|---|---|
| **`DbO5FVYgd19`** Kronos | **API surface**: `KronosTokenizer.from_pretrained("NeoQuasar/Kronos-Tokenizer…")`, `Kronos.from_pretrained("NeoQuasar/Kronos-small")`, `KronosPredictor(model, tok, max_context=512)`, `pred.predict(df=klines[-400:], pred_len=120)`. **Architecture**: K-line tokenisation via **BSQ** → coarse+fine subtokens → causal transformer, cross-attention header. **Both tokenizer and predictor finetune** on your own asset. Final slide, verbatim: *"Raw signals are not pure alpha. No transaction costs, no risk neutralization. **A research tool, not a money printer.**"* | Zero-shot baseline gate. **`max_context=512` is a hard constraint** on the 400→120 setup. The disclaimer is the authors' own and supports our validation stance |
| **`DbYOQlSFJSZ`** Zomma | Now **quantified**, not just described. σ=15.9% → Δ 0.636, Γ 0.130, **Zomma −0.749**; σ=8.6% → Δ 0.822, Γ 0.164, **Zomma −0.373**. S≈30.4–31, K=30, T=90d, r=4.15%. *"Lower vol makes the gamma bell taller and narrower."* | Phase 6 options layer. Confirms Zomma runs negative near the money — a vol spike drains gamma exactly where you are sitting |
| **`Da_f158GyKd`** delta/absorption | Full mechanism on a footprint chart: aggressive buying into **passive seller absorption** at the high; *"high volume without price progress is a sign of reversal."* The trap: green delta lures retail to chase while institutions absorb passively, then drive price down filling on the stop runs | **Order-book signal layer.** Reinforces depth-weighted OFI over raw delta — and gives a concrete absorption signature to detect |
| **`DbXE8o_sspP`** MacroHFT | The **objective function**: `L_HFT(τ_a, λ_m) = −S̄ + ασ_S + βD_max + γC + δΩ` — negative mean Sharpe plus penalties on vol, max drawdown, cost, churn | Directly reusable shape for our promotion-gate objective. Creator still disclaims real alpha |
| **`Dbbvsvcsmbb`** AOSm | The actual **update rule**: `x_i^{t+1} = p_i^t + η_t(c_i^t − p_i^t)`, `c_i^t ∈ {g^t, ℓ_i^t}`, `g^t = argmin_j L(x_j^t)` | Optimiser candidate — must run inside the Trial Registry, same multiple-testing caveat as any search method |
| **`DYU0dMcpBFP`** vertoxquant | **Random matrix theory for correlation cleaning**: *"Most correlations in financial markets are fake… if an eigenvalue looks statistically random, remove it."* | **Portfolio/risk layer.** Marchenko–Pastur denoising before covariance estimation — real, standard technique, and we had not recorded it |
| **`DY4dxCkDa8Z`** 5 libraries | Five verified libraries, all real (see table below) | Options, allocation, and Bayesian layers |
| **`DZ2PiNFltKt`** ZipLime | `Limex-com/ziplime` — Zipline reimplemented on Polars, claims identical strategy code backtest→live | **Considered and rejected** — see below |

### The five libraries (`DY4dxCkDa8Z`) — all verified real

| Library | Version | License | Stars | Use |
|---|---|---|---|---|
| CVXPY | 1.9.2 | Apache-2.0 | 6,293 | Allocation — CVaR, tracking-error, MIP cardinality caps |
| NumPyro | 0.21.0 | Apache-2.0 | 2,730 | Stochastic vol, regime detection, hierarchical alpha — posteriors not point estimates |
| Diffrax | 0.7.2 | Apache-2.0 | 2,078 | Heston / rough Bergomi / jump-diffusion calibration as one optimizer call |
| FinancePy | 1.0.1 | **GPL-3.0** | 3,080 | SABR, LMM, Hull-White, Bermudan trees, CDS — copyleft, same caution as Nautilus's LGPL |
| py-pde | 0.58.0 | MIT | 463 | Black-Scholes, **Dupire local-vol PDE**, Fokker-Planck of a diffusion |

> The py-pde slide was a **video slide** inside the carousel and was silently dropped by
> `instaloader --no-videos`. Recovered by re-fetching with video enabled + `ffmpeg` frames.
> **This is a real failure mode of the skill as written** — carousels can mix image and video slides.

### ZipLime — considered, not adopted

`Limex-com/ziplime`: **452★, GPL-3.0, Python ≥3.12, PyPI 1.19.16, pushed 2026-07-22.** Real and active.
Claims the same "identical strategy code across backtest and live" property we chose NautilusTrader
for, and its own benchmark chart puts Nautilus second-fastest.

**Not reopening the stack** (§3c ARCHITECTURE.md): the benchmark is vendor-published by Limex, and
**GPL-3.0 is stronger copyleft than Nautilus's LGPL-3.0**, which §3c already flags as a constraint.

### Kronos — verified, with a caveat worth recording

`shiyu-coder/Kronos`: **35,412★, 5,902 forks, MIT** — but **last push 2026-04-13, ~4 months stale.**
Check maintenance status before treating it as a live dependency.

---

## Per-link ledger

### Batch 2 — posts and carousels

| Shortcode | Status | Content |
|---|---|---|
| `DazZdo6Dv-S` | IMAGES READ (8 slides) | @seb.ai "Fable 5 × Kalshi" prediction-market forecaster. EVENT→RESEARCH→DEBATE→PROBABILITY→RISK→FORECAST. Concept diagrams only, gated "FORECAST". **Fabricated-source account** |
| `Da6C_ajgZ2B` | IMAGES READ (8) | @seb.ai "24/7 AI TRADER". SCAN→SIGNALS→PLAN→RISK→MONITOR→DECISION. Blueprint mockups, gated "24/7". **Fabricated-source account** |
| `DaprsQ4CdnU` | IMAGES READ (2) | **Relationships Among Common Distributions** reference chart — Geometric→NegBinomial→Poisson→Binomial→Normal with transformations and limits, plus Gamma, Beta, χ², Cauchy, t, F, Weibull, Lognormal. Genuinely useful reference |
| `DauS_vfFCHE` | IMAGES READ (8) | @seb.ai "CITADEL OS" — Research/Bull/Bear/Trader/Risk/Verdict. Gated "FUND". **Fabricated-source account** |
| `DZyRSEvjCDS` | IMAGES READ (8) | 7 financial models: reverse DCF, comps, 3-statement, LBO, M&A accretion/dilution, portfolio risk, Monte Carlo. Equity/IB valuation — **irrelevant to a crypto systematic stack** |
| `DagUfJzgeTx` | IMAGES READ (8) | The fabricated repo list. See headline finding 1 |
| `DY4dxCkDa8Z` | IMAGES READ (6 + video slide) | The five libraries. **High value** |
| `DZ2PiNFltKt` | IMAGES READ (6) | ZipLime / Quant Science. Real repo, see above |
| `DZtFyvpjoHz` | IMAGES READ (9) | 8 quant portfolio projects: options pricing engine (Greeks 5ms), stat-arb backtester (1,000+ strategies), factor model (5–10 factors), HFT simulator (1ms ticks), 99% VaR engine, crypto arb bot (0.2–1.5% spread), ML alpha model (**"Sharpe 1.2–2.0"** — treat sceptically against our own 73% backtest→live deterioration finding), portfolio optimizer (100+ assets) |

### Batch 1 — previously CAPTION ONLY, now read at image/video level

| Shortcode | Status | Content |
|---|---|---|
| `DbO5FVYgd19` | IMAGES READ (6) | **Kronos** — see above. Major upgrade over caption |
| `DbDnA_8kcjW` | downloaded (7 jpg) | Second Kronos post |
| `Dbbvsvcsmbb` | FRAMES READ (4) | **AOSm update rule** recovered |
| `DbPaMI1ndH2` | IMAGES READ (3) | Three dense cheat-sheets: mean reversion, neural networks in algo trading, statistical arbitrage. Textbook, but the stat-arb backtesting checklist (survivorship, look-ahead, transaction costs, slippage) matches our validation stack |
| `DaNFqoYNtIQ` | FRAMES READ (5) | Real DOM/ladder screen recording — large resting orders held. Reinforces L2 depth as P0 data |
| `Dax2J2LEl5G` | CAPTION ONLY | No media published. Gated "SEND". Nothing recoverable |
| `DbT9K96Afsx` | IMAGES READ (8) | "AI COMPANY OS" — CEO/support dashboards. **Not trading at all.** Gated "STARTUP" |
| `DbYwC02ERkt` | FRAMES READ (8) | The viral profit claim, now showing **$245,092 / 64 days / +2,148%, 62,824 trades, 58.8% win, Sharpe 4.91** (caption said $220k — the number moved). Stated mechanism: news breaks → Polymarket odds take 30–90s to adjust → bot enters during the lag → exits before repricing completes. Unverifiable dashboard; **mechanism is coherent, the numbers are not evidence** |
| `DbYOQlSFJSZ` | FRAMES READ (4) | **Zomma quantified** — see above |
| `DbXE8o_sspP` | FRAMES READ (5) | **MacroHFT objective function** — see above |
| `DbMx1AUlBo7` | IMAGES READ (8) | "OPUS 5 AI HEDGE FUND". **Retraction target** — see headline finding 1 |
| `DbL4zzRo7dy` | FRAMES READ (8) | Meme-edited, but embedded cards state: *"Institutions don't need direction — directional edge ✗, volatility edge ✓; institutions profit from pricing risk, not predicting direction"*, and low-vol regimes let institutions build size quietly. Consistent with our regime work, not new |
| `Da8LFnfFnqx` | downloaded (8 jpg) | 17 Python libraries post |
| `DbGFvV0Bwn5` | FRAMES READ (8) | **Not a trading tool.** "WEB 4.0 / Conway — giving AI access to the world": `npx conway-terminal`, onchain identity, pay x402 services in USDC, spin up Linux compute, run frontier inference. Agent-with-a-wallet autonomy. Off-project, but a **security consideration** given Rule 4 |
| `Da_f158GyKd` | IMAGES READ (6) | **Delta vs absorption, full mechanism** — see above |
| `DbGYmZQiHxN` | IMAGES READ (7) | Grokking — memorisation first, generalisation later, against the classic bias-variance curve. Plus the anti-grokking collapse at ~10M steps from the caption. Argues against "train longer is safer" |
| `DbDbx6onUOI` | IMAGES READ (6) | **The 30 formulas, not gated.** Bayes, conditional probability, E[X], Var, Cov, correlation, Z-score, LLN, matrix mult/inverse, eigen, covariance matrix, gradient, Hessian, Lagrange multipliers, Taylor, partials, chain rule, **Itô's lemma, GBM, Wiener process, SDE**. Textbook, but the batch-1 "gated" claim was wrong |
| `DbKYvkCifnY` | downloaded (15 jpg) | ML number patterns — 15 slides |
| `DaqrnR3j8oM` | FAILED | instaloader "Fetching Post metadata failed" (tried twice across two sessions) |
| `DatgKiljpXS` | FAILED | Same failure mode |
| `Da0EeF1DTZ-` | CAPTION RECOVERED | 10 open-source projects: Dify, Crawl4AI, Stirling PDF, Supabase, Langflow, Browser Use, Open WebUI, Maxun, OpenHands, Coolify |
| `DYB671CtuaQ` | CAPTION RECOVERED | Caption is just "Tier List" |
| `Da_kNEjNt9f` | CAPTION RECOVERED | "Ai 24/7 at $0 cost" |
| `Da1XG9qgd4E` | CAPTION RECOVERED | **AI supply-chain security**: embedded payloads in models, hidden behaviours triggered on events; recommends running models **air-gapped and sandboxed** because detection tooling is immature. Relevant to Rule 4 / secrets posture |

### Reels — transcript + frames

| Shortcode | Status | Content |
|---|---|---|
| `DYU0dMcpBFP` | TRANSCRIPT + 11 frames | **Random matrix theory correlation cleaning.** Best reel in the set |
| `DVRWC25DDid` | TRANSCRIPT + 11 | GBM → Monte Carlo, *"a probability not a prediction."* Basic but correctly framed |
| `DZ2eqaZInfk` | TRANSCRIPT + 41 | Gradient descent explainer. Basic |
| `DVaB4VAEhMf` | TRANSCRIPT + 29 | *The Hummingbird Project* clip — Kansas↔NYSE fibre latency arb. Narrative, not method |
| `Dak-8k6oNeA` | TRANSCRIPT + 26 | "3PO" self-learning AI quant with a "brain vault" — graph of papers/books read with idea-links. **Closest thing in the corpus to our own brain/competency concept**; no evidence offered |
| `Da4XlSfhtNo` | TRANSCRIPT + 14 | "Automaton" — agent with its own crypto wallet that dies at zero balance and clones itself when profitable. Same theme as `DbGFvV0Bwn5` |
| `DW4yP9HgWv-` | TRANSCRIPT + 24 | Claims "Memory Palace, highest-scoring AI memory system ever benchmarked", attributed to a Milla Jovovich GitHub repo. **Could not verify — treat as unsubstantiated** |
| `DYW1yX6AIKX` | TRANSCRIPT + 17 | Accumulation/manipulation/distribution + fixed-range volume profile. Retail ICT framing |
| `Da8E8_sDtBx` | TRANSCRIPT + 6 | "Never use X, instead use Y" → free-course funnel. Noise |
| `DacDmnGsQsy` · `Dasuyqan5n7` · `DaTsmSOzl3c` · `Dau64tdyY4n` | TRANSCRIPT + frames | Music / no speech content. `Dau64tdyY4n` transcribed only a copyright notice — Whisper picked up unrelated audio |
| `Da0BA-GRGN1` · `DatQIOQTcwT` | FRAMES ONLY (8 each) | No audio track recoverable; frames are the only content |
| `DXZX8JYDZZt` · `DYSAzzpAZH9` · `DYNEuorDrLy` | FAILED (rc=1) | Need retry |
| `DZ9xV72I54p` · `DZ7bTCtoc3s` · `DZ7lPp6slQl` · `DZwTzBwhHXS` · `DT1WyeYjEnL` · `DV_w-fRDEGI` | PENDING | Reel job still running at time of writing |

---

## What this changes in the existing research

1. **`instagram-sources.md` needs two corrections**: the `DbMx1AUlBo7` "convergent architecture"
   note must be retracted, and the `DbDbx6onUOI` "gated, material not in post" claim is false.
2. **`FEATURES.md` / options layer**: add CVXPY, NumPyro, Diffrax, py-pde, FinancePy with their
   licences. FinancePy is GPL-3.0 — same copyleft caution already applied to NautilusTrader.
3. **Risk/allocation layer**: add **Marchenko–Pastur / RMT correlation denoising** before covariance
   estimation. This was not in the corpus before.
4. **Promotion gate**: the MacroHFT objective `−S̄ + ασ_S + βD_max + γC + δΩ` is a usable reference shape.
5. **`ARCHITECTURE.md` §3c**: log ZipLime as considered-and-rejected (GPL-3.0, vendor benchmark).
6. **The `instagram-content` skill has a bug**: `--no-videos` silently drops video slides inside image
   carousels. Fix is to fetch with video enabled and extract frames.

## Late additions — found after the first pass

### `Da1XG9qgd4E` — AI supply-chain attack on model weights (55 frames + full transcript)

The caption only gestured at this. The spoken content is specific and, for us, **directly actionable**:

> *"Models are just numbers, and binaries are just numbers. We pre-build the bad stuff directly into
> the neural network… the way we wire up the network, at this layer we jump all the way over here.
> These layers are completely ignored, never actually executed. So the behaviour of the network
> continues to do all the stuff it's supposed to do — and now we've embedded a Trojan that is
> pre-built object code that all it needs to do is be linked into something."*

Portability is handled by abstracting to a generic object representation (JVM/.NET-style) with a
translation layer per architecture. The speaker explicitly maps this onto the **xz-utils backdoor**:
no malicious code in the repo, just object code shipped as "tests", unpacked from the tarball and
linked by the resident linker into an SSH backdoor. Recommendation: run models **air-gapped and
sandboxed**, because detection tooling is immature.

**Why this matters here:** adopting Kronos means loading third-party weights
(`NeoQuasar/Kronos-small`) from HuggingFace. That is exactly the threat model described. This should
inform how model artefacts are fetched, pinned and executed — and it pairs with guardrail check #6,
which already fingerprints third-party hook code for the same class of reason.

### `Da8LFnfFnqx` — 17 Python libraries (batch 1 dismissed this as "generic")

The slides name real, checkable libraries, several relevant to the Phase 6 options layer:
**OpenBB Terminal**, **PyQL** (QuantLib Python port), **vollib** (option prices, IV, greeks),
**pynance**, **pysabr** (SABR), **FinancePy**, **optlib**, **tf-quant-finance**, **Q-Fin**.
Worth a pass against the settled stack before writing any options pricing from scratch.

### Reels worth keeping

| Link | Content |
|---|---|
| `DZ9xV72I54p` | Monte Carlo, correctly framed: *"You don't simulate what you think the stock will do. You pretend it grows at the risk-free rate, average the payoff, and discount it back. **A pricing device, not a forecast.**"* Risk-neutral pricing stated properly |
| `DZ7bTCtoc3s` | PCA explainer — emphasises **centre and scale first** so no feature dominates by magnitude |
| `DYB671CtuaQ` · `DV_w-fRDEGI` | Two independent indicator tier-lists. Both rank **order flow / DOM / volume profile highest** and RSI/MACD lowest as lagging. One calls DOM *"the proxy of aggression and the interaction between orders."* Opinion, not evidence — but it converges with `Da_f158GyKd`, `DaNFqoYNtIQ` and our own L2-depth-is-P0 decision |
| `DZ7lPp6slQl` · `DZwTzBwhHXS` · `Da_kNEjNt9f` | No speech content recoverable |

### `DbT9K96Afsx` is a sixth `@seb.ai` link

Its final slide reads "FOLLOW @SEB.AI". So the fabricating account accounts for **six** of the 57.
Its repo carousel also contradicts itself: the CTA promises "all 8 repos" while the carousel only
ever shows five, and claims "10,000+ developers already using these tools."

### `DY4dxCkDa8Z` is from a different, more reliable account

The five-library carousel ends with a `quantframe.io` CTA — not `@seb.ai`. Every library it named
checked out. Worth treating `quantframe.io` and `@quantscience_` as the two higher-quality sources in
this corpus, alongside `edgebuildit.com`.

## Signal-to-noise, restated

Of 57 links, roughly **8 carried something actionable**. The reliable filter from batch 1 holds and is
now better evidenced: **the posts that taught something were specific, mechanism-level, and made no
profit claim** — Kronos (with its own disclaimer), Zomma, delta/absorption, MacroHFT's loss function,
AOSm's update rule, RMT denoising. Every post that led with a return figure or a dashboard was either
fabricated or unverifiable.
