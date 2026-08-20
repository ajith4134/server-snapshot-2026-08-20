# FRONTIER — the hard tier

Third file in the capability stack:

- `IDEAS-ADVANCED.md` — **techniques** (uncertainty, causality, RL, optimisation)
- `IDEAS-INTELLIGENCE.md` — **architecture for behaving intelligently** (epistemics, autonomy, self-modelling)
- **this file** — **ideas that change the objective itself**, not the machinery that pursues it

Verdict key as before: **★ HIGH** · ◆ REAL · ◇ SPECULATIVE · ✕ DECLINED.

> **Why a third tier.** Everything in the first two files makes the system better at pursuing a
> goal. The entries here mostly argue that **the goal is wrong** — that maximising expected return,
> harvesting an edge as fast as possible, or optimising a metric you also measure yourself by, are
> each subtly self-defeating. These are harder to accept than they are to implement.

> **Fourth tier: `IDEAS-STRATEGIC.md`** (added 2026-08-02) — the premises beneath even this one:
> comparative advantage and where a solo operator can structurally win, year-1 objective as
> information gain rather than return, Knightian uncertainty regimes and which decision theory
> applies, extreme value theory for tails, multi-period optimisation with precommitment,
> convexity as a design target, **prompt injection arriving through the market data feed**,
> byzantine data quorum, project-level kill criteria, operator continuity, and making the
> knowledge layer outlive the code.

---

## 1. The objective is probably wrong — ergodicity

**This is the most important entry in all three files.** It is rigorous, it is ~15 years old, and it
is still almost absent from practitioner systems.

| Idea | Verdict | Why |
|---|---|---|
| **Optimise the time-average growth rate, not expected value** | **★ HIGH** | Expected value is an average **across parallel universes**. You get **one** capital path, compounding, with an absorbing barrier at zero. For multiplicative dynamics these two averages **are not equal** — the ensemble average is dominated by branches you will never occupy. A bet with positive expected value can have negative time-average growth and **ruin you with probability 1 while looking profitable in every backtest that averages P&L across trades.** Optimise $\mathbb{E}[\log(1+r)]$, not $\mathbb{E}[r]$ |
| **Survival-first objective** | **★ HIGH** | Reformulate the top-level goal as *maximise the probability of still trading in N years*, with return as a constraint rather than the objective. Different optimum, and it is the one that matches an operator with one account and no outside capital |
| **Bayesian Kelly from the posterior, not a heuristic fraction** | **★ HIGH** | "Half Kelly" is folklore compensating for parameter uncertainty. If you have a **posterior** over edge (§NumPyro in `FEATURES.md` §7), integrate over it and derive the fraction properly. Uncertainty in the edge estimate should shrink size *mathematically*, not by superstition |
| **Absorbing-barrier-aware backtest metrics** | **★ HIGH** | A backtest that reports mean return across paths hides ruin. Report **median terminal wealth and P(ruin)** alongside Sharpe. Mean and median diverge enormously under multiplicative dynamics — that divergence *is* the risk |
| Ensemble-vs-time-average divergence as a strategy diagnostic | ◆ REAL | Compute both. A large gap flags a strategy whose apparent profitability is an artefact of averaging |

---

## 2. Alpha is a depleting resource — harvest rate as a decision

Nobody treats edge as a stock to be managed. It is one.

| Idea | Verdict | Why |
|---|---|---|
| **Optimal harvest rate — deliberately trade *below* capacity to extend edge life** | **★ HIGH** | An edge has a finite total extractable value. Trading it hard maximises today's P&L **and accelerates its death** — through impact, through crowding, through detection. This is the **optimal-extraction problem** (Hotelling / fishery management), and its solution is *not* "trade maximum size". Almost every fund does the wrong thing here because quarterly incentives dominate. **A single operator has no such pressure and can actually do the correct thing** |
| **Endogenous decay model — decay as a function of your own footprint** | **★ HIGH** | Model edge half-life as depending on **your own deployed capital and visibility**, not as an exogenous constant. Then edge lifetime becomes a control variable |
| **Reflexivity / crowding self-forecast** | ◆ REAL | Success attracts imitation; the trade becomes crowded; crowded trades unwind violently together. Forecast your own crowding from public footprint, correlation with known factor returns, and how discoverable the mechanism is |
| **Optimal stopping for strategy retirement** | **★ HIGH** | When to kill a decaying strategy is a **formal optimal-stopping problem**, not a drawdown threshold. The alternative use of that capital is the opportunity cost. Retiring too late is the single most common capital destroyer in systematic trading |
| **Real-options view of research projects** | ◆ REAL | A half-built strategy is an option, not a sunk cost. Value it as one — that is what makes abandoning research rational instead of emotional |

