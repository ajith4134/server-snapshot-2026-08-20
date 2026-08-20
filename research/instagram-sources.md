# Instagram source links

## Batch 2 — saved 2026-08-01, **READ IN FULL 2026-08-02**

33 links. **24 reels, 9 posts (3 carousels).**

> ✅ **Read.** Both batches were re-processed at media level on 2026-08-02 — carousel images,
> video frames, and local Whisper transcripts. **49 of 57 links read at media level**
> (144 images, 445 video frames, 19 transcripts); 2 caption-only; 6 unrecoverable.
>
> The caveat this block originally carried — *"caption text is all that is recoverable… a reel's
> substance is in the video and audio, neither of which this method reaches"* — **no longer applies.**
> The `instagram-content` skill reaches both. That limitation was the cause of the two errors
> corrected below.
>
> **Findings live in `instagram-findings.md`; raw material in `instagram-raw/` (104 MB).**

| # | Type | URL |
|---|---|---|
| 1 | post (carousel) | https://www.instagram.com/p/DazZdo6Dv-S/ |
| 2 | reel | https://www.instagram.com/reel/Da8E8_sDtBx/ |
| 3 | reel | https://www.instagram.com/reel/DacDmnGsQsy/ |
| 4 | reel | https://www.instagram.com/reel/Da4XlSfhtNo/ |
| 5 | post | https://www.instagram.com/p/Da6C_ajgZ2B/ |
| 6 | reel | https://www.instagram.com/reel/Dasuyqan5n7/ |
| 7 | post (carousel) | https://www.instagram.com/p/DaprsQ4CdnU/ |
| 8 | reel | https://www.instagram.com/reel/DatQIOQTcwT/ |
| 9 | reel | https://www.instagram.com/reel/Da0BA-GRGN1/ |
| 10 | reel | https://www.instagram.com/reel/DXZX8JYDZZt/ |
| 11 | post | https://www.instagram.com/p/DauS_vfFCHE/ |
| 12 | reel | https://www.instagram.com/reel/Dau64tdyY4n/ |
| 13 | post (carousel) | https://www.instagram.com/p/DZyRSEvjCDS/ |
| 14 | reel | https://www.instagram.com/reel/DYSAzzpAZH9/ |
| 15 | reel | https://www.instagram.com/reel/DVaB4VAEhMf/ |
| 16 | reel | https://www.instagram.com/reel/Dak-8k6oNeA/ |
| 17 | post | https://www.instagram.com/p/DagUfJzgeTx/ |
| 18 | reel | https://www.instagram.com/reel/DaTsmSOzl3c/ |
| 19 | reel | https://www.instagram.com/reel/DW4yP9HgWv-/ |
| 20 | reel | https://www.instagram.com/reel/DYW1yX6AIKX/ |
| 21 | reel | https://www.instagram.com/reel/DYNEuorDrLy/ |
| 22 | post | https://www.instagram.com/p/DY4dxCkDa8Z/ |
| 23 | post | https://www.instagram.com/p/DZ2PiNFltKt/ |
| 24 | reel | https://www.instagram.com/reel/DYU0dMcpBFP/ |
| 25 | reel | https://www.instagram.com/reel/DZ2eqaZInfk/ |
| 26 | reel | https://www.instagram.com/reel/DVRWC25DDid/ |
| 27 | reel | https://www.instagram.com/reel/DZ9xV72I54p/ |
| 28 | reel | https://www.instagram.com/reel/DZ7bTCtoc3s/ |
| 29 | reel | https://www.instagram.com/reel/DV_w-fRDEGI/ |
| 30 | post | https://www.instagram.com/p/DZtFyvpjoHz/ |
| 31 | reel | https://www.instagram.com/reel/DZ7lPp6slQl/ |
| 32 | reel | https://www.instagram.com/reel/DZwTzBwhHXS/ |
| 33 | reel | https://www.instagram.com/reel/DT1WyeYjEnL/ |

---

# Batch 1 — read 2026-08-01

23 links provided. **17 read, 6 unrecoverable** (returned only Instagram branding — login-gated).
Only caption text is fetchable; carousel images and reel video/audio content are **not** recoverable
this way. Anything shown only in an image or spoken in a reel is missing from what follows.

---

## Genuinely useful — actionable for the project

