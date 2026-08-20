---
name: memory-is-keyed-by-directory
description: Project memory lives under a per-working-directory key; a session started from / gets an empty set unless the key is symlinked.
metadata:
  type: reference
---

Memory is stored at `~/.claude/projects/<cwd-key>/memory/`. A session whose working
directory is `/` reads `projects/-/memory/`, which was **empty** while 12 real
memories sat under `projects/-home-anushadudekula71/memory/`. Fixed 2026-08-17 by
symlinking the `-` key at the real directory; verified 13 files readable from both.

**Why:** every session started from `/` began with no project memory at all — including
[[interview-instead-of-assuming]] and [[trading-bot-goal-and-ledger]], the two that exist
precisely to stop the assistant re-deriving settled decisions. On 2026-08-17 that produced
a session which claimed a two-week-old user ruling "is not in the record" when it was, and
the user had to correct it.

**How to apply:** if memory looks empty, check which key the working directory maps to
before concluding nothing was ever saved. `ls ~/.claude/projects/` shows every key. A new
key appears for every distinct cwd, so the same failure returns for any directory that has
not been linked.
