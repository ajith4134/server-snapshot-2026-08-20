# STRATEGIC — the questions that precede the system

Fourth tier:

- `IDEAS-ADVANCED.md` — **techniques**
- `IDEAS-INTELLIGENCE.md` — **architecture for behaving intelligently**
- `IDEAS-FRONTIER.md` — **ideas that change the objective**
- **this file** — **the premises the whole project rests on**

Verdict key: **★ HIGH** · ◆ REAL · ◇ SPECULATIVE · ✕ DECLINED.

> **Why a fourth tier.** Tiers 1–3 assume the project should exist and ask how to build it well.
> This tier asks the questions that come *before* that: what is it actually for, where can a solo
> operator structurally win, what mathematics genuinely describes this market, what can kill the
> project that is not a bad trade, and what survives when the code is rewritten.
>
> **Sections marked NEW are absent from all three earlier files** — verified by search, not assumed.

---

# PART I — POSITIONING

## 1. What is the system actually for? — NEW

The objective is a **choice**, and choosing "return" by default is the most expensive unexamined
decision in the project.

| Idea | Verdict | Why |
|---|---|---|
| **Year-1 objective: maximise information gain per dollar risked — not return** | **★ HIGH** | Treat the first phase as a **measurement campaign, not a profit campaign.** The objective becomes *how much do we learn per unit of capital at risk*, with P&L as a **constraint** ("do not lose more than X"), not the thing being maximised. This inverts almost every design decision: you would deliberately take positions that are **maximally informative about your own fill behaviour, impact, capacity and model error** rather than maximally profitable. Backtests cannot produce these numbers at any price — only live capital can. **The thing you are actually short in year one is knowledge, not money**, and optimising for the wrong scarcity is why most systematic projects die with beautiful backtests and no working system |
| **Optionality preservation as an explicit criterion** | **★ HIGH** | Between two actions of equal expected value, prefer the one that **keeps more future choices open**. Irreversible commitments — a venue lock-in, a data format, a capital deployment that cannot be unwound quickly — should pay a premium for their irreversibility. Most architecture regret is optionality that was destroyed cheaply and repurchased expensively |
| **Explicit objective ladder by phase** | ◆ REAL | Year 1 information → Year 2 survival with positive expectancy → Year 3 risk-adjusted return. Writing the transition criteria down prevents the silent drift into "just make money" before the foundation exists |
| **The objective is not the metric** | ◆ REAL | Whatever gets written here will be Goodharted by the system itself. Pairs with the sealed-envelope metric in `IDEAS-FRONTIER.md` §5 |

## 2. Comparative advantage — where a solo operator can actually win — NEW

**The single most neglected question in the entire project**, and the one most likely to decide it.

A solo operator competing head-on with a well-capitalised firm in liquid BTC perpetuals **loses by
construction** — worse latency, worse fees, worse data, worse people, no exceptions. The only viable
strategy space is the one where the disadvantages do not apply and the structural advantages do.

**Structural advantages a solo operator genuinely has:**

| Advantage | Why it is real |
|---|---|
| **No redemption risk** | Nobody can pull capital at the worst moment. You can hold through a drawdown that would liquidate a fund — which means you can run strategies whose edge *requires* surviving drawdowns others cannot |
| **No career risk** | A fund manager who deviates and loses is fired; who follows consensus and loses keeps the job. That asymmetry **forces** herding. You are free of it, and the resulting crowded-trade avoidance is a real edge |
| **Capacity irrelevance** | Opportunities too small to move a $500M book are invisible to the people who would otherwise compete them away. **This is the largest single advantage** and it points the whole strategy space toward small, awkward, capacity-constrained corners |
| **No quarterly clock** | You can run the optimal harvest rate (`IDEAS-FRONTIER.md` §2) instead of maximising this quarter. Institutions structurally cannot |
| **Willingness to hold ugly positions** | No investor to explain a weird-looking book to |
| **Patience as a weapon** | You can wait months for a setup. A desk with fixed costs cannot |

