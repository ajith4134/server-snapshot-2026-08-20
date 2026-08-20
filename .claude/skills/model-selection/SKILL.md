---
name: model-selection
description: Choose the right Claude model and effort level for a task — both for subagents being spawned and for the user's own model picker in the Claude app. Use when delegating work, when deciding whether a task needs Fable or Opus, when a task is failing and escalating tiers is being considered, when picking an effort level, or when the user asks which model to use for something. Carries Fable's hard API constraints and the escalation protocol.
---

# Model selection

Two audiences, one decision procedure: which model does this task need, and at what effort.

**Posture: narrow.** Fable is an escalation, not a default. Decided 2026-08-01 — the default is
Opus 5, and Fable is reached for only after Opus 5 has demonstrably fallen short. Reason below.

## The ladder

| Model | ID | Context | $/Mtok in / out | Position |
|---|---|---|---|---|
| Fable 5 | `claude-fable-5` | 1M | $10 / $50 | Highest capability released publicly |
| Opus 5 | `claude-opus-5` | 1M | $5 / $25 | **The default for hard work** |
| Sonnet 5 | `claude-sonnet-5` | 1M | $3 / $15 ($2/$10 intro through 2026-08-31) | Execution once the target is clear |
| Haiku 4.5 | `claude-haiku-4-5` | **200K** | $1 / $5 | Mechanical only |

Prices are API list, for **ratios only** — the Max plan bills against a usage allowance, not dollars.
Fable is 2x Opus 5 and 3.3x Sonnet 5 on output.

**On Max, Fable costs no money — it costs allowance.** Verified 2026-08-01: since 2026-07-20, Max
plans and premium Team seats include Fable 5 as standard, usable up to **50% of weekly usage limits
at no extra cost**. Only Pro and standard Team seats pay usage credits for it. So the real constraint
on escalating is the weekly allowance and the 50% ceiling, not a surcharge — which is exactly what
Rule 1 already optimizes for.

## Why Fable is not the default

**Opus 5 took most of Fable's ground.** Opus 5 is a step-change over Opus 4.8 on deep reasoning,
agentic and long-horizon work — at **half Fable's price**. Fable remains the top tier, but the gap
it used to fill is much narrower than it was even in mid-July 2026.

**And model choice is the smaller lever.** See the measurement below.

## The measurement — 2026-08-01

Rule 1 was an assertion until this. Summed `message.usage` across every subagent transcript:

```
2,158 subagent messages, all claude-sonnet-5
  in 697,654 │ out 647,393 │ cache read 111,825,782 │ cache write 15,769,070

  as run (sonnet):  $104.49      list-price equivalent
  if opus:          $174.14      → Rule 1 saved 40%
  if haiku:          $34.83
```

**The rule holds — but the headline is the second number: 87% of all subagent tokens were cache
reads**, billed at 0.10x. Cache economics dominate tier choice. **Fewer, longer-lived agents beat
many cold ones**, because a fresh agent pays full price for context a warm one reads at a tenth.
That is a bigger lever than moving one tier down the ladder.

**To re-measure**, sum `message.usage` over `~/.claude/projects/**/subagents/*.jsonl` with `jq`,
grouped by `message.model`. The `claude-burn` script on PATH **cannot** do this — it explicitly
skips any path containing `subagents/`, so it reports subagent spend as `$0.00` and measures only
the main-thread half of the bill, which is the half Rule 1 does not target. See the
`burn-cost-tooling` memory.

## Decision procedure

Ask what the hard part is, not how big the task looks.

| The hard part is… | Use |
|---|---|
| Retrieving, listing, locating, mechanical transformation | `haiku` — 200K context, no effort dial (see below) |
| Writing code whose **shape is already decided** | `sonnet` |
| Research, docs lookup, web search | `sonnet` |
| Code reading that needs comprehension or judgment | `sonnet` |
| **Deciding what to write** — new module, interfaces, data model, trade-offs | `opus` |
| Architecture, hard debugging, final review, synthesis | `opus` |
| Opus 5 already tried and demonstrably fell short | **escalate to `fable`** — see below |

The split for code creation is never how *much* gets written. It is whether the hard part is
WRITING it or DECIDING what to write.

## Effort

Five levels: `low`, `medium`, `high`, `xhigh`, `max`. **Default is `high`.** `xhigh` sits between
`high` and `max` and is the best setting for most coding and agentic work — it is Claude Code's own
default.

