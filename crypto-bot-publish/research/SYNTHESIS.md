> # ⚠️ SUPERSEDED — 2026-08-01
> **This file is retained as a historical record. Do not build from it.**
> Replaced by **`ARCHITECTURE.md`** in this directory.
>
> Specifically stale: the "Decided: what we are NOT doing" list below forbids installing MCP
> servers, installing plugins, and pre-building skills. All three were done later the same day
> with recorded reasons. The priorities were written before the 42-file research sweep and before
> the prior attempt's `PROJECT_BRIEF.md` was read.

# Synthesis — what we should actually do

**Written:** 2026-08-01. Sources: 5 videos (`~/video-notes/`) + 5 Sonnet research
reports (`~/research/`). Synthesis done on the main thread (Rule 1, constraint 2).

---

## The single most important finding

Three independent source streams converged on the same thing:

| Source | How it was stated |
|---|---|
| Videos (3 of 5) | *"Give Claude a way to verify its work → 2-3x quality"* (Cherny) |
| Official docs | *"Give Claude a check it can run… the difference between a session you watch and one you walk away from"* |
| GitHub issues | **#11913**: fabricated test results from a stale JSON file. **Closed "not planned."** |

**Verification is the highest-leverage thing we can build, and false completion is a
documented, unfixed defect.** Not a prompting problem — a structural one.

The mechanism is now precisely known:
> **CLAUDE.md is delivered as a user message after the system prompt, not baked into
> it.** That's *why* it is advisory and why hooks are the only real enforcement.

Everything below follows from that.

---

## Where we actually stand

| Item | State | Evidence |
|---|---|---|
| Rules 1–3 | **All prose. Zero enforcement.** | Nothing is unbypassable |
| CLAUDE.md size | **169 lines** (was 220) | Official target **<200** — now met |
| Hooks | **2 written, NOT yet wired** | `~/.claude/hooks/` — 37/37 tests pass, inert until registered |
| settings.json | **Exists** (tui/theme/notif only) | no `hooks` or `permissions` block yet |
| Permissions | **Default** | — |
| MCP servers | **None** | ✅ correct per research |
| Skills | **None** | ✅ correct — build from real work, not abstraction |
| Compounding memory | `~/video-notes/`, `~/research/` | ✅ already working |

We're closer than the videos would suggest — because "install nothing by default"
turned out to be the right answer, and we already have a working notes-to-disk habit.

**The one real gap is enforcement.**

---

## Priority 1 — the enforcement layer

Everything needed is now known exactly (`enforcement-layer.md`). The critical facts:

- **Exit 2 blocks. Exit 1 does NOT** — easiest way to write a hook that looks like
  it works and doesn't.
- **`PreToolUse` runs before the permission check in every mode**, including
  bypass modes. A hook denial always wins.
- **A hook `allow` cannot override a settings `deny`** — asymmetric by design.
- **`matcher` filters on tool NAME only.** The `if` field matches arguments but
  **fails open** — never a security boundary.
- **Only `Edit(path)` and `Read(path)` are checked for file tools.** A path rule on
  `Write` is silently ignored.

**What to build, in order:**

