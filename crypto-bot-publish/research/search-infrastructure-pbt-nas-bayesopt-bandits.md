# Search/Compute-Allocation Infrastructure for Trading Strategy Discovery

**Provenance:** Researched by a Sonnet subagent, 2026-08-01, via WebSearch/WebFetch. Part of a 5-agent parallel sweep on autonomous strategy-discovery systems for a $100k-$1M crypto trading project. Report-only, no files modified by the subagent.

## Bottom line up front

Of four techniques (PBT, NAS, Bayesian optimization, multi-armed bandits), only two are worth building at $100k-$1M scale: **multi-armed bandits** (live capital allocation) and **Bayesian optimization** (hyperparameter tuning). PBT is conditional (only if training genuinely expensive neural nets). NAS: don't build — wrong problem, institutional-lab-scale compute cost.

## 1. Population-Based Training (PBT)

Jaderberg, M. et al. (2017), "Population Based Training of Neural Networks," DeepMind, arXiv:1711.09846. Mechanism: train N models in parallel with own hyperparameters; periodically rank population, kill worst, copy weights+hyperparameters from a top performer ("exploit"), perturb copied hyperparameters ("explore"). Discovers a *schedule* of hyperparameters over training time at roughly the cost of training N models once.

- Good for: expensive single training runs, hyperparameters that plausibly change over training (LR annealing etc.), existing cluster capable of parallel jobs with checkpoint/weight-copy plumbing. DeepMind used it for deep RL, GAN training, machine translation.
- Cost: distributed scheduler, checkpointing infra, periodic comparison/mutation process. Ray Tune ships a `PopulationBasedTraining` scheduler off the shelf, lowering build cost substantially.
- Exact original population sizes/GPU-hours: UNVERIFIED this session (PDF unreadable); general recollection (not re-verified) is populations in the tens at cluster/TPU-pod scale.
- **Verdict for $100k-$1M**: conditional yes only via Ray Tune's built-in scheduler if already training expensive NNs with schedule-sensitive hyperparameters. If your system is gradient-boosted trees or a moderate-size model with a handful of tunable parameters (lookback windows, thresholds, sizing) — skip. PBT's whole value prop (avoid wasting expensive runs) doesn't apply when a backtest is CPU-cheap and fast.

## 2. Neural Architecture Search (NAS)

Lineage: Zoph & Le (2017), "Neural Architecture Search with Reinforcement Learning," arXiv:1611.01578 — RL controller generates architectures, confirmed cost **800 GPUs × 28 days ≈ 22,400 GPU-hours** for one search. Pham et al. (2018) ENAS, arXiv:1802.03268, and Liu, Simonyan, Yang (2018) DARTS, arXiv:1806.09055, built to cut that cost — DARTS found a competitive PTB recurrent cell in ~1 GPU-day (confirmed) vs. thousands of GPU-days for earlier NASNet/AmoebaNet-era methods.

- Good for: discovering network *topology* for a fixed, well-defined supervised task with abundant labeled data (image classification, language modeling).
- **Verdict: don't bother, clearest "resume-driven engineering" candidate on the list.** NAS solves architecture topology for a fixed prediction task; "trading strategy discovery" is a search over strategy *logic* (features, rules, entry/exit, sizing) — fundamentally different, more open-ended, closer to GP/symbolic regression than to NAS. Even where a system uses a neural net as one component, architecture rarely moves the needle in financial time series relative to data quality/feature engineering/overfitting control, and off-the-shelf small architectures (or often gradient-boosted trees, which frequently beat deep nets on tabular/limited-sample financial data) get you there without GPU-days of search.

## 3. Bayesian Optimization

Snoek, Larochelle, Adams (2012), "Practical Bayesian Optimization of Machine Learning Algorithms," NeurIPS 2012 / arXiv:1206.2944. Probabilistic surrogate (originally Gaussian Process) over hyperparameter space + acquisition function (e.g. expected improvement) for sample-efficient search when each evaluation is expensive.

- Good for: moderate dimensionality (2-20 hyperparameters), costly-enough evaluations that grid/random search wastes too much.
- Cost: lowest of the four. Optuna (pip install, TPE sampler default, ASHA pruning support) — day or two of integration. Ax/BoTorch (Meta, GP-based) more statistically principled but heavier lift; default strategy uses Sobol sampling for ~first 5 trials before switching to GP-based acquisition.
- Important caveat found: in the low-dimensional, low-trial regime (exactly what a small team operates in — a handful of hyperparameters, tens of evaluations), Optuna's default Bayesian sampler barely beats random search. Doesn't make it worthless (nearly free to stand up) but won't manufacture edge that isn't there, and overfits to backtest noise exactly as readily as grid search absent proper validation discipline.
- **Verdict: build the minimal version** — Optuna wrapped around an existing walk-forward backtest, budget-capped at ~50-100 trials, paired with strict walk-forward/purged validation rather than a hands-off large-trial search.

## 4. Multi-Armed Bandits (Thompson Sampling, EXP3)

