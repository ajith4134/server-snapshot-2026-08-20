---
name: claude-code-internals
description: Reference for this box's toolchain and for Claude Code's hook, settings, and plugin internals. Use when writing or debugging a hook, editing settings.json, installing or troubleshooting a plugin or MCP server, deciding whether a config change needs a restart, or when an install needs a tool whose location or version is unknown.
---

# Claude Code internals and box environment

Split out of CLAUDE.md on 2026-08-01 — reference material, not behavioral rules. The
rules that *change what Claude does* stayed in CLAUDE.md; this is what you look up.

## Environment facts (installed 2026-08-01, all without root)

- `git` 2.55 — micromamba env at `~/.local/gitenv`
- `gh` 2.97.0 — GitHub CLI, **deliberately chosen over the GitHub MCP server**, which
  costs ~3,100 tokens/turn for 26 tools. CLI output pipes through `jq`/`grep`; MCP dumps
  raw into context.
- `node` 24.18.1, `npm`, `npx` — `~/.local/node`
- `uv` / `uvx` 0.12.1 — unlocks the uvx package ecosystem
- `pip` 26.2 — inside `~/.venvs/media`. **System Python has NO pip and NO ensurepip** —
  use a venv + get-pip.py. (Note: the `security-guidance` plugin routes around this with
  `pip install --target`, so it is not an absolute barrier.)
- `micromamba` 2.8.1 — for anything needing a non-Python system package

Notes for future installs:
- **No passwordless sudo.** `apt-get` exists but cannot be used. Install to user space:
  static binary, venv, npm prefix, or micromamba.
- `bzip2` was missing, so `tar -xj` fails. Use Python's `bz2` module, or the `bzip2` now
  in `~/.local/gitenv/bin`.
- MCP server `mcp-youtube-transcript` installs but is BROKEN upstream (ImportError:
  FastMCP). Do not retry without checking upstream. `ytgrab` supersedes it anyway — that
  server does transcripts only, no frames.

## Hook facts

1. **exit 2 blocks. exit 1 does NOT.** Docs: "Claude Code treats exit code 1 as a
   non-blocking error and proceeds with the action, even though 1 is the conventional
   Unix failure code. If your hook is meant to enforce a policy, use `exit 2`."
   Exception: `WorktreeCreate`, where any non-zero aborts.
2. **User-scope hooks need ABSOLUTE paths.** `$CLAUDE_PROJECT_DIR` is project-scoped;
   using it in a user-scope hook means the hook never fires.
3. **Permission path rules only apply to `Read()` and `Edit()`** — a rule on `Write()` is
   silently never consulted. That gap is why file protection is a hook.
4. `PreToolUse` runs before the permission check in every mode, so a hook denial always
   wins — but a hook `allow` cannot override a settings `deny`.
5. **CLAUDE.md is deliberately NOT write-protected** — edited often and legitimately.
6. **Fail direction is per-event, and opposite for Stop.** PreToolUse fails CLOSED
   (error → block); a wrong block is merely annoying. Stop fails OPEN (error → allow); a
   wrong block leaves you unable to end a turn at all.
7. **A Stop hook MUST honour `stop_hook_active`.** Without the guard it does not loop
   forever — it blocks `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP` times (default 8, set 0 to
   disable), then the turn is force-ended. Still burns 8 rounds of hook + model turns.
   Open issues #78121 and #69201 show the cap does not always save you.
8. **`agent` and `prompt` hook types are tool-events only** (PreToolUse, PostToolUse,
   PermissionRequest). Stop can only use `command`.
9. **Stop hook stdout is NOT shown to Claude.** Only `UserPromptSubmit`,
   `UserPromptExpansion`, and `SessionStart` get stdout injected as context. For Stop use
   exit 2 + stderr, or exit 0 + structured JSON — **never both**: JSON is ignored on exit 2.
