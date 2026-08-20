# Hook-authoring tooling: is `hookify` worth installing?

**Provenance**
- Researched by: subagent (`general-purpose`), model **sonnet**, per Rule 1 (docs lookup → sonnet)
- Date: 2026-08-01
- Run via: `parallel-research` skill, first invocation as a skill (area 3 of 4)
- Sources: raw fetches from `raw.githubusercontent.com/anthropics/claude-plugins-official/main/plugins/hookify/...`, both marketplaces' `marketplace.json`
- Tool use: 22 calls, ~64K subagent tokens, 240s

---

## Verdict: DON'T BOTHER (for now)

Not a close call. The existing hand-written hook layer is strictly more capable.

## What `hookify` actually does (source-verified, not tagline)

It is **not** a script generator and does **not** manage `settings.json`. It installs one
fixed, generic Python rule engine as the plugin's own hooks, and your "rules" become data
files that engine interprets at runtime.

- `plugins/hookify/hooks/hooks.json` registers on **four** events — `PreToolUse`,
  `PostToolUse`, `Stop`, `UserPromptSubmit` — **with no `matcher` field**, so every one
  fires on every invocation of that event type.
- Rules live per-project at `.claude/hookify.{name}.local.md`, markdown + YAML frontmatter:

  ```yaml
  ---
  name: block-dangerous-rm
  enabled: true
  event: bash
  pattern: rm\s+-rf
  action: block
  ---
  ⚠️ warning body shown to Claude
  ```

- Match schema is flat: fields `command`, `file_path`, `new_text`, `old_text`, `content`,
  `user_prompt`; operators `regex_match`, `contains`, `equals`, `not_contains`,
  `starts_with`, `ends_with`.
- `/hookify` with no args runs a bundled subagent (`agents/conversation-analyzer.md`) that
  re-reads the transcript for "behaviors you've corrected" and drafts a rule file.

## Why it loses to what we already have

1. **Strictly less expressive.** `block-dangerous-bash.sh` blocks destructive git history
   and worktree commands, recursive deletes at root/home, pipe-to-shell, world-writable
   chmod, and credential-into-network shapes. Several need real logic, not one regex
   against `command`. Porting our rules into hookify's format would be a **downgrade**.
2. **No conflict, but no migration path either.** Hooks from `settings.json` and from
   plugins stack side by side — hookify would run alongside our three, not replace them.
   Safe to add is a low bar.
3. **Permanent runtime cost even with zero rules.** No matcher means every tool call spawns
   two cold `python3` interpreters (Pre + Post), every user message one more, every stop one
   more, each doing a filesystem scan. This never becomes "config-only, code-free."
4. **It has no knowledge of the hard parts we already solved** — `stop_hook_active`
   reentrancy, the fail-open/fail-closed asymmetry between PreToolUse and Stop, exit-2
   semantics.

**Token cost is NOT the objection**: 4 commands + 1 skill + 1 subagent ≈ a few hundred
tokens/turn standing. Small — nowhere near the ~3,100/turn the GitHub MCP server would have
cost. The objection is duplication plus subprocess overhead.

**The one gap it would fill:** fast, no-restart, natural-language authoring of throwaway
per-project nag rules ("warn on `console.log` in this one repo") that don't justify writing
and testing a real script. Revisit if that need appears. Not before.

## The other two plugins we had flagged as "relevant to open items"

| Plugin | What it actually is | Maintainer |
|---|---|---|
| `code-simplifier` | **Not hook-related.** A subagent that refines recently modified code for clarity/consistency. You invoke it; it is not a hook. | Anthropic |
| `plugin-dev` | **Not for personal hooks.** A meta-toolkit for building *distributable* plugins — 7 skills covering hooks, MCP, commands, agents. Only useful if packaging our hooks for others. | Anthropic |

Our INDEX.md filed both under "relevant to our open items." That was wrong for both:
neither addresses hook authoring for a personal `~/.claude/hooks/` setup.

## Marketplace facts confirmed

- Official `anthropics/claude-plugins-official`: **276 plugins** — matches our recorded count.
- Community `anthropics/claude-plugins-community`: **exactly 2,307** — matches our count.
- Community README states it is *"synced nightly from Anthropic's internal review pipeline"*
  and listings *"passed automated security scanning"* — **automated scanning only, not human
  code review.** Direct PRs are auto-closed; submission via `clau.de/plugin-directory-submission`.
- `hookify` last commit **2026-05-19**. Anthropic first-party, in-repo source
  (`"source": "./plugins/hookify"`). Actively maintained.
- Searched all 2,307 community entries for hook-authoring tools. **None exist.** `hookdeck`
  matches on name only — it is a webhook *receiver* integration from the Hookdeck company,
  unrelated. Dozens of "guardrails"-branded plugins are pre-packaged policy bundles, not
  authoring tools.

## UNVERIFIED — preserved, not smoothed over

- Standing token cost is an **order-of-magnitude estimate** from fetched frontmatter. Exact
  count not measured.
- `plugin-dev`'s 7 skills were read at the `marketplace.json` description level only; the
  skill files themselves were not fetched.
- `code-simplifier` source not fetched — description-level only.
- Every community "guardrails" plugin found carries `"author": null`, i.e. no declared
  maintainer identity beyond the repo owner. Source not fetched for any. Given the
  automated-scanning-only vetting bar, the agent declined to recommend any of them.
- `skillers` (`github.com/agent-sh/skillers`) — reads transcripts and suggests skills, hooks,
  and agents. Conceptually adjacent, no author field, source unexamined. Flagged, **not**
  recommended.
- Cosmetic upstream bug: `hookify`, `plugin-dev`, `agent-sdk-dev` have `homepage` fields
  pointing at `claude-plugins-public`, a repo name that looks like a stale rename artifact.
  The `source` field resolves correctly, so installs work; only the doc link is wrong.
