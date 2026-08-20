# BULL / BEAR / PROFIT-TAIL — three-bot architecture

**Decided with user 2026-08-03, in interview.** Supersedes `dual-agent-spec.md`, which
stays valid for everything it says about the two directional agents; this document adds
the third bot, fixes the authority map, and raises all three from model heads to
independent bots.

---

## 0. What changed, and why

The previous design had two directional specialists sharing one pipeline, with an
arbiter choosing between them. Two changes:

1. **BULL and BEAR become genuinely independent bots** — own features, own model
   architecture, own training pipeline, own validation history. Not two heads on a trunk.
2. **A third bot is added: PROFIT-TAIL.** Also a full project — dedicated data,
   dedicated features, dedicated architecture. It owns the profit path.

**The authority constraint, in the user's words:** PROFIT-TAIL "will not reject trades
after the trades are selected." It does not hold the go/no-go. What it holds is
**when to get in, and everything that happens after**.

---

## 1. The three bots

| | **BULL** | **BEAR** | **PROFIT-TAIL** |
|---|---|---|---|
| Thesis | price will **rise** | price will **fall** | *when to enter, how much of the move is collectable, and how it ends* |
| Emits | calibrated P(up) + conviction | calibrated P(down) + conviction | entry trigger · profit-lock level · position action · advisory expectancy and tail estimates |
| Authority | proposes only | proposes only | **owns entry timing and the whole position after fill** |
| Cannot | propose a short | propose a long | **reject a selected trade · refuse to close a loser** |
| Instruments | long / call side | short / put side | instrument-agnostic — acts on whatever is open |

BULL and BEAR keep every constraint in `dual-agent-spec.md`: three-state output space
(LONG / SHORT / FLAT, and flat is frequently correct), mandatory calibration before
sizing, options are not a directional bet, short-side limits stricter than long-side.

**Scope: crypto only** — spot, perps, futures, options. Confirmed in interview,
consistent with `DECISIONS.md`. No other segment is in scope.

---

## 2. Authority map — who decides what

```
symbol selected
        │
        ├──────────────┬──────────────────┐
      BULL           BEAR            PROFIT-TAIL
     P(up)          P(down)          net expectancy · loss tail
     conviction     conviction       (ADVISORY — inputs, not a vote)
        └──────────────┴──────────────────┘
                       │
                   ARBITER  ── meta-label ──▶ LONG / SHORT / FLAT + size
                       │        this is where a trade is selected or refused
                       │
                   PROFIT-TAIL  ── decides WHEN, and at what price
                       │        may wait, may not refuse
                       │        bounded by signal expiry
                       │
                   RISK GATE  ──▶ EXECUTION ──▶ fill
                       │
                 PROFIT-TAIL owns the position from here
                       │
    HOLD · RATCHET LOCK · SCALE_OUT · CLOSE · request-add ──▶ RISK GATE ──▶ EXEC
                       │
                   HARD STOP — outside all of it, overrides everything
```

Five rules fall out of this diagram. None is negotiable.

1. **Trade selection belongs to the arbiter.** PROFIT-TAIL's expectancy and tail numbers
   are *features the arbiter consumes*, not a veto. If PROFIT-TAIL could refuse, it would
   be a second risk gate — and every blow-up in the research set traces to risk authority
   being split or exempted.
2. **Entry timing belongs to PROFIT-TAIL,** and is bounded. See §4.
3. **The hard stop always wins.** PROFIT-TAIL's objective is to close in profit; it has
   no power to refuse to close a loser. Stop and risk gate override it absolutely.
4. **Every order re-enters the risk gate** — entries, adds, scale-outs, closes alike.
   PROFIT-TAIL has no direct line to execution. Exits are `reduce-only` so a close can
   never accidentally open the reverse position.
5. **It may request an add, never take one.** When a position is running, PROFIT-TAIL can
   signal "this one is in its tail, consider more"; the arbiter and risk gate decide like
   any fresh entry. It may never flip a position — a reversal is a new trade and belongs
   to the bulls and bears.

---

## 3. What "its own data and architecture" actually means

Independence at the **feature and model layer**, not the raw-data layer.

| Layer | Shared or separate | Why |
|---|---|---|
| Raw market data lake | **Shared, single source of truth** | Three ingestion paths means three bots silently disagreeing about what the price was. Reconciliation failures start here |
| Feature computation | **Separate namespace per bot** | This is where the independence lives |
| Model architecture | **Separate, free to differ** | Whatever wins its own bake-off |
| Training pipeline & retrain cadence | **Separate** | A 4-hour signal and an exit policy do not retrain on the same clock |
| Model registry entries | **Separate** | Independent promotion, independent rollback |
| Trial Registry | **Shared, joint trial count** | Trap 3 below. This one must not be separated |
| Risk gate · execution · ledger | **Shared** | No exemptions. Ever |