---

## 3. Know the ceiling before you spend years chasing it

| Idea | Verdict | Why |
|---|---|---|
| **Estimate the information-theoretic ceiling at each horizon** | **★ HIGH** | Before optimising, bound what is *achievable*: estimate the mutual information between the feature set and forward returns. If the ceiling at a horizon is near zero, **no model will ever work there** and every month spent is wasted. This converts "our model is bad" into "this horizon carries no information for us", which is a completely different decision |
| **Channel-capacity audit of the data pipeline** | ◆ REAL | Information cannot exceed what the inputs carry. If the target needs order-flow information and you only have OHLCV, the ceiling is structural — **buy the data or abandon the horizon** |
| **MDL / description-length as a promotion criterion** | **★ HIGH** | A strategy whose description costs more bits than it saves in prediction error is overfit — **provably, not statistically.** A parameter-count-free complexity penalty that composes cleanly with the existing DSR/PBO stack |
| **Predictability decay curve by horizon** | ◆ REAL | Measure how the ceiling falls with horizon; it tells you which horizons are worth infrastructure investment at all |

---

## 4. Strategies as programs in a restricted language

The strongest single architectural idea here for a self-modifying system.

| Idea | Verdict | Why |
|---|---|---|
| **A restricted strategy DSL — not free-form Python** | **★ HIGH** | If the system authors strategies, it should emit **programs in a small typed language** whose primitives are market-meaningful (signals, filters, sizing rules, guards). Then: unsafe operations are **inexpressible by construction** (no network, no file access, no unbounded loops, no future indexing); strategies become **diffable, searchable and hashable**; equivalence and dominance are checkable; and the search space is enormously smaller than free-form code. **The safety argument alone justifies it** — you cannot sandbox your way to the guarantee that a DSL gives you for free |
| **Program synthesis over the DSL** | ◆ REAL | Enumerative/constraint-guided synthesis with the mechanism as specification. Beats free-form LLM code generation on verifiability, and composes with `IDEAS-ADVANCED.md` §8 |
| **Neurosymbolic: symbolic mechanism graph + learned parameters** | ◇ SPECULATIVE | Structure carries the causal claim and is human-auditable; parameters are fitted. Interpretability by construction rather than post-hoc |
| **Semantic dedup of the strategy archive** | **★ HIGH** | Two strategies with different code and identical behaviour are **one trial, not two** — and counting them as two corrupts the multiple-testing correction. Canonicalise DSL programs and dedup on behaviour, not text |

---

## 5. Goodhart defence — the metric you never optimise

| Idea | Verdict | Why |
|---|---|---|
| **Sealed-envelope metric** | **★ HIGH** | Hold out one evaluation metric — and ideally one data slice — that is **never used for any optimisation, selection, or tuning decision, ever.** It exists solely to audit whether improvements in the optimised metrics are real. The moment it is used to choose anything, it is burned and must be replaced. **This is the only reliable defence against a self-improving system optimising its own scoreboard**, and it costs nothing but discipline |
| **Improvement-theatre detection** | **★ HIGH** | Track correlation between "metrics we optimise" and "sealed metric" over time. **Divergence means the system is learning the evaluation rather than the market** — the precise failure mode of any self-modifying loop |
| **Metric rotation** | ◆ REAL | Periodically rotate which metrics drive selection, so no single one is gamed indefinitely |
| **Production ablation** | **★ HIGH** | Periodically disable a component on a small capital slice and measure the difference. **A/B test your own architecture.** Most systems accumulate components nobody can prove contribute anything — this is how you find out, and how you delete things |
| **Counterfactual shadow portfolios** | **★ HIGH** | Continuously run N counterfactual books — no risk gate, different sizing, no regime filter — to get **component-level marginal value by counterfactual rather than correlation.** Cheap: they are simulations sharing one live data feed |

