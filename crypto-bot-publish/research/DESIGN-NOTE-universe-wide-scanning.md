# DESIGN NOTE — universe-wide scanning ("examination hall")

**Status:** evaluated 2026-08-02. **Verdict: 8/10 on the instinct, conditional on one empirical test.**
Belongs to the strategy/signal layer, not Layer 0 — but it produces **two unrecoverable Layer 0
requirements**, recorded at the bottom.

---

## The idea, as proposed

> Instead of picking symbols from the universe and trading them while skipping the rest — even
> though the skipped ones have profit potential — the brain tracks the **full universe** in each
> segment. Like a teacher in an examination hall who wants every student to pass: every symbol has
> potential, and the brain **waits for that symbol's exact setup** rather than pre-selecting
> favourites.

## The idea, stripped of metaphor

Selectivity moves from **space to time**. Not "pick K of N and trade them", but "watch all N, act on
any one only when its own condition fires."

The claim underneath: **the unit of edge is `(symbol, condition, moment)`** — not `(symbol)`, not
`(strategy)`. Most systematic design says "I have a momentum model, I apply it to a universe." This
says each symbol has moments when it becomes tradeable and the job is to be *present* for them.
That is event-driven-desk thinking rather than factor-quant thinking. A real architectural position.

---

## 1. The mechanism — use this framing, not "every symbol has potential"

"Every symbol can be profitable" does not pass the **"who loses when I win?"** test
(`IDEAS-INTELLIGENCE.md` §6). This does:

> **Attention scarcity.** Mid- and small-cap symbols get *episodic* coverage. Most of the time
> nobody competent is watching them properly. When something happens — unlock, listing, funding
> dislocation, liquidation cascade, venue-specific break — there is a window before adequate
> participants arrive. **A machine watching 500 symbols is structurally present for windows humans
> and small desks physically cannot cover.** Large funds ignore the region on capacity grounds;
> retail watches only what is trending. There is a genuine coverage gap in the middle tail.

That is a defensible, constraint-based mechanism with identifiable counterparties. **Put this in the
Mechanism Declaration; do not put "potential" in it.**

## 2. The mathematics — and the one question everything rests on

This is a **breadth play**. Grinold's fundamental law: **IR ≈ IC × √breadth**. If each symbol yields
~2 good setups per year, 500 symbols ≈ 1000/year ≈ 3/day. Breadth converts a weak, rare edge into a
tradeable business. The instinct maximises the correct term.

**But breadth means *independent* bets, not symbols.** Crypto cross-sectional correlation is severe;
500 symbols is largely one BTC factor plus noise. Naively, effective breadth could collapse from
500 to ~5–15 — which would gut the entire proposition.

The escape is precise:

- **Idiosyncratic setups** — unlock schedules, listing events, single-venue dislocations,
  symbol-specific funding — are **far more independent than price returns**.
- **Systematic setups** — volatility or momentum shaped — fire together in regimes, and effective
  breadth collapses toward 1.

> ### THE TEST — run before building anything
>
> Define candidate setups, fire them historically across the universe, and measure:
> 1. **Clustering of trigger times** (are triggers concentrated in a few periods?)
> 2. **Correlation of the resulting return streams**
>
> If triggers cluster and returns correlate, the architecture is **one macro bet wearing 500 hats**
> and must be redesigned. This is cheap and answerable in days. **It is the highest-value experiment
> available**, and it gates everything downstream.

## 3. The sharpest design constraint — the metaphor points the wrong way

One setup definition applied to 500 symbols is **not** 500 hypotheses. It is **one hypothesis with
500 correlated samples** — statistically *favourable*, more evidence for the same claim.

It becomes 500 hypotheses the moment **per-symbol tuning** is allowed.

> **RULE: the setup definition must be universal and parameter-free across symbols. Per-symbol
> variation comes only from *normalisation* — z-scores or percentiles against that symbol's own
> history — never from fitted per-symbol parameters.**

**The most attractive feature of the teacher metaphor — personalised attention, tailoring help to
each student — is the single most dangerous thing to implement.** Teachers individualise.
Individualising here destroys the statistical advantage that makes breadth work.

Keep the metaphor for the **posture** (willing to examine everyone, expects to fail almost all).
Discard it for the **method**.

Corollary on posture: a teacher maximises pass rate; you do not maximise symbols traded. The
teacher framing carries a built-in bias toward *action* when the correct default is **abstention**
(`IDEAS-INTELLIGENCE.md` §2). Better image: **an examiner willing to examine every student, who
fails almost all of them, almost always.**

## 4. The binding constraint is the opposite of the expected one

