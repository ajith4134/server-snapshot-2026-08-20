# ADVANCED, INTELLIGENT CODE — what we settled, and what the evidence actually says

**Status:** the consolidated record of the 2026-08-08 discussion and the research it produced.
**Purpose:** so this is never re-derived, re-argued, or restated by the user again.

This is a **summary of sources, not a new set of rules.** Every claim here traces to a file on this
box. Where the evidence is thin, contested, or unverified, it says so rather than rounding up.

**Primary sources, all local:**

| File | What it holds |
|---|---|
| `IDEAS-INTELLIGENCE.md` | The corpus's own answer — 12 capability areas, ~60 ideas, verdicts, and the master test |
| `learned-vs-hardcoded-boundary.md` | 24 claims. Where knowledge lives, continual learning, meta-learning, the SEC precedent, 10 reviewer tests |
| `reasoning-vs-learning.md` | ~45 claims, 17 UNVERIFIED preserved. Pearl's ladder, world models, the negative record on LLM reasoning, 9 tests |
| `what-makes-code-deep.md` | ~45 claims. Ousterhout, Parnas, Brooks, six empirical studies on generated code, 8 tests, and the traps |
| `strategies-as-evolved-programs.md` | ~40 claims. FunSearch through ShinkaEvolve, six finance systems, DSL restriction, quality-diversity, the failure record |
| `IDEAS-ADVANCED.md`, `IDEAS-AI-FIELD.md`, `IDEAS-FRONTIER.md`, `IDEAS-STRATEGIC.md` | The wider capability catalogue these sit inside |

The binding version lives in **goal doc §1a**. This file is the evidence behind it.

---

## 0. What was actually asked for

> *"I need the bots to have real intelligence, real AI in the code — not some hardcoded values or
> instructions."*

then, sharpening it:

> *"Not only learning but also real intelligence."*

**That second message is the important one.** Learning and reasoning are different capabilities and
the corpus already separates them: `IDEAS-ADVANCED.md` catalogues *techniques*, while
`IDEAS-INTELLIGENCE.md` catalogues *"architecture for behaving intelligently — what separates a
system that adapts from a script that executes."* Two files, on purpose.

A model that retrains hourly **learns**. It fits whatever correlation is in front of it, faster. It
does not **reason** — it forms no hypothesis about mechanism, holds no belief it could revise, and
cannot tell you when it is out of its depth.

---

## 1. The honest boundary — stated first, because everything else depends on it

`IDEAS-INTELLIGENCE.md` §0 opens with it, and it should never be softened:

> No architecture available in 2026 produces understanding. LLMs do not know things; they produce
> text conditioned on text. Anything promising "real intelligence" from a model swap is selling
> something.

The empirical answer to that hope, from the same file: **Alpha Arena — six frontier models, $10k
each, autonomous, Hyperliquid perps, on-chain verifiable. 17 days.** Qwen3-Max +22.32%, DeepSeek
+4.89%, Claude Sonnet 4.5 −30.81%, Grok 4 −45.3%, Gemini 2.5 Pro −56.71%, GPT-5 −62.66%. The causes
were mundane: over-trading into fees, rigid directional bias, no stop discipline. **Absent risk
rails, not exotic failure.**

**But the distance between a script and an adapting system is real, and it is crossable.** What
crosses it, per §0, is not a smarter model:

1. Beliefs that carry provenance and expire — instead of facts hardcoded at build time.
2. Calibrated knowledge of its own competence — instead of always producing an answer.
3. Learning from its own history as data — instead of only from market data.
4. Self-directed acquisition of what it lacks — instead of consuming only what it was fed.
5. Modelling itself as a participant — instead of assuming it acts on the world for free.

> Every one of those is buildable with boring engineering. None requires a breakthrough. **That is
> the actual opportunity**, and it is almost universally skipped because it is unglamorous.

**The failure mode to design against is not stupidity. It is confident staleness** — a system that
learned something true, never noticed it stopped being true, and keeps betting on it.

---

## 2. The learning axis — where the evidence lands

