# Official Anthropic Guidance — primary sources

**Researched:** 2026-08-01 by a Sonnet 5 subagent (Rule 1), fetching official pages
directly rather than trusting search snippets.

**Canonical docs domain is `code.claude.com/docs`.** Older
`docs.claude.com/en/docs/claude-code/` paths redirect there — stale but still resolve.

---

## Memory hierarchy — exact paths, loaded broadest → narrowest

| Scope | Path | Shared with |
|---|---|---|
| Managed policy | Linux: `/etc/claude-code/CLAUDE.md` | Whole org |
| **User** | **`~/.claude/CLAUDE.md`** | You, all projects |
| **Project** | **`./CLAUDE.md`** or `./.claude/CLAUDE.md` | Team, via git |
| Local | `./CLAUDE.local.md` (gitignore it) | You, this project |

Loaded by walking **up** the directory tree from cwd to filesystem root; within each
directory `CLAUDE.local.md` is appended after `CLAUDE.md`.

> **This confirms our setup is correct:** `~/CLAUDE.md` (project scope, since our
> working dir is home) + `~/.claude/CLAUDE.md` (user scope) both load. Not redundant
> — different scopes.

**Docs are explicit: Claude Code reads `CLAUDE.md`, not `AGENTS.md`.** Bridge with
an `@AGENTS.md` import or a symlink if a project uses that convention.

HTML comments (`<!-- ... -->`) are stripped before injection — usable for notes to
humans that cost no context.

---

## CLAUDE.md quality test (official, and the best single heuristic found)

> **"For each line, ask: would removing this cause Claude to make mistakes?
> If not, cut it."**

Size target: **under 200 lines** — *"longer files consume more context and reduce
adherence."*

Verification commands: **`/context`** (confirms CLAUDE.md actually loaded) and
**`/doctor`** (flags oversized CLAUDE.md, invalid managed entries).

---

## settings.json

Recommended `$schema`: `https://json.schemastore.org/claude-code-settings.json`

Known keys: `permissions`, `hooks`, `env`, `model`, `defaultMode`,
`autoMemoryEnabled`/`autoMemoryDirectory`, `allowedMcpServers`/`deniedMcpServers`,
`sandbox.{filesystem,network,credentials}`, `outputStyle`, `companyAnnouncements`.

Settings are **watched and hot-reloaded**, except `model` (use `/model`) and
`outputStyle` (needs `/clear` or restart).

Recommended project layout:
```
your-project/.claude/
├── CLAUDE.md
├── settings.json / settings.local.json
├── rules/{code-style,testing,security}.md
├── skills/api-conventions/SKILL.md
└── agents/security-reviewer.md
```

`/init` generates CLAUDE.md from project structure; re-running on an existing file
**suggests improvements rather than overwriting**.

---

## The six engineering blog posts (all located on official domains)

**1. Claude Code: Best practices for agentic coding**
`anthropic.com/engineering/claude-code-best-practices` → **308-redirects to the
living docs page**, so treat it as continuously updated, not the frozen April 2025 text.

Key points: give Claude a **verifiable success signal** (tests/lint/screenshot diff);
Explore→Plan→Code→Commit; feed rich context (`@file`, images, piped logs); keep
CLAUDE.md lean; hooks deterministic vs CLAUDE.md advisory; **`/clear` after 2 failed
correction attempts** rather than continuing to argue; adversarial review via a fresh
subagent.

Named failure patterns: **kitchen-sink session · over-specified CLAUDE.md ·
trust-then-verify gap · infinite exploration.**

**2. Writing effective tools for agents** (Sep 2025)
`anthropic.com/engineering/writing-tools-for-agents` — build **few high-impact
consolidated tools**, not thin API wrappers; namespace by service/resource; build in
pagination/truncation; prefer semantic IDs over UUIDs; actionable error messages;
**write tool descriptions like onboarding a new hire**; evaluate on realistic
multi-tool transcripts and read the raw reasoning, not just pass/fail.

