# Mined: early repos — meta_ai, ai_civilization, backtesting layers

Mined 2026-08-08. Source: `ajith-ai-crypto-trading-bot` — `meta_ai/*.py` (16 files),
`ai_civilization/{hooks,control_mode,config,__init__}.py`, `backtesting/{engine,parameter_sweep,__init__}.py`.
Plus a line-by-line diff of `meta_ai/circuit_breaker.py` against `crypto-linix-server-bot`.

**Provenance note:** produced by a mining agent that returned its findings as a message rather than
writing a file. Transcribed to disk by the orchestrating session to prevent loss. Content unaltered.

**Coverage note:** the wider `ai_civilization` submodules — evolution, society, governance, councils,
world_model, memory — were NOT read in this pass. Rows touching them describe the call site, not the
implementation behind it.

**Critical caveat carried from `prior-attempts-postmortem.md` §3.2–3.3:** IMPLEMENTED means code with
a real body exists. It does not mean validated, and it does not mean profitable.

---

## Circuit-breaker fork diff — 463 → 484 lines

The extra 21 lines in the linix fork are **not new circuit breakers**. Two targeted bug fixes to
existing CB1 and CB7, plus one threshold change:

1. `_cb1_consecutive_losses` now filters out `exit_reason == "session_restart"` trades and losses
   under $5 (fee/slippage noise) before counting consecutive losses, and auto-resolves CB1 when too
   little real history remains. Fixes a bug where **every bot restart falsely tripped CB1**.
2. `consecutive_losses` threshold raised 3 → 5.
3. `_resolve(..., restore_conf=True)` restores to `cfg.get("trading.min_confidence_to_trade", 60.0)`
   instead of a hardcoded `60.0`. Comment labels this "BUG #6 fix" — the hardcode permanently
   elevated min_confidence after CB7 resolved, blocking every signal that passed the original
   threshold.

**CB5 (liquidity crisis), CB6 (strategy overconcentration) and CB9 (data anomaly) are absent in
both repos** — documented in the header docstring of each, implemented in neither.

## Feature table

