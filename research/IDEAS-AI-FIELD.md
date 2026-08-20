# AI FIELD SWEEP — every subfield, at the frontier

Fifth file. The others are organised by *altitude*; this one is organised by **AI subfield**, and
sweeps the whole discipline for what is genuinely useful here.

- `IDEAS-ADVANCED.md` — techniques · `IDEAS-INTELLIGENCE.md` — intelligent behaviour
- `IDEAS-FRONTIER.md` — the objective · `IDEAS-STRATEGIC.md` — the premises
- **this file** — **the field itself, subfield by subfield**

Verdict key: **★ HIGH** · ◆ REAL · ◇ SPECULATIVE · ✕ DECLINED.
Entries marked **NEW** were verified absent from all four earlier files by search.

> **Organising judgement.** Most of AI is irrelevant here, and saying so is the useful part. The
> subfields that matter for this project are the ones that **give guarantees under non-stationarity,
> learn without exploring, or bound behaviour formally.** Everything optimising average-case
> performance on iid data is the wrong tool, however impressive.

---

# PART I — GUARANTEES: learning theory that actually binds

The most underused branch of AI in quantitative finance, because it is unglamorous and hard.

| Idea | Verdict | Why |
|---|---|---|
| **PAC-Bayes generalisation bounds** — NEW | **★ HIGH** | Gives **non-vacuous, finite-sample bounds on out-of-sample loss** from the training set alone. Unlike DSR/PBO — which correct for how *many* things you tried — PAC-Bayes bounds the generalisation gap of the *specific* strategy you selected, and it tightens when the strategy is "simple relative to the prior". **Complementary to the existing validation stack, not a replacement**, and it attacks the problem from a completely different direction: DSR asks "did you get lucky across trials?", PAC-Bayes asks "is this thing complex enough to have memorised?" |
| **Learning theory for dependent data** — NEW | **★ HIGH** | Nearly all generalisation theory assumes iid. **Financial data is not iid, and it is not even close.** There is a real literature on bounds under β-mixing / φ-mixing conditions, where the effective sample size is *far smaller* than the row count. **Estimating the effective sample size is the point**: 5 years of minute bars is not 2.6M independent observations, and every significance calculation that pretends otherwise is wrong by orders of magnitude |
| **Online learning / online convex optimisation with regret bounds** — NEW (deepens existing mention) | **★ HIGH** | **The most philosophically correct framework available for markets.** It assumes **no distribution at all** — data may be chosen adversarially — and still proves bounds on regret against the best fixed strategy in hindsight. No stationarity assumption to be violated, because none was made. Follow-the-Regularised-Leader, online mirror descent, adaptive-regret variants that handle regime change *by construction* |
| **Universal portfolios (Cover)** — NEW | **★ HIGH** | Provable regret against the best constant-rebalanced portfolio **chosen in hindsight**, with no distributional assumption whatsoever. Beautiful, rigorous, and directly implementable. Even as a **benchmark** it is valuable: if a sophisticated strategy cannot beat a universal portfolio's guarantee, that is decisive information |
| **Conformal prediction, adaptive / time-series variants** | **★ HIGH** | Already named in `IDEAS-ADVANCED.md`; restated because it belongs in the **top five of this entire corpus**. Distribution-free, finite-sample coverage guarantees around *any* model — wrap the existing predictor and get intervals that are actually calibrated. **Adaptive conformal (ACI) maintains coverage under distribution shift**, which is precisely the failure mode everything else in this project is fighting. Turns "the model says 0.7" into "an interval with a real guarantee", which is what position sizing actually needs |
| **Rademacher / VC complexity of the strategy class** | ◆ REAL | Bound the capacity of the strategy space being searched. Pairs with MDL (`IDEAS-FRONTIER.md` §3) |

---

# PART II — DECISION-MAKING WHEN YOU CANNOT EXPLORE

The defining constraint of this project: **exploration costs real money and cannot be undone.**
There is an entire subfield built for exactly this, and it is absent from the corpus.

