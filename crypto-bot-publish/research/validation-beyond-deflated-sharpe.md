# Strategy validation beyond deflated Sharpe

**Provenance**
- Researched by: subagent (`general-purpose`), model **sonnet**, per Rule 1
- Date: 2026-08-01 · Run via `parallel-research` (area 2 of 6)
- Brief: find what the user does NOT already know; deflated Sharpe was already decided

---

## The finding that reframes everything else

**Every technique below is defeated by unlogged iteration.** They each answer "is this backtest
overfit *given this set of trials*." Run fifty informal variants before the one you test formally,
and the trial count `N` is an undercount — every p-value downstream is fiction.

> The single biggest failure mode is not "we didn't run PBO." It is "we tried fifty variants before
> the one we wrote down."

**The experiment ledger is therefore a prerequisite, not a complement.** If it does not log every
trial — including failed and abandoned ones — PBO, deflated Sharpe, and multiple-testing correction
are all computing over the wrong `N`. §5 of `DECISIONS.md` already calls the ledger
non-negotiable; this is *why*, and it raises the bar: **abandoned runs must be logged too.**

## Three false-confidence traps

1. **"We walk-forward tested it" as a substitute for purging.** Walk-forward still leaks when labels
   span multiple bars — a triple-barrier label formed over the next 4 hours overlaps price action
   at the end of the training window. **Temporal ≠ non-overlapping.** Walk-forward without purging
   is naive k-fold wearing a disguise.
2. **PBO computed once at the end.** Validity decays with every subsequent tweak-and-rerun. Run it
   over the full set of configurations actually searched, from the ledger.
3. **Meta-labeling as an overfitting cure.** Marketed as reducing overfitting because the model only
   *sizes* bets. True only against a fixed, already-decided primary model. Search over primary
   variants or a large meta feature set and you have **moved** the multiple-testing problem into a
   second layer, not removed it.

## What is worth implementing

| Technique | Verdict |
|---|---|
| **Multiple-testing correction vs the FULL ledger** | **Do it.** Cheapest, biggest effect, most often skipped. t=2.5 out of 5 trials is notable; out of 500 it is the tail behaving normally |
| **Pre-registered untouched holdout, tooling-enforced** | **Do it.** Everything else approximates what this gives directly |
| **MinBTL (minimum backtest length)** | **Do it.** Closed form, few lines. Hard gate against "great Sharpe over 3 months" |
| **PBO / CSCV** | Yes — as a *portfolio-of-trials* check over everything searched, not per-strategy |
| **CPCV** | Yes, but **finalists only**. Combinatorics explode; use N≈8–12 groups, screen with cheaper PBO first |
| **Hansen's SPA** | Yes — the right promotion-gate test: "does the challenger beat the incumbent, corrected for variants tried" |
| **White's Reality Check** | **Skip.** SPA strictly dominates it. Running both is ceremony |

**Citations (verified):** Bailey/Borwein/López de Prado/Zhu, *The Probability of Backtest
Overfitting*, J. Computational Finance 2015 (SSRN 2326253) · Bailey & López de Prado, *The Deflated
Sharpe Ratio*, JPM 2014 (SSRN 2460551), which also defines MinBTL · White, *A Reality Check for Data
Snooping*, Econometrica 68(5) 2000 · Hansen, *A Test for Superior Predictive Ability*, JBES 23(4)
2005 · Harvey/Liu/Zhu, *…and the Cross-Section of Expected Returns*, RFS 29(1) 2016 — proposes a
multiple-testing-adjusted t-hurdle of **~3.0**, not 1.96 · Hou/Xue/Zhang, *Replicating Anomalies*,
RFS 33(5) 2020 — **~65% of ~450 published anomalies failed to replicate** · McLean & Pontiff,
*Does Academic Research Destroy Stock Return Predictability?*, JF 71(1) 2016 — anomalies decay
**~58% post-publication**.

**UNVERIFIED:** no standalone peer-reviewed CPCV paper found distinct from *Advances in Financial
Machine Learning* (Wiley 2018) ch. 12 — cite the book, not a journal.

## Labeling and sampling

- **Triple-barrier** (AFML ch. 3): upper/lower/vertical barriers sized to local volatility; label is
  whichever is touched first. Buys labels reflecting how a position would actually be risk-managed.
  **But barrier width is a hyperparameter** — searching it is itself overfitting and must go through
  the same machinery.
- **Meta-labeling**: secondary model predicts *whether to act*. Real value is bet sizing and
  precision, not statistical laundering.