---

## 6. Adversarial reality — your data is manufactured by people who profit from your reaction

Standard ML assumes nature generates the data. In markets, **an adversary can create it.**

| Idea | Verdict | Why |
|---|---|---|
| **Data-poisoning resistance as an explicit design requirement** | **★ HIGH** | Wash trades, spoofed depth, painted closes and fake volume are **inputs someone deliberately manufactured**, sometimes specifically to trigger systematic reactions. This is training-time and inference-time poisoning, and it is legal-adjacent, routine, and cheap for the attacker. **Any order-book-derived feature must be built assuming its inputs are partly hostile** |
| **Decision-flip robustness testing** | **★ HIGH** | Perturb inputs within plausible bounds; check whether the decision flips. A strategy that reverses on one spoofed level is fragile to **both** glitches and deliberate manipulation. Cheap, and almost never done |
| **Certified robustness bounds around decisions** | ◇ SPECULATIVE | Formal margins on the decision boundary. Expensive, rarely tractable at scale |
| **Manipulation-signature detection** | ◆ REAL | Layering, momentum ignition and quote stuffing have identifiable signatures. Detecting them is both a **filter** (discard poisoned inputs) and, carefully, a **signal** |
| **Assume your execution is being modelled** | **★ HIGH** | Pairs with counter-detection in `IDEAS-INTELLIGENCE.md` §5. Design under the assumption that a well-resourced participant is fitting a model to your order flow, because at any meaningful size one is |

---

## 7. Structured failure — degrade instead of break

| Idea | Verdict | Why |
|---|---|---|
| **Degradation ladder with automatic transitions** | **★ HIGH** | Most systems have two states, on and off. Define **full → reduced size → hedge-only → flat → halt**, with explicit triggers and automatic transitions **in both directions**. Recovery must also be automatic and gated, or a human under stress makes the re-entry decision — historically the worst possible time |
| **Failure precursor learning** | **★ HIGH** | Every past incident had observable precursors. Learn the signatures and monitor for them: **forecast failure rather than detect it.** The Trial Registry and postmortem corpus already hold the training data |
| **Dead-man's switch** | **★ HIGH** | Heartbeat absence auto-flattens. Protects against the failure nobody plans for — the system being alive enough to hold positions but not alive enough to manage them. **The most likely catastrophic mode for a solo-operated system** |
| **Runtime temporal-logic monitors** | ◆ REAL | Compile properties like *"never place an order while the risk-gate token is older than N ms"* into runtime monitors over the event stream. Stronger than scattered asserts, and machine-checkable |
| **Differential testing of risk calculations** | **★ HIGH** | Two independent implementations of position and risk maths, continuously cross-checked. Disagreement halts trading. **Cheap paranoia in exactly the place where a silent bug is unrecoverable** |

---

## 8. Structural breaks — the world changes discretely

| Idea | Verdict | Why |
|---|---|---|
| **Bayesian online change-point detection driving automatic re-validation** | **★ HIGH** | Maintain a posterior over "has the regime structurally broken". On a break, **automatically force re-validation** rather than waiting for a drawdown to reveal it. Turns non-stationarity from a post-mortem cause into a monitored variable |
| **Pre-break / post-break model blending by posterior** | ◆ REAL | Do not discard the old model at a break; weight both by the posterior over which world you are in |
| **Break taxonomy** | ◆ REAL | Microstructure change, participant-mix change, regulatory change, liquidity-regime change — different breaks invalidate different things. A fee change kills fee-dependent edges only |

---

## 9. Simulation, honestly evaluated

| Idea | Verdict | Why |
|---|---|---|
| **Measure the sim-to-real gap as a first-class metric** | **★ HIGH** | A market simulator is worthless until you know its error. Track: do strategies that work in sim work live, and by how much do they degrade? **The gap is the metric**, and it is the only thing that makes simulator output usable |
| **Agent-based simulation including your own participation** | ◆ REAL | The only way to test reflexivity and impact before deploying capital. Also the only honest way to test capacity |
| **Generative market models for scenario search** | ◇ SPECULATIVE | Useful for stress-scenario *generation*; **never** for validation — training a strategy on synthetic data validates the generator, not the strategy |
| **Adversarial scenario search** | **★ HIGH** | Do not sample scenarios randomly — **search for the path that breaks the book.** Optimise against the current portfolio. Far higher information per simulation than Monte Carlo |

