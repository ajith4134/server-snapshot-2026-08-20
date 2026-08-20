# ADVANCED CAPABILITY SPACE — AI/ML and adjacent fields

**Companion to `ARCHITECTURE.md` (components) and `FEATURES.md` (capabilities).**
This file is the *frontier*: ideas worth knowing exist, across every relevant field.

**Verdict key:**
**★ HIGH** — strong theory, fits this system, underused. Consider early.
**◆ REAL** — legitimate and used in industry, but costly or later-phase.
**◇ SPECULATIVE** — interesting, thin evidence, treat as research not roadmap.
**✕ DECLINED** — named so it is not rediscovered later; reason given.

> Calibration note: an idea being listed is not a recommendation. Roughly a third of what follows is
> marked SPECULATIVE or DECLINED deliberately — a menu is only useful if it says what not to order.

> **See also `IDEAS-INTELLIGENCE.md`** (added 2026-08-02). This file catalogues *techniques* —
> uncertainty, causality, RL, optimisation. That one catalogues **architecture for behaving
> intelligently**: epistemics and belief decay, competence boundaries and abstention, memory
> consolidation, bounded autonomy in acquiring what it lacks, self-modelling as a market
> participant, adversarial awareness, meta-research over its own trial history, open-ended
> diversity search, self-modification safety, and metacognition over its own LLM components.
> §8 and §13 here are the thin versions of what that file develops properly.

> **Full-field sweep: `IDEAS-AI-FIELD.md`** (added 2026-08-02) — the AI discipline organised by
> **subfield** rather than by altitude, with 30 topics verified absent from every other file:
> PAC-Bayes and learning theory for *dependent* data, online learning and universal portfolios,
> offline / distributional / risk-sensitive RL, control barrier functions and reachability,
> neural CDEs and point processes, simulation-based inference, test-time adaptation, machine
> unlearning, mechanistic interpretability, process supervision, evals-as-CI, and the efficiency
> tier. Read it alongside this file — this one is broad, that one is deep.

---

## 1. Uncertainty quantification — the most underused field here

| Idea | Verdict | Why |
|---|---|---|
| **Conformal prediction** | **★ HIGH** | Distribution-free prediction intervals with *finite-sample coverage guarantees* — no distributional assumptions. Converts a point forecast into a calibrated interval, which feeds **position sizing directly**. Arguably the single highest-value underused technique for this system |
| **Abstention / reject option** | **★ HIGH** | The model is permitted to say "I don't know" and **not trade**. Most trading ML forces a prediction on every bar; the option to decline is nearly free alpha because it removes the lowest-confidence trades, which is where costs dominate |
| Quantile regression / distributional forecasting | **★ HIGH** | Predict the return *distribution*, not a point. Directly compatible with CVaR sizing and drawdown budgeting |
| Model calibration (Platt, isotonic) | **★ HIGH** | A model saying 60% must be right 60% of the time or Kelly-style sizing is nonsense. Cheap to add, routinely skipped |
| Deep ensembles | ◆ REAL | The practical uncertainty baseline; expensive on CPU-first |
| Bayesian neural networks | ◇ SPECULATIVE | Elegant, costly, rarely beats ensembles in practice |
| Evidential deep learning | ◇ SPECULATIVE | Single-pass uncertainty; young literature, known failure modes |

## 2. Causality and distribution shift — the direct attack on non-stationarity

| Idea | Verdict | Why |
|---|---|---|
| **Invariant Risk Minimization (IRM)** | **★ HIGH** | Explicitly learns features whose predictive relationship is **stable across environments**. Treat each volatility regime / year / venue as an environment. This is the most principled published attack on the exact problem that kills trading models |
| **Adversarial validation** | **★ HIGH** | Train a classifier to distinguish train from test. If it succeeds, the distributions differ — a **cheap, decisive leakage and drift detector**. Few lines of code, catches problems nothing else does |
| **Transfer entropy** | ◆ REAL | Information-theoretic, directional lead-lag between assets and venues. Better than correlation for "who moves first" |
| Causal discovery (PC, NOTEARS, Granger) | ◆ REAL | Which features *cause* returns vs merely co-move. Feeds the Mechanism Declaration requirement |
| Counterfactual backtesting | ◆ REAL | "What would have happened had I not traded" — separates market impact from alpha |
| Domain adaptation / DANN | ◇ SPECULATIVE | Regime as domain; thin financial evidence |
| Do-calculus / full SCM | ◇ SPECULATIVE | Requires a causal graph you probably cannot justify |

