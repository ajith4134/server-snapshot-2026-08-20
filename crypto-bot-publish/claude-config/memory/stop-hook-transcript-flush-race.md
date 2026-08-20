---
name: stop-hook-transcript-flush-race
description: A Stop hook reading transcript_path sees no assistant text on text-only turns because the turn-ending text block is flushed after the hook fires
metadata: 
  node_type: memory
  type: project
  originSessionId: eeb7daf9-58bf-48bc-910f-660cb2be28a0
  modified: 2026-08-01T15:33:54.982Z
---

When a `Stop` hook reads the transcript at `transcript_path`, the **turn-ending
assistant text block has not been written to the file yet**. A first read of a
text-only turn finds zero assistant text.

This is the worst possible failure for `~/.claude/hooks/verify-before-stop.sh`
(Rule 0 enforcement): it fails open on "no assistant text found", so it was blind
to **exactly the turns it exists to police** — a bare success claim with no tool
calls. Turns *with* tool calls escaped the bug entirely, because `tool_use` entries
are already on disk by the time Stop fires, and the hook allowed on
"a command was run this turn" before ever needing the text.

**The real fix, applied 2026-08-01 after research:** read `last_assistant_message` from the
Stop payload. The docs are explicit — *"the transcript file is written asynchronously and may
lag... Hooks that need the final assistant text of the current turn should use
`last_assistant_message` on Stop and SubagentStop instead of reading the transcript."* This is
known open bug [#74340](https://github.com/anthropics/claude-code/issues/74340). The transcript
also goes stale after compaction (#75435, #76362). There is **no ordering guarantee** at all.

A bounded re-read (12 attempts at 0.25s) remains as the fallback when the field is absent.

**Why:** the hook passed its whole 8-case suite while being completely inert in
production. Synthetic transcripts are written before the test runs, so they can
never reproduce the race.

**How to apply:** Any hook that parses `transcript_path` must not assume the current
turn is fully flushed. Never treat "no assistant text found" as a reason to allow
without retrying first. When writing a fail-open hook, list every allow-path and ask
which ones a race could trigger — those are silent disarms, not safe defaults.

Related: [[session-start-binding]], [[hook-verification-needs-a-live-log]]