---

## 10. Population-level intelligence

| Idea | Verdict | Why |
|---|---|---|
| **Independently-seeded system instances, and treat their disagreement as the uncertainty estimate** | **★ HIGH** | A single model's confidence is nearly worthless. **Disagreement between independently-trained systems** — different seeds, different data windows, different feature sets — is a far better uncertainty signal, and it is the same insight that makes the bull/bear split work, applied one level up |
| **Deliberate prior diversity** | ◆ REAL | Seed instances with genuinely different inductive biases, so agreement means something |
| **Consensus as signal, dissent as risk limit** | **★ HIGH** | Size on agreement; **cut size on dissent** rather than picking a winner. Converts model uncertainty directly into position sizing without any extra machinery |

---

## 11. Human attention as a scarce, optimisable resource

Most designs treat the human as an always-available fallback. For a solo operator that is the
binding constraint on the entire system.

| Idea | Verdict | Why |
|---|---|---|
| **Optimise *what* to escalate, not just when** | **★ HIGH** | The operator has minutes per day, not hours. Escalation should be **selected by expected value of human input**, and the policy should be learned from which past escalations actually changed a decision. **An alert that never changes behaviour is negative value** — it consumes the attention budget for the alert that matters |
| **Explanation quality measured by decision improvement** | **★ HIGH** | Do not score explanations on plausibility — score them on whether the human's decision got **better** with them. A fluent explanation that does not improve decisions is actively harmful, because it manufactures confidence |
| **Alert-fatigue metric as a system health indicator** | ◆ REAL | Track acknowledged-and-ignored rates. Rising ignore rate means the system is training its operator to disregard it — a failure of the system, not the human |
| **Attention budget as an explicit constraint** | ◆ REAL | Cap escalations per day; force the ranking problem to be solved rather than deferred |

---

## 12. Hierarchical time-scale control

| Idea | Verdict | Why |
|---|---|---|
| **Slower layers emit *constraint sets*, not suggestions** | **★ HIGH** | Regime/capital (slow) → strategy weights (medium) → execution (fast). The invariant that makes this safe: **a faster layer can never violate a slower layer's constraints, only choose within them.** This is standard nested control, and it gives structural — not procedural — guarantees that a fast-loop bug cannot breach a risk limit |
| **Learning rate matched to layer time-scale** | ◆ REAL | Execution can learn daily; regime models must not. Mismatched adaptation speed is a common and subtle instability |
| **Cross-layer oscillation detection** | ◆ REAL | Layers adapting to each other produce hunting. Detect it; damp it |

---

## The eight that would change the system most

1. **Time-average (ergodic) objective and Bayesian Kelly** (§1) — changes every position size in the system, and it is *correct*, not a preference.
2. **Sealed-envelope metric** (§5) — the only real defence against a self-improving system gaming itself. Costs nothing.
3. **Restricted strategy DSL** (§4) — makes self-modification safe by construction rather than by sandboxing.
4. **Optimal harvest rate and optimal-stopping retirement** (§2) — treats edge as a depleting asset, which it is.
5. **Information ceiling estimation** (§3) — tells you when to stop, which no other tool does.
6. **Degradation ladder + dead-man's switch** (§7) — the difference between a bad day and a terminal one.
7. **Counterfactual shadow portfolios + production ablation** (§5) — the only honest measure of what each component contributes.
8. **Data-poisoning resistance** (§6) — the assumption break that separates market ML from ordinary ML.

---

## What is deliberately not here

- **Anything requiring a model capability that does not exist in 2026.**
- **Anything whose evidence is a self-reported benchmark.**
- **Anything that increases autonomy over capital.** The frontier being explored here is *epistemic
  and structural* sophistication, never expanded authority. Every idea above is compatible with the
  human gate on capital movement staying exactly where it is.

> **The pattern across all three files:** the highest-value ideas are not the ones that make the
> system cleverer when it is right. They are the ones that make it **behave correctly when it is
> wrong, ignorant, being manipulated, or being gamed by itself.**