## 3. Representation learning

| Idea | Verdict | Why |
|---|---|---|
| **Path signatures (rough path theory)** | **★ HIGH** | Signature transform encodes *path-dependent* information — order of events, not just endpoints. Genuine quant technique with real theory; `esig`/`iisignature`. Strong fit for order-flow sequences |
| **Graph neural networks** | ◆ REAL | Assets as nodes, correlation/lead-lag as edges. Natural for cross-sectional crypto structure where everything co-moves with BTC |
| Autoencoder market-state compression | ◆ REAL | Latent regime embedding without hand-labelled regimes |
| Contrastive regime embeddings | ◆ REAL | Learn "these two periods are similar" without labels — feeds case-based reasoning |
| State-space models (S4, Mamba) | ◇ SPECULATIVE | Efficient long sequences; **zero live trading evidence found** |
| Topological data analysis | ◇ SPECULATIVE | Persistent homology on market structure; academically interesting, no durable trading record |
| Wavelets / spectral | ✕ DECLINED | Standard non-causal DWT **leaks future data at window boundaries** — invisible in your own backtest. Only with an explicit causality unit test |

## 4. Learning paradigms

| Idea | Verdict | Why |
|---|---|---|
| **Time-series foundation models** (Chronos, TimesFM, Moirai, TimeGPT) | **★ HIGH** | Pretrained, zero/few-shot forecasting. Use as a **strong baseline your own models must beat** — cheap, and it exposes whether your pipeline adds anything |
| **Kronos — finance-native foundation model** | **★ HIGH** | The one to actually use: first open-source foundation model for **K-lines specifically**, MIT, AAAI 2026, CPU-runnable at 24.7M params. **Zero-shot baseline gate.** Caveats — no cost model anywhere in its repo, and its own train/val/test ranges overlap with no purge/embargo. Full read: `kronos-foundation-model.md` |
| **Multi-task learning** | ◆ REAL | Predict return, volatility, and direction jointly. Shared representation regularises; vol is far more predictable than return and stabilises training |
| **Active learning** | ◆ REAL | Which experiment to run *next* — directly upgrades the meta-model over the ledger from descriptive to prescriptive |
| Self-supervised pretraining (masked/contrastive) | ◆ REAL | Learn from unlabelled market data before touching scarce labels |
| Curriculum learning | ◆ REAL | Easy regimes first, hard later |
| Meta-learning (MAML) | ◇ SPECULATIVE | "Learn to adapt fast to a new regime" — appealing, unproven here |
| Few-shot for new listings | ◇ SPECULATIVE | Genuine need (no history on a new token), weak evidence |
| Continual learning (EWC etc.) | ✕ DECLINED | **EWC specifically struggles on RNNs**; practitioners use walk-forward retraining and regime switching instead |

## 5. Reinforcement learning — bounded use only

| Idea | Verdict | Why |
|---|---|---|
| **RL for execution scheduling only** | ◆ REAL | Direction and size decided elsewhere; RL schedules the slicing. Bounded sub-problem, well-defined reward, low blast radius |
| **Risk-sensitive RL (CVaR objective)** | ◆ REAL | Optimise a tail measure rather than expected return — aligns the objective with survival |
| Offline / batch RL | ◇ SPECULATIVE | Learn from historical logs without live exploration; distribution-shift issues are severe |
| Inverse RL | ◇ SPECULATIVE | Infer other participants' objectives from order flow. Fascinating, speculative |
| Multi-agent market simulation | ◇ SPECULATIVE | See §7 — better framed as stress testing than alpha |
| End-to-end RL for strategy | ✕ DECLINED | Structural mismatch: a single trader has ~zero market impact, so the core RL premise fails. Reward hacking against simulator artefacts is documented and severe |

## 6. Ensembling and meta-learning