| Idea | Verdict | Why |
|---|---|---|
| **An explicit "do not compete here" list, written before strategy search** | **★ HIGH** | Latency-sensitive market making on major pairs, anything where the edge is speed, anything requiring exchange colocation or tier-1 fee status, anything requiring licensed data. **Excluding these first shrinks the search space enormously and removes the most seductive time-wasters.** Every hour spent on a strategy that requires being fastest is an hour spent losing to someone structurally faster |
| **Advantage-first strategy generation** | **★ HIGH** | Do not generate strategies and then check feasibility. **Start from the advantage** — "what is only profitable at small size?", "what requires holding through pain?", "what is too operationally annoying for a desk?" — and generate into that space |
| **Operational-annoyance premium as a screening lens** | ◆ REAL | Edges persist when they are irritating: obscure venues, manual onboarding, awkward settlement, poor APIs. Annoyance is a **barrier to entry you can pay in patience instead of capital** |

### Worked example — why the "do not compete here" list exists

Added 2026-08-02, from a social post claiming *"a Chinese programmer accidentally exposed $868K
profit from an AI bot trading Bitcoin 28,000 times every 15 minutes."* The abstract principle above
convinces nobody; **the arithmetic does.**

The claim contains one checkable number, and it decides everything:

> **28,000 trades / 15 minutes = 31.1 trades per second, sustained.**
> 2.69M trades/day · 80.6M trades/month.

At a plausible $100 average trade that is **$268.8M/day of notional**. Fees at Binance USDⓈ-M rates:

| Fee tier | Cost per day | Cost per month |
|---|---|---|
| Taker 0.040% | $107,520 | $3.2M |
| Maker 0.020% (ordinary) | $53,760 | **$1.6M** |
| VIP 9 maker 0.000% | $0 | $0 |
| VIP 9 maker rebate −0.005% | **−$13,440 (earns)** | −$403K |

**At ordinary maker fees the strategy pays $1.6M/month in fees against a claimed $868K profit.** It
is solvent only at **VIP 9**, which requires 30-day volume no solo operator will ever reach. The
required gross edge is roughly **1 basis point of notional per trade** — market-making territory,
won on queue position and latency, not on signal.

So the strategy is exactly the first entry on the list above: **latency-sensitive market making on a
major pair at institutional fee tier.** Three structural disqualifiers at once — fee tier, latency,
and colocation — each individually fatal for a solo operator on a cloud VM.

**Three transferable lessons:**

1. **A trade-rate claim is a fee claim in disguise.** Any strategy quoting trades-per-second is
   really quoting a fee bill; compute it before anything else. The fee bill alone disqualifies most
   high-frequency claims without needing to evaluate the edge at all.
2. **This is the cheapest possible filter.** Two minutes of arithmetic answered a question that
   could otherwise have consumed weeks of research. Apply it to every "look at these returns" claim
   *before* engaging with the mechanism.
3. **The filter from `instagram-sources.md` held again** — the post led with a profit figure, showed
   a screen recording, and offered no audit trail. Every post in that corpus leading with a return
   figure was fabricated or unverifiable. **Nothing about the number needed to be disproved; the
   structure it implied was disqualifying on its own.**

> One genuinely useful thing did come out of it: the screens showed a **DOM/footprint ladder with
> resting-liquidity levels** — corroborating the decision to capture **full L2 depth on the core
> tier** rather than trades alone. Confirmation of a data choice, not a strategy to copy.

## 3. Project-level kill criteria — NEW

| Idea | Verdict | Why |
|---|---|---|
| **Pre-registered abandonment criteria for the entire project** | **★ HIGH** | Written **now**, before emotional investment compounds: what evidence, by what date, would mean this should stop? Nobody writes this, so nobody ever concludes it, and projects consume years by default rather than by decision. **This is the same discipline as pre-registering a strategy's kill criteria, applied one level up** — and it is far harder to do honestly, which is exactly why it must be done in advance |
| **Milestone-gated capital escalation** | **★ HIGH** | Capital is a **mechanical function of demonstrated out-of-sample performance**, not a judgement call made while excited. Each rung requires a pre-specified number of live trading days, a minimum trade count, and OOS metrics inside pre-declared bounds. Removes the single most common capital destroyer: sizing up after a good month |
| **Operator time costed explicitly** | **★ HIGH** | The scarce input is not capital, it is **operator hours**. A strategy needing daily intervention has a large hidden cost that never appears in its Sharpe. Cost it, or the portfolio silently fills with high-maintenance strategies |
| **Expected value of the project, honestly stated** | ◆ REAL | Including the base rate: most systematic projects fail. A plan that only works if you are in the top decile should say so out loud |

