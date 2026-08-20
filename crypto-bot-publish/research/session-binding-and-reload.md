# What Claude Code binds at session start vs. reloads live

**Provenance**
- Researched by: subagent (`general-purpose`), model **sonnet**, per Rule 1
- Date: 2026-08-01
- Run via: `parallel-research` skill (area 2 of 4)
- Sources: `code.claude.com/docs` via WebFetch (verbatim quotes requested, not paraphrase),
  every GitHub claim re-verified with `gh issue view -R anthropics/claude-code` against the
  real issue body rather than WebSearch summaries
- Tool use: 21 calls, ~77K subagent tokens, 288s

> ⚠️ **This report contradicts CLAUDE.md Rule 4 fact #9 as written on 2026-08-01.**
> Fact #9 over-generalized from four same-day observations. Corrections below.

---

## The correction that matters most: `/reload-plugins`

> "If you enable or disable a plugin during a session, run `/reload-plugins` to connect or
> disconnect its MCP servers."

A full restart was **not** required for Exa or Caveman. `/reload-plugins` connects a
plugin's MCP servers in-session. The "restart Claude Code" advice given at the end of the
prior session was more drastic than necessary.

For a **plugin that is also a skill folder**, the same command covers the rest:

> "Live change detection covers `SKILL.md` text only. For a skill folder that is also a
> plugin, changes to `hooks/`, `.mcp.json`, `agents/`, and `output-styles/` need
> `/reload-plugins` to take effect."

## Point-by-point against fact #9

| Fact #9 claimed | Docs say | Verdict |
|---|---|---|
| Skill list frozen at session start | Skills dirs are **watched**; add/edit/remove picked up in-session, no restart | **WRONG** — except a top-level skills dir that did not exist at session start (watcher cannot watch it) |
| `statusLine` frozen at session start | Settings reload automatically; "changes won't appear until your next interaction" | **WRONG** — no restart needed, just a next interaction |
| MCP tool schemas frozen | Live for **already-connected** servers via `list_changed`. A **newly added** server is the real gap | **PARTLY RIGHT, wrong mechanism** |
| New hook EVENT key inert until reload | Docs claim the file watcher covers `hooks`; real issues show event-specific flakiness | **DISPUTED** — our observation stands as first-party evidence, not universal |
| `SessionStart` hooks cannot fire again | Event only fires when a session begins/resumes | **RIGHT** — by the event's nature, not a caching bug |
| Hook script edits are live | No doc states the spawn mechanism; true for plain absolute paths, **not** for plugin-resolved ones | **RIGHT for our setup**, unsafe as a general rule |

## Exit codes — authoritative

> "**Exit 0** means success. Claude Code parses stdout for JSON output fields. JSON output is
> only processed on exit 0... **Exit 2** means a blocking error. Claude Code ignores stdout
> and any JSON in it. Instead, stderr text is fed back to Claude as an error message...
> **Any other exit code** is a non-blocking error for most hook events."

Per-event exit-2 behavior: `PreToolUse` blocks the call; `Stop`/`SubagentStop`/`TeammateIdle`
prevent stopping; `UserPromptSubmit` erases the prompt; `ConfigChange` blocks the config
change; `PostToolUse`/`Notification`/`SessionStart` are non-blocking. Confirms the
exit-2-blocks / exit-1-does-not fact we already had.

## 29 documented hook events

**Lifecycle**: `SessionStart` `Setup` `SessionEnd` `PreCompact` `PostCompact` `CwdChanged`
`WorktreeCreate` `WorktreeRemove` `ConfigChange` `InstructionsLoaded` `FileChanged`
**Prompt/turn**: `UserPromptSubmit` `UserPromptExpansion` `Stop` `StopFailure` `MessageDisplay`
**Tool use**: `PreToolUse` `PermissionRequest` `PermissionDenied` `PostToolUse`
`PostToolUseFailure` `PostToolBatch`
**Subagents/tasks**: `SubagentStart` `SubagentStop` `TeammateIdle` `TaskCreated` `TaskCompleted`
**MCP**: `Elicitation` `ElicitationResult` · **Other**: `Notification`