### 2.1 Hardcoded structure is not the problem, and cannot be eliminated

Mitchell (1980, CBM-TR-117, Rutgers) proves a generalizer with **no** bias beyond consistency with
training data *cannot outperform rote memorisation*. Bias is "any basis for choosing one
generalization over another, other than strict consistency with the observed training instances."
Wolpert & Macready's No Free Lunch theorems (1997) formalise it further: averaged over all problems,
no algorithm beats any other — "any elevated performance over one class of problems is exactly paid
for in performance over another class."

> **Asking for a system with no built-in assumptions is asking for something that provably cannot
> generalise at all.** The question is never "does it have hardcoded structure." It is: **does the
> *fitted* part move in response to data, and is the *fixed* part disclosed as fixed.**

Parametric vs non-parametric is a different axis and is not the distinction: it is about whether
capacity is bounded a priori. Both learn. What matters is whether the parameter **values** came from
an optimisation against a loss, or from a person's judgment.

### 2.2 The crux, stated precisely

> A weight is a hardcoded constant with extra steps when it was never actually subjected to an
> optimisation process, **or when the process that set it is not reproducible or inspectable.**

Nothing distinguishes learned from hardcoded by *appearance* — a stored float looks identical either
way. The evidence is procedural: is there a loss function, a dataset it was computed against, and a
re-runnable fitting procedure that would produce a *different* value on different data?

`self.weight = 0.73` with no `fit()` anywhere that could have produced it is a hardcoded constant,
**whatever the variable is named.**

Sutton's *Bitter Lesson* (2019) is the field's own critique of this at design level: "AI researchers
have often tried to build knowledge into their agents; this always helps in the short term… but in
the long run it plateaus and even inhibits further progress." A hand-tuned indicator threshold that
works in a backtest is exactly that — legitimate as a starting point, not learning.

### 2.3 Continual learning is harder than it sounds, and naive online updating is its own failure

**Catastrophic forgetting.** McCloskey & Cohen (1989) trained a backprop network sequentially and
found new learning destroyed the old — near-zero accuracy after a *single* new training trial, far
worse than human retroactive interference. Their conclusion still holds: "at least some interference
will occur whenever new learning alters the weights involved in representing old learning."

**Consequence, directly:** a system that updates weights on every trade outcome, with no
countermeasure, **will silently degrade on patterns it used to handle.** Learning is not
automatically an improvement over static behaviour.

**Stability–plasticity.** Grossberg: "How do we learn things quickly but remember them for a long
time? Why does a fast-learning rate not force a fast-forgetting rate?" He names the algorithms that
fail it by default — competitive learning, SOMs, backpropagation, simulated annealing, neocognitron,
SVM, regularisation, and Bayesian models.

**EWC, and the correction it needed.** Kirkpatrick et al. (2017, *PNAS* 114:3521) slow learning on
weights the Fisher information identifies as important to prior tasks. It works on sequential Atari.
**But** Huszár (2018, *PNAS* comment) showed the original penalty is applied inconsistently beyond
two tasks, causing "an unwanted sensitivity to task ordering." *Even a PNAS-vetted "solves
catastrophic forgetting" claim needed a published correction once others checked the maths.*

**The mechanical test that separates the two things people call "learning."** River's architecture
(`learn_one` / `predict_one`): "An online model is therefore a stateful, dynamic object. It keeps
learning and doesn't have to revisit past data."

> In a genuinely continual system, the **update step is in the same runtime loop as the prediction
> step**, invoked automatically on every observation, with no human deciding when to retrain.
>
> A human running `train.py` on a cron job and redeploying a frozen model file is doing **periodic
> retraining** — legitimate, but a different claim, and it inherits every multiple-testing risk in
> §2.5.