## 4. Continuity and the bus factor — NEW

Almost nobody designs for this, and for a **solo-operated system holding leveraged positions it is a
first-order risk** — not an afterthought.

| Idea | Verdict | Why |
|---|---|---|
| **Absence-triggered de-risking ladder** | **★ HIGH** | No operator heartbeat for N hours → stop opening; N days → reduce; longer → flatten. **Distinct from the dead-man's switch** in `IDEAS-FRONTIER.md` §7, which handles *system* death. This handles **operator** death, illness, travel, or simply being asleep during a cascade. The system must degrade safely toward "no positions" when unattended |
| **Documented recovery runbook, tested** | **★ HIGH** | Written so that someone who is *not* you can flatten the book and secure the funds. Untested runbooks are fiction — schedule an actual rehearsal |
| **Key escrow / inheritance path** | **★ HIGH** | Self-custodied crypto with no recovery path is **permanently lost**, not merely inaccessible. This is an estate problem, not a technical one, and it needs an actual answer |
| **Designed boringness as a target** | ◆ REAL | If running the system is exciting, that is a design defect. Optimise for *not needing attention*; measure interventions per week as a first-class health metric that should trend to zero |

---

# PART II — DECISION THEORY UNDER THE RIGHT KIND OF UNCERTAINTY

## 5. Risk vs uncertainty vs ignorance — NEW

| Idea | Verdict | Why |
|---|---|---|
| **Classify which uncertainty regime you are in, and switch decision rule accordingly** | **★ HIGH** | Three distinct regimes, three different correct mathematics. **Risk**: probabilities known → expected utility, Kelly. **Knightian uncertainty**: outcomes known, probabilities not → **maximin / robust optimisation**; probabilistic optimisation is not merely imprecise here, it is **invalid**. **Ignorance**: outcome space itself incomplete → only heuristics survive — hard limits, diversification, small size. **Applying Kelly under Knightian uncertainty is a category error**, and it is the standard error in quantitative finance. Tag every model with its regime |
| **Structural / model-class uncertainty, not just parameter uncertainty** | **★ HIGH** | Bayesian methods quantify uncertainty *within* a model. The larger error is nearly always that **the model class is wrong**. Maintain structurally different models and average over them — disagreement across model *classes* is the honest uncertainty estimate. Pairs with population disagreement in `IDEAS-FRONTIER.md` §10 |
| **Falsification budget** | **★ HIGH** | Allocate a fixed share of research effort to **trying to kill the current best strategy**, not to finding new ones. Popper as resource allocation. Search naturally spends 100% on confirmation; this forces the split, and it is the cheapest overfitting defence available |
| **Deep uncertainty → robustness, not precision** | ◆ REAL | When you cannot know the distribution, seek decisions that are **acceptable across many distributions** rather than optimal under one. Explicitly abandons optimality as the target |

## 6. Tails need their own model — NEW

| Idea | Verdict | Why |
|---|---|---|
| **Extreme value theory (POT / generalised Pareto) for tail risk** | **★ HIGH** | Do not extrapolate a body-fitted distribution into the tail — **model the tail directly** from exceedances. Crypto tails are fat, asymmetric, and the entire reason for position limits. Gaussian or historical VaR **systematically understates exactly the event that ends the account.** Directly parameterises the risk gate rather than decorating a report |
| **Tail dependence, not just correlation** | **★ HIGH** | Correlations converge toward 1 precisely during the events that matter. Model **tail dependence** (copulas at minimum) — a portfolio diversified by ordinary correlation can be entirely undiversified in the tail, which is the only place diversification needed to work |
| **Hill estimator monitoring on live returns** | ◆ REAL | Track the tail index over time. A thickening tail is an early regime warning that volatility measures miss |

---

# PART III — MULTI-PERIOD REALITY

## 7. One-period optimisation is the wrong problem — NEW