**Model choice is decided by evidence, not by preference.** Every bot bakes off deep
architectures against gradient-boosted trees and a mandatory linear baseline, on this
system's own data. Whatever wins out-of-sample gets capital. Deep learning is permitted
to win; it is not assumed to. The research position stands: boosted trees on good
features usually beat deep nets on financial data, and transformers lost to a one-layer
linear model on standard forecasting benchmarks.

Each bot is independently validated through the full promotion pipeline and carries its
own competency level. A bot at competency 2 does not get capital because its sibling is
at 5.

---

## 4. PROFIT-TAIL in detail

**Why it exists:** almost all of the return in a directional book comes from a small
number of large winners. Exiting those early is the most expensive habit a system can
have, and it is invisible — the trade still shows a profit. PROFIT-TAIL exists to get in
well, hold the tail open, and lock what has been won.

### Functions

| Function | Returns | Authority |
|---|---|---|
| `time_the_entry` | enter now / keep waiting, plus limit price | **authoritative**, bounded by signal expiry |
| `ratchet_profit_lock` | new lock level — monotone, favourable direction only | **authoritative** |
| `decide_position_action` | `HOLD` · `SCALE_OUT` · `CLOSE` · `REQUEST_ADD` | **authoritative**, post-fill only |
| `estimate_net_expectancy` | expectancy net of fees, funding, slippage, impact | advisory — feeds the arbiter |
| `estimate_loss_tail` | extreme-loss exposure: cascade, gap, liquidation distance | advisory — feeds arbiter and risk gate |
| `forecast_profit_tail` | distribution of forward P&L, not a point estimate | internal — drives the three authoritative calls |

### Entry timing — the joint policy

The arbiter has already selected the trade. PROFIT-TAIL decides the moment, on **two
signals together**:

- **Price level** — pullback, retest, or a level worth waiting for. Improves average
  entry and therefore every trade's tail.
- **Flow confirmation** — order-flow imbalance, absorption, momentum ignition. Evidence
  the move is actually starting, rather than a cheaper price in something that is dying.

Either can fire; the policy is learned jointly, not as two rules bolted together.

**The bound that makes this safe:** waiting has a deadline. Every signal carries a
time-in-force, already a P0 requirement in `FEATURES.md`. If it expires unfilled the
trade is abandoned and logged as a **missed entry attributed to PROFIT-TAIL**. Without
this, "not yet" becomes a silent rejection and the bot acquires the exact authority it
was denied. The missed-entry rate is a first-class monitored metric — a bot that misses
the biggest movers is failing at its stated job even while its fill prices look excellent.

### The profit lock

A ratchet, not a stop-loss:

- **Monotone.** Moves only in the favourable direction. It never widens, under any
  condition, for any model output. A lock that can loosen is not a lock.
- **Volatility-scaled, learned.** The distance is a function of realised volatility and
  the position's own path — not a fixed percentage. A fixed percentage is either
  strangling the tail or not protecting anything, depending on regime.
- **Mirrored venue-side.** The lock rests at the exchange as a `reduce-only` stop order,
  reconciled continuously against local state. **If the bot process dies, the lock must
  survive.** A profit lock that exists only in memory protects nothing during exactly the
  event where you need it.
- **Below it sits the hard stop**, owned by the risk gate, always active from the moment
  of fill, never moved by PROFIT-TAIL.

### Data it needs that BULL and BEAR do not

- **Realised path data** — the shape of the move after entry, not just its endpoint
- **Live microstructure at decision time** — the confirmation half of entry timing
- **Its own fill history** — actual entry price, actual slippage, actual fees paid
- **Funding accruals at real settlement times** — a held perp bleeds on a schedule
- **Its own past decisions and their counterfactuals** — what the trade would have
  returned had it held, and what the entry would have cost had it not waited. Without the
  counterfactual it only ever learns that its choice was fine, because it never observes
  the outcome it prevented

### Architecture candidates (all bake off against the baseline)

- **Survival / hazard model** over holding time — P(move dies in the next interval)
- **Quantile or distributional regression** on forward P&L — the tail is the point, so a
  conditional mean is the wrong target