| Idea | Verdict | Why |
|---|---|---|
| **Dynamic ensemble selection per regime** | **★ HIGH** | Choose *which* model to trust based on current regime rather than averaging always. Fits the BULL/BEAR + arbiter design exactly |
| **Online learning with expert advice** (Hedge, EXP3) | **★ HIGH** | Regret bounds that hold **without distributional assumptions** — rare and valuable in a non-stationary market. Natural allocator upgrade |
| Mixture of experts with learned gating | ◆ REAL | The honest version of the "node network" idea — but note MoE in LLMs routes *within* one model; routing separate predictive models is a different problem |
| Bayesian model averaging | ◆ REAL | Principled weighting by posterior evidence |
| Stacking / blending | ◆ REAL | Standard, effective, cheap |

## 7. Generative and simulation

| Idea | Verdict | Why |
|---|---|---|
| **Agent-based market simulation for stress testing** | **★ HIGH** | Not for alpha — for **what-if**. "What happens to my book if 30% of liquidity withdraws in 4 minutes." The Oct 2025 cascade is a scenario you should be able to replay against your own positions |
| Block bootstrap / regime-conditional resampling | **★ HIGH** | The cheap, honest way to generate scenarios and drawdown distributions. Prefer over GANs |
| Diffusion models for path generation | ◇ SPECULATIVE | Fashionable; no demonstrated trading edge |
| GANs for synthetic market data | ✕ DECLINED | **No source found claiming a GAN pipeline delivered live edge** over block bootstrap. Real research area, wrong tool for a data-scarcity problem you can solve cheaper |

## 8. LLM and agentic — beyond the Dual-LLM split

| Idea | Verdict | Why |
|---|---|---|
| **LLM parsing exchange announcements and changelogs** | **★ HIGH** | Auto-detect API changes, fee-schedule changes, listing/delisting, maintenance windows. **A pure operations win** — schema changes fail silently, and this is the cheapest defence |
| **LLM as feature proposer, not decider** | **★ HIGH** | Propose candidate features with a stated causal rationale; the Trial Registry counts them like any other trial. Keeps the LLM in representation, out of decisions |
| **Automated postmortem writer** | **★ HIGH** | Every retirement, breaker trip, and anomaly gets a written cause feeding the ledger. Turns incidents into a corpus |
| **LLM-as-judge for Mechanism Declaration** | ◆ REAL | Critique a claimed inefficiency for plausibility before promotion — an adversarial reviewer that never gets tired |
| Retrieval-augmented research memory | ◆ REAL | Vector store over papers, postmortems, prior experiments |
| Multi-agent debate (bull vs bear critique) | ◆ REAL | You already have the shape; making them *argue* before the arbiter is the upgrade |
| Tool-use agent for data exploration | ◆ REAL | Bounded, read-only |
| LLM-authored strategy code | ◇ SPECULATIVE | Sandboxed, gated, never auto-promoted. **AlphaEvolve's own numbers are self-reported and unaudited** |
| LLM as direct trading decider | ✕ DECLINED | **Alpha Arena, real money, Oct–Nov 2025: four of six frontier models lost 30–63% in 17 days.** Causes were over-trading, rigid bias, no stop discipline |

> ⚠️ **LLM look-ahead contamination:** models know outcomes inside their training window. Any
> LLM-derived signal is contaminated on those dates. This is a hard constraint on every row above.

## 9. Optimization

| Idea | Verdict | Why |
|---|---|---|
| **Distributionally Robust Optimization (DRO)** | **★ HIGH** | Optimise against the *worst case within an uncertainty set* rather than a point estimate. Directly addresses "my covariance estimate is wrong" — the exact failure of mean-variance |
| **Multi-objective / Pareto frontier** | **★ HIGH** | Return vs drawdown vs turnover as an explicit frontier rather than a hand-tuned scalar. Makes the tradeoff visible instead of implicit |
| Robust optimization | ◆ REAL | Cheaper cousin of DRO |
| Convex portfolio optimisation (`cvxpy`) | ◆ REAL | Needed for CVaR-minimising allocation |
| Stochastic programming | ◇ SPECULATIVE | Heavy machinery for a handful of strategies |

## 10. Stochastic processes and microstructure math

