# SYNTHESIS — composites, actuarial thinking, and the selection problem

Sixth and **final** tier.

- `IDEAS-ADVANCED.md` techniques · `IDEAS-INTELLIGENCE.md` intelligent behaviour
- `IDEAS-FRONTIER.md` the objective · `IDEAS-STRATEGIC.md` the premises
- `IDEAS-AI-FIELD.md` the discipline by subfield
- **this file** — **what emerges between them, and how to choose**

> **Why this is the last tier, stated plainly.** The corpus now holds **383 candidate features, 172
> rated HIGH.** Generating more is no longer the constraint — **choosing is.** A seventh file of
> ideas would be padding, and padding a research corpus is worse than useless because it dilutes the
> signal in the six that came before.
>
> So this file does three things that adding more ideas cannot: it captures **composites** that
> exist only where two earlier ideas meet, it adds the **one genuinely new lens** left (actuarial /
> ecological), and it confronts the **selection problem** the corpus has created.

---

# PART I — COMPOSITES

Not new ideas. **Intersections** — where two entries from earlier files combine into something
neither has alone. This is where the corpus's real value is, and none of it is visible from any
single file.

| Composite | Sources | Why it matters |
|---|---|---|
| **Conformal-bounded safety filter** | Conformal prediction (`AI-FIELD` I) × Control barrier functions (`AI-FIELD` III) | A CBF needs a **safe set**. Defining it from point estimates inherits every model error. Define it instead from **conformal prediction intervals** — distribution-free, finite-sample, valid under shift. The result is a safety filter whose guarantee **does not depend on the model being right**, only on the conformal coverage holding. **This is the strongest safety construction available in the whole corpus**, and neither component suggests it alone |
| **Belief graph as the PAC-Bayes prior** | Belief records (`INTELLIGENCE` §1) × PAC-Bayes (`AI-FIELD` I) | PAC-Bayes bounds tighten when the learned hypothesis is close to a **prior specified before seeing the data**. The belief graph *is* exactly that — a dated, provenanced record of what was believed beforehand. **Strategies consistent with prior mechanism knowledge earn mathematically tighter generalisation bounds than strategies discovered by search alone.** It converts "we had a reason" from a soft argument into a quantity inside a bound |
| **Pessimism proportional to capacity distance** | Offline-RL pessimism (`AI-FIELD` II) × Capacity discovery (`INTELLIGENCE` §5) | Offline RL penalises value estimates in low-data regions. **Size is such a region.** Penalise expected edge in proportion to how far the proposed size sits beyond sizes you have actually traded — a principled, continuous version of "scale up slowly" that replaces a rule of thumb with a derived quantity |
| **Gate entropy as a free regime detector** | MoE regime experts (`AI-FIELD` VI) × Change-point detection (`FRONTIER` §8) | If experts specialise by regime, the **gating distribution is a regime posterior you already compute.** Rising gate entropy = the model no longer recognises the regime. A structural-break alarm derived from the model's own internals, at zero marginal cost |
| **Correlated-drift detection** | Population disagreement (`FRONTIER` §10) × Sealed-envelope metric (`FRONTIER` §5) | Population disagreement catches *idiosyncratic* failure. It is **blind to all instances drifting together** — which is the dangerous case, since they share data and priors. The sealed-envelope metric is the only thing that sees common-mode drift. **Each covers precisely the other's blind spot; neither is sufficient alone** |
| **Effective-sample-size-aware trial accounting** | Dependent-data theory (`AI-FIELD` I) × Trial Registry / DSR | The multiple-testing correction counts trials. But if observations are heavily dependent, the *evidence per trial* is far smaller than the row count implies. **Correct on both axes at once** — number of trials *and* effective sample size per trial — or the correction is precise about one thing while wrong about the other |
| **Regret-minimising execution under a CBF** | Execution regret learning (`INTELLIGENCE` §12) × Safety filter (`AI-FIELD` III) | Execution is the best place for genuine online learning (dense, fast feedback), and the *only* place aggressive learning is safe — **because a barrier function bounds the damage.** Learn freely inside a provably bounded set |
| **Mechanism side-predictions as conformal calibration targets** | Falsifiable side-predictions (`INTELLIGENCE` §8) × Conformal | Do not merely check whether the side-prediction was directionally right — **check whether its conformal intervals were calibrated.** A mechanism that is right on average but miscalibrated is not understood |