| Idea | Verdict | Why |
|---|---|---|
| **Offline / batch RL** — NEW | **★ HIGH** | Learn a policy **purely from logged data with no online exploration** — literally the trading constraint, formalised. Conservative Q-Learning, Implicit Q-Learning and similar are designed around the core difficulty: **extrapolation error**, where the policy drifts to state-actions absent from the data and confidently hallucinates value there. **That failure mode is the exact mechanism by which a backtested policy blows up live**, which makes this literature directly diagnostic even if you never deploy an RL policy. The pessimism principle — penalise value estimates in low-data regions — is the correct default and generalises far beyond RL |
| **Distributional RL** — NEW | **★ HIGH** | Learn the **full return distribution**, not its mean. Once you have the distribution, you can optimise **CVaR or a quantile** instead of expectation — which is the ergodic/survival objective from `IDEAS-FRONTIER.md` §1 made operational in a learning algorithm |
| **Risk-sensitive RL with CVaR objectives** — NEW | **★ HIGH** | Optimise the tail directly rather than the mean. **The single most natural fit between modern RL and this project's actual objective**, and it sidesteps the usual objection to RL in trading (that it maximises the wrong thing) |
| **Constrained MDPs / safe RL** — NEW | **★ HIGH** | Maximise return **subject to hard constraints** on drawdown, exposure and turnover — constraints as first-class citizens rather than reward penalties. Reward shaping to encode risk limits is fragile and gameable; **constrained formulations are the principled version of the risk gate** |
| **Conservative / safe exploration bandits** | ◆ REAL | Exploration with a guarantee that performance never falls below a baseline by more than a set margin. The right formalism for the curiosity budget (`IDEAS-INTELLIGENCE.md` §4) |
| **Inverse RL / imitation on your own history** | ◇ SPECULATIVE | Recover the implicit objective from past decisions. Mostly useful as a **mirror** — it tells you what you have actually been optimising, which is often not what you believe |
| **Online RL on live markets** | ✕ DECLINED | Exploration means losing money to learn, with no reset button and non-stationary dynamics. Offline RL plus a bounded curiosity budget dominates this |

---

# PART III — FORMAL SAFETY: control theory ∩ AI

Almost entirely missing from the corpus, and it is where the **rigorous** version of a risk gate lives.

| Idea | Verdict | Why |
|---|---|---|
| **Control barrier functions / safety filters** — NEW | **★ HIGH** | A **provable** shield: given a "safe set" (exposure, drawdown, leverage bounds), a CBF-based filter takes *any* proposed action from *any* policy — LLM, RL, human, hand-written — and projects it to the nearest action that **provably keeps the system inside the safe set**. The policy can be arbitrarily untrustworthy; the filter's guarantee is structural. **This is exactly the architecture already chosen** (proposer separate from approver, `IDEAS-INTELLIGENCE.md` §10) — CBFs are the mathematics that turns it from a code review into a theorem |
| **Reachability analysis** — NEW | **★ HIGH** | Compute the set of states reachable within horizon H given the dynamics and action limits. Answers **"can this book reach a margin call in the next hour under any price path in the modelled set?"** — a far stronger statement than a VaR number, because it is a worst-case over paths rather than a quantile over a fitted distribution |
| **Lyapunov-style stability for the allocation loop** | ◆ REAL | Prove the capital-allocation feedback loop cannot oscillate or diverge. Feedback between allocation and performance is a genuine instability source that nobody analyses |
| **Robust / H-infinity control framing** | ◆ REAL | Designed for bounded-but-unknown disturbance — a better match for markets than stochastic-optimal control, which requires a distribution you do not have |
| **Runtime assurance / simplex architecture** | **★ HIGH** | A verified simple controller runs alongside the complex one and **takes over on violation**. Standard in aerospace. Maps perfectly onto the degradation ladder (`IDEAS-FRONTIER.md` §7): the dumb, provable strategy is always warm and ready to assume control |

---

# PART IV — SEQUENCE MODELLING

| Idea | Verdict | Why |
|---|---|---|
| **State space models (S4 / Mamba family)** — NEW as a class | ◆ REAL | Linear-time in sequence length with long effective memory, where attention is quadratic. For **very long market histories at fine resolution** this is the architectural class that makes the context affordable. Judge on evidence, not novelty |
| **Neural CDEs / neural ODEs for irregular sampling** — NEW | **★ HIGH** | Market events arrive at **irregular times**, and the standard fix — resampling to fixed bars — **destroys information and creates artefacts**. Neural CDEs handle irregularly-sampled paths natively, and are the learning counterpart to **path signatures** (rough path theory, `IDEAS-STRATEGIC.md`). Tick data is the natural domain, and this is the mathematically honest treatment of it |
| **Neural point processes / neural Hawkes** — deepens existing | **★ HIGH** | Order arrivals are **self-exciting**: trades beget trades, and clustering is the dominant feature of order flow. A point process **models event times as the object of interest** rather than treating them as a nuisance to be bucketed away. The right primitive for microstructure |
| **Temporal graph networks** — NEW | ◆ REAL | The market is a **time-evolving graph**: assets, venues, participants, and flows between them. Temporal GNNs model structure that changes — cross-asset contagion, venue migration, liquidity fragmentation — which flat feature vectors cannot express |
| **Time-series foundation models as a class** — deepens Kronos | ◆ REAL | Kronos is one of a class — Chronos, TimesFM, Moirai, Lag-Llama, TimeGPT. **Treat the class, not the instance**: they are zero-shot baselines and pretrained encoders, and the honest verdict is that **published gains on financial series are far weaker than on the general forecasting benchmarks they are marketed on.** Use as a **baseline gate** — if your bespoke model cannot beat a zero-shot foundation model, that is the finding |
| **Patch-based / channel-independent transformers** | ◆ REAL | Strong, simple baselines for multivariate forecasting; frequently beat elaborate architectures |