Common payload: `session_id`, `prompt_id` (v2.1.196+), `transcript_path`, `cwd`,
`permission_mode`, `effort`, `hook_event_name`. Subagent context adds `agent_id`, `agent_type`.

`ConfigChange` is the directly useful one for us — it fires per detected settings change and
can log proof the watcher actually saw an edit instead of assuming it did.

## `/hooks` is read-only

> "The menu is read-only: to add, modify, or remove hooks, edit the settings JSON directly or
> ask Claude to make the change."

But issue #56631's reporter observed that opening it **forced a clean re-registration** —
an undocumented side effect, empirically observed, not confirmed intended.

## Where "correct on disk, inert in session" genuinely bites (ranked)

1. **New manually-configured MCP server** — [#24057](https://github.com/anthropics/claude-code/issues/24057), still **OPEN**, commented 2026-07-29. `/mcp reconnect` does not help: it only re-reads config for an already-connected server, not a first-time add.
2. **New hook EVENT type** — [#56631](https://github.com/anthropics/claude-code/issues/56631), `UserPromptSubmit` registration intermittently drops after mid-session script edits (v2.1.131); `Stop` stayed reliable on the same install.
3. **Plugin-resolved hook scripts** (`${CLAUDE_PLUGIN_ROOT}`) — [#35406](https://github.com/anthropics/claude-code/issues/35406), old cached version keeps executing; reporter found ~186MB of stale cache under `~/.claude/`. **If we ever package our hooks as a plugin, this assumption breaks.**
4. **Redeployed binary behind unchanged MCP config** — confirmed unhandled July 2026.
5. **Skills directory that did not exist at session start** — the one skills exception.

Also: [#22679](https://github.com/anthropics/claude-code/issues/22679) "Hook settings are cached
and changes don't take effect until session restart" (Feb 2026, closed duplicate) is the *old*
behavior the current file-watcher docs appear to supersede.

## Already-rendered skills do not update

> "the rendered `SKILL.md` content enters the conversation as a single message and stays
> there... Claude Code does **not** re-read the skill file on later turns."

Live reload applies to future invocations, not the copy already in context.

## Verification commands (Rule 0)

`/status` — loaded setting sources · `/hooks` — registered hooks + source file ·
`/mcp` — per-server tool counts and connection state · a `ConfigChange` hook logging
detected changes.

## UNVERIFIED — preserved

- **The hook spawn mechanism is not documented anywhere.** Our "script edits are live because
  the harness spawns by absolute path and re-reads per invocation" is an architectural
  inference plus today's live observation — not a primary-source fact. It held for our plain
  absolute-path `Stop` hook. It demonstrably does not hold for plugin-resolved hooks.
- Internal cache implementation details (`dynamicMcpConfig`, `onChangeDynamicMcpConfig`,
  `handleQueryStart`) come from a commenter's decompilation of the closed-source binary on
  #24057. Directional color for *why* the gaps exist — the config layer hot-reloads, specific
  consumers like MCP client state do not react — but **not citable and not worth chasing.**
- Issue #55867 closed as duplicate of an unspecified canonical issue, not chased.
- Per-event exit-2 table was summarized, not reproduced verbatim.

## Sourcing note from the agent

WebSearch's AI summaries of GitHub results were "vague and generic in a way that read as
synthesized-not-quoted," citing issue numbers without matching content. The agent discarded
them and re-verified every issue with `gh issue view`. Worth remembering: for issue-tracker
research, `gh` beats WebSearch.

> Harness flagged this agent's output as instruction-shaped (`settings-json` pattern) because
> it discusses config files. Descriptive research, reviewed, nothing executed from it.