| Idea | Verdict | Why |
|---|---|---|
| **Multi-period portfolio optimisation with transaction costs (receding horizon)** | **★ HIGH** | Single-period optimisation **cannot** handle transaction costs correctly, because the cost of getting into a position depends on how long you will hold it and what you will do next. Optimise a **trajectory** over a horizon subject to costs and constraints, execute only the first step, re-plan next period — model-predictive control applied to the book. This is the correct formulation, it is convex under standard assumptions, and it composes directly with CVXPY (`FEATURES.md` §7). *(`IDEAS-ADVANCED.md` §17 lists MPC as control theory; this is the portfolio-specific application, which is the one that matters here.)* |
| **Time-inconsistency and precommitment** | **★ HIGH** | A plan optimal today may not be optimal tomorrow even with no new information — so a system that re-optimises freely every period **thrashes**, paying costs to chase its own changing plan. Requires explicit **precommitment devices**: minimum holding periods, hysteresis bands, rebalance thresholds rather than rebalance schedules. Turnover control is a *consequence* of this, not a heuristic |
| **Hysteresis instead of thresholds everywhere** | **★ HIGH** | Any binary decision driven by a continuous signal will chatter at the boundary. Separate entry and exit thresholds. Cheap, universal, and routinely omitted |

## 8. Convexity as a design target — NEW

| Idea | Verdict | Why |
|---|---|---|
| **Prefer convex payoff profiles to disorder** | **★ HIGH** | Beyond robustness: seek positions and strategies whose payoff **improves with volatility and dislocation** — long optionality, long gamma, liquidity provision that pays more in stress, cross-venue dislocation capture. In a market that periodically breaks, convexity to breakage is the most reliable structural edge available. Robust means "survives stress"; convex means "**profits from it**" |
| **Barbell allocation** | ◆ REAL | Extreme safety plus a small allocation to extreme convexity, avoiding the middle where most capital sits and most ruin occurs. Fits the ergodic objective in `IDEAS-FRONTIER.md` §1 |
| **Via negativa — improvement by removal** | **★ HIGH** | Systematically test **deleting** components, features and rules. Nearly all systems accumulate; almost none prune. Composes directly with production ablation (`IDEAS-FRONTIER.md` §5) — the ablation infrastructure exists to answer "what can we delete?" and deletion is the highest-confidence improvement available, because removing a thing cannot overfit |
| **Lindy filter on load-bearing components** | ◆ REAL | For the parts that must not break, prefer techniques that have survived decades over those that are three years old. Novelty belongs in the alpha layer, never in the risk layer |

---

# PART IV — ATTACK SURFACE NOBODY MODELS

## 9. Prompt injection *through market data* — NEW, and genuinely under-appreciated

This is the most novel security item across all four files.

| Idea | Verdict | Why |
|---|---|---|
| **Treat every attacker-controlled string in the market data path as an injection vector** | **★ HIGH** | The system's LLM components will read text. **Much of that text is written by adversaries and costs them almost nothing to create.** Token names and symbols. On-chain memo fields. NFT and contract metadata. Project descriptions. Social sentiment feeds. New listing announcements. **Anyone can deploy a token named to read as an instruction** — and it arrives through the *market data feed*, not through anything anyone thinks of as user input. It appears in a screener, a new-listings scan, a sentiment pipeline, and lands directly in a model's context. **The Dual-LLM quarantine in `FEATURES.md` §11 was designed for research documents; this threat comes in through the price feed itself.** Any pipeline where market-derived text reaches a model with tool access is exploitable, and the attacker's cost is one token deployment |
| **Structured extraction only — never free text into a reasoning context** | **★ HIGH** | Market-derived text should be parsed into **typed fields with validated ranges**, never passed as prose to a component that can act. Strip, escape, allowlist. Treat it exactly as you would treat SQL from a stranger |
| **Slow context poisoning of long-lived memory** | **★ HIGH** | The memory and belief systems in `IDEAS-INTELLIGENCE.md` §1/§3 are **persistent**, which makes them a durable target. An adversary who can influence what gets remembered has more leverage than one who influences a single decision. **Belief provenance is the defence** — every belief traceable to its source, and sources scoreable and revocable |
| **Semantic denial of service** | ◆ REAL | Flood the autonomous researcher with plausible, useless material to exhaust its budget and attention. The curiosity budget cap (`IDEAS-INTELLIGENCE.md` §4) is the structural mitigation |
| **Adversarial content targeting known model behaviours** | ◇ SPECULATIVE | As LLM-driven trading grows, content crafted to move *models* rather than people becomes economically rational. Early, but the incentive is unambiguous |

