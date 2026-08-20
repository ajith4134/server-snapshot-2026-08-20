# INTELLIGENCE, AUTONOMY & SELF-KNOWLEDGE — capability space

Companion to `IDEAS-ADVANCED.md`. That file catalogues **techniques** (uncertainty, causality, RL,
optimisation). This file catalogues **architecture for behaving intelligently** — what separates a
system that adapts from a script that executes.

> **Third tier: `IDEAS-FRONTIER.md`** (added 2026-08-02) — ideas that change **the objective
> itself** rather than the machinery pursuing it: ergodicity and time-average growth, alpha as a
> depleting resource with an optimal harvest rate, information-theoretic ceilings, strategies as
> programs in a restricted DSL, the sealed-envelope metric against self-Goodharting, data-poisoning
> resistance, degradation ladders, and population-level disagreement as the uncertainty estimate.

Verdict key follows the existing convention: **★ HIGH** · ◆ REAL · ◇ SPECULATIVE · ✕ DECLINED.

---

## 0. The honest framing

No architecture available in 2026 produces understanding. LLMs do not know things; they produce
text conditioned on text. Anything promising "real intelligence" from a model swap is selling
something — the Alpha Arena result already in `IDEAS-ADVANCED.md` §8 (four of six frontier models
lost 30–63% in 17 days trading real money) is the empirical answer to that hope.

**But the distance between a script and an adapting system is real, and it is crossable.** What
crosses it is not a smarter model. It is:

1. **Beliefs that carry provenance and expire** — instead of facts hardcoded at build time.
2. **Calibrated knowledge of its own competence** — instead of always producing an answer.
3. **Learning from its own history as data** — instead of only learning from market data.
4. **Self-directed acquisition of what it lacks** — instead of consuming only what it was fed.
5. **Modelling itself as a participant** — instead of assuming it acts on the world for free.

Every one of those is buildable with boring engineering. None requires a breakthrough. **That is
the actual opportunity**, and it is almost universally skipped because it is unglamorous.

The failure mode to design against is not stupidity. It is **confident staleness** — a system that
learned something true in 2024, never noticed it stopped being true, and keeps betting on it.

---

## 1. Epistemics — beliefs that know where they came from

The single highest-leverage area, and the one nobody builds.

| Idea | Verdict | Why |
|---|---|---|
| **Belief records with provenance, evidence strength, and a half-life** | **★ HIGH** | Every belief the system acts on — "funding spikes precede reversals on this venue", "maker rebates apply above tier 3" — is a **record**, not a constant: source, acquisition date, evidence class, supporting trials, and a **decay half-life**. Edges decay; confidence must decay with them. A belief past its half-life without refresh **automatically drops to a lower tier** and stops sizing positions. This makes staleness structurally visible instead of invisible |
| **Retraction propagation** | **★ HIGH** | When a source is falsified, **everything derived from it must be re-scored automatically.** Concrete precedent: on 2026-08-02 an entire Instagram account was found to be fabricating repos and metrics — and a conclusion in `instagram-sources.md` ("independent architectural convergence") had already been built on it. That took a human to catch. A belief graph with source edges catches it mechanically. **Any system ingesting the open web needs this or it silently accumulates poison** |
| **Contradiction detection across the knowledge base** | **★ HIGH** | Postmortem A: "widening spreads preceded the loss." Postmortem B: "spreads were normal." Knowledge bases accumulate; they never argue with themselves. A scheduled consistency pass that surfaces contradictions **is how a corpus becomes knowledge instead of an archive** |
| **Source credibility as a live, updating score** | ◆ REAL | Sources earn trust by making checkable claims that check out. The filter already validated empirically: **specific + mechanism-level + no profit claim** correlates with truth; **return figures and dashboards** correlate with fabrication |
| **Distinguish "I read this" from "I verified this" from "I observed this"** | **★ HIGH** | Three epistemic classes with different rights. **Only observed-in-our-own-data beliefs may size a position unaided.** Read-on-the-internet beliefs may only generate hypotheses. This one rule would have prevented most published-strategy disasters |
| Belief-graph query interface | ◆ REAL | "Why do we believe this?" must be answerable in one query, back to primary evidence |

