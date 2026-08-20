---
name: session-start-binding
description: "Most Claude Code config hot-reloads in-session; only SessionStart hooks, newly added MCP servers, and plugin-resolved hook scripts genuinely need a restart or /reload-plugins"
metadata: 
  node_type: memory
  type: project
  originSessionId: eeb7daf9-58bf-48bc-910f-660cb2be28a0
  modified: 2026-08-01T15:42:03.138Z
---

> **Rewritten 2026-08-01** after research contradicted the first version. The original claimed
> everything enumerated at session start was frozen and a restart was the only fix. Wrong for
> skills, wrong for `statusLine`, and it missed `/reload-plugins` entirely.

**Reach for `/reload-plugins` before a restart.** It connects a newly enabled plugin's MCP
servers in-session. Exa and Caveman never needed the full restart they were given.

Hot-reloads, no restart:
- `settings.json` — permissions, hooks, credential helpers. A file watcher covers it.
- Skills — add/edit/remove under a watched skills dir applies in-session. **Verified live
  2026-08-01**: `claude-code-internals` was created mid-session, appeared in the skill
  listing without a restart, and invoked successfully.
- `statusLine` — changes appear on the next interaction.
- Already-connected MCP servers — refresh via `list_changed` notifications.
- Plain absolute-path hook scripts — re-read per invocation. **Verified live 2026-08-01**:
  a mid-session patch to `verify-before-stop.sh` fired on the very next Stop.

Genuinely needs more:
- **`SessionStart` hooks cannot re-fire.** The event already passed. By nature, not caching.
- **A newly added MCP server** — `/reload-plugins` if plugin-supplied, restart if manually
  configured. Open issue #24057; `/mcp reconnect` does not help, it only re-reads config for
  an already-connected server.
- **Plugin-resolved hook scripts (`${CLAUDE_PLUGIN_ROOT}`) really do cache stale** — issue
  #35406, with ~186MB of accumulated stale cache reported. If our hooks are ever packaged as
  a plugin, the re-read-per-invocation assumption breaks.
- **A skills directory that did not exist at session start** is unwatched.
- An **already-rendered** `SKILL.md` stays in context as-is; reload affects later invocations.

Disputed, unresolved: whether a **brand-new hook EVENT key** fires without a reload. Docs say
the watcher covers `hooks`; our 2026-08-01 observation says it did not; issue #56631 reports
`UserPromptSubmit` registration intermittently dropping while `Stop` stayed reliable on the
same install. Keep the conservative practice until retested.

**Why:** an entire session was spent diagnosing four "installed but inert" cases separately,
concluding "restart everything," when the actual mechanisms differ per subsystem and a
one-command fix existed for two of them.

**How to apply:** when something is installed but not working, identify which subsystem it is
before assuming a restart. Plugin MCP server → `/reload-plugins`. Skill → already live.
`SessionStart` hook → genuinely needs a new session. Verify with `/status`, `/hooks`, `/mcp`.

Full detail: `~/research/session-binding-and-reload.md`.
Related: [[stop-hook-transcript-flush-race]], [[hook-verification-needs-a-live-log]]