**The Claude app exposes all five — parity with the API is exact** (verified against the Help
Center, 2026-08-01). There is no reduced consumer set. Effort is available on Opus 5, Sonnet 5,
Fable 5, Opus 4.8/4.7/4.6, and Sonnet 4.6.

**Haiku 4.5 has no effort dial at all** — but it is not thinking-incapable. It supports *extended*
thinking via a toggle; it does not support *adaptive* thinking, and effort errors on it. So "Haiku
can't reason" is wrong; "Haiku's reasoning can't be tuned with effort" is right.

**On Opus 5, start high and sweep DOWN.** Begin at `xhigh` for coding/agentic and `high` elsewhere,
then test lower — `low` and `medium` are unusually strong on this model and often beat prior
models' `xhigh`. Effort defaults carried over from an older model are rarely right.

**At `xhigh` or `max`, set `max_tokens` to at least 64K.** Effort raises thinking spend, and
`max_tokens` caps thinking *plus* response text together — a tight budget truncates mid-answer.

Do **not** try to shorten output by lowering effort. It moves thinking volume without reliably
changing visible length. Use a conciseness instruction instead.

## Escalating to Fable — the protocol

1. **Run it on Opus 5 first**, at `xhigh` or `max`.
2. **Escalate only on a demonstrated shortfall** — a wrong answer, an incomplete design, a run that
   stalled. "This looks hard" is not a shortfall. "It might be safer" is not a shortfall.
3. **Record the escalation** in `~/.claude/fable-escalations.md`: the task, what Opus 5 produced,
   why it was insufficient. Without that record there is no way to tell later whether escalating
   was justified or reflexive.
4. **Do not pay twice on a known-hard task.** If a task class has already escalated more than once
   for the same reason, go straight to Fable for that class and note it — Rule 1's do-not-pay-twice
   clause. The log is what makes this visible.

## Fable's hard constraints — encode these, do not discover them

- **Thinking is always on.** `thinking: {type: "disabled"}` returns 400. `{type: "enabled",
  budget_tokens: N}` returns 400. Omit the parameter; control depth with `effort`.
- **No assistant prefill** — a last-assistant-turn prefill returns 400. Use structured outputs
  (`output_config.format`) or a system-prompt instruction.
- **Requires 30-day data retention.** Not available under zero data retention — a non-compliant org
  gets `400 invalid_request_error` on **every** request, with a perfectly valid payload. Check
  retention config before debugging the request body.
- **Safety classifiers can refuse.** Returns HTTP 200 with `stop_reason: "refusal"` and a
  `stop_details` category — notably `cyber` and `bio`. Check `stop_reason` **before** reading
  `content`; code that indexes `content[0]` breaks on a refusal. Opt into the `fallbacks` parameter
  so a decline is re-served rather than lost.
- **Turns run for minutes.** 15+ minutes on a single hard request is normal. Plan timeouts,
  streaming, and progress UX — do not block a user-facing path on one.
- **Raw chain of thought is never returned.** `display: "summarized"` gives a summary; the default
  `"omitted"` leaves thinking text empty.
- Same tokenizer as Opus 4.8 — token counts are roughly unchanged coming from Opus 4.7/4.8.

## Prompting Fable differently

**De-prescribe.** Prompts and skills written for weaker models are often too prescriptive for Fable
and actively *reduce* output quality. State the goal and the constraints; do not enumerate the
steps. If a prompt migrated from another model underperforms, strip the step-by-step scaffolding
before concluding the model is wrong.

**Give it the reason, not just the request.** It connects the task to relevant context rather than
inferring intent. *"I'm working on X for Y, who needs Z. With that in mind: <request>."*

**Start at the top of the difficulty range.** The best outcomes come from handing it the hardest
unsolved problem first — let it scope, ask questions, then execute.

## Opus 5 behaviors worth knowing (it is the default, so these apply constantly)

- **Thinking is ON by default** — omitting `thinking` runs adaptive, unlike Opus 4.8. Routes that
  never set it now spend thinking tokens; revisit `max_tokens`.
- **Disabling thinking is capped at `high` effort.** `disabled` + `xhigh`/`max` returns 400.
- **It delegates more readily than Opus 4.8** — the opposite direction from its predecessor. Cap
  subagent spawn counts explicitly; each one re-establishes context and pays cold-cache prices.
- **It verifies its own work.** Delete verification instructions and harness verification steps —
  telling it to double-check now causes over-verification with no capability gain.
