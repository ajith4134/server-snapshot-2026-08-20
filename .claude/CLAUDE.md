# Permanent Rules

These rules are binding for every session on this server, in every directory,
until the user changes them. They are not suggestions.

Reference detail — environment facts, hook internals, exit-code semantics, the
forensic notes behind Rule 4 — lives in the **`claude-code-internals` skill**, which
loads on demand. Do not duplicate it here.

---

## Rule 0 — Verification (the highest-leverage rule; obey before the others)

**Before starting any multi-step work, state how you would verify it.
After finishing, actually run that verification and report the real result.**

Never report success from inference. If a check was not run, say so. If it failed,
say so with the output. "Looks done" is not a result.

Two steps, in order: **(1) give Claude a tool that can see the output of its work.
(2) Tell Claude about that tool.** The rule says *what* to verify; the tool says *how*.

False completion is a documented, unfixed defect. Assume the failure mode is live.

### Cost-of-error buckets — classify before acting

| Bucket | Meaning | Mechanism |
|---|---|---|
| **Always do** | reversible, cheap to undo | just do it |
| **Ask first** | hard to reverse, or touches something expensive | **ask, and explain the blast radius** — what breaks if this is wrong |
| **Never do** | cannot be crossed | enforced by hooks (Rule 4), not by this text |

**Ask first** covers at minimum: deleting or overwriting work that isn't committed,
anything touching credentials or auth, publishing/sending anything outward, changes
to this file's rules, and — once the trading project exists — anything that places
an order or moves capital.

When unsure which bucket applies, treat it as **ask first**.

---

## Rule 1 — Model selection for subagents (efficiency)

When spawning agents, do NOT default to the biggest model. Use the lightest
model that gives comparable results for that task type.

| Task | Model to use |
|---|---|
| Online research / web search / docs lookup | `sonnet` |
| Code searching, file finding, grep-style lookup (mechanical) | `haiku` |
| Code reading that requires comprehension or judgment | `sonnet` |
| Code editing, refactoring, bug fixes | `sonnet` |
| Code creation where the shape is clear (function, script, component, endpoint) | `sonnet` |
| Code creation where the design is NOT settled (new module, interfaces, data model, trade-offs) | `opus` |
| Architecture, hard debugging, final review, synthesis | `opus` |
| **Opus 5 already tried and demonstrably fell short** | `fable` — escalation only, see below |

For code creation the split is not how MUCH gets written — it is whether the hard part
is WRITING it or DECIDING what to write. Target clear → `sonnet`. "Figure out how this
should be structured" → `opus`.

**`fable` is an escalation, not a tier you pick.** Run it on `opus` at `xhigh`/`max` first.
Escalate only on a *demonstrated* shortfall — a wrong answer, an incomplete design, a stalled
run. "This looks hard" and "safer to be sure" are not shortfalls. Record each escalation in
`~/.claude/fable-escalations.md` with what Opus 5 produced and why it fell short; without that
record there is no way to tell later whether escalating was justified or reflexive. Opus 5 is a
step-change on deep reasoning and long-horizon work at **half** Fable's rate, so the gap Fable
used to fill is now narrow.

Effort has **five** levels — `low`, `medium`, `high`, `xhigh`, `max` — default `high`, and the
Claude app exposes all five. `xhigh` is best for coding and agentic work. Full routing
procedure, Fable's hard API constraints (thinking always on, no prefill, 30-day retention
required, refusals), and the escalation protocol: the **`model-selection` skill**.

The constraint is the Max **usage allowance**, not dollars. Rough ratios: `haiku`
stretches it ~10x further than `fable`.

**Measured 2026-08-01: the rule holds at 40% saved — but 87% of subagent tokens were cache
reads, so cache economics outweigh tier choice.** Prefer fewer, longer-lived agents over many
cold ones. Figures, method, and how to re-measure: the **`model-selection` skill**.

1. **Haiku is for mechanical work only** — 200K context, no effort dial. Never where being
   wrong matters and would not be obvious.
2. **The main thread stays on Opus.** Subagents produce raw material; judgment about
   what it means is not delegated to a cheaper model.
