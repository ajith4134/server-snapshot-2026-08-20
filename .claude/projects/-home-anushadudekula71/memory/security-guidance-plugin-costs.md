---
name: security-guidance-plugin-costs
description: "The security-guidance plugin runs LLM security review on Stop, commit, and push using claude-opus-4-7 by default — inert outside a git repo, real token spend inside one"
metadata: 
  node_type: memory
  type: project
  originSessionId: eeb7daf9-58bf-48bc-910f-660cb2be28a0
  modified: 2026-08-01T15:36:49.955Z
---

`security-guidance` (official Anthropic plugin, v2.0.6) registers on **four** events, not one:

- `SessionStart` → `ensure_agent_sdk.py`, timeout **180s**. Creates a venv at
  `~/.claude/security/agent-sdk-venv` and pip-installs the Claude Agent SDK. It succeeded on
  this box on 2026-08-01 despite system Python having no pip and no ensurepip — it has a
  `pip install --target` fallback for exactly that case.
- `UserPromptSubmit` → runs on every prompt.
- `PostToolUse` → on `Edit|Write|MultiEdit|NotebookEdit`, and on `Bash` gated by `if` clauses
  for `git commit:*`, `git push:*`, `gt create/modify/submit:*`.
- `Stop` → git-diff-based LLM security review.

**The cost that matters:** the review calls `api.anthropic.com/v1/messages` with
`SECURITY_REVIEW_MODEL`, defaulting to **`claude-opus-4-7`**. Overridable by env var; base URL
overridable via `ANTHROPIC_BASE_URL`. Every Stop, every commit, and every push inside a git
repo triggers an Opus-tier call. All the `Stop`/`PostToolUse` entries set `asyncRewake: true`,
so it can wake the agent in the background with findings.

**Right now it is inert.** The primary working directory is not a git repo, so
`~/.claude/security/log.txt` shows 47 × "not a git repo" and 17 × "skipping", with zero LLM
calls. Present cost is subprocess spawns only.

**Why:** this directly interacts with Rule 1. The whole point of Rule 1 is stretching the Max
allowance by not defaulting to the biggest model — and an Opus-tier review firing on every
stop and every commit is exactly the kind of silent spend that rule exists to prevent. It is
invisible because it is a plugin default, not a choice made in-session.

**How to apply:** before starting any git-backed project (the trading project especially),
decide deliberately whether this review should run. To keep it but cut the cost, set
`SECURITY_REVIEW_MODEL` to a smaller model. Check `~/.claude/security/log.txt` to see what it
actually did rather than assuming. Note the hooks are `${CLAUDE_PLUGIN_ROOT}`-resolved, so
[[session-start-binding]] applies — they cache stale after plugin updates (issue #35406), and
updates run unreviewed under original install trust (issue #73914).
