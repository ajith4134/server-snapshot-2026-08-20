# Automated Alpha Discovery via GP / Symbolic Regression

**Provenance:** Researched by a Sonnet subagent, 2026-08-01, via WebSearch/WebFetch against primary sources (arXiv, SSRN, GitHub READMEs). Part of a 5-agent parallel sweep on autonomous strategy-discovery systems for a $100k-$1M crypto trading project. Report-only, no files modified by the subagent.

## Bottom line up front

Every primary source found points the same direction: large-scale formulaic/GP alpha search is a multiple-comparisons problem at industrial scale. The one dataset that explicitly quantifies this (pure noise input, Bailey/Borwein/López de Prado/Zhu) produced an in-sample Sharpe of 1.27 with 53% of out-of-sample Sharpe ratios negative, from testing "only" 8,800 configurations. Nothing found — academic or GitHub — provides audited, live, real-capital evidence that GP/symbolic-regression-discovered formulaic alphas produce durable edge, in equities or crypto.

## 1. WorldQuant "101 Formulaic Alphas" (Kakushadze)

Zura Kakushadze, "101 Formulaic Alphas," *Wilmott* 2016(84); arXiv:1601.00991; SSRN 2701346. **Status: practitioner/trade publication (Wilmott), not a top peer-reviewed academic finance journal.**

- The alphas are **not GP-discovered**. No mention of genetic programming/symbolic regression/automated search anywhere in the text. Direct quote: "We picked these alphas largely based on simplicity considerations, so they can be presented within the inherent limitations of a paper." Hand-selected-for-simplicity illustrative subset, not automated-search output.
- Builds on Kakushadze & Tulchinsky, "Performance v. Turnover: A Story by 4000 Alphas," *Journal of Investment Strategies* 5(2) (2016), 75–89 / arXiv:1509.08110 — a study of WorldQuant's larger internal pool of ~4,000 real alphas.
- Reported performance: Sharpe 1.238–4.162 (median 2.224); avg daily return 3.285%–28.72% (median 5.441%); avg holding period 0.6–6.4 days (high turnover); avg pairwise correlation 15.9%. Backtest window: Jan 2010–Dec 2013 only, no OOS/live section.
- Critical: table notes state figures are **exclusive of trading/transaction costs, price impact, etc.** — gross, frictionless numbers, on high-turnover signals.
- No dedicated re-test of these exact 101 formulas out to 2024-2026 was found. Given public availability since 2015-16 and ubiquity as the standard toy dataset for open-source alpha-mining repos, the reasoned inference (not a directly cited finding) is that any edge is now crowded/decayed.

## 2. gplearn and GP-for-alpha GitHub tools

- **gplearn** (github.com/trevorstephens/gplearn): general-purpose, scikit-learn-compatible symbolic regression library, domain-agnostic. Zero mentions of finance in the README.
- **AlphaGen** (github.com/RL-MLDM/alphagen; arXiv:2306.12964, KDD 2023, peer-reviewed): primarily an RL (PPO) framework that also ships GP (modified gplearn) and Deep Symbolic Optimization as baselines. Trading-integration code marked "Experimental." Claims "higher returns" on unspecified real-world stock data, no transaction costs stated, no live-trading claim.
- Other GitHub repos (Genetic-Alpha, Genetic-Algorithm-for-quantitative-alpha-factors-mining, alpha-gfn, AlphaGenerator): small hobby/research repos, mostly Chinese A-shares, no disclosed live/production deployment or audited results. One author's own README: "Most of traditional alpha factors are known by many investors, then gradually becomes invalid" — i.e. authors themselves acknowledge crowding.
- Recent arXiv papers (Warm Start GP for Quant Investment 2024 arXiv:2412.00896; AlphaSAGE; AlphaPROBE; "Navigating the Alpha Jungle" LLM+MCTS): all backtest-only on historical equity indices (mostly CSI300/500), no live/production/audited example found anywhere.

**Conclusion:** everything found is academic/hobbyist demonstration code and conference-paper research, not production trading infrastructure with disclosed live results.

## 3. Symbolic regression more broadly (PySR, DSO)

- PySR: peer-reviewed software review exists (*Genetic Programming and Evolvable Machines*, Springer 2024, DOI 10.1007/s10710-024-09503-4) but it's a general software review, not a finance-application study. No peer-reviewed PySR-in-finance paper found.
- DSO (Deep Symbolic Optimization): won 1st place, Real-World Track, 2022 SRBench competition — genuine achievement, but entirely in physics/scientific-discovery domains. No DSO-in-finance peer-reviewed work found.
- **Absence of evidence**: no peer-reviewed paper found demonstrating durable OOS financial alpha from symbolic regression tools specifically.

## 4. Realistic hit rates — concrete numbers