## 10. Data integrity — the feed itself may be wrong — NEW

| Idea | Verdict | Why |
|---|---|---|
| **Byzantine data handling with independent quorum** | **★ HIGH** | Two independent sources for anything that drives a decision. **When they disagree — which they will — there must be a pre-decided rule**, not a live judgement: trade on the conservative value, or halt. Silent single-source corruption is a documented cause of real blowups, and it is invisible precisely because nothing errors |
| **Clock discipline and timestamp provenance** | **★ HIGH** | Exchange timestamp, gateway timestamp, and local receipt time are **three different quantities**, and conflating them creates look-ahead bias that no purge/embargo scheme catches — because the leakage is in the *data*, not the split. Every record carries all three, and the clock-gated access API (`ARCHITECTURE.md` §Layer 0) keys on the correct one |
| **Data quality as a monitored signal, not a batch check** | ◆ REAL | Staleness, gaps, out-of-order arrival, crossed books, impossible prints. Continuous, with automatic de-risking on degradation — bad data should reduce size before it reaches a model |

---

# PART V — DURABILITY

## 11. The knowledge layer must outlive the code layer — NEW

| Idea | Verdict | Why |
|---|---|---|
| **Architect so the durable asset is portable** | **★ HIGH** | The code will be rewritten — probably more than once, and possibly by a better model in two years. **What must survive that rewrite is the calibrated knowledge**: the trial registry, the belief graph with provenance, postmortems, the negative-result corpus, measured costs and capacities. Store these in **model-independent, framework-independent formats with their own schema**, never as an implementation detail of the current codebase. This is the difference between "two years of work" and "two years of work you can build on" — and it is decided by an early architectural choice that looks unimportant at the time |
| **Preserve raw immutable data as an option on future insight** | **★ HIGH** | Feature engineering is **lossy and opinionated**. Every derived feature encodes today's hypotheses; tomorrow's will differ. Keep raw immutable capture forever — it is cheap, and it is the only way a future model can ask a question you have not thought of yet. **You cannot re-collect the past.** The highest-regret decision in the whole project is discarding data you will want in 2028 |
| **Event sourcing with deterministic replay** | **★ HIGH** | Full system state reconstructible from an immutable event log. Makes every incident **exactly reproducible**, every "why did it do that" answerable, and every backtest/live divergence (`IDEAS-FRONTIER.md` §7) precisely diagnosable rather than argued about |
| **Write for your successor — including a successor model** | ◆ REAL | Documentation and knowledge artefacts should assume the reader has full capability and **zero context**. That reader may well be a future model rewriting this system, and legibility to it is worth real effort now |

---

## The eight that would change the project most

Ordered by consequence, not by difficulty.

1. **Comparative advantage and the "do not compete here" list** (§2) — decides whether any of the rest can work. Nothing else matters if the strategy space is one you structurally cannot win.
2. **Year-1 objective as information gain per dollar risked** (§1) — inverts almost every design decision, correctly.
3. **Preserve raw data forever; make the knowledge layer portable** (§11) — cheap now, irrecoverable later.
4. **Prompt injection through market data** (§9) — a live, cheap, unguarded attack surface on the exact design being built.
5. **Uncertainty-regime classification** (§5) — using Kelly where maximin is required is a category error, not a tuning issue.
6. **EVT and tail dependence** (§6) — the tail is the only part of the distribution that can end the project.
7. **Pre-registered project kill criteria and milestone-gated capital** (§3) — the discipline nobody applies to themselves.
8. **Multi-period optimisation with precommitment and hysteresis** (§7) — single-period optimisation cannot price transaction costs correctly, and thrashing is a silent, permanent tax.

---

## What is deliberately still absent

Unchanged across all four tiers: nothing requiring a capability that does not exist in 2026, nothing
resting on a self-reported benchmark, and **nothing that expands autonomy over capital.**

> **The through-line across four files.** Tier 1 asks *what techniques exist*. Tier 2 asks *how does
> a system behave intelligently*. Tier 3 asks *what should it optimise*. This tier asks *should this
> exist, where can it win, and what survives when the code is thrown away.*
>
> The answers get less technical and more consequential the further up you go — which is the
> opposite of where effort usually goes.
