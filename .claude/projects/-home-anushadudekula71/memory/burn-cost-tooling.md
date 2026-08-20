---
name: burn-cost-tooling
description: "The burn plugin was audited and deliberately NOT installed; its script lives at ~/.local/bin/claude-burn instead, and it cannot see subagent spend"
metadata: 
  node_type: memory
  type: project
  originSessionId: eeb7daf9-58bf-48bc-910f-660cb2be28a0
  modified: 2026-08-01T15:58:51.155Z
---

`claude-burn` reports Claude Code token usage and cost. Run it directly:

```
claude-burn --all --days 7      # or --top N, --export csv|json
```

**Deliberately not installed as a plugin** (decision 2026-08-01). The script is on PATH
at `~/.local/bin/claude-burn`, frozen at the exact revision that was audited —
upstream `into-the-intraverse/claude-money-burn`, marketplace sha `d4bc685`. No standing
context cost, no exposure to unreviewed auto-updates (#73914).

Audit result: **stdlib only** — no network imports, no `subprocess`, no `eval`/`exec`. It
reads `~/.claude/projects/**/*.jsonl` and writes nothing unless given `--export`. Ships no
hooks and no MCP server, so nothing runs on every prompt. Safe.

**Its blind spot is the one that matters here: it explicitly skips any path containing
`subagents/`.** Handed all 58 subagent transcripts directly, it found the files and parsed
zero sessions. So its `sonnet $0.00` line is an artifact, not a fact — subagent spend is
invisible to it, and subagent spend is precisely what Rule 1 exists to optimize.

For the half it cannot see, sum `message.usage` over
`~/.claude/projects/**/subagents/*.jsonl` with `jq`. That is how the 40% figure now cited
in Rule 1 was produced.

**Why:** the useful part of a third-party plugin can often be kept without adopting the
plugin — no standing tokens, no supply-chain tie, and the code frozen at the revision
actually read. Worth trying before installing anything that is really just a script.

**How to apply:** treat `claude-burn` as main-thread-only. A complete picture needs it
plus the subagent `jq` sum. Related: [[security-guidance-plugin-costs]] for the other
direction — a plugin whose cost is invisible until you are in a git repo.
