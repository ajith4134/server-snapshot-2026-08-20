---
name: trading-bot-intelligence-standard
description: "The user's standing requirement for the crypto trading bot — real learning, reasoning and depth, judged on three axes, never restated by them"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: bf5a5150-d785-455c-af49-9be1126ba144
  modified: 2026-08-08T08:58:48.993Z
---

The user requires the autonomous crypto trading system to contain **real learning, real reasoning
and real depth — not hardcoded values with intelligent-sounding names**. They stated it on
2026-08-08 and then asked that it be recalled permanently so they never have to raise it again.

**Learning and reasoning are separate axes.** They clarified this explicitly: *"not only learning but
also real intelligence."* A model retraining hourly learns; it does not reason.

**Why:** they have been sold "AI" before. Their own prior system lost **$837 over 10,240 live
trades** because a feature-governance controller credited bot-wide P&L to all 36 features and
deactivated all of them twice in production. Several prior subsystems read as built and were not —
`ai-scientist/` and `fable5/` are session logs, five circuit breakers exist only in docstrings, a
Dreamer rollout rewards itself with `np.random.normal`.

**How to apply:** the binding standard with 23 mechanical tests is **§1a of
`trading-system/docs/superpowers/specs/2026-08-08-final-project-goal-design.md`**. The sourced
evidence behind it — every claim traced to a primary source — is
**`~/research/ADVANCED-INTELLIGENT-CODE.md`**. `trading-system/CLAUDE.md` is an index pointing at
both, and loads automatically in that repo.

**Do not re-derive it and do not summarise it from memory.** The user corrected exactly that on
2026-08-08: a paraphrase written from memory becomes what future sessions read, in place of the
research. Read the source. The three tests carrying most of the weight:

1. **Provenance + ablation** — show the fitting process that produced the values, then freeze or
   remove the component and show measured behaviour changes.
2. **Falsifiable side-prediction** — the claimed mechanism must imply another checkable consequence,
   checked on data never used to fit it.
3. **Interface-to-implementation ratio** — public symbols against lines of implementation behind them.

Every module ships with an axis verdict; *not applicable* is allowed, blank is not.

Governed by one master test from their corpus: **does it change what the system does when it is
wrong?** Anything that only helps when the system is already right is decoration.

Never soften the honest boundary into a sales pitch: no architecture in 2026 produces understanding.
What is reachable is the distance between a script and an adapting system.

Related: [[trading-bot-goal-and-ledger]]