---

# PART V — PROBABILISTIC INFERENCE

| Idea | Verdict | Why |
|---|---|---|
| **Simulation-based inference / neural posterior estimation** — NEW | **★ HIGH** | You will have a market simulator whose likelihood is **intractable** but which you can sample from. SBI infers **posteriors over simulator parameters** from observed data using only simulations — no likelihood required. This is what makes an agent-based market simulator *calibrated* rather than decorative, and it directly closes the sim-to-real loop (`IDEAS-FRONTIER.md` §9) |
| **Amortised inference** | ◆ REAL | Train once, infer in milliseconds thereafter. Turns Bayesian methods from research-only into something usable in a live loop |
| **Nested/sequential Monte Carlo for regime posteriors** | ◆ REAL | Particle filters over latent regime state, updating online. The natural online counterpart to Bayesian change-point detection |
| **Evidential deep learning** | ◆ REAL | Single forward pass yields uncertainty, no ensemble cost. Known to be **poorly calibrated out of distribution** — useful as a cheap screen, never as the risk input |

---

# PART VI — ADAPTATION AND SURGERY

| Idea | Verdict | Why |
|---|---|---|
| **Test-time adaptation / test-time training** — NEW | **★ HIGH** | Adapt the model **at inference** to the current distribution, without labels, using only the incoming inputs. Directly targets regime shift — the model updates to the world it is now in rather than the world it was trained on. **High value and high danger**: an adaptation loop with no supervision can quietly adapt itself into nonsense, so it needs the sealed-envelope metric (`IDEAS-FRONTIER.md` §5) watching it |
| **Machine unlearning** — NEW | **★ HIGH** | **Surgically remove** a learned pattern without full retraining — a dead microstructure regime, a delisted venue's behaviour, a contaminated data window discovered after the fact. The operational counterpart to *active forgetting* (`IDEAS-INTELLIGENCE.md` §3), which currently has no mechanism behind it |
| **Model editing (ROME / MEMIT family)** — NEW | ◇ SPECULATIVE | Targeted modification of specific learned associations. Elegant; brittle in practice; watch |
| **Mixture-of-experts as explicit regime specialisation** — deepens existing | **★ HIGH** | Not for parameter-count scaling — **for interpretability and regime structure.** Experts specialise per regime, and the **gating weights become a readable regime posterior** you can monitor, alarm on, and audit. Gate entropy spiking is a regime-transition signal *for free*. This is a genuinely good structural fit that the usual MoE framing misses entirely |
| **Continual learning without catastrophic forgetting** | ◆ REAL | Already covered in the corpus's continual-learning research; restated as the sibling of unlearning — you need both directions |

---

# PART VII — INTERPRETABILITY AND MODEL SURGERY

| Idea | Verdict | Why |
|---|---|---|
| **Mechanistic interpretability — circuits, superposition, sparse autoencoders, activation patching** — NEW | ◆ REAL | The most active area in AI research and almost absent from finance. SAEs decompose activations into interpretable features; activation patching establishes **causal** roles for internal components rather than correlational attributions like SHAP |
| **Interpretability to detect look-ahead memorisation** — NEW | **★ HIGH** | **The genuinely novel application, and it may be the most valuable idea in this file.** The corpus already flags that LLMs know outcomes inside their training window (`FEATURES.md` §11, "LLM look-ahead guard"), and treats it as an unfixable constraint to route around. Mechanistic interpretability offers an actual **test**: probe whether the model's internals **recognise specific historical dates or events** rather than computing from features. If activations light up distinctively on 2020-03-12 or 2022-11-08, the model is **recalling, not predicting** — and no statistical validation can detect that, because the memorised answer *is* the correct answer on that data. **Turns an assumed contamination into a measurable one** |
| **Probing classifiers on internal representations** | ◆ REAL | Test whether the model internally represents regime, volatility state or venue identity. Cheap, informative |
| **Concept-based explanation over feature attribution** | ◆ REAL | "Because volatility regime shifted" beats a ranked list of 400 feature importances that nobody can act on |