Intuition says the hard part is finding enough setups. It will not be. **Triggers cluster**, so the
real constraint is **having capital free when the good ones fire.**

Fully deployed in mediocre setups when an excellent one appears means the mediocre ones *cost* you
the excellent one. So the decision rule is not *"is this setup profitable?"* but:

> **"Is this setup better than the option value of waiting for a better one?"**

That is optimal stopping. Two consequences:

- **Dry powder has computable value** — it is not idle capital, it is a held option.
- **The acceptance threshold should RISE with opportunity flow.** The more symbols watched, the
  *pickier* each trade must be. Directly opposed to the teacher's instinct to pass as many as
  possible.

## 5. A new risk this design creates — manufactured setups

Breadth into thin books creates specific exposure. **A universe-wide scanner with deterministic
triggers is a target.** In a thin symbol, moving the book enough to fabricate the entry condition is
**cheap** — far cheaper than the position that can then be unloaded into you. This is
`IDEAS-STRATEGIC.md` §9 (data poisoning) made concrete, and **the broader and thinner the tail, the
cheaper it is to bait you.**

Mitigations:

| Defence | Why |
|---|---|
| **Corroboration across independent data types** | Require trade flow **and** funding **and** open interest — not one signal alone. Faking three at once costs much more |
| **Persistence requirements** | Conditions must hold for a duration, not fire instantaneously. Sustaining a fake is expensive |
| **"Why is this liquidity available to me?"** | An explicit pre-trade check, and it is sharpest exactly in the tail |
| **Randomised trigger latency** | Bounded jitter so entries are not exactly predictable (costs little, breaks exact timing attacks) |
| **Per-symbol tradability gate before the setup gate** | Cheap to evaluate, kills most bait candidates for free |

## 6. Other guards required

| Problem | Guard |
|---|---|
| **Correlation illusion** | 40 simultaneous triggers can be one bet. **Exposure limits bind at factor level, not per symbol** |
| **Capacity asymmetry** | The tail has the least competition *and* the least capacity. Needs a **minimum viable setup size**: expected profit must exceed all-in cost (fees + slippage + operational + inference) |
| **Watching cost** | Two-stage funnel — cheap coarse screen across the whole universe, expensive evaluation only on candidates. Mirrors the router pattern (`IDEAS-AI-FIELD.md` XI) |
| **Trial accounting** | Every scan counts in the Trial Registry, corrected on both axes — trial count *and* effective sample size (`IDEAS-SYNTHESIS.md` Part I) |
| **Per-symbol edge lifecycle** | Hazard models (`IDEAS-SYNTHESIS.md` Part II) apply **per symbol**: a symbol's setup can die while others live |

---

## Verdict

**8/10 on the instinct, conditional on the §2 test.**

**Why it rates well:** it is not an arbitrary idea — it **follows from the comparative advantage**
already established in `IDEAS-STRATEGIC.md` §2. Capacity-irrelevance and patience are monetised
through *breadth*; concentration would mean competing on the axis where a solo operator is weakest.
Coherence with positioning is rarer than good ideas are.

**Why conditional:** the whole value rests on setup idiosyncrasy, and that is measurable before any
building begins.

**Recommended shape:** universe-wide always-on scanning · per-symbol tradability gate · universal
parameter-free setup definitions with own-history normalisation · event-triggered entry ·
corroboration + persistence requirements · every scan counted as a trial · exposure capped at factor
level · threshold that rises with opportunity flow · default action **stand aside**.

---

## CONSEQUENCES FOR LAYER 0 — both unrecoverable if missed

These are the reason this note exists now rather than later.

### R1. The broad tail must be genuinely broad

The tiered capture decision (deep L2 core + broad tail) already selected the right shape. This idea
**raises the value of tail breadth specifically**. Widening the tail is cheap today and impossible
to backfill. **Do not settle for a token 20 symbols** — capture trades / funding / open interest /
liquidations across as wide a universe as the venues stream and storage allows.

### R2. Point-in-time universe membership must be recorded

**The subtle one, and it is invisible if missed.** Backtesting "watch every symbol" against
*today's* symbol list silently conditions on survival — the universe would exclude everything that
died. That is **survivorship bias entering through the universe definition rather than through
prices**, and no purge/embargo scheme catches it.

The recorder must therefore capture, as first-class events with timestamps:

- **Listings** — when a symbol became tradeable
- **Delistings** — when it stopped
- **Symbol renames and contract migrations**
- **Status changes** — trading halts, maintenance, settlement changes

Trivial to record now. **Impossible to reconstruct later**, because exchanges do not publish
historical universe membership reliably and third-party reconstructions are exactly the kind of
unverifiable secondary source this project has already been burned by once.