| Idea | Verdict | Why |
|---|---|---|
| **Hawkes processes** | **★ HIGH** | Self-exciting point processes — order arrivals and **liquidation cascades are literally self-exciting**. The natural mathematical object for the Oct 2025 class of event, and for modelling clustered order flow |
| **Copulas for tail dependence** | **★ HIGH** | Correlation is the wrong tool for crisis co-movement. Copulas model **tail dependence directly** — the mechanism behind correlation breakdown |
| Kalman / particle filters | ◆ REAL | Latent state estimation (fair value, hidden regime) with principled uncertainty |
| Propagator / price-impact models | ◆ REAL | Decaying impact of past trades; informs capacity |
| Queue-reactive models | ◆ REAL | Order-book dynamics conditioned on queue state |
| Avellaneda-Stoikov market making | ◆ REAL | Even though MM is closed to you, the inventory-risk math informs sizing |
| Rough volatility (rough Bergomi) | ◆ REAL | Volatility is rougher than Brownian — matters for options pricing in Phase 6 |
| Hurst exponent / fractal measures | ◇ SPECULATIVE | Popular in retail quant, weak durable evidence |
| Entropy measures (permutation, sample) | ◇ SPECULATIVE | Complexity as a regime feature; thin |

## 11. Interpretability and debugging

| Idea | Verdict | Why |
|---|---|---|
| **SHAP / feature attribution** | **★ HIGH** | Which features drove *this* trade. Feeds Mechanism Declaration and makes decay diagnosable |
| **Influence functions** | ◆ REAL | Which *training samples* drove a prediction — finds label errors and leakage sources |
| Counterfactual explanations | ◆ REAL | "What minimal change flips this signal" |
| Rule extraction / surrogate models | ◆ REAL | Distil a black box into inspectable rules for the audit log |
| Concept activation vectors | ◇ SPECULATIVE | Elegant, mostly vision |

## 12. Systems-level AI

| Idea | Verdict | Why |
|---|---|---|
| **Anomaly detection on own behaviour** | **★ HIGH** | Order rate, cancel ratio, latency, fill patterns. Catches a compromised or runaway bot **from outside**, which the bot cannot do for itself |
| **Predictive feed-failure detection** | ◆ REAL | Degradation signatures often precede outright failure |
| LLM log analysis and triage | ◆ REAL | Ops force multiplier |
| Chaos engineering | ◆ REAL | Deliberately kill the feed, the venue, the process — verify the ladder fires. **Cheap and rarely done** |
| Auto-remediation | ◇ SPECULATIVE | Dangerous near capital; keep humans on the repair path |

## 13. Knowledge and memory

| Idea | Verdict | Why |
|---|---|---|
| **Case-based reasoning over the ledger** | **★ HIGH** | "This regime resembles March 2024 — here is what worked and what died." The ledger becomes queryable experience rather than an archive |
| Knowledge graph of strategies/features/regimes | ◆ REAL | Makes relationships explicit; feeds the meta-model |
| Lessons-learned corpus feeding prompts | ◆ REAL | Compounding memory |

## 14. Explicitly declined, with reasons

| Idea | Why not |
|---|---|
| Quantum / quantum-inspired optimization | No demonstrated advantage on problems of this size; marketing outruns results |
| Neuromorphic computing | No path to value here |
| Federated learning | Solves multi-party privacy; you are one party |
| Blockchain-based anything for internal state | Adds latency and complexity to solve a trust problem you do not have |
| Sentiment from generic (non-domain) models | Financial language inverts general polarity — use a domain-adapted model or nothing |
| 200-indicator technical library | 7,846 rules tested over 100 years; best failed OOS after search-size correction |
| NAS for strategy discovery | Searches network topology, not strategy logic |

---

---

# PART II — Beyond AI/ML

## 15. Pure & applied mathematics

| Idea | Verdict | Why |
|---|---|---|
| **Random Matrix Theory — covariance cleaning** | **★ HIGH** | Marchenko-Pastur separates *signal* eigenvalues from *noise* in an estimated correlation matrix. With few strategies and short history, most of your covariance matrix **is** noise — this is the standard fund-grade fix and directly repairs the input every allocator depends on |
| **Ergodicity economics** (Peters) | **★ HIGH** | Wealth dynamics are **non-ergodic**: the time-average growth of one trajectory ≠ the ensemble average across many. Most finance optimises the ensemble average, which no single account ever experiences. Your prime directive — *compound* — is a **time-average** objective, and this is its formal justification. It is also the deepest reason full Kelly overbets |
| **Optimal transport / Wasserstein distance** | ◆ REAL | A principled distance *between distributions* — better drift detection than KS or PSI, and it degrades gracefully |
| Stochastic calculus (Itô, SDEs) | ◆ REAL | The language of continuous-time price models; required for options in Phase 6 |
| Measure-theoretic probability | ◆ REAL | Filtrations formalise "what was knowable when" — the mathematical statement of your Layer 0 contract |
| Information geometry | ◇ SPECULATIVE | Elegant view of model manifolds; little practical payoff here |
| Ergodic theory (proper) | ◇ SPECULATIVE | Beautiful; the practical content is captured by the row above |

