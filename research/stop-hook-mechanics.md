# Stop hook runtime behavior

**Provenance**
- Researched by: subagent (`general-purpose`), model **sonnet**, per Rule 1
- Date: 2026-08-01
- Run via: `parallel-research` skill (area 1 of 4)
- Sources: raw `curl` of `code.claude.com/docs/en/hooks` and `/env-vars` (WebFetch discarded as
  lossy — see below), `hooks-guide.md`, plus direct read of this session's live transcript
  (v2.1.220), flagged as empirical
- Tool use: 32 calls, ~134K subagent tokens, 922s

---

## The docs say exactly what we discovered the hard way

Verbatim, `hooks.md` line 628, common input fields:

> "`transcript_path` — Path to conversation JSON. **The transcript file is written
> asynchronously and may lag the in-memory conversation, so it may not yet include the current
> turn's most recent messages when a hook fires.** Hooks that need the final assistant text of
> the current turn should use `last_assistant_message` on Stop and SubagentStop instead of
> reading the transcript."

And again, Stop-specific:

> "For hooks that act on the just-completed turn... use this field rather than reading
> `transcript_path`: **the transcript file isn't guaranteed to include the final message at
> Stop time on all versions.**"

**There is no ordering guarantee at all** — no SLA, no "eventually consistent within N ms."
`last_assistant_message` exists precisely because the race is real and unfixable from the hook
side. Our fix (applied 2026-08-01) matches the documented path.

## Full Stop payload — authoritative

```json
{
  "session_id": "abc123",
  "transcript_path": "~/.claude/projects/.../abc123.jsonl",
  "cwd": "/Users/...",
  "permission_mode": "default",
  "hook_event_name": "Stop",
  "stop_hook_active": true,
  "last_assistant_message": "I've completed the refactoring. Here's a summary...",
  "background_tasks": [{"id": "task-001", "type": "shell", "status": "running",
                        "description": "tail logs", "command": "tail -f /var/log/syslog"}],
  "session_crons": [{"id": "cron-001", "schedule": "0 9 * * 1-5", "recurring": true}]
}
```

Common fields on every hook: `session_id`, `prompt_id` (v2.1.196+, absent until first user
input), `transcript_path`, `cwd`, `permission_mode` (`default`/`plan`/`acceptEdits`/`auto`/
`dontAsk`/`bypassPermissions`), `effort` `{level}`, `hook_event_name`; `agent_id`/`agent_type`
inside subagent runs. `background_tasks`/`session_crons` need v2.1.145+ and exist to distinguish
"session done" from "session paused on background work."

`SubagentStop` additionally gets `agent_transcript_path` (a nested `subagents/` file), separate
from `transcript_path`, which stays the parent session's.

## The block cap is configurable

> "`CLAUDE_CODE_STOP_HOOK_BLOCK_CAP` — Maximum number of consecutive times a Stop or
> SubagentStop hook may block the turn from ending before Claude Code overrides it and ends the
> turn anyway (**default: 8**). Set to `0` to disable the cap."

Corrects our CLAUDE.md wording: without a `stop_hook_active` guard it does **not** loop forever
— it blocks 8 times, then Claude Code force-ends the turn with a warning. Still bad (8 rounds of
hook + model turns burned), so the guard stays mandatory. `additionalContext` feedback goes
through the same loop protections as `decision: "block"`.

## Stop hook stdout is NOT shown to Claude

> "For most events, stdout is written to the debug log but not shown in the transcript. The
> exceptions are `UserPromptSubmit`, `UserPromptExpansion`, and `SessionStart`, where stdout is
> added as context that Claude can see and act on."

**`Stop` is not in that list.** Plain stdout from a Stop hook goes to the debug log only. To
reach Claude you need exit 2 + stderr (our approach), or exit 0 + structured JSON
(`decision`/`reason`, `hookSpecificOutput.additionalContext`). Our design is correct.

## A better verification channel than our /tmp log

Undocumented, observed directly in this session's live transcript (v2.1.220). The transcript
contains `type: "system"` records with:

- `subtype: "stop_hook_summary"` — fields `hookCount`, `hookInfos` (array of
  `{command, durationMs}`), `hookErrors`, `hookAdditionalContext`, `preventedContinuation`
  (bool), `stopReason`, `hasOutput` (bool), `level`. **A per-turn record of exactly what the
  Stop hooks did**, including whether they blocked.
