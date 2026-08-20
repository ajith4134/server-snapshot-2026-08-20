# Skills, Subagents & Workspace Structure — official spec

**Researched:** 2026-08-01 by a Sonnet 5 subagent (Rule 1).
**Sources:** official `code.claude.com/docs` and `platform.claude.com` fetched
directly, plus named third-party repos. Third-party claims marked as such.

---

## 1. CLAUDE.md — official guidance (directly relevant to our open item)

**Official size target: under 200 lines.** Memory docs state plainly:
*"longer files consume more context and reduce adherence."*

> **RESOLVED 2026-08-01: now 169 lines.** Rule 2's operational half was promoted
> to the `youtube-video` skill (loads on demand). Two
> independent research streams (this and `failure-modes.md`) plus video 2 now agree.

**The mechanistic reason hooks exist — worth internalising:**
> **CLAUDE.md is delivered as a *user message after the system prompt*, not baked
> into the system prompt.** That is *why* it is context rather than enforced config,
> and why hooks are the only real enforcement layer.

**Include vs exclude (official table):**

| Include | Exclude |
|---|---|
| Bash commands Claude can't guess | Anything derivable from reading the code |
| Style rules that differ from defaults | Standard language conventions |
| Testing instructions / preferred runner | Detailed API docs (link instead) |
| Repo etiquette (branches, PRs) | Info that changes frequently |
| Architecture decisions specific to this project | Long tutorials |
| Environment quirks, required env vars | File-by-file descriptions |
| Gotchas, non-obvious behaviour | Self-evident advice ("write clean code") |

**⚠️ Correction to my earlier plan:** `@path/to/file` **imports do NOT reduce
context cost** — an imported file still loads in full at launch. Splitting
CLAUDE.md into `.claude/rules/*.md` only saves context if those files carry
**`paths:` frontmatter** so they load *only* when matching files are touched.
Unscoped rules files that always load are explicitly listed as a common mistake.

Import details: resolved relative to the *importing* file, max depth 4, skipped
inside code fences. External imports (outside the working dir) trigger a one-time
approval dialog.

**`/doctor` (v2.1.206+) proposes trims for a checked-in CLAUDE.md** — cuts content
Claude can derive from the codebase, keeps pitfalls/rationale/non-default
conventions. Directly useful for our size problem.

**On emphatic language ("IMPORTANT", "YOU MUST"):** official best-practices says it
*can* improve adherence — but there is **no independent empirical study**. Treat as
*weakly-sourced-but-official*, not evidence-backed. What IS better attested:
**structure and specificity** measurably help. "Use 2-space indentation" beats
"format code properly." "Run `npm test` before committing" beats "test your changes."

---

## 2. Skills — the real spec

**Layout:**
```
.claude/skills/<name>/
├── SKILL.md          # required entrypoint
├── reference.md      # loaded ONLY if Claude follows the link
└── scripts/helper.py # EXECUTED, never read into context
```

Precedence: Enterprise > Personal (`~/.claude/skills/`) > Project
(`.claude/skills/`) > Plugin.

**Key frontmatter fields** (only `description` really matters for discovery):

| Field | Notes |
|---|---|
| `description` | **The single highest-leverage field.** Skill is invisible without it. Truncated at **1,536 chars** combined with `when_to_use`. |
| `when_to_use` | Extra trigger phrases; same cap |
| `disable-model-invocation` | `true` = only you can invoke. **Use for anything with side effects** (deploy, commit, send) |
| `user-invocable` | `false` = hidden from `/` menu, Claude can still use it |
| `allowed-tools` / `disallowed-tools` | Tool scoping for the turn |
| `model` | `sonnet`/`opus`/`haiku`/`fable`/`inherit` |
| `effort` | `low`…`max` |
| `context: fork` | Runs in an isolated subagent instead of inline |
| `paths` | Globs — auto-load only when touching matching files |
| `hooks` | Lifecycle hooks scoped to the skill |

**How invocation actually works — not magic:** at session start only
`name` + `description` load, as a *listing*. Claude reads that menu and picks.
Full SKILL.md loads only on trigger. **A skill with perfect instructions and a
vague description simply never fires.**