| Feature | What it does | Category | Evidence | State |
|---|---|---|---|---|
| ATC policy/value network | Transformer encoder over strategy signals + MLP over market/portfolio/risk context, fused into actor-critic with a 300-way discrete action space (direction × size × SL × TP) | models | meta_ai/atc.py | IMPLEMENTED |
| ATC PPO training loop | GAE returns, clipped surrogate objective, entropy bonus, background thread every 30s | models | meta_ai/atc.py | IMPLEMENTED |
| ATC state builder | Pulls live strategy scores, market indicators, entropy, portfolio heat/drawdown, Lévy jump probability, options IV/RV, cross-exchange imbalance, sentiment | intelligence | meta_ai/atc.py | IMPLEMENTED |
| ATC `decide()` with pass-through | Returns direction/size/SL/TP; falls back to no-op if untrained | strategy | meta_ai/atc.py | IMPLEMENTED |
| ATC "Dreamer" imagination rollouts | Docstring claims Dreamer world-model simulated outcomes; actual reward is `np.random.normal(0.1, 0.5)` — code comment admits "simplified: use small random reward for imagination" | models | meta_ai/atc.py (`imagine_and_train`) | STUB — fake reward signal |
| ATC checkpoint persistence | torch save/load of net + optimizer state | operations | meta_ai/atc.py | IMPLEMENTED |
| Bayesian hyperparameter optimizer | Optuna TPE over confidence/SL/TP/leverage/category weights, median pruner, objective = Calmar ratio from `backtesting.engine` | models | meta_ai/bayesian_optimizer.py | IMPLEMENTED |
| Bayesian optimizer random-search fallback | Used when Optuna is not installed | models | meta_ai/bayesian_optimizer.py | IMPLEMENTED |
| Bayesian optimizer auto-apply + notify | Writes best params to live config, notifies via Telegram | operations | meta_ai/bayesian_optimizer.py | IMPLEMENTED |
| CB1 — consecutive losses → reduce leverage | Threshold check + config write | risk | meta_ai/circuit_breaker.py | IMPLEMENTED |
| CB2 — drawdown acceleration → raise confidence bar | Reads advanced_risk_manager, raises min-confidence | risk | meta_ai/circuit_breaker.py | IMPLEMENTED |
| CB3 — model confidence drift → recalibrate + retrain | Compares avg confidence to actual WR, spawns `ml.trainer` retrain thread | risk | meta_ai/circuit_breaker.py | IMPLEMENTED |
| CB4 — volatility spike → widen SL | ATR-ratio check, config write | risk | meta_ai/circuit_breaker.py | IMPLEMENTED |
| CB5 — liquidity crisis | Named in header docstring only; no method, never called | risk | meta_ai/circuit_breaker.py | DOCUMENTED-ONLY |
| CB6 — strategy overconcentration | Named in header only; no method, never called | risk | meta_ai/circuit_breaker.py | DOCUMENTED-ONLY |
| CB7 — time-of-day risk | Raises confidence during low-liquidity UTC hours | risk | meta_ai/circuit_breaker.py | IMPLEMENTED |
| CB8 — win-rate collapse → suspend strategy | Persists suspended list to JSON | risk | meta_ai/circuit_breaker.py | IMPLEMENTED |
| CB9 — data anomaly | Named in header only; no method, never called | risk | meta_ai/circuit_breaker.py | DOCUMENTED-ONLY |
| CB10 — system resource throttle | Real psutil CPU/mem check, scan-interval scaling with hard cap | operations | meta_ai/circuit_breaker.py | IMPLEMENTED |
| CB gatekeeper (`check_symbol_entry`) | Final pre-trade check combining CB1/2/7 confidence floor + CB8 suspension list + cold-start confidence cap | risk | meta_ai/circuit_breaker.py | IMPLEMENTED |
| CB1 fork fix | Excludes restart artefacts and sub-$5 losses from the consecutive-loss count | risk | crypto-linix-server-bot/meta_ai/circuit_breaker.py | IMPLEMENTED |
| CB7 fork fix | Restores configured `min_confidence_to_trade` instead of a hardcoded 60.0 | risk | crypto-linix-server-bot/meta_ai/circuit_breaker.py | IMPLEMENTED |
| Cognitive Immune — Strategy Cult | Detects one strategy holding >40% of open slots while net-losing, halves its size | governance | meta_ai/cognitive_immune_system.py | IMPLEMENTED |
| Cognitive Immune — Ideology Lock | Detects L/S ratio >4:1 over 48h while losing, boosts opposite-side confidence | governance | meta_ai/cognitive_immune_system.py | IMPLEMENTED |
| Cognitive Immune — Fake Alpha | Flags recent WR spiking >20pp above lifetime WR as an overfit signal, caps size | governance | meta_ai/cognitive_immune_system.py | IMPLEMENTED |
| Cognitive Immune — Epistemic Drift | Greps the daily log for "CONCEPT DRIFT DETECTED" count, penalises global confidence | governance | meta_ai/cognitive_immune_system.py | IMPLEMENTED |
| Cognitive Immune — Unstable Mutation | Quarantines sandbox genomes with >30% shadow-trade loss rate | governance | meta_ai/cognitive_immune_system.py | IMPLEMENTED |
| MetaAIController orchestration | Boots ATC, CircuitBreaker, HealthMonitor, Bayesian, MAML, PortfolioRL, GeneticEvolution, LLMAnalyst, Overseer with per-component try/except | operations | meta_ai/controller.py | IMPLEMENTED |
| MetaAIController lifecycle hooks | `on_signal` / `on_trade_opened` / `on_trade_closed` / `on_portfolio_tick` wire ATC + CB + MAML + PortfolioRL into the trade lifecycle | operations | meta_ai/controller.py | IMPLEMENTED |
| Debate Council 3-agent system | Advocate/Bear heuristic scoring + reputation-weighted Arbiter decision (APPROVE / APPROVE_SIZED / APPROVE_DEFER / REJECT) | strategy | meta_ai/debate_council.py | IMPLEMENTED — pure heuristic, **no LLM call**; "Agent" naming is metaphorical |
| Debate Council reputation persistence | Per (strategy, regime, hour-bucket) reputation update after close | strategy | meta_ai/debate_council.py | IMPLEMENTED |
| Drawdown-at-Risk Monte Carlo | Vectorised 1000-scenario / 50-trade forward simulation of P(20% drawdown) | risk | meta_ai/drawdown_at_risk.py | IMPLEMENTED |
| Drawdown-at-Risk auto-apply | Soft-reduces `max_concurrent_trades` when DaR crosses 0.30 / 0.60 | risk | meta_ai/drawdown_at_risk.py | IMPLEMENTED |
| EvolutionaryStrategy wrapper | Adapts a GA-evolved `StrategyIndividual` into a `BaseStrategy` for the live selector | strategy | meta_ai/evolved_strategy.py | IMPLEMENTED |
| Genetic algorithm strategy discovery | Gene/individual dataclasses, mutation, single-point crossover, elitism | strategy | meta_ai/genetic_evolution.py | IMPLEMENTED |
| NSGA-II multi-objective Pareto ranking | Ranks population by (Sharpe, win rate, max drawdown) | strategy | meta_ai/genetic_evolution.py | IMPLEMENTED (delegates to a module outside this pass's scope) |
| GA fitness evaluation | Bar-by-bar backtest of each individual's gene rules against real historical OHLCV | validation | meta_ai/genetic_evolution.py | IMPLEMENTED |
| GA hall-of-fame bridge | Registers the best evolved strategy into the live selector and the civilization genome bridge | strategy | meta_ai/genetic_evolution.py | IMPLEMENTED |
| HM1 — ML calibration check | Bins trades by confidence, checks reliability drift, auto-recalibrates threshold on severe drift | observability | meta_ai/health_monitor.py | IMPLEMENTED |
| HM2 — strategy decay check | Flags strategies with WR<40% over 20+ trades | observability | meta_ai/health_monitor.py | IMPLEMENTED |
| HM3 — feature importance drift | Named in header docstring only; no method, never called | observability | meta_ai/health_monitor.py | DOCUMENTED-ONLY |
| HM4 — execution quality check | Estimates slippage as entry-vs-stop-loss distance — a proxy, not real fill-vs-quote data | observability | meta_ai/health_monitor.py | IMPLEMENTED (weak proxy metric) |
| HM5 — data pipeline health | Checks for all-NaN indicator columns, zero ATR, out-of-bounds RSI on a live BTCUSDT fetch | observability | meta_ai/health_monitor.py | IMPLEMENTED |
| HM6 — ensemble agreement check | Imports the ensemble class and unconditionally returns "healthy" — never measures disagreement | observability | meta_ai/health_monitor.py | STUB |
| HM7 — regime detector drift | Named in header only; no method, never called | observability | meta_ai/health_monitor.py | DOCUMENTED-ONLY |
| HM8 — sentiment signal lag | `sent = None  # placeholder`; always returns "No sentiment data in DB" | observability | meta_ai/health_monitor.py | STUB |
| Intelligence Overseer 35-system audit | Introspects Core-ML (7) / Meta-AI (8) / Specialist (8) / Analysis (7) / Connector (5) subsystems for trained / data-rich / active / effective, computing HEALTHY / NEEDS_DATA / NOT_APPLYING / DEGRADED / BROKEN | observability | meta_ai/intelligence_overseer.py | IMPLEMENTED — real file-freshness checks, telemetry windows, per-subsystem DB queries |
| Overseer timeout-guarded audit loop | Runs the audit in a worker thread with a 300s hard wall-clock cap so a stuck query cannot hang the cycle | observability | meta_ai/intelligence_overseer.py | IMPLEMENTED |
| LLM self-analysis via Claude API | Real `anthropic` SDK client, `.messages.create(...)`, collects trade/strategy/health/CB context, parses JSON improvement proposals | intelligence | meta_ai/llm_analyst.py | IMPLEMENTED — genuine API integration (model string `claude-opus-4-7` is non-standard and unverified) |
| LLM Analyst context collection | Aggregates trade stats, strategy performance, health checks, CB events, config, recent error-log lines | observability | meta_ai/llm_analyst.py | IMPLEMENTED |
| LLM Analyst proposal auto-apply | Regex-extracts confidence-threshold suggestions, auto-applies only pure "config" proposals at confidence ≥0.8; code and strategy changes always require human approval | governance | meta_ai/llm_analyst.py | IMPLEMENTED |
| LLM strategy code generation | Second real Claude call asks the model to write a `BaseStrategy` subclass; validated by syntax compile check, dangerous-import blocklist, and a sandboxed dry-run against synthetic OHLCV before saving and seeding into genetic evolution as a sandbox genome | strategy | meta_ai/llm_analyst.py (`generate_strategy_code`) | IMPLEMENTED — real call, real 3-stage validation gate |
| MAML fast-adaptation network | FOMAML; lightweight net + inner-loop SGD (3 steps) on the last 10–15 trades | models | meta_ai/maml.py | IMPLEMENTED |
| MAML outer-loop meta-update | Samples tasks, evaluates adapted weights on a held-out split, updates base weights every 100 trades | models | meta_ai/maml.py | IMPLEMENTED |
| Portfolio RL attention network | Multi-head transformer attention over variable-count open positions + portfolio context, 3 heads (per-trade action, portfolio action, value) | models | meta_ai/portfolio_rl.py | IMPLEMENTED |
| Portfolio RL heuristic fallback | PnL-threshold rules used before the net is trained | risk | meta_ai/portfolio_rl.py | IMPLEMENTED |
| Portfolio RL policy-gradient training | Baseline-subtracted policy gradient + value loss, background thread every 60s | models | meta_ai/portfolio_rl.py | IMPLEMENTED |
| Intelligence telemetry counter | Thread-safe call-count singleton feeding the Overseer's ACTIVE dimension | observability | meta_ai/telemetry.py | IMPLEMENTED |
| AI Civilization boot/shutdown lifecycle | Wires data bus, control mode, event subscriptions (reflector, agent registry, shadow trader), seeds genomes/society/memory, starts the evolution scheduler | governance | ai_civilization/hooks.py | IMPLEMENTED at this layer |
| Civilization event-bus observers | Propagates the bot kill-switch to the civilization kill-switch; refreshes the world model on regime change | governance | ai_civilization/hooks.py | IMPLEMENTED |
| Civilization call-driven hooks | `evaluate_trade_signal`, `adjust_sizing`, `adjust_sl_tp`, `should_exit`, `pre_trade_risk_check` — exception-safe, blend civ opinion by authority weight | governance | ai_civilization/hooks.py | IMPLEMENTED at this layer |
| Control Mode authority system | 7-state mode enum (DISABLED → … → LIVE_SOVEREIGN) with per-organ blend weights (signal/sizing/sl/tp/exit/veto), JSON persistence, kill-switch gating | governance | ai_civilization/config.py, control_mode.py | IMPLEMENTED |
| Civilization LLM policy slot | `LLM_MODE = "free_only"` referencing a Groq free-tier key; comment states "v1 ships pure local algorithmic reasoning. The slot exists but is wired to a no-op" | governance | ai_civilization/config.py | DOCUMENTED-ONLY — explicit no-op, unrelated to the real Anthropic integration in llm_analyst.py |
| Backtest engine | Bar-by-bar simulation using the real `StrategySelector`, ATR-based SL/TP, fee and slippage accounting, equity curve, Sharpe/Calmar/drawdown/profit-factor | validation | backtesting/engine.py | IMPLEMENTED |
| Backtest walk-forward OOS split | Re-runs on a held-out tail segment and penalises overfit parameter sets in `.score()` | validation | backtesting/engine.py | IMPLEMENTED |
| Parameter sweep grid search | Expands `min_confidence × sl_atr_mult × tp_atr_mult`, ~140 combinations | operations | backtesting/parameter_sweep.py | IMPLEMENTED |
| Parameter sweep parallel backends | Ray / ProcessPoolExecutor / ThreadPoolExecutor with auto-selection | operations | backtesting/parameter_sweep.py | IMPLEMENTED |
| Parameter sweep auto-apply + shadow seeding | Writes best params to live config, notifies Telegram, seeds a new A/B shadow experiment at best + 2.5% confidence | operations | backtesting/parameter_sweep.py | IMPLEMENTED |

## Real vs mocked external calls — explicit flags

| Call | Verdict |
|---|---|
| `meta_ai/llm_analyst.py` | **Real.** Genuine `anthropic` SDK calls at two sites — performance-analysis proposals and executable strategy-code generation. Both no-op gracefully if the package or key is missing rather than faking a response |
| `meta_ai/atc.py` `imagine_and_train` | **Fake, flagged in-code.** Claims Dreamer world-model rollouts; the imagined reward is literally `np.random.normal(0.1, 0.5)` |
| `ai_civilization/config.py` `LLM_MODE` | **Explicit no-op stub.** Placeholder pointing at a free Groq tier, documented as wired to nothing in v1 |

## Architectural summary

A supervisory layer above the 57-strategy voting system. `meta_ai/controller.py` boots and
coordinates nine largely independent subsystems: a PPO-trained transformer policy (ATC) intended to
eventually replace confidence-threshold voting; ten rule-based circuit breakers and a five-check
cognitive immune system for risk containment; a MAML fast-adaptation net and a portfolio-level
attention-RL agent; a genetic-algorithm strategy-discovery engine bridged into a separate
`ai_civilization` genome registry; Bayesian hyperparameter tuning backed by real backtests; and an
LLM analyst that genuinely calls the Claude API both to critique performance and to write, validate
and sandbox new strategy code.

A parallel `ai_civilization` layer governs how much authority any of this holds over live trading,
via a staged blend-weight promotion system gated by its own kill switch.

**Health and audit coverage is broad but not uniformly real.** Five documented checks (HM3, HM7,
CB5, CB6, CB9) exist only in docstrings, and two implemented checks (HM6, HM8) are effective no-ops
that always report healthy or perpetually report no data. This is the same "reads as built, isn't"
pattern found elsewhere in this project — see `ai-scientist/` and `fable5/` in
`nse-crypto-bot-final`, and `tail_specs()` in the current repo.