10. **Never read `transcript_path` for the current turn's assistant text.** Documented:
    "the transcript file is written asynchronously and may lag." Use
    `last_assistant_message` from the Stop payload. Open issue #74340. The transcript also
    goes stale after compaction (#75435, #76362).

### Stop payload fields

`session_id`, `prompt_id` (v2.1.196+), `transcript_path`, `cwd`, `permission_mode`,
`effort`, `hook_event_name`, plus Stop-specific `stop_hook_active`,
`last_assistant_message`, `background_tasks`, `session_crons` (last two v2.1.145+).

### Default timeouts

600s for `command`/`http`/`mcp_tool`; 30 for `prompt`; 60 for `agent`. `UserPromptSubmit`
lowers command-type to 30, `MessageDisplay` to 10. `SessionEnd` shares a 1.5s budget.
**Ours set explicit timeouts (10 / 10 / 15), so the 600s default does not apply.**

## What needs a restart, and what does not

Most config hot-reloads. **Reach for `/reload-plugins` before a restart.**

Live, no restart: `settings.json` (permissions, hooks), skills, `statusLine` (next
interaction), already-connected MCP servers (`list_changed`), and plain absolute-path
hook scripts — re-read per invocation, verified live 2026-08-01.

Genuinely needs more:
- `SessionStart` hooks cannot re-fire — the event passed. By nature, not caching.
- A **newly added** MCP server: `/reload-plugins` if plugin-supplied, restart if manually
  configured (open #24057; `/mcp reconnect` only helps already-connected servers).
- **Plugin-resolved hook scripts (`${CLAUDE_PLUGIN_ROOT}`) DO cache stale** (#35406).
- A skills directory that did not exist at session start is unwatched.
- An already-rendered `SKILL.md` stays in context; reload affects later invocations.

Unresolved: whether a brand-new hook EVENT key fires without reload. Docs say the watcher
covers `hooks`; our 2026-08-01 observation says it did not; #56631 reports
`UserPromptSubmit` registration dropping while `Stop` stayed reliable. Stay conservative.

## Verifying a hook actually fired

- `~/.claude/hooks/verify-before-stop.sh` logs one line per invocation to
  `/tmp/claude-stophook-fired.txt` naming the branch taken. **Keep this log.** It is the
  only thing that revealed the hook was inert while its suite was green.
- The transcript carries undocumented `type: "system"` records with
  `subtype: "stop_hook_summary"`: `hookCount`, `hookInfos[{command, durationMs}]`,
  `hookErrors`, `hasOutput`, `preventedContinuation`, `stopReason`, `level`.
  **`preventedContinuation` is NOT the block indicator** — it read `false` on the turn
  that actually blocked. The block appears as `hasOutput: true` plus stderr in
  `hookErrors[]`. Undocumented and version-liable; do not build a hard dependency.
- `attachment` records with `attachment.type: "hook_success"` carry `hookName`,
  `hookEvent`, `command`, `stdout`, `stderr`, `exitCode`, `durationMs` for any hook.
- Commands: `/status` (loaded setting sources), `/hooks` (registered hooks + source file,
  read-only), `/mcp` (per-server tool counts and connection state).

## Known false positive (verified 2026-08-01)

`block-dangerous-bash.sh` matches the **raw command string**. A command that merely
*mentions* a blocked pattern — a heredoc documenting it, a `grep` for it, an `echo` — is
blocked even though it executes nothing dangerous. It **fails closed**, which is correct
for a safety control. Workaround: write such content with Write/Edit, not a bash heredoc.

## Two Stop hooks are registered

Ours, plus `security_reminder_hook.py` from the `security-guidance` plugin. `hookCount: 2`
in `stop_hook_summary` is correct, not a duplicate registration. That plugin also hooks
`SessionStart`, `UserPromptSubmit`, and `PostToolUse`, and runs an Opus-tier LLM review
inside a git repo — see the `security-guidance-plugin-costs` memory.

## Gaps worth knowing before expanding

- **`claude -p --bare` skips hooks entirely** — the whole enforcement layer is silently
  absent. Grep any CI/automation for `--bare`.
- `@file` references in a prompt bypass PreToolUse entirely, including `Read` matchers.
  Use a `permissions` `Read()` deny rule to block paths — which is what we already do.
- Desktop app and VS Code extension have per-turn hook dispatch gaps (#81788, #71022).
- One malformed `matcher` anywhere can silently discard the entire hooks config, with no
  diagnostic (#75081, #82618). One reporter measured a ~30-hour outage.
- A deleted or moved hook script exits non-2, which is **non-blocking** — the control
  vanishes with no signal (#82323).

Full reports: `~/research/stop-hook-mechanics.md`, `hook-failure-modes.md`,
`session-binding-and-reload.md`, `hook-tooling-plugins.md`.