1. **PreToolUse hook on `Bash`** — deny `rm -rf` at root/home, `git reset --hard`,
   `git push --force`, `git clean -f`, `git checkout <ref> -- .`, pipe-to-shell.
   Every one of these is a documented incident (#34327, #17190, #55024, #46058).
2. **PreToolUse hook on `Edit|Write`** — protect `.env`, credentials, SSH keys,
   `.claude.json` (auth state) and shell profiles. **Deliberately NOT CLAUDE.md** —
   we edit it legitimately and often; blocking it would break normal work.
3. **`permissions.deny`** in settings.json as the cheap second layer (deny beats
   everything, and merges across scopes).
4. **Stop hook** — the answer to false completion. Refuses to end the turn until a
   verification command *actually* passes. ⚠️ **Cap retries** — block cap is 8, and
   check `stop_hook_active` or it loops.

**Known unknown to test, not trust:** issue #39344 reports a hook returning `"ask"`
can bypass a matching `deny` rule. Use `deny`/exit-2 for anything that must not
happen, and verify with `--debug`.

---

## Priority 2 — restructure CLAUDE.md by TYPE

The videos disagreed on size; the research resolved it. The axis is **type**:

| Keep in CLAUDE.md | Move out |
|---|---|
| Rules that **change what Claude does** | Text that **describes** things |
| Non-obvious environment facts (no sudo, no pip, PO-token gate) | Anything derivable from reading the repo |
| Gotchas that cost real time to rediscover | Tooling inventories |

**Official quality test — the best single heuristic found:**
> *"For each line, ask: would removing this cause Claude to make mistakes?
> If not, cut it."*

⚠️ **Correction to my earlier plan:** `@file` imports do **NOT** reduce context cost —
imported files load in full at launch. Splitting into `.claude/rules/*.md` only saves
context if those files carry **`paths:` frontmatter** so they load conditionally.
Unscoped rules files that always load are a documented mistake.

Also available: **`/doctor`** proposes trims, **`/context`** confirms what loaded.

---

## Priority 3 — verification as structure, not a request

From the official docs and all five videos:
1. A CLAUDE.md line requiring a verification plan **before** multi-step work.
2. Real tools to check output — *"give Claude a tool to see its output, then tell
   Claude about the tool."*
3. A **Stop hook** that re-runs the check independently (Priority 1, item 4).
4. **Hot zones** — high cost-of-error paths requiring sign-off and
   *"explain the blast radius."*

Note the layering: 1 is advisory, 3 is enforcement. Both, not either.

---

## Priority 4 — skills, later and only from real work

Anthropic's own trigger table:

| Trigger | Add |
|---|---|
| Claude gets a convention wrong **twice** | CLAUDE.md entry |
| You paste the same procedure a **third** time | Skill |
| Something must happen **every time without asking** | **Hook** |
| A side task floods context | Subagent |
| A second repo needs the setup | Plugin |

**Do not pre-build skills.** Video 3 and the docs agree: build from a conversation
you just had, where the use case is already validated.

When we do: **the `description` field is the whole game** — third person, key use
case first, concrete trigger nouns. A skill with perfect instructions and a vague
description simply never fires.

---

## Decided: what we are NOT doing

| Not doing | Why |
|---|---|
| Installing MCP servers | Most official ones are redundant or archived. **CLI beats MCP 4–32× on tokens, 100% vs 72% success.** GitHub's server alone costs ~3,100 tok/turn |
| Installing plugins | Third-party ecosystem is thin; the researcher declined to name one |
| Pre-building skills | No validated use cases yet |
| Version-specific env-var workarounds | Two features named in community posts are already **removed** (`/output-style` v2.1.91, `/agents` wizard v2.1.198) |

If we ever need browser automation, **Playwright MCP** is the one clear win — and
headless deps on a no-sudo box need testing first.

`gh` CLI is worth installing over the GitHub MCP server. We don't have it yet.

---

## Corrections to things I said earlier in this session

1. **`@file` imports don't save context.** I implied splitting CLAUDE.md would
   reduce cost. Only `paths:`-scoped rules files do.
2. **Subagents are not automatically cheaper.** `model` frontmatter defaults to
   `inherit`; the built-in `Explore` agent is no longer hardcoded to Haiku
   (v2.1.198). Rule 1's explicit `model:` is doing real work — but delegating
   *trivia* costs more than doing it inline.
3. **Slash commands and skills are the same mechanism now.**
   `.claude/commands/x.md` and `.claude/skills/x/SKILL.md` both make `/x`.

---

## Open questions — status

1. ~~**What is the actual project?**~~ **ANSWERED** — autonomous crypto trading
   system. Full decision record: `DECISIONS.md`. Design settled, not yet built.
2. **Where are the hot zones?** Still open. For the trading system these are
   already implied (order placement, capital allocation, live promotion); for this
   workspace they are not yet defined.
3. **How much autonomy?** Still open. Loop Training Mode defaults to
   approve-every-step.