## 16. Statistics & econometrics — the underrated section

| Idea | Verdict | Why |
|---|---|---|
| **Cointegration (Engle-Granger, Johansen)** | **★ HIGH** | The actual statistical foundation of basis and pairs trading. **You are already planning basis trades** — cointegration tests tell you whether the spread is genuinely mean-reverting or you are trading a random walk. Error-correction models give the reversion speed, which sets holding period |
| **Sequential Probability Ratio Test (SPRT)** | **★ HIGH** | Wald's optimal sequential test — *minimum expected samples* to reach a decision at fixed error rates. Precisely the right tool for "is this strategy dead," monitored continuously, without the peeking problem |
| **Survival analysis** (Kaplan-Meier, Cox) | **★ HIGH** | Model **strategy lifetime** and hazard rate directly. Turns "how long do strategies like this usually last" into an estimate rather than a hunch — and censored data is handled natively (strategies still alive) |
| Permutation / randomisation tests | **★ HIGH** | Assumption-free significance. Shuffle labels, recompute, compare. Should be the default sanity check |
| Robust statistics (M-estimators, MAD) | ◆ REAL | Crypto is fat-tailed; means and standard deviations are fragile |
| Hierarchical / partial-pooling models | ◆ REAL | Share strength across correlated assets without pretending they are identical |
| Bootstrap (block, stationary) | ◆ REAL | Already in the plan for drawdown distributions; also the basis of Reality Check / SPA |
| GARCH family, VAR | ◆ REAL | Classical vol and multivariate baselines to beat |
| Regime-switching (Markov-switching) | ◆ REAL | Feature only — never a gate |

## 17. Control theory & operations research

| Idea | Verdict | Why |
|---|---|---|
| **Model Predictive Control (MPC)** | **★ HIGH** | Optimise actions over a receding horizon subject to hard constraints, re-solving each step. The natural formalism for **execution scheduling and inventory management under position limits** — and it handles constraints explicitly rather than by penalty |
| **Queueing theory** | **★ HIGH** | Order queue position determines maker fill probability and adverse selection. Even though market making is closed to you, **queue position governs whether a post-only order fills at all** |
| Inventory control theory | ◆ REAL | Classic newsvendor/base-stock logic maps onto position management with holding costs (funding) |
| Lyapunov stability | ◆ REAL | Prove the feedback loop (signal → position → P&L → sizing) cannot diverge. Rarely done, genuinely reassuring |
| Optimal stopping | ◆ REAL | When to exit — a solved problem class, usually reinvented badly |
| Scheduling / integer programming | ◆ REAL | Rebalance ordering under constraints |
| Adaptive control | ◇ SPECULATIVE | Self-tuning controllers; overlaps online learning |

## 18. Physics, chaos & complexity

| Idea | Verdict | Why |
|---|---|---|
| **Self-organised criticality / percolation** | **★ HIGH** | **Liquidation cascades are a percolation phenomenon** — the system sits near a critical point and a small trigger propagates. This is the physics of the Oct 2025 event ($19.13B liquidated), and it predicts *power-law* cascade sizes, meaning "worst case" has no natural scale |
| **Power-law / heavy-tail estimation** | **★ HIGH** | Crypto returns are heavy-tailed. Fitting the tail exponent tells you whether variance is even finite — if α < 2 it is not, and **every variance-based risk measure silently breaks** |
| Ising / phase-transition models | ◆ REAL | Herding and phase transitions in participant behaviour; econophysics has a real literature |
| Recurrence plots / recurrence quantification | ◆ REAL | Nonlinear structure detection in the "patterns in chaos" spirit of the brief |
| Lyapunov exponents | ◇ SPECULATIVE | Quantifies chaos; hard to estimate reliably on short noisy series |
| Renormalisation group | ◇ SPECULATIVE | Multi-scale structure; conceptually lovely, thin payoff |
| Turbulence analogies | ◇ SPECULATIVE | Volatility cascades resemble energy cascades — mostly metaphor |

