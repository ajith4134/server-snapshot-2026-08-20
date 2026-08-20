# Experiment → Promotion Pipeline (DESIGN DECISION — settled)

**Decided:** 2026-08-01 with the user.
**User's requirement:** *"first paper trading with full experiment without any
restriction, open to all kinds of experiments, and saving the things that get
profits and use them on live trading or repeating them."*

**Design response:** unrestricted search, ruthless promotion. The experiment layer
has no limits. The gate between experiment and capital is where the rigor lives.

---

## Why the gate exists (the load-bearing math)

If the system tests N strategy variants and keeps the best in-sample performer,
that maximum Sharpe is inflated **even when every variant is pure noise** — the
expected maximum of N draws from a null distribution grows with N.

Bailey & Lopez de Prado's **Deflated Sharpe Ratio** corrects for exactly this: it
deflates observed Sharpe by the expected maximum under the null, given the trial
count and variance across trials, and returns the probability that true Sharpe ≤ 0.

**This imposes a hard architectural requirement:**

> **Every experiment ever run must be logged immutably — including failures.**
> If the system discards losers without counting them, N is dishonest and DSR
> cannot do its job. Silent discard re-introduces the exact bias the gate exists
> to catch.

This is why the experiment ledger is a **core subsystem**, not logging.

---

## The stages

Each stage is a filter. A strategy that fails any stage is **retired with its
result recorded** — never silently dropped, because the record is what keeps N honest.

### Stage 0 — Experiment (UNRESTRICTED)
- Any strategy family, model class, timeframe, feature set, hyperparameter.
- Any of the three brains (hours→min, min→sec, sub-second).
- No approval needed. This is the creative layer and it should run hot.
- **Every trial written to the ledger before it runs** — id, hypothesis, config,
  code hash, data window, random seed.
- Trained on the training window only.

### Stage 1 — Purged cross-validation
- Purged K-fold with embargo, or CPCV for a *distribution* of outcomes rather
  than a point estimate.
- Standard k-fold is **invalid** here: financial data is serially correlated and
  labels from overlapping windows leak across folds.
- Kill criteria: negative mean Sharpe, or performance not distinguishable from
  the linear/LightGBM baseline.

### Stage 2 — Held-out test (touched ONCE)
- A chronological block, embargoed, never used in Stage 0 or 1.
- **Touched exactly once.** Any result requiring a second look invalidates the
  strategy — going back means it becomes training data.
- Realistic costs mandatory: maker/taker fees, depth-aware slippage, partial
  fills, funding at correct settlement times, latency.

### Stage 3 — Deflated Sharpe
- DSR computed with the **honest N** from the ledger.
- Also compute Probability of Backtest Overfitting via CPCV.
- Kill criteria: DSR not significant, or PBO above threshold.
- *This is the stage that catches "we tested 10,000 things and this one looked good."*

### Stage 4 — Forward paper trading (the only truly clean test)
- Live market data, simulated fills, **model frozen**.
- This is the one test provably free of leakage — the data had not happened when
  the model was frozen.
- Minimum duration set by statistics, not impatience — **and the math is now known**
  (see `risk-and-failure.md`):
  - **`n` is trade count, not calendar time.** Bailey & López de Prado: *"frequency of
    observation, not calendar time, is what buys you statistical power."* The fast
    brains clear this gate in a fraction of the wall-clock time the slow brain needs.
  - Use **PSR / Minimum Track Record Length** against the minimum acceptable Sharpe,
    not a fixed number of days. **No authoritative "N months" figure exists** — this
    was searched for specifically and came up empty.
  - Calibration: confirming Sharpe 2.0 > 1.0 at 95% takes **2.73 years of daily
    observations — 4.99 years** with realistic skew/kurtosis. Crypto has both.
  - Require **CPCV regime coverage**, not just trade count — have independent market
    regimes actually been observed?
- Kill criteria: live paper performance outside the statistical bounds implied
  by the backtest. Expect **~50% decay** from backtest — that's normal. Expect
  *worse* than 50% and it's broken.
- **Drawdown is a detector, not just a loss.** Zero-Sharpe expected drawdown grows
  unboundedly as **√T**; positive-Sharpe grows only **logarithmically** in T
  (Magdon-Ismail et al. 2004). Normal while inside the envelope implied by the
  claimed Sharpe; broken when it materially exceeds it. **Never judge on elapsed
  time alone.**

### Stage 5 — Gated live (small)
- Requires the **user's manual go-live control** — the button.
- Hard caps: small fraction of capital, per-strategy position limit, daily loss
  limit, kill switch.
- Runs alongside its paper twin; divergence between them is itself a monitored
  signal (real slippage vs modelled).

### Stage 6 — Scaled live
- Size increases only on sustained live performance tracking expectation.
- Continuous monitoring — see decay below.

---

## Decay: promotion is not permanent

The user's *"or repeating them"* needs one correction: **a strategy that worked
does not stay working.** Alpha decays as edges get crowded out — crypto has seen
this dramatically (cross-exchange arb, basis trades, MEV all compressed hard
since 2021).

So promotion is a **lease, not a deed**:
- Rolling Sharpe monitored continuously against its promotion-time baseline.
- Feature and prediction distribution drift monitored (ADWIN/DDM via `river`).
- Statistical decay test distinguishes normal losing streaks from a broken model —
  **critical, because a Sharpe-1.5 strategy has long losing runs that are entirely
  normal**, and pulling it early is as costly as leaving a dead one running.
- On decay: demote to paper, re-enter the pipeline. Do not delete — the record
  stays in the ledger and still counts toward N.

---

## What "self-improving" means here, precisely

**It does:** generate new hypotheses, test them automatically, run the full gate,
retire decayed strategies, reallocate capital toward what is measurably working,
and accumulate a permanent record of what has and hasn't worked.

**It does not:** edit live model weights from its own P&L without passing the gate.

That second thing is what people usually mean by "self-learning trading bot," and
no credible production example of it was found in research. It is a machine for
overfitting its own recent noise, and it fails on the first regime change it
hasn't seen. The version above is genuinely autonomous *and* survives contact with
a changing market.

---

## Ledger schema (sketch — the core of the system)

```
experiment
  id, created_at, brain, strategy_family, hypothesis
  config_json, code_git_sha, data_window_start/end, random_seed
  status: running|failed|killed_stage_N|promoted|decayed|retired

trial_result
  experiment_id, stage, metrics_json (sharpe, sortino, max_dd, turnover,
  hit_rate, avg_slippage, fees_paid), passed BOOL, killed_reason

promotion_event
  experiment_id, from_stage, to_stage, at, approved_by (system|user), notes

live_allocation
  experiment_id, capital_fraction, position_limit, daily_loss_limit, active
```

**`status` must record kills.** A schema that only stores winners cannot produce
an honest N, and an honest N is the whole point.
