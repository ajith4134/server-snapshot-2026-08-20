---
name: hook-verification-needs-a-live-log
description: "A passing hook test suite proves logic, not firing; only a per-invocation log file shows what the hook actually did in production"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: eeb7daf9-58bf-48bc-910f-660cb2be28a0
  modified: 2026-08-01T14:59:31.507Z
---

`~/.claude/hooks/verify-before-stop.sh` writes one line per invocation to
`/tmp/claude-stophook-fired.txt` naming the branch it took
(`ALLOW: a command was run this turn`, `BLOCK: claim with no verification`, ...).

That log is the only thing that revealed the hook was inert. The 8-case suite was
`ALL PASS` at the same moment the hook was allowing every real turn through. Three
independent signals were needed to actually settle it:

1. the live log (which branch ran, or whether it ran at all),
2. a replay of the hook against the **real** transcript truncated at the real turn
   boundary — that gave exit 2 and proved the logic was never the problem,
3. the absence of a log line for the turn under test.

Second lesson from the same fix: a refactor left `entries`/`start` out of scope in
the diagnostic log line, and the resulting `NameError` fired **before** `sys.exit(2)`.
Python then exits 1 — which does not block. A fail-closed hook was silently disarmed
by an exception in the code path leading to its own exit. The suite caught it.

**Why:** this is Cherny's verification rule applied to the enforcement layer itself.
The hook is a tool that sees my output; the log is the tool that sees the hook's.
Without it, "registered", "tests pass", and "firing" are three different things that
all look identical.

**How to apply:** Keep the log line in — it was labelled a temporary diagnostic and
must not be deleted. After any edit to a hook, run its suite AND check the live log
for a new entry from a real turn. Re-run
`python3 ~/.claude/hooks/tests/test-stop-hook.py` after every change. Never claim a
hook works from a green suite alone.

Related: [[stop-hook-transcript-flush-race]], [[session-start-binding]]