---

# PART II — ACTUARIAL: your own strategies are a population

`IDEAS-ADVANCED.md` names survival analysis as a technique. **What is absent is turning it on
yourself.** Strategies are born, live, and die; you will have dozens; that is a population with a
mortality structure, and it is measurable.

| Idea | Verdict | Why |
|---|---|---|
| **Hazard model over your own strategy population** | **★ HIGH** | Fit survival curves and a hazard function to **strategy lifetime**. Covariates: family, complexity, capacity used, search intensity that produced it, regime at birth, mechanism class. Output: **the probability this strategy is still alive in 90 days, conditional on its features and current age.** That number belongs directly in sizing — and nobody computes it, because nobody thinks of strategies as a cohort |
| **Cause-of-death registry with a controlled vocabulary** | **★ HIGH** | Every retirement records cause from a **fixed, extensible taxonomy** — mechanism died, crowded out, capacity exceeded, cost regime changed, was never real (overfit), operational failure, venue change. A free-text postmortem is unqueryable; a controlled vocabulary makes mortality **statistically analysable**. Extends the self-extending failure taxonomy (`INTELLIGENCE` §7) with the discipline that makes it countable |
| **Competing-risks analysis** | ◆ REAL | Strategies do not die of one thing. Separate cause-specific hazards tell you **which death to defend against for this strategy** — crowding and overfitting demand completely different responses |
| **Actuarial expected remaining life as a sizing input** | **★ HIGH** | Position size should reflect **expected remaining edge life**, not just current Sharpe. A strategy with a great Sharpe and a 30-day median remaining life deserves less capital than a mediocre one with two years. **Sharpe is a point estimate about the past; hazard is a forecast about the future** — and only one of them is about what happens next |
| **Left-truncation and survivorship correction in your own records** | **★ HIGH** | Your registry contains strategies that died before ever being recorded properly. **Your own history has survivorship bias** — the same defect you correct for in market data, applied to your own experience. Almost nobody notices this |
| **Birth-cohort effects** | ◆ REAL | Strategies discovered in the same regime share failure modes and die together. Track by cohort; **a cohort is a hidden correlation cluster in the portfolio** |

---

# PART III — ECOLOGY: co-evolution and the AI-vs-AI market

| Idea | Verdict | Why |
|---|---|---|
| **Alpha as an ecological niche; competitive exclusion** | **★ HIGH** | Two strategies exploiting the identical inefficiency **cannot coexist indefinitely** — the better-capitalised or faster one excludes the other. This reframes strategy selection as **niche selection**, and it makes the comparative-advantage analysis (`STRATEGIC` §2) formal: find niches where the exclusion principle works *for* you because incumbents cannot profitably occupy them at your size |
| **Model monoculture as a systemic risk — and as an opportunity** | **★ HIGH** | **The most important forward-looking item in this file.** As participants converge on a small number of foundation models and similar agent designs, their **errors correlate**. That produces herding at machine speed, synchronised liquidation, and crowded trades that unwind together — a *new* systemic risk with no historical analogue in the data anyone is training on. Two consequences: **(1) defensively**, do not build on the same models everyone else uses without expecting correlated failure at the worst moment; **(2) offensively**, predictable machine behaviour is **forced flow** (`INTELLIGENCE` §6), and forced flow is the most durable edge class there is |
| **Deliberate model-family diversity** | **★ HIGH** | Where the system depends on model judgement, use **genuinely different model families** — different pretraining, different vendors. Agreement then means something; correlated failure becomes less likely. This is the population-diversity argument (`FRONTIER` §10) applied to a dependency you do not control and cannot inspect |
| **Red Queen dynamics** | ◆ REAL | Edges decay because competitors adapt, so a constant research rate is required merely to stand still. Makes research throughput a **maintenance cost**, not a growth investment — and budgeting it as growth is why systems decay quietly |
| **Niche-invasion forecasting** | ◇ SPECULATIVE | Predict which corners get competed away next — as capital grows, tooling commoditises, or a venue matures. Would let you exit before decay rather than after. Hard, but the exit-timing value is large |