**Why this bites in markets specifically.** Gama et al. (*ACM Computing Surveys*, 2014) define
concept drift formally. Suárez-Cetrulo et al.: "The succession of manias, panics and crashes have
stressed the non-stationary nature and the likelihood of drastic structural or concept changes in
the markets. Traditional systems are unable or slow to adapt." And naive online learning trades
staleness for forgetting — fine-tuning only on the recent window catastrophically forgets recurring
historical regimes. A system claiming to solve both needs a mechanism a reviewer can point at: a
concept history, a replay buffer, or an EWC-style penalty.

### 2.4 The single best illustration — a celebrated "learns to learn" result that mostly did not

MAML (Finn et al., 2017) is the reference algorithm for learning to learn. Raghu, Raghu, Bengio &
Vinyals (2019, ICLR 2020) asked whether its success comes from **rapid learning** or **feature
reuse**, by freezing the network body during the inner loop at test time.

> **"Even when freezing all layers in the network body, performance hardly changes… feature reuse is
> the dominant factor."**

They went further: a version with **no inner loop at all** — nearest-neighbour cosine similarity on
frozen features — "performs comparably to MAML."

**This is the user's exact question, answered empirically.** A celebrated adaptive algorithm, checked
with a freezing ablation, turned out to be doing almost no adaptation at inference. The learning was
front-loaded into a fixed feature extractor; what looked like fast on-the-fly learning was mostly
lookup against a frozen representation.

**And the direct trading analogue.** arXiv:2604.10996 (single-author preprint, flagged UNVERIFIED)
describes a pipeline where an LLM prompt is optimised against Information Coefficient, then "frozen
as `v4-stable-core`… used for all subsequent extraction." The prompt *was* genuinely fit. At
deployment it is a fixed string — indistinguishable in the running system from a hand-typed
constant. Its own finding: during a macroeconomic shock, the frozen features **add noise and
underperform a price-only baseline.**

> **Optimisation history does not transfer to deployment-time adaptivity.** A component can be
> legitimately learned and still behave, once deployed, exactly like a hardcoded value — because
> nothing in the runtime path updates it.

### 2.5 Four documented ways a system can be "learning" and still be worthless or dangerous

**AI washing is a fined offence, in this exact industry.** SEC press release 2024-36, 2024-03-18:
settled charges against **Delphia (USA) Inc.** and **Global Predictions Inc.** for false statements
about their use of AI; $400,000 combined. Delphia claimed it "deployed machine learning to analyze
the collective data shared by its members." The SEC found it did not have those capabilities — and
had **already admitted internally in 2021** that it had never built an algorithm using client data
for investment decisions, then continued the claims for two more years.

**Backtest overfitting is the quant version of fitting noise, and it applies whether or not you call
it machine learning.** Bailey & López de Prado: given enough configurations against one history,
some will show a significant-looking Sharpe by chance — "nearly guaranteed, not a tail risk." López
de Prado (2019) on the field's practice: "practically all papers in empirical finance fail to
disclose the number of trials involved."

> An "adaptive" strategy whose adaptivity is periodic re-optimisation against a rolling backtest
> window **is not learning — it is repeated overfitting**, and every re-optimisation is a trial.

**Specification gaming is common, not exotic.** Krakovna et al. (2020) catalogue ~60 real cases — the
boat-racing agent that "goes in circles" hitting reward pickups instead of finishing. Their
diagnosis transfers directly: a profit-maximising agent whose weights genuinely move can still learn
to exploit a simulator quirk or a microstructure artifact absent live. **Learning that games its
specification is still learning — a different and more dangerous failure than hardcoding.**

**Shortcut learning means a good backtest is not evidence of transferable learning.** Geirhos et al.
(2020, *Nature Machine Intelligence*): shortcuts are "decision rules that perform well on standard
benchmarks but fail to transfer to more challenging testing conditions." **Good backtest performance
is exactly the evidence a shortcut-learner would also produce.** Converges with MetaTrader
(AAAI/arXiv:2505.12759): offline RL trading agents "merely 'memorize' the optimal… actions from the
offline data while neglecting the non-stationary nature of the financial market."