---

## 2. Competence boundaries — knowing what it does not know

| Idea | Verdict | Why |
|---|---|---|
| **Explicit competence map in feature space** | **★ HIGH** | Not "confidence 0.8" but **"is this input inside the region where I was actually validated?"** Density estimate over training/validation inputs; flag out-of-support live inputs. A model asked to predict in a regime it has never seen should say so. **Most live blowups are OOD events, not model error** |
| **Abstention as a first-class action, with its value measured** | **★ HIGH** | Systems that always emit a position are structurally incapable of saying "I don't know." Add **stand-aside** as a real action, and track **the P&L of abstention** — what would have happened had it traded. If abstention never helps, the gate is miscalibrated; if it helps a lot, that is the cheapest alpha in the system |
| **Calibration scoring of its own forecasts** | **★ HIGH** | Brier / log score on every probabilistic claim the system makes, tracked over time and **per regime**. A system that says 70% and is right 50% of the time is not slightly wrong, it is **systematically overconfident**, and position sizing inherits that error multiplicatively |
| **Decision-relevant value of information** | ◆ REAL | Do not chase the highest uncertainty — chase uncertainty **that would change an action**. Uncertainty about something you'd trade identically either way is worth nothing. This is the correct objective for autonomous data acquisition (§4) |
| **Blind-spot audit** | ◆ REAL | Periodically enumerate what the system *never* looks at. Every ignored data source is either a deliberate scope decision or an unknown unknown — and nobody can tell which without writing the list down |
| **Known-unknowns register** | ◆ REAL | An explicit list of things believed to matter but not currently measured. The gap between "we don't model this" and "we forgot this exists" is the difference between risk and surprise |

---

## 3. Memory that behaves like understanding

| Idea | Verdict | Why |
|---|---|---|
| **Offline consolidation — a scheduled "sleep" pass** | **★ HIGH** | Between sessions, re-read raw experience and **re-derive compressed lessons**. Not summarising once at write time — *periodically re-deriving*, because later evidence changes what earlier events meant. A loss in March only becomes "we systematically misprice gap risk" after the fifth similar loss. **Consolidation is where episodes become principles** |
| **Episodic → semantic promotion, evidence retained** | **★ HIGH** | Specific incidents abstract into general rules, but **the supporting cases stay linked**. A principle you cannot trace to incidents is folklore; incidents without a principle are noise |
| **Active forgetting** | ◆ REAL | Knowledge tied to dead market structure (a delisted venue, a retired fee tier, a pre-upgrade chain) must be **retired, not merely outranked**. Unbounded memory degrades into noise, and stale rules fire at the worst moment |
| **Case-based retrieval keyed on regime similarity** | **★ HIGH** | Already in `IDEAS-ADVANCED.md` §13 — restated because it is the payoff of everything above. "This looks like March 2024" is only useful if the retrieval key is a **regime fingerprint**, not text similarity |
| **Negative-result corpus** | **★ HIGH** | What did not work, kept deliberately and searchably. Almost nobody retains failures, so teams re-run the same dead ideas for years. In a system with a Trial Registry this is nearly free — **it is already recording the failures, it just has to make them queryable** |

---

## 4. Autonomy — self-directed acquisition, bounded

The system decides what it needs to know and goes and gets it. This is where autonomy earns its
keep, and also where it is most dangerous.