**3. Effective context engineering for AI agents** (Sep 2025)
`anthropic.com/engineering/effective-context-engineering-for-ai-agents` —
**"context rot"**: recall degrades as context grows (finite attention budget,
O(n²) self-attention). System prompts need the **"right altitude"** — not brittle,
not vague. **Minimal instruction sets beat exhaustive edge-case lists.**
Long-horizon levers: compaction, structured note-taking to files, sub-agent
architectures. **Prefer just-in-time retrieval over eager pre-loading.**

**4. Building effective agents** (Dec 2024)
`anthropic.com/engineering/building-effective-agents` — **workflows** (predefined
code paths) vs **agents** (LLM directs its own process). Use workflows for
predictable tasks. Five patterns: prompt chaining, routing, parallelization,
orchestrator-workers, evaluator-optimizer. Explicit advice: **start with direct API
calls before frameworks; maintain simplicity; prioritise transparency.**

**5. Introducing Agent Skills** (Oct 2025) — `claude.com/blog/skills`. Skill =
folder + SKILL.md + bundled resources, loaded on demand, automatic invocation.

**6. Code execution with MCP** (Nov 2025)
`anthropic.com/engineering/code-execution-with-mcp` — **the most striking number in
the whole research set:** presenting MCP servers as filesystem code APIs the agent
writes code against took a Google Drive→Salesforce workflow from **150,000 tokens to
2,000 — a 98.7% reduction.** Problem being solved: tool-definition overload +
intermediate-result duplication.

---

## Slash commands / features — confirmed real

- **`/loop`** — CONFIRMED, but it is a **bundled skill shipped by default**, not
  compiled-in logic. Local and session-scoped, expires after 7 days. Alias
  `/proactive`. Disable with `CLAUDE_CODE_DISABLE_CRON=1`.
- **`/schedule`** — CONFIRMED. CLI entry to **Routines**, which run on
  Anthropic-managed cloud infra (cron/API/GitHub triggers). **Requires claude.ai
  subscription login — not available with API-key/Bedrock/Vertex auth.**
  **Explicitly "in research preview."**
- **Output styles** — real; change the system prompt (role/tone/format), not
  knowledge. ⚠️ **The `/output-style` command was REMOVED in v2.1.91** — switch via
  `/config` or `{"outputStyle": "..."}` in settings.
- Built-ins confirmed: `/init`, `/agents`, `/permissions`, `/model`, `/config`,
  `/context`, `/doctor`, `/clear`, `/compact`, `/rewind`, `/hooks`, `/skills`,
  `/plan`, `/goal`, `/sandbox`, `/mcp`, `/fork`, `/subtask`, `/loop`, `/schedule`,
  `/code-review`, `/security-review`, `/simplify`.

---

## Subagent limits (official)

- Spawn depth: **3 layers** below main conversation by default
  (`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`) — **this default has changed across
  versions; don't hardcode it.**
- Session caps: **200 subagents total, 20 concurrent.**
- `model` frontmatter **defaults to `inherit`** — a subagent with no `model:` uses
  the main conversation's model. **Directly relevant to Rule 1:** delegation is not
  automatically cheaper; we must set `model:` explicitly, which our rule already does.

---

## Version/beta flags to carry into any permanent rule

| Item | Status |
|---|---|
| Routines (`/schedule`) | **research preview** — expect change |
| `type: "agent"` hooks | **experimental** |
| Fork mode | experimental, staged rollout |
| `/output-style` command | **removed** (v2.1.91) |
| `/agents` wizard | **removed** (v2.1.198) — the `.claude/agents/` dir still works |
| Subagent spawn depth default | changed across versions |
| `#` memory shortcut | **could not be verified in current docs at all** |

> **Lesson for our rules:** anything version-specific needs a date stamp and a
> "verify before relying on this" note. Two features named in community posts have
> already been removed.