**And how claims get inflated in writing.** Lipton & Steinhardt (2018) name four patterns; the one
that matters for code review is **failure to identify the sources of empirical gains** — "authors
propose many tweaks absent proper ablation studies, obscuring the source of empirical gains."
*A system with five "adaptive" components evaluated only as a bundle cannot support the claim that
all five are learning something real.*

---

## 3. The reasoning axis

### 3.1 Prediction cannot answer "what happens if I act"

Pearl's ladder — association, intervention, counterfactual. A purely predictive model lives on rung
one. Causal discovery from observational data is underdetermined (Markov equivalence); NOTEARS-style
methods have a documented varsortability failure. DoWhy's contribution is **refutation semantics**:
placebo treatment, random common cause, data subset. Passing all three is *necessary, not
sufficient* — **but failing any one is a hard, mechanical disqualifier**, and cheap to run.

### 3.2 World models buy planning, and punish overconfidence in themselves

Model-based RL lets a system plan inside a learned model rather than react. The documented failure
mode is the planner exploiting the model's flaws.

> **MBPO's own theoretical bound implies the optimal rollout length into an uncalibrated model is
> zero.** And Lambert et al. recorded a **45% real-world reward collapse (176 → 98)** from a model
> whose own training-loss metric never signalled a problem.

**"Still accurate by its own metric" is precisely the state pattern-completion hides in.** Hence the
sharpest test found in the whole sweep: does planning depth *shrink as measured model error grows*,
or is lookahead a fixed hyperparameter?

### 3.3 The negative record on LLM "reasoning" — with numbers

This section is mandatory reading before trusting any LLM component:

- **Self-correction without ground truth degrades performance.** "LLMs Cannot Self-Correct Reasoning
  Yet" (ICLR 2024) — one documented collapse from **75.8% → 38.1%**.
- **LLM-as-judge position bias.** Claude-v1 flipped its judgment on answer order **76%** of the time;
  GPT-4 **30%** — on a task with no principled reason to depend on order.
- **Multi-agent debate does not reliably beat the cheap baseline.** An ICML 2024 replication (Smit et
  al.) found debate does not beat a single agent with self-consistency resampling at matched compute,
  and an assigned adversarial "devil" persona made it *worse*.
- Chain-of-thought unfaithfulness: stated reasoning need not be the reasoning that produced the
  answer.

This is why `DECISIONS.md` §7 already records two corrections against earlier advice: **no
multi-agent committee**, and **the red-team agent is not a judge** — it generates testable
hypotheses; running the test settles them.

### 3.4 Metacognition with actual guarantees

Conformal prediction gives coverage guarantees under exchangeability; selective prediction has SGR
bounds. Verbalised LLM confidence is measurably overconfident and **RLHF degrades it further**.

> A system whose "I'm not sure" is a string the model learned to emit, with no calibration harness
> behind it, fails — **however appropriately humble it sounds.**

---

## 4. The depth axis — "depth" is a definition, not a compliment

### 4.1 The definition

Ousterhout, *A Philosophy of Software Design*: **"the best modules are those whose interfaces are
much simpler than their implementations,"** and **"It is more important for a module to have a
simple interface than a simple implementation."**

Depth is a ratio: functionality provided ÷ what a caller must learn to use it. It traces to Parnas
(1972): a good module hides a **design decision**, not a line count — and his own worked example of
the *wrong* decomposition was by flowchart, i.e. by execution order.

Brooks (1986) separates **essential** complexity (inherent to the problem) from **accidental**
(imposed by tools and notation). **Depth is specifically the discipline of absorbing essential
complexity into a module instead of leaking it into every caller.**

The failure mode has a name: **classitis** — many small classes each exposing nearly as much
interface as implementation.

### 4.2 What the measurements say about generated code

Uneven in rigour, and the report is explicit about which is which:

- **GitClear 2024/2025** — large-N but observational, not peer-reviewed, and the report flags a
  possible conflict of interest: less "moved" (refactored/reused) code, more copy-paste duplication.
- **An academic code-smell study** independently replicates the duplication finding.
- **Pearce et al. 2021/2022 ("Asleep at the Keyboard?")** and **Perry et al. (Stanford, ACM CCS
  2023)** — peer-reviewed, modest-N: a well-replicated tendency to produce vulnerable code, with
  **high user confidence in it.**