| Idea | Verdict | Why |
|---|---|---|
| **Curiosity budget as an explicit, capped line item** | **★ HIGH** | A fixed fraction of capital and compute allocated to **actions whose purpose is information, not profit** — deliberately probing fill behaviour at size, testing a venue's true depth, measuring impact decay. Backtests cannot tell you these; only live probing can. Capping it makes exploration **a budget decision instead of an accident** |
| **Autonomous research loop, read-only and quarantined** | ◆ REAL | Detect gap → search → fetch → extract → verify → write a belief record with provenance. **The reader has no credentials and no trading tools** (the existing Dual-LLM quarantine). Everything it produces enters as a *hypothesis*, never a decision |
| **Verification-before-ingestion as a hard gate** | **★ HIGH** | Any factual claim with a checkable form — repo, version, licence, star count, paper, API field — **must be checked against the primary source before entering the knowledge base**. Cheap: `gh`, PyPI JSON, raw docs. This is exactly the discipline that exposed the fabricated account, and it must be mechanical, not a habit |
| **Exchange announcement and changelog monitoring** | **★ HIGH** | Already flagged in `IDEAS-ADVANCED.md` §8 as a pure ops win. Restated because it is the **most defensible autonomous behaviour in the whole system**: schema and fee changes fail silently and cost real money |
| **Active learning over data spend** | ◆ REAL | Historical data, higher-resolution feeds and vendor sources all cost money. Buy the dataset that most reduces **decision-relevant** uncertainty (§2), not the one that is most interesting |
| **Tool/venue discovery** | ◇ SPECULATIVE | Noticing that a needed capability exists and proposing its adoption. Proposal only — adoption stays human |
| **Autonomous browsing with credentials** | ✕ DECLINED | The moment the researcher holds credentials, prompt injection from a hostile page becomes a trading action. Read-only, quarantined, no exceptions |
| **Autonomous capital movement** | ✕ DECLINED | Rule 0 "never do". Non-negotiable regardless of how good it gets |

---

## 5. Self-modelling — the system as a market participant

Almost every backtest assumes the system is a ghost. It is not.

| Idea | Verdict | Why |
|---|---|---|
| **Own-footprint attribution** | **★ HIGH** | Separate *"the market moved"* from *"I moved the market."* Without this, the system learns from its own impact as though it were signal — **a direct route to a self-reinforcing loop that looks like alpha and is actually just pushing price and paying for it** |
| **Counter-detection: am I being read?** | **★ HIGH** | Test whether slippage worsens *conditionally on the system's own recent activity*. If it does, the execution signature has become predictable and someone is trading against it. **This is a measurable, testable question that almost nobody asks**, and the answer decays edges silently |
| **Execution signature entropy** | ◆ REAL | Deliberate randomisation of timing/sizing/venue — but priced, because randomisation costs. Only worth it when counter-detection (above) shows a live problem |
| **Capacity discovery, live** | **★ HIGH** | The size at which an edge dies is a *measurement*, not an assumption. Grow size deliberately until marginal edge decays, then hold below it. Most strategies die from being scaled past capacity, not from being wrong |
| **Cost of its own operation inside the objective** | **★ HIGH** | Compute, data, inference and API costs belong **in the P&L**. A strategy earning less than its inference cost is negative-alpha regardless of Sharpe. As LLM components proliferate this stops being rounding error — and it is a genuine risk of the whole "AI trading" design |
| **Compute allocation as a bandit** | ◆ REAL | Next GPU-hour: more search on strategy A, or better execution modelling on B? An explicit allocation problem, currently made by whim everywhere |

---

## 6. Adversarial awareness — who is on the other side

| Idea | Verdict | Why |
|---|---|---|
| **"Who loses when I win, and why do they accept that?"** as a required field | **★ HIGH** | A mandatory declaration alongside the Mechanism Declaration. Genuine edges have identifiable counterparties acting under constraint — **forced liquidations, index rebalances, expiry hedging, redemption flows, miner/validator sell pressure.** If the answer is "someone irrational", the edge is probably imaginary. This single question kills more bad strategies than any statistical test |
| **Forced-flow calendar** | **★ HIGH** | Predictable non-discretionary flow is the most durable edge class in any market: settlement, expiry, rebalance dates, unlock schedules, funding intervals. **Non-discretionary means it happens whether or not it is profitable for them** — which is exactly why it persists |
| **Standing red-team agent** | ◆ REAL | An adversary whose only job is constructing the market path that kills the current book, run continuously rather than at review time. Its outputs become stress scenarios |
| **Model other participants as agents, not noise** | ◇ SPECULATIVE | Explicit participant taxonomy (market maker, liquidator, index fund, retail momentum) with inferred constraints. Powerful and easy to overfit — hypothesis-generation only |