---

# PART IV — DEEP MATHEMATICS still missing

| Idea | Verdict | Why |
|---|---|---|
| **Stochastic portfolio theory — relative arbitrage (Fernholz)** | **★ HIGH** | A rigorous, descriptive theory proving that **relative arbitrage exists under empirically observable market-structure conditions** — chiefly *diversity* and volatility structure — rather than under assumed return predictions. Diversity-weighted portfolios can provably outperform the market portfolio over sufficient horizons **without forecasting anything.** Almost unused outside a few shops, mathematically solid, and philosophically the opposite of everything else here: **structure rather than prediction.** Crypto's concentration dynamics make the diversity condition directly testable |
| **Nonlinear filtering for latent market state** | **★ HIGH** | Regime is a **latent** state observed through noise. Kalman assumes linear-Gaussian; markets are neither. Proper nonlinear filtering — particle filters, unscented variants — gives a **posterior over hidden state, updated online**, rather than a regime label from a classifier. The honest formulation of "what state is the market in", and it composes with the ergodic sizing objective |
| **Stochastic optimal control / HJB** | ◆ REAL | The continuous-time formulation behind optimal execution and dynamic portfolio choice. Often intractable directly, but **the formulation itself disciplines the problem** — it forces explicit statements of dynamics, controls and costs that discrete heuristics leave vague |
| **Propagator models for execution** | ◆ REAL | Named in `IDEAS-ADVANCED.md`; restated because it is the correct model of **transient vs permanent impact** and therefore of how quickly you may re-trade after a fill. Directly parameterises the multi-period optimiser (`STRATEGIC` §7) |
| **Malliavin calculus for Greeks** | ◇ SPECULATIVE | Efficient sensitivities for path-dependent payoffs. Only relevant if the options layer becomes substantial |

---

# PART V — THE NULL HYPOTHESIS: how would you know you have no edge?

Absent from all six files, and it is the question most likely to be true.

| Idea | Verdict | Why |
|---|---|---|
| **A formal no-edge test, pre-registered** | **★ HIGH** | Define **in advance** the observation that would mean "there is no edge here and there never was." Without it, every result is interpreted as encouraging, because ambiguous evidence always is. This is the epistemic counterpart to project kill criteria (`STRATEGIC` §3) — that one is about *when to stop*, this one is about *how you would know you should* |
| **Minimum track record length** | **★ HIGH** | Named in `promotion-pipeline.md` for strategy promotion; **not applied to the operator.** Given an observed Sharpe and its variance, there is a **minimum number of observations before skill is distinguishable from luck at a stated confidence.** Compute it for the *whole enterprise*, not just per strategy. The answer is usually far longer than people expect, and knowing it prevents both premature scaling and premature despair |
| **Pre-mortem** | **★ HIGH** | Before starting: *"It is 2028 and this failed completely. Write the explanation."* Prospective hindsight is one of the few debiasing techniques with **real experimental support** — it surfaces risks that forward-looking risk assessment reliably misses. Costs an hour |
| **Base rates for this exact endeavour** | **★ HIGH** | Most solo systematic projects fail; most retail algorithmic trading loses; most published strategies do not replicate — the corpus already documents a **median 73% Sharpe deterioration** backtest→live across 215 promoted strategies. **A plan should state which base rate it expects to beat and why**, or it is implicitly claiming top-decile skill without saying so |
| **Distinguishing process from outcome in the operator's own record** | ◆ REAL | The same discipline `INTELLIGENCE` §7 applies to the system, applied to yourself. Resulting bias operates on humans far more strongly than on code |