| Source | Finding | Where it lands |
|---|---|---|
| **Kronos** (appears **twice** in the list: `DbO5FVYgd19`, `DbDnA_8kcjW`) | Open-source foundation model for K-lines, MIT, AAAI 2026, 400 candles in → 120 out | Already read at source → `kronos-foundation-model.md`. **Use as zero-shot baseline gate** |
| **Zomma** (`DbYOQlSFJSZ`) | Third-order Greek — **dGamma/dVol**. Near the money it runs negative, so a vol spike *drains gamma from exactly where you are sitting*. Caption also notes the leverage effect: price grinds up while vol bleeds, then rolls over when vol wakes — **gamma and direction get hit together** | **Phase 6 options layer.** Genuinely non-obvious, and the "both hit together" point is a real risk-management insight, not content filler |
| **Delta vs absorption** (`Da_f158GyKd`, Nexural.io) | *"Positive delta can still be bearish. Buying aggression at a high means nothing if price cannot hold. That is often absorption, not strength."* | **Order-book signal layer.** Directly reinforces the spoofing-aware / depth-weighted OFI decision — raw delta is as naive as level-1 imbalance |
| **AOSm — Modified Atomic Orbital Search** (`Dbbvsvcsmbb`, edgebuildit.com) | Population-based metaheuristic: candidates as electrons, best solution as nucleus, search reorganises through orbital layers. Redistribution + orbital reassignment + personal-best memory + jumps to global best | Optimiser candidate for parameter search. **Same multiple-testing caveat as any search method** — must run inside the Trial Registry |
| **Grokking / anti-grokking** (`DbGYmZQiHxN`) | Memorisation circuit dominates first; a generalisation circuit develops silently beneath; weight decay eventually lets the elegant algorithm win. Phase-transition signatures. **2026 addition: models can "anti-grok" at ~10M steps — collapsing back out of understanding** | Training-schedule awareness. The anti-grok finding argues against "train longer is safer" |
| **DOM / order-book walls** (`DaNFqoYNtIQ`) | A large resting seller invisible on the chart but visible in the book; price repeatedly rejected at that level | Reinforces why L2 depth is P0 data, not a nice-to-have |
| **MacroHFT Regime Fracture Landscape** (`DbXE8o_sspP`, edgebuildit.com) | Interactive sim of a multi-agent HFT system across 2000–2026 regimes, rolling 6-year windows. Five sub-agents, dynamically weighted. Axes: arbitration temperature × macro-volatility sensitivity. Analysis modes include slippage stress, drawdown risk, execution churn | **Creator explicitly disclaims real alpha, a live system, or a trained AI.** Useful as a *visualisation* of regime fragility, not as evidence |

## ~~Convergent design — worth noting, not evidence~~ → **RETRACTED 2026-08-02**

> **This section was wrong and is withdrawn.** It read: *"AI hedge fund with Claude Opus 5
> (`DbMx1AUlBo7`) … structurally the same shape as `DECISIONS.md` … independent convergence on the
> architecture is mildly reassuring."*
>
> It is **not independent convergence.** Reading the carousel images (the post was previously assessed
> from its caption only) shows `DbMx1AUlBo7` is one of **six links from the single account `@seb.ai`**,
> which posts the same fabricated template under rotating names — OPUS 5 AI HEDGE FUND, CITADEL OS,
> 24/7 AI TRADER, Fable 5 × Kalshi, AI COMPANY OS — with invented metrics (VaR 95% −1.89%, beta 0.67,
> max DD −12.4%, Sharpe figures on mockup equity curves).
>
> The account's "5 GitHub repos" carousel (`DagUfJzgeTx`) names `ai-market-scanner` 3.9k★,
> `ai-trading-agent` 4.2k★, `backtesting-engine` 5.1k★, `ai-news-sentiment-bot` 3.7k★,
> `ai-trade-journal` 4.3k★, `my-trading-workflow` 4.7k★. **`gh search repos` finds none of them at
> those counts.** The same carousel promises "all 8 repos" while only ever showing five, and claims
> "10,000+ developers already using these tools."
>
> **Carries zero evidential weight.** Affected: `DbMx1AUlBo7`, `DagUfJzgeTx`, `DazZdo6Dv-S`,
> `Da6C_ajgZ2B`, `DauS_vfFCHE`, `DbT9K96Afsx`.
>
> Full per-link detail: **`instagram-findings.md`**. Raw material: **`instagram-raw/`**.

## Low signal — educational or engagement-gated

- **`DbYwC02ERkt`** — viral claim: a Claude-built bot made **$220,000 in 64 days** on prediction-market
  latency. The post itself warns the figure is unverified and notes fees, failed executions, liquidity
  limits, and technical errors. **The warning is the useful part**; the number is not evidence.
- **Content gated behind comments** (`Dax2J2LEl5G` "SEND", `DbT9K96Afsx` "STARTUP", `DbMx1AUlBo7`
  "HEDGE", `DbGFvV0Bwn5` "comment to get the tool") — the actual material is not in the post.
  > **CORRECTED 2026-08-02** — `DbDbx6onUOI` "FORMULAS" was listed here. **That claim was false.**
  > All 30 formulas are printed in the carousel images: Bayes, conditional probability, E[X], variance,
  > covariance, correlation, Z-score, LLN, matrix multiplication/inverse, eigenvalues, covariance
  > matrix, gradient, Hessian, Lagrange multipliers, Taylor, partial derivatives, chain rule, **Itô's
  > lemma, GBM, Wiener process, SDE**. Textbook-level, but the post is not gated. The error was an
  > artifact of assessing the post from its caption without ever opening the images.
  >
  > `DbGFvV0Bwn5` is also mis-filed — it is **not a trading tool** at all. It is "WEB 4.0 / Conway":
  > `npx conway-terminal`, onchain identity, paying x402 services in USDC, spinning up Linux compute.
  > Agent-with-a-wallet autonomy. Off-project, but a security consideration.