---

# PART VIII — INFORMATION THEORY

| Idea | Verdict | Why |
|---|---|---|
| **Information bottleneck** — NEW | ◆ REAL | Learn representations that are maximally predictive while maximally compressed. **Compression is a principled regulariser against memorisation** — an information-theoretic complement to MDL |
| **Transfer entropy / directed information** — deepens existing | **★ HIGH** | Measures **directional** information flow: does venue A lead venue B, does spot lead perp, does one asset lead another? Model-free, nonlinear, and asymmetric — unlike correlation, which is symmetric and therefore silent on the question you actually care about |
| **Partial information decomposition** | ◇ SPECULATIVE | Splits multi-source information into unique / redundant / synergistic parts. Would answer "is this feature adding anything or duplicating?" precisely. Estimation is hard at realistic dimensionality |

---

# PART IX — LLM AND AGENT FRONTIER

| Idea | Verdict | Why |
|---|---|---|
| **Inference-time compute scaling** — NEW | **★ HIGH** | Spending more compute per decision — sampling, search, verification — buys accuracy **without retraining**. For a low-frequency system this is the **right place to spend**: a decision made a few times a day can afford heavy deliberation, and this is the cheapest available quality lever |
| **Process supervision over outcome supervision** — NEW | **★ HIGH** | Reward the **reasoning steps**, not just the final answer. Outcome supervision in trading is catastrophically noisy — a correct process loses money constantly, and a lucky guess is rewarded. **Directly mirrors "process quality scored separately from outcome"** (`IDEAS-INTELLIGENCE.md` §7), and is the ML formalisation of it |
| **Constrained / structured decoding** — NEW | **★ HIGH** | Force LLM output to conform to a grammar or schema — **guarantees** valid output rather than validating and retrying. The natural enforcement mechanism for the strategy DSL (`IDEAS-FRONTIER.md` §4): the model becomes structurally incapable of emitting an invalid or unsafe program |
| **Self-consistency and verifier models** | ◆ REAL | Sample many reasoning paths, take consensus; or train a verifier that is cheaper than the generator. Disagreement across samples is a usable confidence signal |
| **GraphRAG over the belief graph** | ◆ REAL | Retrieval over an explicit graph rather than flat vectors — the natural fit for the provenance graph in `IDEAS-INTELLIGENCE.md` §1 |
| **Long context vs retrieval** | ◆ REAL | Long context is simpler; retrieval is cheaper and auditable. **Auditability decides it here** — you must be able to say which documents informed a decision |

---

# PART X — AI SAFETY, APPLIED TO A SELF-MODIFYING TRADING SYSTEM

Not abstract. This system will modify itself and control capital.

| Idea | Verdict | Why |
|---|---|---|
| **Specification gaming as the expected default** | **★ HIGH** | Any sufficiently capable optimiser will satisfy the letter of the objective and violate its intent. **Assume it; do not hope against it.** This is the same phenomenon as Goodhart (`IDEAS-FRONTIER.md` §5), stated in its safety form: the sealed-envelope metric is the detector, the CBF safety filter is the containment |
| **Evals as continuous integration** — NEW | **★ HIGH** | A fixed battery the LLM components must pass **before every promotion**: known-injection resistance, look-ahead traps, calibration checks, framing-invariance, refusal-to-answer under insufficient evidence. **Model providers update models underneath you** — without a standing eval suite, a silent upstream change alters trading behaviour with no diff to review |
| **Scalable oversight / debate** — NEW | ◆ REAL | Structured adversarial critique to supervise reasoning a human cannot fully check. The existing bull/bear split is a primitive form; the literature offers better protocols |
| **Weak-to-strong generalisation** — NEW | ◇ SPECULATIVE | Can a weaker supervisor reliably oversee a stronger system? Directly relevant if the system's components outgrow the operator's ability to check them. Open research, worth tracking |
| **Sandbagging / deceptive-alignment concerns** | ◇ SPECULATIVE | Mostly a frontier-lab concern at current capability. Noted so it is not rediscovered as novel later |
| **Capability elicitation before deployment** | ◆ REAL | Actively attempt to make a component fail *before* it holds capital. Red-teaming your own system as a scheduled activity |

---

# PART XI — EFFICIENCY (because cost is in the objective)

Directly serves "cost of operation inside the objective" (`IDEAS-INTELLIGENCE.md` §5).

