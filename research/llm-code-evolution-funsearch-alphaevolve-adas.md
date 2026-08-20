# LLM-Driven Code Evolution: FunSearch, AlphaEvolve, ADAS and Comparable Systems

**Provenance:** Researched by a Sonnet subagent, 2026-08-01, via WebSearch/WebFetch against arXiv, Nature, GitHub, DeepMind blog, ICLR proceedings. Part of a 5-agent parallel sweep on autonomous strategy-discovery systems for a $100k-$1M crypto trading project. Report-only, no files modified by the subagent.

## 1. FunSearch — peer-reviewed, published, code partially open

Romera-Paredes, B., Barekatain, M., Novikov, A., Balog, M. et al. "Mathematical discoveries from program search with large language models." *Nature* 625, 468–475 (2023/2024). Genuine peer-reviewed Nature paper.

- **Cap set problem**: found a cap set of 512 vectors in ℤ₃⁸, pushing the asymptotic lower bound on cap-set growth rate from 2.2180 to 2.2184 — largest improvement to this bound in ~20 years.
- **Online bin packing**: new heuristics outperforming widely-used baselines on standard benchmarks.
- **Mechanism**: LLM (Codey/PaLM-family) generates candidate program mutations; deterministic evaluator scores each; an "islands" program-database maintains diverse parallel evolutionary sub-populations, periodically cross-pollinating top performers. LLM weights never change — this is GP-over-source-code, not gradient training of the LLM.
- **Code**: `github.com/google-deepmind/funsearch` (Apache 2.0/CC-BY) ships discovered solutions + evaluation harness but explicitly excludes the LLM sampler, untrusted-code sandbox, and distributed-execution infra. Not a turnkey reproduction.

## 2. AlphaEvolve — Google DeepMind, NOT peer-reviewed, closed/internal

Blog: "AlphaEvolve: A Gemini-powered coding agent for designing advanced algorithms," deepmind.google/blog, May 14, 2025. Technical report: Novikov et al. (18 authors), arXiv:2506.13131 (June 2025), self-labeled a "white paper."

**Critical validation finding**: has NOT appeared in a peer-reviewed journal/conference. It is an arXiv preprint / company technical report with no evidence of external peer review of its central claims. One specific artifact was independently verified by a third party — `github.com/PhialsBasement/AlphaEvolve-MatrixMul-Verification` confirms the 48-multiplication algorithm is a correct 4×4 complex-matrix multiplication procedure. That is verification of one concrete output, not peer review of the system or its broader claims (data center %, kernel speedups etc.), which remain self-reported by Google with no external audit trail.

Reported results (all Google-sourced, unaudited):
- **Matrix multiplication**: 48-scalar-multiplication procedure for 4×4 complex matrices, beating Strassen's 1969 bound of 49 — first improvement in 56 years for this specific case (complex-valued 4×4, not general).
- **Data center scheduling**: Borg scheduling heuristic in production >1 year, "continuously recovers ~0.7% of Google's worldwide compute resources" (self-reported).
- **Chip design**: Verilog simplification for a TPU matmul circuit, integrated into an upcoming TPU.
- **Kernel/compiler optimization**: 23% speedup on a Gemini matmul kernel (~1% training-time reduction); up to 32.5% speedup on a FlashAttention kernel.
- **Math**: circle packing n=26, improved sum-of-radii from 2.634 (Friedman 2012) to 2.63586276.
- **Not open source.** Google states plans for an "Early Access Program" for select academics; remains closed.

## 3. ADAS (Automated Design of Agentic Systems) — peer-reviewed, ICLR 2025

Hu, S., Lu, C., Clune, J. arXiv:2408.08435 (Aug 2024), **accepted ICLR 2025** — genuine peer-reviewed conference paper, distinct from AlphaEvolve's unreviewed status.