- **Generic education** — mean reversion with Z-score/Bollinger/RSI (`DbPaMI1ndH2`), volatility-vs-
  direction (`DbL4zzRo7dy`), ML number patterns (`DbKYvkCifnY`).
  > **CORRECTED 2026-08-02** — `Da8LFnfFnqx` ("17 Python libraries") was dismissed here. The slides
  > name real, checkable libraries, several relevant to the Phase 6 options layer: **OpenBB Terminal,
  > PyQL** (QuantLib port), **vollib**, **pynance**, **pysabr**, **FinancePy**, **optlib**,
  > **tf-quant-finance**, **Q-Fin**. Worth a pass before writing options pricing from scratch.

## Sources that proved reliable vs unreliable

| Source | Verdict |
|---|---|
| `quantframe.io` (`DY4dxCkDa8Z`) | **Reliable** — every one of its five named libraries verified real, with correct descriptions |
| `@quantscience_` (`DZ2PiNFltKt`, `Da8LFnfFnqx`) | **Reliable** — ZipLime repo real (452★, GPL-3.0); library list accurate |
| `edgebuildit.com` (`Dbbvsvcsmbb`, `DbXE8o_sspP`) | **Reliable and candid** — publishes actual equations, explicitly disclaims alpha |
| `@seb.ai` (6 links) | **Fabricates.** Invented repos, invented metrics, mockup dashboards, always comment-gated |

**The filter that works, now better evidenced:** posts that taught something were **specific,
mechanism-level, and made no profit claim**. Every post leading with a return figure or a dashboard
was fabricated or unverifiable.

## ~~Unrecoverable — login-gated, no caption returned~~ → **MOSTLY RECOVERED 2026-08-02**

Original list: `DaqrnR3j8oM` · `Da0EeF1DTZ-` · `DYB671CtuaQ` · `Da_kNEjNt9f` · `Da1XG9qgd4E` ·
`DatgKiljpXS`. **Three of the six were recovered** once images and audio were actually fetched:

| Link | Outcome |
|---|---|
| `Da1XG9qgd4E` | **Recovered — 55 frames + full transcript, and it matters.** AI supply-chain attack: Trojan object code embedded in **never-executed layers** of a model ("we jump all the way over here… these layers are completely ignored"), abstracted to a portable object format, linked at deployment. Explicitly the **xz-utils playbook** — object code shipped as "tests", linked by the resident linker into an SSH backdoor. Recommends running models **air-gapped and sandboxed**. **Bears directly on loading `NeoQuasar/Kronos-small` weights from HuggingFace** |
| `DYB671CtuaQ` | Recovered — 37 frames + transcript. Indicator tier list; ranks DOM/order flow and volume profile top, RSI/MACD bottom as lagging |
| `Da_kNEjNt9f` | Recovered — caption + 2 frames, no speech content |
| `Da0EeF1DTZ-` | Caption only (10 open-source projects: Dify, Crawl4AI, Stirling PDF, Supabase, Langflow, Browser Use, Open WebUI, Maxun, OpenHands, Coolify). No media published |
| `DaqrnR3j8oM` · `DatgKiljpXS` | **Still unrecoverable.** Retried via a second independent path (`yt-dlp` + `ffmpeg`, bypassing `ytgrab`): `Instagram sent an empty media response` — login-gated or removed |

Also still unrecoverable from batch 2, same error: `DXZX8JYDZZt`, `DYSAzzpAZH9`, `DYNEuorDrLy`,
`DT1WyeYjEnL`. Six total. To read these, open them signed-in and paste the caption or a screenshot.

---

## Assessment

**Signal-to-noise is low, and that is worth saying plainly.** Of 17 readable posts, roughly **four**
contained something not already in the spec corpus — Zomma, the delta/absorption distinction, AOSm,
and the anti-grokking detail. Kronos was the one genuinely major find, and it appeared before this
batch.

**Recurring source worth noting:** `edgebuildit.com` produced both technically substantive posts
(AOSm, MacroHFT) and is candid about disclaiming alpha. Higher quality than the surrounding feed.

**The pattern to be aware of:** most trading content on this platform is either engagement-gated
(the substance is behind a comment) or repackaged textbook material. The two posts that taught
something — Zomma and delta-absorption — were both **specific, mechanism-level, and made no profit
claim.** That is a usable filter for future sources.