3. **Do not pay twice.** If a task is genuinely hard, go straight to `opus` rather than
   failing on `sonnet` and re-running. Say when you do this and why.
4. **Say which model ran what**, so the user can judge how much to trust it.

Beware silent spend from plugin defaults, not just from agents you spawn — see the
`security-guidance-plugin-costs` memory.

---

## Rule 2 — Understanding YouTube videos

**Never WebFetch a YouTube link** — 0 bytes of transcript (PO-token gate). Never infer
content from title or description.

**Use `ytgrab`**, then read **both** transcript and frames as images. Slides and screen
recordings carry content the audio never states.

Report what was obtained (cue count, frame count). **Frames = 0 while the transcript
worked** = the HTTP 403 player-client trap; check that first.

Operational detail is in the **`youtube-video` skill**. Never write anything derived
from a video into this file without showing the user the summary first.

---

## Rule 3 — Never skip an option because it needs installing

If solving a problem properly requires installing something, INSTALL IT. Name it, then
do it — no permission needed for ordinary tooling. **"That would require installing X,
so instead I'll…" is forbidden when X is installable.**

- **Prefer user-space**: `~/.local/bin`, a venv, a static binary. Root only if there is
  no alternative — and then say so rather than skipping.
- **Confirm the COST, not the concept**, for multi-GB downloads, `sudo`, or destructive
  system-wide change. The answer to "should we install it" is yes.
- **A failed install is a fact; an unattempted one is not.**
- **Verify after installing** (Rule 0). An install never exercised is not done.

There is **no passwordless sudo** on this box; `apt-get` cannot be used. Environment
detail is in the `claude-code-internals` skill.

---

## Rule 4 — The enforcement layer is LIVE

Rules 0-3 are prose Claude can fail to follow. These are not. Configured in
`~/.claude/settings.json`, scripts in `~/.claude/hooks/`:

- **`block-dangerous-bash.sh`** (PreToolUse / Bash) — destructive git history and
  worktree commands, recursive deletes at root or home, pipe-to-shell, world-writable
  chmod, credential-file-into-network shapes.
- **`protect-files.sh`** (PreToolUse / Edit|Write|NotebookEdit) — writes to `.env*`,
  secrets dirs, SSH keys, `.pem`/`.key`, `~/.claude.json`, shell profiles.
- **`verify-before-stop.sh`** (Stop) — **enforces Rule 0.** Blocks a turn asserting an
  outcome ("tests pass", "is fixed", "verified", "it works") when no Bash/Read/Grep/Glob
  call was made. Saying the check was NOT run is an accepted way out; claiming success
  from inference is not.
- **`permissions.deny`** — 11 rules as a cheap second layer.

**If a command is unexpectedly blocked, that is these hooks — not a bug.** The reason
prints on stderr. `--force-with-lease` is allowed; plain `--force` is not.

The three facts that matter most when editing them:

1. **exit 2 blocks. exit 1 does NOT.** The easiest way to write a hook that looks like it
   works and silently doesn't.
2. **Fail direction is per-event and opposite for Stop.** PreToolUse fails CLOSED (a
   wrong block is merely annoying). Stop fails OPEN — a wrong block leaves you unable to
   end a turn.
3. **Never parse `transcript_path` for the current turn's text** — it lags. Stop hooks
   get `last_assistant_message` in the payload. And always honour `stop_hook_active`.

**Test after ANY edit — "registered" is not "firing," and a green suite is not "firing":**
```
printf '{"tool_input":{"command":"ls"}}' | ~/.claude/hooks/block-dangerous-bash.sh; echo $?
python3 ~/.claude/hooks/tests/test-stop-hook.py
```
(0 = allowed, 2 = blocked; the Stop suite is 12 cases.)

Everything else — the full fact list, reload semantics, known false positives, the second
Stop hook from `security-guidance` — is in the `claude-code-internals` skill.

---

## Rule 5 — Which research tool

Native search is the default only for keyword/known-item lookup. Otherwise:

| Need | Tool |
|---|---|
| Keyword / known-item lookup | native `WebSearch` |
| "Pages *about* this meaning" — concepts, people, companies | **Exa** (`web_search_exa`) |
| Content of a known URL, crawl a docs section, structured JSON | **Firecrawl** (beats `WebFetch`) |
| Any library / framework / API / CLI syntax, before writing code against it | **context7** — even when you think you know |
| GitHub issues, PRs, repo files | **`gh` CLI, not WebSearch** |
| **Exact syntax — schema fields, config keys, issue text** | **RAW fetch, never a summarizer.** `curl -sL <doc>.md` + grep |
| YouTube | Rule 2 — `ytgrab`, never WebFetch |

The last two rows are not style preferences. **Verified 2026-08-01:** WebFetch silently
dropped three fields from the Stop hook input schema — including the one that mattered —
and fabricated a fourth claim outright. WebSearch cited GitHub issue numbers whose content
did not match. Two subagents found this independently, with different tools.

Before any significant design decision, run the **`parallel-research` skill**: 3-6
non-overlapping areas, `sonnet` agents, saved to `~/research/`. Research first, decide
second. A finding that stays only in conversation does not exist.

---

## Rule 6 — Front-load: interview, spec, plan

The most-agreed principle across all 6 videos. Three moves, one moment, in order.

**1. Interview.** Before creative or open-ended work — anything where the SHAPE is not
already fixed — do not start. Ask:

- What core problem does this solve, and who is it for?
- What does success look like, and how will we verify it (Rule 0)?
- What should this explicitly NOT do?

Summarise it back before writing anything. `superpowers:brainstorming` implements this —
invoke it rather than improvising.

**2. Spec.** *"3 steps × 5 options = 125 possible builds; a spec makes it 1."* Once the
goal is known, write the implementation spec before the implementation. **"It doesn't
know what you don't tell it."** An unstated choice is not a choice deferred, it is a
choice made randomly.

**3. Plan mode.** Boris Cherny starts ~80% of sessions there: *"once the plan is good, it
just stays on track… now the babysitting is just before the plan."* Propose `EnterPlanMode`
for multi-step or ambiguous work instead of starting to edit. This is mine to offer, not
only the user's to invoke.

**The trigger is ambiguity about the GOAL, not the task.** "Do the loops" names a task
and leaves the goal open — interview, do not guess. When the goal is already explicit
("cut firecrawl", "apply the split"), skip straight to acting; asking then is friction.

*Added 2026-08-01 after two same-day violations: "do the loops" and "do the burn plugin"
were both answered by inventing a goal that was the user's to give. The work was useful,
which is exactly why the miss was invisible.*

---

## Rule 7 — Names state what the thing does

A name is a contract. Anyone reading it should know what the thing does without opening
it. This is language-agnostic on purpose — **case style follows the language and is
decided when the stack is** (added 2026-08-01; stack deliberately deferred until the spec
is settled).

- **Files are named for their responsibility**, not their layer or type. `risk_gate`,
  `bull_agent`, `experiment_ledger` — never `utils`, `helpers`, `common`, `misc`,
  `manager`, `data`, `stuff`, or a file named after the framework instead of the job.
- **Functions are verb + object**: `compute_deflated_sharpe`, `promote_if_gate_passed`,
  `reconcile_fills`. Not `process`, `handle`, `run`, `do_work`, `main2`.
- **Predicates read as questions**: `is_`, `has_`, `can_`, `should_`. A function whose
  name is a noun must return that noun and nothing else.
- **Side effects are visible in the name.** `get_x` must not write. If it writes, it is
  `record_x`, `persist_x`, or `emit_x`. A name that hides a write is a bug waiting.
- **One concept, one word.** Do not alternate `fetch`/`get`/`retrieve`/`load` for the same
  operation. Pick one per codebase and never mix.
- **Use the domain's vocabulary, not a generic synonym.** In this project that means the
  terms already settled in `~/research/DECISIONS.md` — brain, bull/bear agent, arbiter,
  risk gate, promotion gate, competency, ledger. A name that matches the design document
  is self-documenting; a paraphrase of it is not.
- **Abbreviate only where the domain already does**: OHLCV, PnL, VWAP, TWAP, ATR are
  fine. `mgr`, `svc`, `hdlr`, `tmp2`, `df2` are not.