- **METR 2025** — small-N but genuinely causal RCT: AI-assisted work is *slower* for experienced
  developers on codebases they know well.

**The honest gap, kept rather than filled:** *no published study measures module depth in
LLM-generated code directly.* The theory predicts shallowness; duplication and smell counts are
consistent with it; nobody has measured the thing itself.

**And the METR result is commonly over-read.** It measured task completion time, not code depth. Cite
it for "AI-assisted work is slower in depth-sensitive environments," **not** for "AI code is
shallow" — that second claim needs the duplication and security evidence instead.

### 4.3 The eight tests

All countable, none requiring taste.

| # | Test | Fires when |
|---|---|---|
| 1 | **Interface-to-implementation ratio** | Ratio near 1:1 — the interface *is* almost the whole thing |
| 2 | **Concept count at the call site** | Concepts a caller must hold rise with no rise in functionality |
| 3 | **Pass-through count** | A method whose body is only a call to another with a near-identical signature |
| 4 | **Information leakage** | The same design decision, magic constant or business rule encoded in two modules |
| 5 | **Error paths vs happy paths** | The module re-throws everything — the caller inherits the full failure surface |
| 6 | **Leak blast radius** | An internal change forces every call site to change |
| 7 | **General vs special purpose** | A parameter exists only to let one caller bypass the module's own logic |
| 8 | **Temporal decomposition** | Module boundaries narrate "first this, then this" instead of "this owns this fact" |

**Test 1 is the one to run if only one can be** — Ousterhout states it as the defining criterion
rather than a symptom, and it is the only one applicable from the module's own source without
reading call sites.

### 4.4 The traps, which matter as much as the tests

- **A god object can fake Test 1.** Huge implementation, small-looking surface. The distinguishing
  question is **coherence of the design decisions hidden** — is every part of the implementation in
  service of the same interface promise? Riel's heuristic: *"Be very suspicious of an abstraction
  whose name contains Driver, Manager, System, or Subsystem."*
- **Premature abstraction is the mirror image.** Depth is discovered by generalising from *real,
  current* needs. An interface built for functionality that does not exist yet is depth borrowed
  against a future that may not arrive, and Test 2 fires today for a speculative payoff.
- **"Smaller is deeper" is a live disagreement, not settled.** Ousterhout on *Clean Code*'s
  8-method `PrimeGenerator`: *"code is chopped up so much… These methods are shallow and entangled."*
  Martin, quoted in the same document for balance: *"I think you and I are just going to disagree on
  this."* Cited as evidence the idea is contested, not that either side simply wins.
- **Depth can be asserted post-hoc.** No test certifies depth in the abstract — every one of the
  eight needs a real call site, a real failure mode, or a real second module. *A design claim that
  has not been checked is not a result.*

---

## 5. Strategies as evolved programs — the mechanism for "no hardcoded alpha logic"

If no alpha logic may be hardcoded, the concrete mechanism is a system that **writes and selects
strategy code** rather than tuning parameters in code you wrote. Here is what the record supports.

### 5.1 Peer review is uneven, and the most relevant system has none

| System | Review status |
|---|---|
| **FunSearch** | ***Nature* 625, 468–475** — the only genuinely high-bar review in the set |
| ADAS, Eureka, STOP, EvoPrompt, ShinkaEvolve | Real but lower-rigour ML-conference review (ICLR/COLM) |
| **AlphaEvolve** | **No peer review at all.** Self-published corporate white paper (arXiv:2506.13131), code not released. Corroborated by one third-party GitHub issue on one sub-result |

**AlphaEvolve is the system architecturally closest to "evolve a full trading strategy" — and it sits
in the unreviewed tier.**

### 5.2 Every finance system evolves factors, not strategies

