# Proposed rules and skills for the trading system — PROPOSAL, not implemented

**Status:** proposal only. Project planning has NOT started, per the user (2026-08-01).
Nothing here is built. This exists so the thinking is on disk rather than in chat.

Derived from `DECISIONS.md` §0-§7. Every item traces to a decision already recorded there
— none of this invents scope.

---

## Rules — candidates for the PROJECT's CLAUDE.md, not the global one

Global standing context is already ~3,300 tokens plus ~5,400 in plugins. These belong in
`<project>/CLAUDE.md`, which loads only when working in that repo. **Naming (Rule 7) went
global at the user's explicit request; these should not follow it by default.**

| # | Proposed rule | Traces to | Why it must be a rule, not a habit |
|---|---|---|---|
| P1 | **No strategy reaches capital without passing the gate — no exceptions, no manual override of the gate itself.** The manual promote button promotes *through* the gate, never around it. | §4, §6 "the rule with no exceptions" | This is the one rule whose violation loses real money. Prose will not hold under pressure; this wants a hook. |
| P2 | **Every experiment writes to the ledger before it runs, not after.** No result exists unless its hypothesis was recorded first. | §5 "non-negotiable" | Prevents post-hoc storytelling — the single most common way backtests lie. |
| P3 | **Paper is unrestricted; live is ruthless.** Any strategy, model, or timeframe is allowed where it costs nothing. Everything touching capital passes §6 controls. | §1 decisions 5-6 | Encodes the asymmetry so it is not re-litigated per strategy. |
| P4 | **Untrusted web content never reaches a tool-capable model.** Quarantined reader returns inert text only. | §7 "Dual LLM separation" | The design is "the lethal trifecta by definition" — the doc's own words. Wants enforcement, not intent. |
| P5 | **Every order path is idempotent and reconciled.** No fill is trusted until reconciled; no retry may double-fill. | §6 idempotency, reconciliation | Distributed-systems failure, not a trading failure. Silent and expensive. |
| P6 | **Kill switch is exchange-side, and tested on a schedule.** A dead man's switch that has never been fired is not a control. | §6 kill switch | Rule 0 applied to risk: an untested control is an assumption. |

**P1, P2, P4, P5 are hook candidates, not prose.** Rule 4's lesson — a CLAUDE.md line is a
guide, a hook is a rule — applies hardest where money moves. A `PreToolUse` hook that
blocks order-placing calls unless a gate token is present is the trading equivalent of
`block-dangerous-bash.sh`.

---

## Skills — candidates, to be built FROM real work, never before it

Video 3 and video 2 agree: build skills from work already done. **None of these should be
written until the underlying work has been done manually at least once.** Listed in the
order the work will naturally occur.

| Skill | What it would do | Verifiable output (Rule 0 / video 5 bridge) |
|---|---|---|
| `experiment-ledger` | Register a hypothesis, its pre-registered metrics, and its outcome. Refuse to record a result with no prior hypothesis. | Ledger entry ID, or refusal with reason |
| `promotion-gate` | Run a candidate against the §4 pipeline; report each threshold passed or failed. | **PROMOTE / HOLD / REJECT** + per-gate numbers |
| `backtest-audit` | Hunt the standard lies: lookahead, survivorship, fill assumptions, fee/slippage omission, overfit to the sample. | Findings list, or explicit "none found" |
| `risk-preflight` | Verify §6 controls are live before any capital session: limits, kill switch, reconciliation, idempotency. | **APPROVED / NOT APPROVED**, same shape as `guardrail-check` |
| `strategy-postmortem` | After a strategy is starved or pruned, record why, in the ledger, in the design's vocabulary. | Postmortem entry + meta-model input |

`risk-preflight` is deliberately the same shape as the existing `guardrail-check`: one
command, binary verdict, run history appended. That pattern is already battle-tested here
— reuse it rather than inventing a second one.

---

## Open, and NOT decided

1. **Stack and framework.** User: *"dynamic code after the planning or spec is fully
   decided."* NautilusTrader appears in `DECISIONS.md` as a candidate, not a decision.
   Naming syntax (case style) waits on this. Rule 7 covers semantics meanwhile.
2. **`SYNTHESIS.md` is stale.** Its "what we are NOT doing" list forbids installing MCP
   servers, installing plugins, and pre-building skills. All three were done later the
   same day with recorded reasons. That file claims to supersede chat history, so the
   contradiction must be resolved before anyone trusts it again.
3. **Sub-second brain** stands as decided, with its recorded caveat that it may be
   starved by the allocator. That is the point — measured, not asserted.