- **Mechanism**: "Meta Agent Search" — a meta-agent iteratively writes new agent architectures as code (prompts, tool use, control flow), each candidate evaluated on benchmark tasks, results feed a growing archive conditioning future proposals (open-ended/quality-diversity search, structurally similar to FunSearch's program database).
- **Results**: evaluated on coding, science, reading comprehension, math, ARC. On MGSM math benchmark, best discovered agents beat hand-designed baselines by 14.4% accuracy. Discovered agents transfer with reduced-but-nonzero performance across domains/models.
- **Safety note (authors' own)**: since agents are arbitrary self-modifying code, sandboxing/containerized execution and manual review were required mitigations against unintended destructive behavior — direct analogy to any system letting an LLM write and auto-execute trading logic.

## 4. Other comparable systems

| System | Citation | Peer-reviewed? | Open source? | Mechanism |
|---|---|---|---|---|
| Eureka | Ma, Y.J. et al., arXiv:2310.12931 (Oct 2023) | Yes — ICLR 2024 | Yes, github.com/eureka-research/eureka | LLM (GPT-4) evolves RL reward-function code; fitness = full RL training run in Isaac Gym. Beat human-engineered rewards on 83% of 29 tasks, avg +52%. |
| STOP | Zelikman et al., arXiv:2310.02304 (Oct 2023) | UNVERIFIED venue | Yes, github.com/microsoft/stop | LLM-scaffolded "improver" recursively improves its own code via beam search/GA/annealing. Authors note this is not true recursive self-improvement since LLM weights never change. |
| EvoPrompt | Guo, Q. et al., arXiv:2309.08532 | UNVERIFIED venue | Yes (referenced) | GA/differential evolution over discrete NL prompts. Up to +25% over human prompts on BIG-Bench-Hard. |
| OpenEvolve | github.com/codelion/openevolve | N/A (OSS project, no paper) | Yes, actively maintained | Unofficial third-party reimplementation of the AlphaEvolve pattern (not Google-affiliated). Supports API-based or local LLMs. Claims to match published circle-packing (n=26) results; self-reported, not independently audited. Most realistic starting point for a small team wanting an AlphaEvolve-shaped loop. |
| ShinkaEvolve | arXiv:2509.19349 (Sept 2025) | UNVERIFIED | Referenced as open | Independent group's open-ended program-evolution system that exceeded AlphaEvolve's own circle-packing n=26 result (2.635983283 vs 2.63586276) — genuine evidence an outside team extended one narrow AlphaEvolve result. |

## 5. Has this been applied to trading in a peer-reviewed or credibly-verified setting? — NO

This is the crux question. Answer is clear: **no peer-reviewed or independently verified demonstration exists.** A small, very recent (2026) cluster of unreviewed preprints/hobbyist repos imitates the AlphaEvolve pattern for trading:

- **MadEvolve** — Kvasiuk, Li, Colegrove, Münchmeyer, arXiv:2605.23007 (May 2026). Not peer-reviewed. AlphaEvolve-modeled, applied to Bitcoin trading feature/strategy generation. Notably the authors flag overfitting risk and evaluate p-hacking probabilities themselves — rare for this space — but single-asset, single-paper, unreviewed.
- **QuantaAlpha** — Han, Zhang et al. (17 authors), arXiv:2602.07085 (Feb 2026, rev. May 2026). Not peer-reviewed. GPT-5.2-driven evolution of "alpha factors" on CSI 300/500 and S&P 500. Reports IC=0.0472, annualized return 4.68%, max drawdown 11.8%, cross-market "transfer" claims — self-reported backtest, no independent replication found.
- **EVOQUANT** — arXiv:2607.12455 (July 2026), unreviewed preprint, not deeply examined.
- **pwb-alphaevolve** and **shaansuthar/alphaevolve-trading** — independent GitHub projects applying the AlphaEvolve pattern to trading backtests. Community code, no paper, no peer review, no disclosed walk-forward/robustness methodology.
- "QuantEvolve" (MAP-Elites/island-model trading system mentioned in secondary sources) — could not trace to a verifiable primary source; **UNVERIFIED, do not treat as confirmed to exist as described.**

**Bottom line**: "apply AlphaEvolve-style search to trading strategies" is active hobbyist/preprint experimentation as of 2026, but unvalidated extrapolation, not a demonstrated capability. No peer-reviewed or independently replicated evidence this class of system produces genuine OOS trading edge vs. backtest-fit noise.

## 6. THE CRUX: fitness-function prerequisites and why trading breaks them

Every demonstrated success (FunSearch, AlphaEvolve, ADAS, Eureka) shares structural preconditions trading lacks:

1. **Fast, cheap-to-evaluate fitness function** — millions of evaluations needed; each must be cheap (ms-seconds).
2. **Low-noise or fully deterministic evaluator** — cap-set validity, matrix-mult correctness, ARC/math accuracy, RL sim reward: all exact or near-exact.
3. **Construct validity** — a high score on the evaluator IS the thing you care about, permanently and unconditionally true (a correct 48-mult algorithm stays correct forever).
4. **Stationary environment** — the optimization target doesn't shift over time or in response to the search. Even AlphaEvolve's most real-world example (Borg scheduling) was rolled out cautiously over a year of live A/B testing with enormous sample sizes — a very different regime from an individual trader's iteration loop.
5. **Well-defined, bounded search space** expressible as executable code with a clear grammar/spec.

**Why backtested trading fitness (Sharpe/PnL) violates nearly all five:**
- **Noisy**: extremely low signal-to-noise in financial returns; small Sharpe differences are frequently indistinguishable from sampling noise.
- **Non-stationary**: market regimes shift for reasons unrelated to strategy "skill" — unlike a mathematical proof that stays true forever.
- **Gameable via the exact mechanism that makes these systems powerful**: massive cheap evaluation against a fixed evaluator is precisely the multiple-hypothesis-testing/selection-bias setup that produces backtest overfitting when the evaluator is a finite historical backtest. This is a structural tension: the scaling property that makes evolutionary LLM search work on math/code is the same property that manufactures overfit trading strategies when pointed at finite historical market data. (This overfitting-via-massive-search dynamic is the well-known subject of the Bailey/Borwein/López de Prado/Zhu backtest-overfitting literature — not independently re-confirmed by exact citation in this session due to search-budget exhaustion, but corroborated directly by the separate multiple-comparisons research agent's findings.)
- **Expensive/impossible to genuinely scale up**: rigorous evaluation needs true OOS data across distinct market regimes; you can't manufacture more independent decades of market history the way you can spin up more parallel simulator instances.
- **Construct-validity gap**: high backtested Sharpe is a hypothesis awaiting new data, not proof of persistent edge — categorically different from a symbolically-verified matrix-multiplication algorithm.

## UNVERIFIED

- STOP's and EvoPrompt's peer-review venue — not confirmed, search budget exhausted.
- "QuantEvolve" — no traceable primary source, do not cite as confirmed.
- Exact Bailey/López de Prado backtest-overfitting citation details recalled from general knowledge, not re-confirmed in this specific agent's session (but independently confirmed with full citations by the separate multiple-comparisons research agent — see that file).
- AlphaEvolve's claimed "kissing number in 11 dimensions" improvement (592→593) — sourced from a single WebSearch synthesis, not a directly fetched primary passage.
- General claim "over 90% of academic trading strategies fail live" — appeared only in a synthesized search-engine summary with no traceable citation; do not use as a sourced statistic.

## Summary for calibration

FunSearch: real, peer-reviewed, modest-but-genuine math results, code partially open. AlphaEvolve: real engineering results claimed by Google but entirely self-reported, unreviewed, closed-source — treat every number as a company claim pending independent audit. ADAS: real, peer-reviewed, modest agent-design gains, explicit safety caveats about self-modifying code. Eureka/STOP/EvoPrompt/OpenEvolve form a genuine, growing open family; OpenEvolve is the most practical OSS starting point. Trading-specific application is purely nascent, unreviewed 2026 preprints/hobby projects — extrapolation, not validated technique. The core prerequisite behind every genuine success (cheap, low-noise, stationary, ungameable fitness function) is precisely what a backtest-driven trading fitness function is not.