Description rules that move the needle:
- **Third person.** *"Extract text and tables from PDF files…"* — NOT *"I can help
  you…"* or *"You can use this to…"*. Inconsistent POV measurably hurts discovery,
  because it's injected as a system-prompt menu entry, not a conversational turn.
- **Key use case first** (survives truncation).
- Name concrete trigger nouns the user would actually type.
- Good: *"Extract text and tables from PDF files, fill forms, merge documents. Use
  when working with PDF files or when the user mentions PDFs, forms, or document
  extraction."*
  Bad: *"Helps with documents"* / *"Processes data"*.

**Size:** SKILL.md body **under 500 lines**. Keep references **one level deep** — if
`advanced.md` links to `details.md`, Claude may only `head -100` it and silently
lose information. **Files over 100 lines need a table of contents** so a partial
read still shows scope.

**Budget:** invoked skills stay in the conversation and survive compaction up to a
combined **25,000-token budget** (5,000 per skill, most-recent-first) — a bloated
skill invoked early can be **silently dropped** after `/compact`.

**⚠️ Slash commands and skills are now the same mechanism.** `.claude/commands/deploy.md`
and `.claude/skills/deploy/SKILL.md` both produce `/deploy`. Skills just add a
directory for supporting files plus invocation-control frontmatter. Old
`.claude/commands/` files still work.

---

## 3. Subagents

`.claude/agents/<name>.md` (project) or `~/.claude/agents/<name>.md` (personal).
**Only `name` and `description` are required.**

Notable fields: `tools` (allowlist — **a misspelled tool name fails the launch
outright**, it does not silently degrade), `disallowedTools`, `model`,
`permissionMode`, `maxTurns`, `skills` (preloads full skill *content*),
`mcpServers` (**scopes MCP servers to just this subagent — keeps their schemas out
of the main conversation**), `memory`, `isolation: worktree`, `background`.

Model resolution: `CLAUDE_CODE_SUBAGENT_MODEL` env → per-invocation `model` →
frontmatter `model` → main conversation model.

**Relevant to Rule 1:** the built-in `Explore` agent is **no longer hardcoded to
Haiku** (as of v2.1.198) — it inherits the main model, capped at Opus. So default
Explore is *not* automatically cheap; our Rule 1 explicit `model:` choice still
governs when we spawn agents ourselves.

**Context isolation, concretely:** subagents get their own system prompt plus
CLAUDE.md and git status — **except `Explore` and `Plan`, which skip both** to stay
cheap. No conversation history is inherited.

**When subagents HURT** (official framing):
- Task needs frequent back-and-forth, or phases share heavy context.
- **Many subagents each returning detailed results — the summaries alone flood the
  main context.** Explicitly warned about.
- You need intermediate reasoning visible to course-correct.
- Coordination overhead exceeds just doing it inline.

**Briefing rule:** a subagent has *zero* memory of the parent conversation. Give it
exact files/lines, never "based on what we discussed." Unscoped "investigate X" is a
documented failure pattern ("the infinite exploration").

---

## 4. The official "build your setup over time" trigger table

This is Anthropic's own compounding mechanism — the answer to *when* to add what:

| Trigger | Add |
|---|---|
| Claude gets a convention wrong **twice** | CLAUDE.md entry |
| You keep typing the same prompt to start a task | User-invocable skill |
| You paste the same multi-step procedure a **third** time | Skill |
| You keep copying data Claude can't see | MCP server |
| A side task floods context with stuff you won't reuse | Subagent |
| You want something to happen **every time without asking** | **Hook** |
| A second repo needs the same setup | Plugin |

**Where people get it wrong:**
1. "Always do Y" in CLAUDE.md when it should be a hook.
2. A 30-line procedure left in CLAUDE.md instead of promoted to a skill (CLAUDE.md
   loads in full every session; a skill costs nothing until invoked).
3. Unscoped `.claude/rules/` files that always load.
4. Subagents used when you need visibility into intermediate steps.
5. Confusing **skills = content/reuse** with **subagents = isolation**.

---

## 5. Compounding — the officially documented mechanism

**Subagent persistent memory:** `memory: user|project|local` in agent frontmatter
creates `.claude/agent-memory/<name>/` with a `MEMORY.md` index plus topic files.
The subagent's system prompt auto-includes read/write instructions and the first
200 lines / 25 KB of MEMORY.md.