Six surveyed — QuantaAlpha, FactorMiner, CogAlpha (ACL 2026), AlphaAgentEvo (ICLR 2026), XAlpha,
AlphaAgent (KDD 2025). **All six evolve alpha formulas only.** Portfolio construction, position
sizing and risk logic are a fixed, hand-written downstream layer in every case.

> That is a direct scope gap against "all signals, weights and regimes must be learned." None of
> these systems learn the weighting or regime layer. **They learn the signal layer and bolt it onto
> hardcoded portfolio logic.**

### 5.3 The one number they all omit

**Five of six do not report the total number of candidates generated and evaluated.** For
AlphaAgentEvo, **an ICLR reviewer asked for that number on the public record and it went
unanswered.**

That is the exact number multiple-testing correction requires. Three independent frameworks agree,
and all move the same direction:

- **Deflated Sharpe Ratio** (Bailey & López de Prado 2014). Worked example: SR 2.5 from N=100 trials
  → **DSR 0.9004, rejected**. The same result from N=46 would have passed. *Significance is a
  function of how many trials preceded it.*
- **Bonferroni / Holm / BHY** (Harvey, Liu & Zhu, *RFS* 2016), over 316 published factors:
  t=2.0 needs M=1 · t=3.0 needs M=19 · t=4.0 needs M=789 · t=5.0 needs M=87,214 · t=6.0 needs
  M=25,340,000. Recommended minimum t-ratio: **3.0**, rising to **3.18–3.78** once hidden trials are
  modelled.
- **PBO / CSCV** (Bailey, Borwein, López de Prado & Zhu 2015). 8,800 configurations against a **pure
  random walk**: in-sample SR 1.27 looks strong; CSCV flags **PBO 55%**, with 53% of out-of-sample
  Sharpes negative.

**The bar rises — never falls — as trials grow. None of the six finance papers applies any of these
corrections.**

### 5.4 The archive clause

Quality-diversity search (MAP-Elites) keeps strategies that are good **and behaviourally different**.
`IDEAS-INTELLIGENCE.md` §9 already rates it ★ HIGH, because correlation is what kills portfolios.

> **A diverse archive buys no discount on multiple testing. The correction keys on candidates
> *evaluated*, never candidates *retained*.**

A QD archive is, if anything, the *opposite* failure mode from the one these frameworks were built to
catch — it makes more of the true trial count visible, since nothing is discarded as "not the
winner." But it does not shrink the true count.

The closest published work is **MadEvolve/QuantEvolve** (arXiv:2605.23007), a MAP-Elites search over
trading strategies with a section explicitly asking *"are we doing research, or are we p-hacking?"*
It was found only because two research legs were cross-checked against each other — a reminder that
"no paper found" from a single search pass is provisional.

### 5.5 The failure record for evolved trading rules

Allen & Karjalainen (*Journal of Financial Economics* 51:245–271, 1999), S&P 500 daily 1929–1995,
10 out-of-sample splits: **"After transaction costs, the rules do not earn consistent excess returns
over a simple buy-and-hold strategy in the out-of-sample test periods."** Average out-of-sample
excess return at 0.25% costs: **−2.05%/year**, only 17 of 89 rules positive.

The exceptions are instructive too. Neely, Weller & Dittmar (1997) found GP-discovered FX rules
profitable 1981–1995 — and the same group later reversed it: *"As the profitability of those simple
rules became widely publicized in the academic literature, the profitability of the rules
disappeared."* Kozhan & Salmon: a GP GBP/USD strategy profitable in 2003, gone by 2008, attributed to
crowding.

**The shape across two decades: apparent GP edges are real often enough to publish, then decay once
genuinely new data arrives or the pattern becomes known.**

### 5.6 On restricting the search space

Grammar/DSL restriction (McKay et al., *GPEM* 11:365–396) *"reduce[s] the search cost to the minimum
necessary to find a solution, but it comes with the concomitant risk that the solution may not be
within the search space defined by the grammar."* Empirically, Ren, Qin & Li: random-sampling 10,000
GP alphas from an *unconstrained* space found **fewer than 3% effective** (IC > 0.03).