- **Bailey, Borwein, López de Prado & Zhu, "The Probability of Backtest Overfitting," Journal of Portfolio Management (2014)** [peer-reviewed]: testing 8,800 configurations against a **pure random walk (no signal)** produced best in-sample Sharpe 1.27, CSCV-based PBO of 55%, ~53% of OOS Sharpes negative. With a genuine embedded seasonal effect at similar in-sample Sharpe (1.54), PBO dropped to 13%. This is a lower bound — real GP searches evaluate far more than 8,800 candidates.
- **Harvey, Liu & Zhu, "...and the Cross-Section of Expected Returns," RFS 29(1) (2016)** [peer-reviewed]: argue for t-stat > 3.0 (not 2.0) as the multiple-testing-adjusted bar; conclude most claimed findings in financial economics are likely false.
- **McLean & Pontiff, "Does Academic Research Destroy Stock Return Predictability?", Journal of Finance 71(1) (2016)** [peer-reviewed]: published-anomaly returns are 26% lower OOS pre-publication (data-mining/selection bias) and 58% lower post-publication (~32 more points from crowding/arbitrage once known).
- **Chen, Lopez-Lira & Zimmermann, "Does Peer-Reviewed Research Help Predict Stock Returns?"** (arXiv:2212.10317, venue UNVERIFIED): mining ~29,000 accounting ratios mechanically for t>2.0 produces predictability statistically similar to published peer-reviewed factors; ~50% of in-sample predictability persists post-sample for both groups.
- No verified "1-in-7" or similar practitioner rule of thumb attributed to López de Prado — searched specifically, not found, treat as not existing.
- WorldQuant's 2025 International Quant Championship: 263,000+ alpha submissions from ~80,000 participants. Acceptance/licensing rate not publicly disclosed (UNVERIFIED/not found) — but the scale itself indicates how crowded/competitive formulaic alpha search already is institutionally.

## 5. Overall skeptical assessment

Mostly overfitting to noise at scale, not durable edge. Reasoning:

1. **Search space vs. data size**: GP runs evaluate thousands-to-millions of candidate formulas against a few thousand independent-ish daily observations. The PBO example (8,800 configs against noise → 1.27 Sharpe, 53% negative OOS) is a lower bound since real GP search spaces are effectively unbounded.
2. **Published formulas decay/crowd, measurably**: McLean & Pontiff's ~58% post-publication decay is direct evidence. The WorldQuant 101 have been public since 2015-16 and are the standard toy dataset for open-source alpha-mining repos — no plausible reading has residual edge left.
3. **Transaction costs threaten this style of signal specifically**: the 101-alphas paper explicitly excludes costs while reporting 0.6-6.4 day holding periods — gross Sharpes of 2-4 are inherently cost-sensitive and unlikely to survive net of realistic crypto fees/slippage.
4. **Crypto differs from equities against this literature, not for it**: nearly all the GP-alpha literature is built/tested on liquid equity indices with daily-bar, dollar-neutral, long-short frameworks that don't map onto crypto spot/perp markets. Crypto adds funding rates, exchange-specific fees, thinner books outside majors, 24/7 trading with active HFT competition pushing short-horizon inefficiencies to efficiency quickly (this specific crypto-decay claim is lower-confidence, sourced from secondary search summaries not independently fetched — flagged below).
5. **No audited live-capital evidence found anywhere** (GitHub, arXiv, SSRN) that a GP/symbolic-regression-discovered formulaic alpha, from any named tool, has produced durable real-money returns for an individual/small team.

**Practical recommendation implied**: if pursued at all, must have rigorous deflated-Sharpe/PBO-style validation (not a single train/test split), realistic crypto-specific cost modeling, and mandatory live paper-trading before capital allocation — and even then base rates from the equity literature (50-58% decay on real published factors; majority-negative OOS rate on pure-noise GP-scale searches) suggest most discovered formulas won't survive contact with live, cost-inclusive trading. Reusing already-published formula sets (e.g. WorldQuant 101) specifically should be assumed to have no residual edge.

## UNVERIFIED

- Whether the 101 published alphas specifically still have any efficacy today — inferred, not directly re-tested in a found study.
- AlphaGen's exact backtest dataset/time split/quantitative IC/return/cost figures — only abstract-level claims extracted.
- Publication/peer-review status of Chen, Lopez-Lira & Zimmermann (confirmed arXiv preprint through Dec 2025, final journal placement unconfirmed).
- WorldQuant BRAIN's actual alpha acceptance/licensing rate — not publicly disclosed, not found.
- Crypto-specific microstructure alpha decay claims (signal half-life compression, minute-level alphas "too weak to overcome retail costs") — sourced from WebSearch result summaries, not independently fetched/read in full.
- A practitioner "1-in-7" backtest-to-live survival rule of thumb attributed to López de Prado — searched specifically, not found; should not be used.
- Whether any specific hedge fund/crypto firm has publicly disclosed audited live returns attributable specifically to GP/symbolic-regression-discovered alphas — none found; consistent with industry opacity, not proof of absence.