Prompting pattern from the docs — put directly in the agent body:
> *"Update your agent memory as you discover codepaths, patterns, library locations,
> and key architectural decisions."*
> *"Before starting work, check your memory for patterns you've seen before."*

**Session auto-memory** (on by default) does the same for the main conversation,
writing to `~/.claude/projects/<project>/memory/MEMORY.md`. Self-limiting by design —
Claude Code errors when MEMORY.md exceeds its read budget, forcing curation.

**Skill gotchas:** use an "Old patterns" `<details>` block rather than
time-sensitive prose ("before August 2025…" rots the moment the date passes).

---

## 6. Planning — and the one thing officially framed as THE lever

**Plan mode:** Explore (read-only, uses the `Plan` subagent) → Plan
(**`Ctrl+G` opens the plan in your editor for direct hand-editing** — genuinely
under-advertised) → Implement → Commit.

**Official caveat against overuse:** plan mode adds overhead. Skip it for a
one-sentence change. It earns its cost when the approach is uncertain, multiple
files are involved, or the code is unfamiliar.

**The docs independently converge on the videos' advice:** start a fresh session,
have Claude **interview you** with `AskUserQuestion` about implementation, UX, edge
cases and tradeoffs, then **write a complete spec to `SPEC.md`** — then **start a
fresh session to execute it**, deliberately discarding the interview context.

What makes a spec good, verbatim:
> *"self-contained: names the files and interfaces involved, states what is out of
> scope, and ends with an end-to-end verification step that proves the feature
> works. Time spent making the spec precise pays off more than time spent watching
> the implementation."*

**And the strongest statement in the entire research set:**
> *"Give Claude a check it can run: tests, a build, a screenshot to compare. It's
> the difference between a session you watch and one you walk away from."*

Without a pass/fail signal, *"looks done"* is the only signal available — **and you
become the verification loop.** This is framed with more conviction than any
planning claim.

Complementary: an **adversarial review subagent** in a fresh context reviewing the
diff against the spec. Caveat the docs give: a reviewer asked to find gaps *will*
report some even on sound work — over-trusting every finding causes over-engineering.

---

## 7. Real published workspaces

- **`obra/superpowers`** (Jesse Vincent) — most-cited real example. 7-stage enforced
  pipeline: brainstorm → worktree → short plan → TDD (deletes code written before
  its test) → dev → two-stage review → completion. Note: **a `CLAUDE.md` at a plugin
  root is NOT loaded as project context** — plugins ship context via skills/agents/hooks.
- **`github/spec-kit`** — specify → plan → tasks → implement, tool-agnostic.
- **`hesreallyhim/awesome-claude-code`** — large curated index of examples.
- **`skill-creator`** (official plugin) — evaluation-driven compounding: stores test
  cases in `evals/evals.json`, runs isolated subagent tests, benchmarks with-skill vs
  without-skill, blind A/B between skill versions. The closest thing to a rigorous
  "does this actually help" loop.

Common project layout:
```
.claude/
├── settings.json / settings.local.json
├── rules/          topic-scoped, path-scoped via frontmatter
├── skills/<name>/SKILL.md
├── agents/<name>.md
├── agent-memory/<name>/
└── hooks/
```
`.claude/` should generally be gitignored **except** the deliberate config
subfolders — it holds transcripts that can leak secrets pasted into prompts.

---

## Backed vs cargo cult (researcher's own grading)

**Backed by official docs with a mechanism:** third-person + specific skill
descriptions; CLAUDE.md size/adherence tradeoff; hooks-for-enforcement vs
prompts-for-guidance; **verification checks as the actual driver** of unattended
success; subagent isolation tradeoffs.

**Official but unevidenced:** emphatic language improving adherence; ADRs as a
compounding mechanism (practitioner reports exist — including reports of it
*failing* until routed through an explicit command rather than passive instruction).

**Unverified:** a literal `#`-prefixed memory shortcut (documented mechanism is
conversational — "remember X" / "add this to CLAUDE.md"); `license` as a Claude Code
SKILL.md frontmatter field (belongs to the separate Agent Skills open standard).