---

## 7. Learning from its own history — meta-research

The system's own experiment log is an untapped dataset. Nobody mines it.

| Idea | Verdict | Why |
|---|---|---|
| **Meta-analysis over the Trial Registry** | **★ HIGH** | Treat *the system's own experiments* as data. "Strategies of family F die within N days of regime transition T." "Features derived from source S have never survived OOS." **This is learning about learning**, and it is available for free the moment the registry exists |
| **Self-extending failure taxonomy** | **★ HIGH** | Cluster failures; when a cluster fits no existing label, **name a new failure mode**. A taxonomy that can only classify into pre-existing buckets never discovers anything |
| **Decision journal with pre-registered rationale** | **★ HIGH** | Record the reasoning and the *prediction* **before** the outcome. Then score. Without pre-registration, every post-hoc explanation is confabulation — and LLM components confabulate fluently |
| **Process quality scored separately from outcome** | **★ HIGH** | A good decision that lost money is still a good decision. **Resulting bias** — judging process by outcome — is the classic destroyer of trading discipline, and an automated system inherits it directly through any outcome-driven reward |
| **Postmortem → hypothesis pipeline** | ◆ REAL | Every postmortem must end in a testable proposition entering the registry, or it was journaling |

---

## 8. Mechanism-first discovery

| Idea | Verdict | Why |
|---|---|---|
| **Independent falsifiable side-prediction** | **★ HIGH** | The strongest anti-overfitting device available, and it is not statistical. If the claimed mechanism is "funding pressure forces longs to close", that implies **other** observable consequences — open-interest decay, a specific liquidation pattern, a term-structure signature. **Predict one, check it on data never used for the backtest.** A curve-fit has no side-predictions; a real mechanism has many |
| **Natural-experiment mining** | ◆ REAL | Exogenous shocks — outages, halts, listings, regulatory dates — are instruments for causal identification, and they are already in the history |
| **Mechanism decay monitoring** | **★ HIGH** | Monitor the *mechanism's* premise, not just the strategy's P&L. If the edge depended on a fee asymmetry and the fee schedule changed, **retire it immediately** — do not wait for the drawdown to prove it |

---

## 9. Open-ended search — diversity as the real hedge

| Idea | Verdict | Why |
|---|---|---|
| **Quality-diversity archive (MAP-Elites style) instead of a single optimum** | **★ HIGH** | Maintain an archive of strategies that are **good *and* behaviourally different**, indexed by behaviour (holding period, direction bias, regime affinity, turnover) rather than by score. **Correlation is what kills portfolios**; a stable of decorrelated mediocre strategies beats one optimised strategy that fails in one regime. This also matches how the promotion gate should think |
| **Novelty pressure in the search objective** | ◆ REAL | Reward a candidate for behaving *unlike* existing strategies at equal risk-adjusted return. Directly counteracts search collapsing onto one crowded idea |
| **Multiple-testing accounting across the whole archive** | **★ HIGH** | Non-negotiable, and it is the trap in everything above: **a diverse archive is a larger search**, so the DSR/PBO correction gets harsher, not gentler. Search breadth must be *counted* — this is exactly where the corpus's 7,846-rule and 73%-deterioration findings bite |

---

## 10. Self-modification with an immune system

If the system ever writes or rewrites its own logic, these stop being optional.