Theoretically it also *"reduces the VC dimensionality of the corresponding solution."* But this is
**not settled** — Tuite et al. cite Domingos' counter-position that "overfitting is an unwanted
side-effect not of complexity" per se.

AlphaEvolve's stated reason for skipping a DSL: classical GP's *"use of handwritten evolution
operators… can be hard to design and may fail to capture important properties of the domain."* In
effect, betting an LLM's priors constrain the effective search space better than an explicit grammar,
without hard-excluding solutions the grammar designer did not anticipate.

---

## 6. The master test

From `IDEAS-INTELLIGENCE.md`, and it governs everything above:

> # Does it change what the system does when it is wrong?

> Features that only improve behaviour when the system is already right are decoration. Every entry
> marked ★ HIGH changes behaviour under error — by refusing to act, by expiring a belief, by
> catching a contradiction, by rolling back, or by noticing that the world moved.

---

## 7. The ten to build first

`IDEAS-INTELLIGENCE.md`'s own ordering, by leverage per unit of effort, not sophistication:

1. **Belief records with provenance and half-life** — the substrate everything else needs.
2. **Read / verified / observed epistemic classes**, with **only "observed" allowed to size a position**.
3. **Verification-before-ingestion gate** — mechanical, cheap, already proven necessary here.
4. **Abstention as a real action, with its P&L measured.**
5. **Calibration scoring of the system's own forecasts.**
6. **"Who loses when I win?" as a required declaration** — one question, enormous filtering power.
7. **Meta-analysis over the Trial Registry** — the data already exists.
8. **Own-footprint attribution and counter-detection** — otherwise it learns from its own noise.
9. **Cost of operation inside the objective** — decides whether the AI layer pays for itself.
10. **Property-based invariants across backtest / shadow / live** — cheapest defence against leakage.

> **What is deliberately absent:** anything requiring a model breakthrough, anything giving the
> system credentials or capital autonomy, and anything whose value rests on a self-reported
> benchmark. **The list is boring on purpose. Boring is what compounds.**

---

## 8. What this means for our build, in one page

**The requirement is satisfiable, and not by a model swap.** Nothing above needs a breakthrough. It
needs belief records, calibration harnesses, ablation runs, trial counting, and modules whose
interfaces are smaller than their implementations.

**The three axes are judged separately** because a module can pass one and fail the others. Learning
asks where a number came from. Reasoning asks whether the component knows why and knows when it does
not. Depth asks whether the code hides complexity or merely spreads it.

**Three tests carry most of the weight:**

1. **Provenance + ablation** — show the fitting process that produced the values; then freeze or
   remove the component and show measured behaviour changes. Fail either and it is a parameterised
   script wearing the costume of learning. This is the shape the SEC fined.
2. **Falsifiable side-prediction** — the claimed mechanism must imply another checkable consequence,
   checked on data never used to fit it. A curve-fit has no side-predictions; a real mechanism has
   many.
3. **Interface-to-implementation ratio** — the defining criterion of depth, applicable from a
   module's own source.

**And the three things this project must not repeat**, all first-party and all on this box:

- The prior system lost **$837 over 10,240 live trades** because a feature-governance controller
  credited bot-wide P&L to all 36 features and deactivated all of them, twice, in production.
  **Correct per-feature attribution precedes every learning loop** — without it the ledger is wrong,
  the Deflated Sharpe is wrong, and the learning curve measures noise.
- **Three concurrent self-modification loops** ran against the system being debugged. One loop at a
  time, through the bounded canary — and the safe version already exists in the same account,
  `signals/scibrain/` (ledger row OGE-072).
- **Things that read as built and are not**: `tail_specs()` built, tested, called by nothing;
  `ai-scientist/` and `fable5/` as session logs dressed as autonomous machinery; five circuit
  breakers and health checks living only in docstrings; a Dreamer rollout rewarding itself with
  `np.random.normal`.

The binding, buildable version of all of this is **goal doc §1a**, with its 23 numbered tests and the
per-module axis verdict. This file is why those tests say what they say.