- `subtype: "turn_duration"` — `durationMs`, `messageCount`.

Also `type: "attachment"` records wrapping hook execution: `attachment.type: "hook_success"`
carries `hookName`, `hookEvent`, `command`, `stdout`, `stderr`, `exitCode`, `durationMs`. This
is the after-the-fact audit trail for *any* hook, not just Stop.

Useful, but **undocumented and version-liable** — do not build a hard dependency on it. Our own
`/tmp/claude-stophook-fired.txt` stays the primary signal since we control it.

### Verified against this session, with one correction to the above

14 `stop_hook_summary` records present. Two findings:

1. **`hookCount: 2` — a second Stop hook exists that we did not know about.** `hookInfos[].command`
   shows ours (labelled by its `statusMessage`, "Checking Rule 0 verification...") plus
   `bash "${CLAUDE_PLUGIN_ROOT}/hooks/sg-python.sh" "${CLAUDE_PLUGIN_ROOT}/hooks/security_reminder_hook.py"`
   from the **security-guidance** plugin. Note it is `${CLAUDE_PLUGIN_ROOT}`-resolved — exactly
   the shape issue #35406 flags for stale-cache-after-edit.
2. **`preventedContinuation` is NOT the block indicator.** It read `false` on all 14 records,
   *including* the turn our hook demonstrably blocked. The block appears instead as
   `hasOutput: true` plus the full stderr text inside `hookErrors[]`. Anyone auditing "did a Stop
   hook block this turn" by reading `preventedContinuation` would get the wrong answer. What that
   field actually tracks is unconfirmed — plausibly `continue: false`, which we never set.

## Transcript JSONL schema — officially undocumented

No page on `code.claude.com/docs` describes the format; it is an internal storage detail. The
CLI's transcript-writing code is not in the public `anthropics/claude-code` repo (that repo is
examples/docs, not the binary source). Third-party reverse-engineering exists
(`claude-dev.tools/docs/jsonl-format`, `daaain/claude-code-log`, `simonw/claude-code-transcripts`)
but is not Anthropic-primary and was not verified. **Don't bother searching further.**

Observed empirically this session — top-level `type` values: `user`, `assistant`, `system`,
`attachment`, `file-history-snapshot`, `last-prompt`, `mode`, `permission-mode`,
`queue-operation`, `ai-title`. Content block types: `text`, `thinking`, `tool_use`,
`tool_result`, with `tool_result` appearing inside the *next* `user` record — standard Messages
API nesting, not a Claude Code invention.

## METHODOLOGY FINDING — WebFetch is lossy, and it fabricated

The agent's own words:

> "The `WebFetch` tool summarizes pages through a small model before returning them, and it is
> **lossy even when it reports the output as 'fully persisted.'** My first pass at
> `/docs/en/hooks` via WebFetch silently *dropped* the `stop_hook_active`, `background_tasks`,
> and `session_crons` fields from the Stop input schema, and it **fabricated a claim** that
> Stop-hook stdout 'is added as context Claude can see' — false, per the raw doc."

**This is the field we needed.** A summarizer dropped the single most important field in the
schema. Fix: `curl -sL <url>.md` and grep the raw markdown.

Converges independently with the area-2 agent, which found WebSearch's GitHub summaries "vague
and generic in a way that read as synthesized-not-quoted," citing issue numbers whose content
did not match, and re-verified everything with `gh issue view`.

**Two agents, different tools, same conclusion: never trust the summarizer for exact syntax.**

## UNVERIFIED — preserved

- **Stop hook timeout behavior.** Docs spell out cancel-and-discard for `UserPromptSubmit` and
  `MessageDisplay` only. Nothing states what a timed-out *Stop* hook does. By analogy it should
  fail open (non-blocking), but Stop is explicitly a blocking-capable event and this is
  **inferred, not confirmed**. Test empirically if it ever matters.
- `isMeta` appeared only on `type: "system"` records in this sample, always `false`. What it
  signals when `true` is unconfirmed. **Our hook's turn-scoping logic checks `isMeta` on user
  records** — a case never observed.
- The new-hook-EVENT-key reload discrepancy stays unresolved from docs alone. The agent's read:
  editing an existing hook's command reloads live (doc-confirmed), while registering under an
  event key that previously had zero hooks may not (our observation). It recommends keeping the
  conservative restart practice until retested on a current version.
- Transcript schema field names observed on one version in one session; liable to change with no
  deprecation notice.