---

# PART VI — THE SELECTION PROBLEM

**383 candidates and 172 marked HIGH is not a plan. It is a new problem**, and it is the one that
now binds.

| Idea | Verdict | Why |
|---|---|---|
| **Dependency graph over the feature set** | **★ HIGH** | Most of these features **enable** others. Belief records enable retraction propagation, PAC-Bayes priors, and the knowledge layer's portability. The Trial Registry enables meta-analysis, hazard models, and cohort effects. Event sourcing enables deterministic replay and divergence alarms. **Build the graph, then build the roots.** Ordering by individual value is exactly wrong — order by **enabling power** |
| **Minimum viable epistemic core** | **★ HIGH** | The smallest set that makes everything else **learnable rather than guessed**. My candidate: **immutable raw data capture + event sourcing + trial registry + belief records with provenance.** Four things. None of them make money. **All of them determine whether year two is built on evidence or on anecdote** — and every one is far cheaper now than retrofitted later |
| **One-way vs two-way doors** | **★ HIGH** | Classify every architectural decision by reversibility. **Two-way doors should be decided fast and revisited cheaply; one-way doors deserve disproportionate deliberation.** Data schema, storage format, venue lock-in, custody arrangement and licence exposure are one-way. Most feature choices are two-way and are being over-deliberated while the irreversible ones get decided by default |
| **Cost of delay per feature** | ◆ REAL | Some features get **more expensive the later they are added** — anything touching data capture, provenance, or schema. Others are equally cheap forever. **Cost of delay, not value, should drive sequencing** for the first group |
| **Explicit "not now, and here is the trigger" list** | **★ HIGH** | For every HIGH-rated item not being built: record the **condition that would promote it** — a capital threshold, an observed failure, a strategy count. Converts an overwhelming backlog into a **small active set plus a set of watch conditions**, and stops the backlog functioning as a source of guilt rather than direction |
| **Feature-level pre-registration** | ◆ REAL | Before building anything from this corpus, state what it should change and how you would know it did. Otherwise the corpus becomes a shopping list executed for its own sake |

---

## The seven that would change things most, across all six files

Deliberately short. Selected for **enabling power and irreversibility**, not individual cleverness.

1. **Immutable raw data capture, from day one** (`STRATEGIC` §11) — you cannot re-collect the past, and every other idea depends on having it.
2. **Belief records with provenance and half-life** (`INTELLIGENCE` §1) — the substrate for retraction propagation, PAC-Bayes priors, and knowledge portability.
3. **Trial registry with effective-sample-size-aware accounting** (composite, Part I) — makes every later claim about edge meaningful rather than decorative.
4. **Conformal-bounded safety filter** (composite, Part I) — the strongest safety construction in the corpus; its guarantee survives the model being wrong.
5. **Comparative advantage and the "do not compete here" list** (`STRATEGIC` §2) — decides whether any of this can work at all.
6. **Ergodic / time-average objective** (`FRONTIER` §1) — changes every position size, and is correct rather than preferred.
7. **Pre-registered no-edge test and minimum track record length** (Part V) — the only defence against spending years mistaking noise for skill.

---

## Closing note, meant seriously

Six files, 383 candidates, 172 rated HIGH. **The corpus is now comprehensive enough that its
main risk is itself.**

Three failure modes it creates, and the honest countermeasure to each:

1. **Paralysis by option count** → Part VI exists for this. Build the four-item epistemic core first, and put everything else behind explicit promotion triggers.
2. **Sophistication as procrastination** → every idea here is more enjoyable to read about than to build. **A working system with the four core items beats a perfect design document, permanently.**
3. **Dilution of the good ideas** → this is why there is no seventh tier. The marginal idea is now worth less than the clarity it costs.

> The single most valuable thing in six files is not any individual feature. It is that
> **every altitude independently converged on the same conclusion**: build the thing that tells you
> when you are wrong, before building the thing that tries to be right.