Thompson, W.R. (1933), Biometrika 25(3-4), 285-294 — original posterior-sampling idea. Modern treatment: Russo, Van Roy, Kazerouni, Osband, Wen (2018), "A Tutorial on Thompson Sampling," Foundations and Trends in ML 11(1), 1-96 / arXiv:1707.02038. EXP3: Auer, Cesa-Bianchi, Freund, Schapire (2002), "The Nonstochastic Multiarmed Bandit Problem," SIAM J. Computing 32(1), 48-77 (algorithm originally from a 1995 FOCS paper by same authors). EXP3 makes no i.i.d. reward assumption — designed for adversarial/non-stationary rewards, at cost of generally higher regret than Thompson sampling in truly stochastic settings.

- **Maps directly onto "which of my N live strategies gets more capital this week."** Each strategy = an arm; reward model per arm (Beta-Bernoulli for win/loss, or Gaussian/Sharpe-like for returns); allocation driven by posterior sampling (Thompson) or exponential weighting (EXP3). Relevant applied literature: "Adaptive Portfolio by Solving Multi-armed Bandit via Thompson Sampling" (arXiv:1911.05309); "Improving Portfolio Optimization Results with Bandit Networks" (arXiv:2410.04217) — both reframe portfolio allocation as a bandit problem, generally reporting improved Sharpe/cumulative return over static allocation in backtests.
- Cost: cheapest of the four — a Beta-Bernoulli or Gaussian Thompson sampler is ~100-200 lines, buildable in an afternoon. **Hard part is the reward signal (a stats/data-engineering problem), not the bandit math.**
- **Practical gotchas**:
  - Non-stationarity breaks the stochastic-bandit assumption — need discounted/sliding-window/change-point-aware variants, not vanilla Thompson sampling. See "Multi-Armed Bandit Strategies for Non-Stationary Reward Distributions and Delayed Feedback Processes" (arXiv:1902.08593), which treats both problems this system will face.
  - Delayed and noisy reward — trades held over multi-day/week horizons mean reward isn't available instantly; classic bandit theory assumes prompt feedback. Daily/weekly PnL is dominated by market noise relative to skill, so raw-return reward has poor SNR; want risk-adjusted rolling-window (Sharpe-like) reward, which needs enough samples per arm to mean anything — tension with the bandit's appetite for fast updates.
  - Capital allocation is usually continuous/simplex (fractional weights across all N strategies), not winner-take-all — closer to "online portfolio selection with bandit feedback" than the textbook K-armed problem; the cited papers address this but it's not a drop-in.
  - EXP3's adversarial robustness is attractive in theory for regime-shifting markets but its guarantees are worst-case and it tends to converge slower/explore more than necessary in markets that are noisy but not literally adversarial — most practitioners lean toward discounted/sliding-window Thompson sampling instead.
- **Verdict: build this. Best-fitting technique for the stated problem, and cheap.** Minimum viable version: discounted or sliding-window Thompson sampling over a weekly risk-adjusted reward per live strategy, hard floor/ceiling allocation caps so the bandit can't go all-in on a lucky strategy, plus a manual override.

## 5. Ranking for a $100k-$1M small-team system

| Rank | Technique | Verdict | Minimum viable version |
|---|---|---|---|
| 1 | Multi-armed bandits (Thompson sampling) | Build it | Discounted/sliding-window Beta or Gaussian Thompson sampler, weekly risk-adjusted reward, hard allocation caps |
| 2 | Bayesian optimization | Build it | Optuna around existing walk-forward backtest, capped ~50-100 trials |
| 3 | Population-Based Training | Build only if genuinely training expensive NNs | Ray Tune's built-in PBT scheduler only — never bespoke; skip if models train in minutes on CPU |
| 4 | Neural Architecture Search | Don't bother | N/A — wrong problem, institutional-lab-scale compute (GPU-days to tens of thousands of GPU-hours) for marginal benefit where architecture rarely matters as much as data/overfitting control |

**Underlying pattern**: PBT and NAS were built to amortize very expensive individual evaluations (large-scale NN training) over compute budgets only an institutional lab has. Bayesian optimization and bandits were designed for the opposite regime (expensive-but-not-astronomical evaluations, online decision-making under uncertainty) — a much closer match to a small team. Heuristic: if one evaluation (one backtest, one training run) costs minutes to low hours on affordable infra, you don't need PBT or NAS; you need Bayesian optimization for tuning and bandits for live allocation.

## UNVERIFIED

- Exact PBT population sizes / GPU-TPU-hours in Jaderberg et al. 2017's individual experiments — PDF fetch failed, blog post lacked specifics; figures cited are approximate recollection.
- ENAS's exact GPU-day figure (commonly cited elsewhere as under 1 GPU-day on a consumer GPU) — not independently re-confirmed this session; only DARTS's ~1 GPU-day figure was confirmed via search.
- Whether any specific institutional fund (Two Sigma, Renaissance, Citadel, DE Shaw etc.) actually uses PBT or NAS for strategy search in production — not sought/found; the "institutional funds have compute to justify this, small teams don't" framing is a cost-benefit inference from confirmed compute-cost figures, not a confirmed industry-practice claim.
- Specific dollar compute-cost estimates for standing up PBT/NAS on cloud infra today — not computed; only original-paper GPU-hour/day figures are confirmed.
- Comparison of GP/symbolic-regression as "the actually right lineage" for trading-rule discovery vs. NAS — asserted from general knowledge in passing, not freshly verified (search budget exhausted); see the separate alpha-discovery-gp-symbolic-regression.md file for the properly-researched version of this comparison.