- **Optimal stopping** — the exit problem in its exact classical form
- **Deep sequence models** over the position's own path and live flow

**Mandatory baseline it must beat:** immediate entry, fixed triple-barrier, ATR trailing
stop. Beat that out-of-sample or it does not get capital.

---

## 5. Traps this architecture creates

1. **Direction-filtered training data destroys calibration.** A BULL trained only on
   up-moves cannot emit a calibrated probability — it has never seen the negative class.
   BULL and BEAR train on **all** data; the specialisation lives in the objective and the
   action space, never in a filtered dataset. This is the easiest way to build two bots
   that are each 90% "accurate" and jointly worthless.

2. **A win-rate objective inverts the entire design.** Train PROFIT-TAIL on hit rate and
   it learns to cut winners early and hold losers — the precise opposite of harvesting a
   profit tail, and the reason the instinct "make sure trades close in profit" destroys
   accounts. **The objective is expectancy and tail capture, never win rate**, with the
   hard stop as a fixed constraint rather than something the model can trade against.

3. **Three bots inflate the search size.** Three model searches means roughly three times
   the trials, and false-discovery correction depends on the *joint* count. The Trial
   Registry counts all three together and the deflated Sharpe uses the joint number.
   Separate registries per bot would quietly restore the overfitting the gate exists to
   prevent.

4. **Credit assignment is now three-way.** A trade's P&L is direction, timing and exit
   mixed together. If BULL is scored on realised P&L it is being judged on a fill it did
   not control and an exit it did not choose. Therefore: **BULL and BEAR are trained on
   fixed triple-barrier counterfactual labels, never on realised outcomes**, and P&L
   attribution splits **signal alpha / timing alpha / exit alpha** as separate lines. The
   existing "P&L attribution by cost component" requirement extends to cover this.

5. **"Not yet" forever is a rejection.** Handled by signal expiry and the missed-entry
   metric in §4. Worth restating because it will re-emerge every time someone widens the
   time-in-force to improve fill quality.

6. **The lock must outlive the process.** Handled by the venue-side mirror in §4. A
   crash, a deploy, or a network partition must not unlock a position.

7. **Twin bots correlate.** BULL and BEAR over the same raw data anti-correlate
   trivially, and apparent agreement looks like confidence when it is shared input.
   Agreement is not confidence; the arbiter trains on the joint distribution.

**Stated cost:** three independent training and validation pipelines per brain is roughly
three times the compute, storage and operational surface of one. That is the price of the
design, and it is worth paying only if each bot clears its own promotion gate on its own
evidence.

---

## 6. Where this sits in the tree

Nine bots — all three per brain — plus a thin netting layer above them.

```
ROOT
├── BRAIN 1 (hours→minutes)
│   ├── BULL ────────┐
│   ├── BEAR ────────┼── ARBITER → PROFIT-TAIL (timing) → RISK GATE → EXEC
│   └── PROFIT-TAIL ─┘                 └── owns position after fill ──┘
├── BRAIN 2 (minutes→seconds)   [own three]
├── BRAIN 3 (sub-second)        [own three]
└── PORTFOLIO NETTING LAYER — nets exposure across brains, enforces total limits
```

**Why per-brain rather than one shared PROFIT-TAIL:** a 4-hour entry point is not a
4-second one, and the exit policy for a 4-hour hold is nothing like the exit policy for a
4-second hold. One model over all three horizons learns the horizon with the most data
and fails the others.

**Why the netting layer is not extra scope:** two brains taking opposite sides of the
same symbol pay fees both ways. Cross-strategy position netting is already a recorded
requirement; this design makes it load-bearing rather than optional.

---

## 7. Phasing

| Phase | State |
|---|---|
| P1 | **Brain 1 only.** BULL and BEAR as independent bots. Entry is immediate, exits run a deterministic policy — triple barrier plus ATR trail plus a monotone ratchet lock. Nothing goes live without an exit policy |
| P2 | PROFIT-TAIL trained on accumulated fill history, running in **shadow** against the deterministic policy. Entry timing and exit policy shadowed separately |
| P2→P3 | PROFIT-TAIL replaces the deterministic policy only by beating it out-of-sample through the promotion gate — per function, per position class. Timing may promote while exit does not |
| P3 | Brains 2 and 3 clone the proven pattern. Netting layer activates once a second brain holds capital |

The ordering is forced, not chosen: **an exit bot cannot be trained before there are fills
to train it on.** The deterministic policy is what generates its first dataset, and it
remains the permanent fallback if the learned policy is ever rolled back.