- **Sample uniqueness / concurrency + sequential bootstrap** (AFML ch. 4): overlapping labels violate
  IID, inflating effective sample size and understating variance. **The least contested part of the
  AFML toolkit.** Cost: sequential bootstrap is inherently non-parallelizable — a real engineering
  expense in an automated system.

> ⚠️ **`mlfinlab` is no longer open source.** Hudson & Thames moved it to a commercial/subscription
> model; the repo carries a custom non-OSS license. A community rewrite, `mlfinpy`, exists on PyPI
> explicitly because mlfinlab is closed-source. **Do not put a licensing risk in the capital-at-risk
> path** — reimplement triple-barrier and sequential bootstrap directly (a few hundred lines) or use
> `mlfinpy`, after checking terms.

## Purging and embargo — mechanics

**Purging:** drop from *training* any sample whose label window `[t_j, t_j+H_j]` intersects any test
sample's window `[t_i, t_i+H_i]`.

**Embargo:** purging alone is insufficient — serial correlation and trailing features leak across the
boundary. Add a buffer *after* each test fold, typically ~1% of total sample size.

> **Non-obvious, and specific to this design: purge/embargo must be configured PER FREQUENCY BAND.**
> Label horizons differ by orders of magnitude across the three brains. An embargo sized for the
> hours→minutes brain is wildly oversized for sub-second (wasting data) and undersized in reverse.
> **Do not share one purge/embargo config across brains.**

## Point-in-time correctness — architecture, not discipline

The reliable version is a **storage and access-layer design decision made before any backtest code
exists**, not a checklist applied to results.

- **Bitemporal storage.** Every datum carries *event time* (when it happened) and *knowledge time*
  (when the system could have known it). All backtest queries filter `knowledge_time <=
  simulation_clock`. Highest-leverage single fix — a schema change, not a discipline.
- **Append-only ingestion.** Never overwrite a republished/corrected candle; store the correction as
  a new row. Overwriting makes "what did we know then" **structurally unanswerable** afterward.
- **Frozen universe snapshots.** Snapshot which pairs were tradeable at each decision date. Deriving
  the universe by filtering a current mutable table reflects *today's* knowledge of who was ever listed.
- **One shared, clock-gated data-access layer for backtest AND live.** If backtesting uses a more
  permissive path (a flat Parquet loaded fully and windowed by hand), the two paths silently diverge
  and an off-by-one in the windowing produces a great backtest and a broken system. Sharing the layer
  converts "don't look ahead" from discipline into **impossibility**.

## Crypto-specific data traps

- **Wash trading.** Bitwise's 2019 SEC submission found **~95% of reported BTC spot volume was
  fake/non-economic** across 81 exchanges, with real volume on ~10. Exchange composition has shifted;
  the magnitude of the problem is durable. **Never use aggregate volume as a liquidity proxy for
  sizing** without a wash discount.
- **Outages correlate with volatility.** Exchanges throttle or fail exactly when a strategy most
  wants to trade. Model execution availability as a haircut *correlated with realized vol*, not a
  flat slippage constant.
- **Backfilled/synthetic candles.** Vendors interpolate gaps without flagging, smoothing away the
  flash crashes that matter most for tail sizing. Track per-candle provenance at ingestion.
- **Timestamp conventions.** Open-vs-close marking, inclusive/exclusive bounds, and funding-rate
  settlement times differ per exchange — a frequent source of off-by-one look-ahead for anything
  trading around funding.
- **Delisted / rebranded pairs.** Survivorship bias; rebrands silently split or merge series.

## The backtest-to-live gap

Ranked contribution (**ordering is the agent's judgment, not cited**): overfitting not caught by the
battery → execution reality (slippage, partial fills, latency, outages) → regime shift → PIT leakage
→ data contamination.

What each pre-live check actually catches:
- **Paper trading** — gross implementation bugs, first read on latency. **Does not catch
  overfitting**; an overfit strategy just looks good for a while. Value is operational.
- **Shadow deployment** (live logic against real books, computing hypothetical fills, no orders) —
  the best available check on the *execution* gap. No better than paper trading on overfitting.
- **Pre-registered holdout** — the actual defense against overfitting, and only if enforced by
  tooling: ledger records a commit hash and a "holdout not yet consumed" flag, and CI blocks any run
  querying the holdout range before the strategy is frozen.

## Ceremony — deprioritize

White's RC alongside SPA · CPCV on every candidate rather than finalists · meta-labeling framed as an
overfitting solution · elaborate barrier-width/embargo-fraction searches not themselves purged.

> The statistics are a second line of defense. The first line — an enforced holdout, a complete
> ledger, and data you structurally cannot query out of order — is less interesting and does more work.