## 19. Game theory & market design

| Idea | Verdict | Why |
|---|---|---|
| **Auction theory** | **★ HIGH** | A matching engine **is** an auction. Price-time priority, pro-rata matching, and batch auctions have different equilibrium behaviour — and it determines whether queue position or size wins |
| **Adverse selection / signalling** | **★ HIGH** | Your fills are not random draws: you are disproportionately filled by someone who knows more. This is the formal frame for why passive strategies bleed |
| Stackelberg (leader-follower) | ◆ REAL | Execution against a reactive opponent |
| Mechanism design | ◆ REAL | Why venues choose their fee and matching rules — predicts rule changes |
| Evolutionary game theory | ◇ SPECULATIVE | Strategy populations competing; explains crowding qualitatively |

## 20. Information theory

| Idea | Verdict | Why |
|---|---|---|
| **Mutual information for feature selection** | **★ HIGH** | Captures *nonlinear* dependence that correlation misses; a better filter than linear screens |
| **Minimum Description Length (MDL)** | ◆ REAL | Model selection as compression — an independent principle to cross-check deflated Sharpe |
| Channel capacity as an edge bound | ◇ SPECULATIVE | Elegant framing: how much information can a signal carry about future returns |
| Kolmogorov complexity | ◇ SPECULATIVE | Uncomputable; useful only as intuition |

## 21. Distributed systems & software engineering

| Idea | Verdict | Why |
|---|---|---|
| **Event sourcing** | **★ HIGH** | State as an immutable append-only event log; current state is a fold over events. Your order-intent WAL **generalises to this** — and it gives perfect audit, time-travel debugging, and replay-based recovery for free |
| **Property-based testing** (Hypothesis) | **★ HIGH** | Generate thousands of cases against invariants — "no fill sequence ever produces negative inventory," "no purge config ever leaks a future label." **The right way to test a validation harness**, since example-based tests miss exactly the edge cases that matter |
| **Exactly-once / idempotency semantics** | **★ HIGH** | Already planned; the formal literature says how to do it correctly across retries and restarts |
| Saga pattern / compensating transactions | ◆ REAL | Multi-leg trades (basis: spot + perp) that must unwind cleanly if one leg fails — **directly relevant to your first strategy family** |
| CQRS | ◆ REAL | Separate the write path (orders) from the read path (analytics) |
| Formal verification / TLA+ | ◆ REAL | Specify the promotion state machine and check it exhaustively. High effort, and this is exactly the class of bug that reactivates a retired strategy |
| Mutation testing | ◆ REAL | Tests your tests |
| Fuzzing exchange responses | ◆ REAL | Malformed/hostile API responses are a real failure mode |
| Vector clocks / CRDTs | ✕ DECLINED | Solves multi-writer conflict resolution you do not have |

## 22. Cryptography & custody

| Idea | Verdict | Why |
|---|---|---|
| **Threshold signatures / MPC wallets** | **★ HIGH** | Split treasury signing so no single key compromise moves funds — and **no single detained key-holder freezes them either** (OKEx froze withdrawals 5.5 weeks for exactly that reason) |
| Hardware wallet / HSM for treasury | **★ HIGH** | Cold keys never touch the trading host |
| Deterministic sub-account derivation | ◆ REAL | Per-venue, per-strategy isolation from one seed |
| Zero-knowledge proofs | ◇ SPECULATIVE | Prove solvency or strategy properties without revealing them — real tech, no need yet |

## 23. Hardware & low-level systems

| Idea | Verdict | Why |
|---|---|---|
| CPU pinning, NUMA awareness, huge pages | ◆ REAL | Removes jitter. Matters at tens of ms, cheap to do |
| Lock-free / wait-free data structures | ◆ REAL | Deterministic latency in the hot path |
| SIMD / vectorisation | ◆ REAL | CPU-first design makes this the main speed lever |
| `io_uring`, memory-mapped IO | ◆ REAL | Efficient ingestion of large tick archives |
| Kernel bypass (DPDK, Solarflare) | ✕ DECLINED | Only pays off colocated; your floor is ~8ms of network |
| FPGA / ASIC | ✕ DECLINED | Latency-arb hardware for races you cannot enter |

