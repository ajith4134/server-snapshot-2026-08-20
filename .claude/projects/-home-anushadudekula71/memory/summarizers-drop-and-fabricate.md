---
name: summarizers-drop-and-fabricate
description: WebFetch and WebSearch pass content through a small model that silently drops fields and invents claims; use raw curl and gh for anything requiring exact syntax
metadata: 
  node_type: memory
  type: feedback
  originSessionId: eeb7daf9-58bf-48bc-910f-660cb2be28a0
  modified: 2026-08-01T15:34:14.149Z
---

`WebFetch` summarizes pages through a small model before returning them, and it is **lossy
even when it reports the output as "fully persisted."** Fetching the Claude Code hooks doc,
it silently dropped `stop_hook_active`, `background_tasks`, and `session_crons` from the Stop
input schema — including the field that solved the problem being researched — and
**fabricated** a claim that Stop-hook stdout is added as context Claude can see. The raw doc
says the opposite.

`WebSearch` has the matching failure on GitHub: its summaries were "vague and generic in a way
that read as synthesized-not-quoted," citing issue numbers whose content did not match.

Two subagents found this independently, with different tools, on the same day. That
convergence is why this is recorded as a rule rather than an anecdote.

**Why:** research is worthless if the thing being extracted is exact syntax and the extraction
layer paraphrases. A dropped schema field reads identically to a field that does not exist.

**How to apply:** for schema fields, config keys, API signatures, or issue text —
`curl -sL <url>.md` and grep the raw markdown; `gh issue view -R owner/repo` for GitHub. Use
WebFetch/WebSearch only for orientation and discovery, never as the source of a value that
gets written into code or config. Now encoded as CLAUDE.md Rule 5.

Related: [[hook-verification-needs-a-live-log]]