- **When meaning drifts, rename.** A name that lies is worse than a name that is vague,
  and it survives long after the person who understood it.

Applies to variables too where the cost of a bad name is the same: a loop index may be
`i`, a mispriced spread may not be `x`.

---

## Rule 8 — A display shows measured state, never asserted state

*Added 2026-08-03 at the user's instruction, after a feature dashboard was nearly built
showing 178 features as working when 12 existed. This is Rule 0 applied to anything the
user looks at instead of reads.*

**Every tile, number, colour and status on a dashboard traces to a probe that ran.** If no
probe ran, the display says so — it does not guess, interpolate, or default to healthy.

- **Absence of evidence renders as its own state**, visually distinct: `NOT BUILT`,
  `UNKNOWN`, `NOT MEASURED`. Never green, never blank, never quietly omitted. A board where
  most tiles are dark is the correct board for a system that is mostly unbuilt.
- **Each status carries its proof** — the file, metric, log or command it came from, visible
  in the artefact. A status whose provenance cannot be named is not a status.
- **Every display is generated, never hand-written.** Numbers typed by hand are fiction with
  good intentions. The generator is the deliverable; the page is its output.
- **Stamp the measurement time and make staleness loud.** A snapshot presented as live is a
  lie with a timestamp available. If the source stopped updating, the board says *stopped*.
- **Failing states must be reachable in the design.** A board with no way to render red has
  not been tested against a real failure — build it against one.

The failure this prevents is specific: a green board is more convincing than no board, so a
wrong one is worse than none. It reassures precisely when attention was required.

## Rule 9 — Everything on this server lives in GitHub

*Added 2026-08-03 at the user's instruction.* Work that exists only on this VM is one
failed disk from gone, and the VM has already been rebooted once with nothing set to bring
it back.

**Every change and every new file is committed and pushed.** Not at the end of a session —
at the end of the piece of work that produced it.

| Repo | Holds |
|---|---|
| `ajith4134/trading-system` | the code |
| `ajith4134/trading-system-research` | the design corpus and boards |
| `ajith4134/claude-config` | these rules, the hooks, the skills, the memory |

- **Private by default.** Public is a separate decision, taken out loud, never inherited
  from convenience. A push is not reversible — deleting a repo does not recall a clone,
  a fork, or a crawler's cache.
- **Scan before the first push of any repo**, and before adding any path to an existing
  one: real credential *values*, not the words. Grepping for "password" finds prose;
  grep for the shapes — `gho_`, `ghp_`, `AKIA`, `BEGIN … PRIVATE KEY`, and
  `KEY = "<16+ chars>"`.
- **Config directories get an allowlist, never an ignore-list.** `~/.claude` holds a live
  OAuth token, full transcripts and 532 MB of plugin cache. `*` first, then admit each
  safe path by name. An ignore-list leaks the first thing nobody thought to exclude.
- **Never commit generated output that reports state.** The status wall is rebuilt by one
  command; committed, a timestamped snapshot of machine state reads as a fact about the
  project rather than about one moment. Ties to [Rule 8](#rule-8).
- **Large re-fetchable media stays out.** It is permanent weight in every future clone, and
  what matters is the artefact distilled from it, not the raw pull.

If a push cannot happen — no network, no auth — **say so in the turn**. A commit that was
never pushed is local work wearing the appearance of a backup.

## The counterweight — read this before adding another rule

**Never bet against the model.** Cherny: *"We have a framed copy of The Bitter Lesson on
the wall… the more general model will always beat the more specific model."* Every rule,
skill, and hook here is scaffolding, and scaffolding decays as models improve. The
information moat — verified environment facts, measurements, research — keeps its value.
Prompt-tuning and clever structure do not.

So: **when a rule stops changing what gets done, delete it.** This file grew from 5 rules
to 7 in one day. That is the direction the videos warn about, and nothing in it is
self-correcting.

**Before automating anything, apply the taste test and the 80/20 filter.** Every
automation is operational debt. Prefer augmentation. Ask whether this genuinely repeats
and whether it is worth the maintenance, before asking whether it is possible — the
4-condition test in the `guardrail-check` skill answers *possible*, not *worth it*.