## 24. Legal, tax & business continuity

| Idea | Verdict | Why |
|---|---|---|
| **Tax-lot accounting from day one** | **★ HIGH** | FIFO/LIFO/specific-identification decisions must be made *before* trading — reconstructing lots afterward across venues is genuinely painful, and in some jurisdictions the method is irrevocable once chosen |
| **Jurisdiction & venue eligibility** | **★ HIGH** | Which venues are lawful for you, and KYC-tier limits that cap withdrawals — a constraint that can invalidate a venue choice after integration |
| Entity structure | ◆ REAL | Affects tax treatment, exchange account type, and liability |
| Business continuity / succession | ◆ REAL | An autonomous system holding capital needs a documented "if the operator is unavailable" path |
| Insurance | ◇ SPECULATIVE | Crypto trading coverage is thin and expensive at this size |

## 25. Biology-inspired

| Idea | Verdict | Why |
|---|---|---|
| **Artificial immune systems for anomaly detection** | ◆ REAL | Self/non-self discrimination is a genuinely good framing for "is my system behaving like itself" |
| Evolutionary / genetic algorithms | ◆ REAL | Covered under discovery — with the multiple-testing caveat attached |
| Swarm / ant-colony optimisation | ◇ SPECULATIVE | Rarely beats modern optimisers |
| Neuroevolution | ◇ SPECULATIVE | Compounds the search-integrity problem |

## The twelve to consider first

Ranked by (value × fit × how unlikely you are to have it on the list already):

1. **Conformal prediction** — calibrated intervals → sizing
2. **Invariant Risk Minimization** — features stable across regimes
3. **Adversarial validation** — cheap, decisive leakage/shift detector
4. **Abstention / reject option** — permission not to trade
5. **Hawkes processes** — self-exciting flow and cascades
6. **Copulas for tail dependence** — the correct crisis-correlation tool
7. **Time-series foundation models as a baseline** — makes "does my pipeline add value" answerable
8. **LLM parsing exchange announcements** — pure ops win, silent-failure defence
9. **Agent-based simulation for stress testing** — replay Oct 2025 against your own book
10. **Path signatures** — path-dependent features with real theory
11. **Distributionally Robust Optimization** — hedges the estimate, not just the outcome
12. **Anomaly detection on own behaviour** — external check on a runaway autonomous system

**Common thread:** ten of the twelve are about **knowing what you do not know** — calibrated
uncertainty, distribution-shift detection, tail dependence, worst-case optimisation, self-monitoring.
That is the opposite emphasis from "more models, more nodes," and it is where the research says the
durable advantage actually lives for an autonomous system.

## And ten more from outside AI/ML

Ranked the same way — value × fit × unlikely-to-be-on-your-list:

1. **Random Matrix Theory covariance cleaning** — most of your correlation matrix is noise; this
   separates it. Fixes the input every allocator depends on
2. **Ergodicity economics** — the formal reason a compounding objective is a *time-average* problem,
   and the deepest justification for fractional Kelly
3. **Cointegration / Johansen** — whether your basis spread actually mean-reverts, and how fast
4. **Sequential Probability Ratio Test** — optimal continuous "is it dead yet" testing
5. **Survival analysis** — strategy lifetime and hazard rates as estimates, not hunches
6. **Event sourcing** — your WAL generalised: perfect audit, replay recovery, time-travel debugging
7. **Property-based testing** — the only sane way to test a validation harness
8. **Self-organised criticality / percolation** — the physics of liquidation cascades, and why
   "worst case" has no natural scale
9. **Power-law tail estimation** — if α < 2 the variance is infinite and every variance-based risk
   measure silently breaks
10. **Model Predictive Control** — execution under hard constraints, re-solved each step

**Two that are cheap and would be embarrassing to skip:** tax-lot accounting decided before the
first trade, and the saga pattern for multi-leg basis trades — because a spot+perp trade where one
leg fills and the other does not is a naked directional position, arriving silently.