- **Prompt-cache minimum is 512 tokens** (down from 1024 on Opus 4.8) — prompts previously written
  off as uncacheable may now cache.
- **Separate rate-limit bucket** from the combined Opus 4.x pool.

## Picking in the Claude app

Same ladder, same test — is the hard part writing it or deciding it. Effort stays at `high` unless
there is a reason; `xhigh` for hard coding, `max` only when correctness outweighs time.

**The workflow that beats picking one model:** Opus 5 to think the problem through and produce the
plan, then Sonnet 5 to execute the settled steps. The expensive tier decides; the cheap tier types.

---

# Run-time routing — models *inside* a running system

Everything above is dev-time: which model writes the code. A system that calls models while it runs
has a second routing problem, and it is governed by **latency and trust, not cost**.

## Latency sets the ceiling before capability does

| Decision cadence | Viable |
|---|---|
| Hours → minutes | Opus 5 per decision is affordable |
| Minutes → seconds | Sonnet 5 at `low` effort, marginal |
| **Sub-second** | **No LLM in the path at all** |

Fable turns run **15+ minutes**; even Haiku is hundreds of milliseconds. A sub-second path must be
compiled numerics and pre-trained models. **An LLM call in a sub-second loop is an architectural
error, not a tuning problem.** The LLM's role at that tier is building and evolving the model
offline — never invoking it in the hot path.

## Route by trust, not just capability

**A quarantined reader gets the cheapest adequate tier — `haiku` or `sonnet` — never `opus` or
`fable`.** In a Dual-LLM split, the component that ingests untrusted external content has no tools
and no credentials and returns inert text. Escalating its tier buys nothing and widens the blast
radius. It also runs constantly, so cost compounds where it matters least.

Reserve the expensive tiers for the components that *reason over* what the quarantined reader
returned, which are the ones actually holding capability and credentials.

## Where Fable genuinely earns it at run time

Offline, detached from any latency budget, long-horizon, open-ended: **overnight discovery loops
and meta-analysis over an accumulated result ledger.** Finding where the gaps are across thousands
of prior runs is Fable's documented strength, and it is the one run-time role where escalation is
likely to be justified rather than reflexive.

## ⚠️ Retention may cap Fable regardless of capability

**Fable requires 30-day data retention and is unavailable under zero data retention** — a
non-compliant org gets 400 on every request, with a valid payload.

For any system whose value is proprietary (trading alpha, discovered strategies, internal models),
routing that material through a tier with mandatory 30-day retention is a **policy decision, not a
performance one**. Opus 5 carries no such requirement. Settle this before the escalation protocol
ever fires — otherwise the first genuine shortfall becomes an argument about data policy under time
pressure.

Related: Fable's classifiers refuse on `cyber` and `bio` categories. Security tooling built
*around* a system can trip them even when the system itself is unrelated.

## Two corrections to the video this came from

The source video (Eliot Prince, 2026-07-16, credibility assessed in
`~/research/eliot-prince-credibility.md`) got the workflow advice right and two mechanisms wrong:

1. **Effort has five levels, not three.** It presents low/high/max and omits `medium` and — more
   importantly — **`xhigh`**, the recommended setting for coding and agentic work. This is not an
   app-vs-API difference: the app exposes all five.
2. **"Extended thinking" is the wrong name** for what it describes. Letting Claude decide how much
   to reason is **adaptive thinking**. Manual extended thinking (a fixed `budget_tokens`) is the
   deprecated mechanism, removed on current models and returning 400. (Confusingly, *extended*
   thinking is the correct term for Haiku 4.5's toggle — it is adaptive thinking that Haiku lacks.)
3. **"After July 19 you pay extra for Fable" is only true on Pro.** On Max it stays included up to
   50% of weekly limits. The video collapses two plan behaviors into one.
4. **"Version numbers don't really mean anything"** is misleading. Anthropic documents a structured
   scheme — `claude-{name}-{major}[-{minor}]` — and model IDs are **pinned immutable snapshots**:
   weights are never updated under an existing ID. What is genuinely undocumented is the *semantic
   magnitude* of a major vs minor bump; that claim appears only on third-party blogs.

**In fairness to the source: it was accurate when published.** Video published 2026-07-16; **Opus 5
launched 2026-07-24**. It aged out in eight days. Its picker tops out at Opus 4.8, which is why its
Fable advice is more aggressive than this skill's — before Opus 5, Fable was a bigger step up.