| Idea | Verdict | Why |
|---|---|---|
| **Proposer and approver must be separate, and the approver must not be self-modifiable** | **★ HIGH** | The fixed point that makes self-modification survivable. A system that can edit its own safety checks has none. **The risk gate, the promotion gate and the kill switch are outside the mutable region — permanently** |
| **Genome diff log** | **★ HIGH** | Every self-authored change: full diff, rationale, author component, and the trial that justified it. Irreversible without this |
| **Canary + quarantine + automatic rollback** | **★ HIGH** | New logic runs shadow → tiny size → normal, with automatic revert on divergence. Never a direct promotion |
| **Property-based invariants that must hold everywhere** | **★ HIGH** | Machine-checked assertions true in backtest, shadow and live alike: no future data touched, position limits never breached, no order without a risk-gate token. **Invariant violation is a bug, never a market event** — and this is the cheapest possible defence against look-ahead leakage |
| **Backtest/live divergence alarm on identical inputs** | **★ HIGH** | Replay the same inputs through both paths; any behavioural difference is a defect. This is the practical enforcement of the "one code path" property that decided the NautilusTrader choice |

---

## 11. Metacognition about its own reasoning

Specific to LLM components, and specific to their known failure modes.

| Idea | Verdict | Why |
|---|---|---|
| **Convergence between adversarial agents treated as a warning, not confidence** | **★ HIGH** | When bull and bear agents agree too often, that is **mode collapse, not certainty** — usually shared priors or a leading prompt. Track disagreement rate as a health metric; **rising agreement is a defect signal.** Genuinely non-obvious and cheap |
| **Sycophancy / anchoring detection** | **★ HIGH** | Does the LLM layer's opinion track whatever was said most recently or most emphatically? Testable by replaying the same decision with reordered and reworded context. **If conclusions move, the component is an echo, not an analyst** |
| **Position-order and framing invariance tests** | ◆ REAL | Same evidence, permuted presentation, must yield the same call. A standing regression test for every LLM component |
| **Reasoning-change audit** | ◆ REAL | When the system changes its mind, log what evidence caused it. Changes with no identifiable new evidence indicate noise being mistaken for updating |
| **Confabulation check on postmortems** | **★ HIGH** | An LLM writing a cause for every incident **will always produce one**, whether or not the cause is knowable. Require "cause unknown" to be an available and sometimes-chosen output, and monitor how often it is chosen — **if it is never chosen, the postmortems are fiction** |

---

## 12. Execution intelligence

| Idea | Verdict | Why |
|---|---|---|
| **Regret-based execution learning** | **★ HIGH** | After the fact, compute the best achievable execution with hindsight, and learn the policy from the **regret** rather than from a fixed schedule. Execution is the rare part of trading with dense, fast, near-honest feedback — **it is the best place in the system for genuine learning** |
| **Counterfactual fill simulation** | ◆ REAL | For every unfilled or partially filled order: what would have happened at a different price, size or venue? Turns non-events into training data |
| **Venue-conditional impact model** | ◆ REAL | Impact and decay differ per venue and per regime; a single global impact constant is a fiction |

---

## The ten to build first

Ordered by leverage per unit of effort, not by sophistication.

1. **Belief records with provenance and half-life** (§1) — the substrate everything else needs.
2. **Read / verified / observed epistemic classes, with only "observed" allowed to size** (§1).
3. **Verification-before-ingestion gate** (§4) — mechanical, cheap, already proven necessary.
4. **Abstention as a real action, with its P&L measured** (§2).
5. **Calibration scoring of the system's own forecasts** (§2).
6. **"Who loses when I win?" as a required declaration** (§6) — one question, enormous filtering power.
7. **Meta-analysis over the Trial Registry** (§7) — the data already exists.
8. **Own-footprint attribution and counter-detection** (§5) — otherwise it learns from its own noise.
9. **Cost of operation inside the objective** (§5) — decides whether the AI layer pays for itself.
10. **Property-based invariants across backtest/shadow/live** (§10) — cheapest defence against leakage.

**What is deliberately absent:** anything requiring a model breakthrough, anything giving the system
credentials or capital autonomy, and anything whose value rests on a self-reported benchmark. The
list is boring on purpose. **Boring is what compounds.**

---

## The one-line test for every idea above

> **Does it change what the system does when it is wrong?**

Features that only improve behaviour when the system is already right are decoration. Every entry
marked ★ HIGH changes behaviour under error — by refusing to act, by expiring a belief, by catching
a contradiction, by rolling back, or by noticing that the world moved.