| Idea | Verdict | Why |
|---|---|---|
| **Quantisation and distillation** — NEW | **★ HIGH** | A distilled small model at a fraction of the cost is often **sufficient** for classification-grade sub-tasks. Most LLM spend in agentic systems goes on tasks a small model handles fine; the frontier model should be reserved for genuine reasoning |
| **Speculative decoding** — NEW | ◆ REAL | Same output distribution, lower latency, via a cheap draft model. Free win where it applies |
| **Aggressive prompt caching** | **★ HIGH** | Already measured on this box: **87% of subagent tokens were cache reads**, and cache economics dominated model-tier choice. Prefer fewer, longer-lived contexts over many cold ones — an architectural decision, not a tuning knob |
| **Router: small model first, escalate on uncertainty** | **★ HIGH** | Cheap model handles the common case, escalates only when uncertain. The same competence-boundary logic from `IDEAS-INTELLIGENCE.md` §2, applied to the AI layer's own cost |

---

# PART XII — SPECULATIVE FRONTIER

Named so they are not rediscovered as novel, with honest verdicts.

| Idea | Verdict | Why |
|---|---|---|
| **Kolmogorov-Arnold Networks** — NEW | ◇ SPECULATIVE | Learnable activation functions on edges; interpretable by construction; claimed data-efficiency. Evidence still thin and mixed. Watch, do not build on |
| **Hyperdimensional computing / vector symbolic architectures** — NEW | ◇ SPECULATIVE | Very high-dimensional distributed representations with algebraic binding. Cheap, robust to noise, composable. Small research community; no strong finance results |
| **Energy-based models** | ◇ SPECULATIVE | Elegant framing for multi-modal distributions; training remains awkward |
| **World models / JEPA-style predictive architectures** | ◇ SPECULATIVE | Learn latent dynamics and plan within them. Compelling in principle; sim-to-real gap (`IDEAS-FRONTIER.md` §9) is the binding constraint |
| **Neural combinatorial optimisation** | ◇ SPECULATIVE | Learn heuristics for execution scheduling. Classical solvers remain hard to beat at this scale |

---

# PART XIII — DECLINED, with reasons

| Idea | Why not |
|---|---|
| Online RL against live markets | Exploration costs real capital, no reset, non-stationary. Offline RL + bounded curiosity budget dominates |
| Deep RL for end-to-end trading | Sample complexity is orders of magnitude beyond available independent data — see effective sample size, Part I |
| Multimodal / vision models on chart images | Charts are a lossy rendering of data you already hold. Reading pixels of your own numbers is strictly worse |
| Federated learning | Solves multi-party privacy; you are one party |
| Neuromorphic / spiking | No path to value at this scale |
| Quantum ML | No demonstrated advantage at these problem sizes; marketing outruns results |
| AGI-adjacent architectures | Not a research lab. Consume outputs, do not chase the frontier |
| Sentiment from general-purpose models | Financial language inverts general polarity — domain-adapted or nothing |

---

## The twelve highest-value across the whole field

Ranked by expected value here, not by research prestige.

1. **Conformal prediction (adaptive)** — distribution-free calibrated intervals under shift. Wraps anything you already have.
2. **Control barrier functions / safety filters** — turns the risk gate from code review into a theorem.
3. **Offline RL's pessimism principle** — even without deploying RL, it names and fixes the exact mechanism of backtest-to-live collapse.
4. **Learning theory for dependent data** — effective sample size. Most significance claims in this domain are wrong by orders of magnitude.
5. **Online learning / universal portfolios** — guarantees with *no* distributional assumption; the honest framework for non-stationarity.
6. **Interpretability to detect look-ahead memorisation** — makes an assumed contamination measurable. Novel.
7. **Risk-sensitive RL with CVaR + constrained MDPs** — optimises the tail, with risk limits as constraints rather than reward hacks.
8. **Simulation-based inference** — the only thing that makes a market simulator calibrated instead of decorative.
9. **Process supervision + evals as CI** — the ML formalisation of judging process over outcome, plus a guard against silent model updates.
10. **Neural CDEs / point processes** — honest treatment of irregularly-timed events instead of destroying information by bucketing.
11. **MoE as regime specialisation** — gate weights become a free, auditable regime posterior.
12. **Router + distillation + caching** — the AI layer must earn its own cost, and this is how.

---

> **The pattern.** Across the whole discipline, the subfields that matter here share one property:
> they **give guarantees without assuming a stable distribution**, or they **bound behaviour
> regardless of how wrong the model is**. Conformal, PAC-Bayes, online learning, CBFs, reachability,
> constrained MDPs, offline-RL pessimism — every one of them is a way of being *safe while
> ignorant*.
>
> That is the same conclusion the other four files reached from different directions, which is
> weak evidence it is the right one.
