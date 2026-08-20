# The Enforcement Layer — hooks & permissions (exact schema)

**Researched:** 2026-08-01 by a Sonnet 5 subagent (Rule 1).
**Sources:** official `code.claude.com/docs/en/{hooks,hooks-guide,permissions,settings}`
fetched directly, cross-checked against the runtime JSON schema this installed
version validates against. Where community sources disagreed, official docs won.

This closes our #1 gap: **every rule we have is currently prose Claude can ignore.**

---

## The mechanism that makes hooks matter

`PreToolUse` hooks run **before the permission-mode check, in every mode** —
including `bypassPermissions` and `--dangerously-skip-permissions`. A hook denial
stops the call regardless of mode.

**Precedence for a single tool call:**
```
hook deny / exit-2  →  settings deny rule  →  settings ask rule  →  hook allow / settings allow
```

Critically asymmetric: **a hook can tighten what permissions allow, but a hook
`allow` can NOT override a settings `deny`.** Verbatim: *"Deny rules from any
settings scope, including managed settings, always take precedence over hook
approvals."*

---

## Blocking — exit codes (the load-bearing detail)

| Exit | Effect |
|---|---|
| **0** | No objection. stdout parsed as JSON **only on exit 0**. |
| **2** | **BLOCKING.** stderr text is fed back to Claude as the reason. JSON on stdout is **ignored** — never mix the two. |
| any other | **Non-blocking.** Shows a hook-error notice, execution continues. |

> ⚠️ **Exit 1 does NOT block**, despite being the conventional Unix failure code.
> This is the single easiest way to write a hook that appears to work and doesn't.

**Structured JSON alternative (exit 0 + stdout):**
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Destructive command blocked by hook"
  }
}
```
`permissionDecision`: `allow` | `deny` | `ask` | `defer` (defer = headless only).

**Schema differs by event** — `PreToolUse` uses `hookSpecificOutput.permissionDecision`;
`PostToolUse`, `Stop`, `SubagentStop`, `UserPromptSubmit` use top-level
`decision: "block"` + `reason`. The old top-level `decision` is *deprecated for
PreToolUse specifically*.

**Multiple hooks on one event:** all run to completion; most restrictive wins —
`deny > defer > ask > allow`. A sibling hook's side effects still happen even if
another denies.

---

## settings.json hooks schema

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/protect-files.sh",
            "timeout": 600
          }
        ]
      }
    ]
  }
}
```

Three nesting levels: **event → matcher group → handlers.**

| Field | Notes |
|---|---|
| `matcher` | **Tool NAME only** — cannot inspect arguments. `"Bash"`, `"Edit\|Write"`, regex, or `""`/absent = everything |
| `if` | **This is how you match on tool INPUT** — permission-rule syntax (`"Bash(git *)"`, `"Edit(*.ts)"`). ⚠️ **FAILS OPEN** if the command can't be parsed — a spawn-avoidance optimisation, **not a security boundary** |
| `type` | `command` \| `http` \| `mcp_tool` \| `prompt` \| `agent` (**agent = experimental**) |
| `args` | If present, runs **exec form** (no shell) — avoids shell-quoting bugs entirely |
| `timeout` | Default 600s; `UserPromptSubmit` 30s, `MessageDisplay` 10s |

Variables available: `${CLAUDE_PROJECT_DIR}`, `${CLAUDE_PLUGIN_ROOT}`.

**stdin JSON a hook receives:**
```json
{
  "session_id": "abc123",
  "cwd": "/path/to/project",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": { "command": "npm test" },
  "transcript_path": "...",
  "permission_mode": "default",
  "tool_use_id": "toolu_..."
}
```
Plus `tool_response` (PostToolUse), `agent_id`/`agent_type` (subagent context),
`stop_hook_active` (Stop hooks).

---

## Official worked example (verbatim from the Hooks Guide)

`.claude/hooks/protect-files.sh`:
```bash
#!/bin/bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
PROTECTED_PATTERNS=(".env" "package-lock.json" ".git/")
for pattern in "${PROTECTED_PATTERNS[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "Blocked: $FILE_PATH matches protected pattern '$pattern'" >&2
    exit 2
  fi
done
exit 0
```
Registered as `PreToolUse` + matcher `"Edit|Write"`. **`chmod +x` it.**

Dangerous-bash variant checks `.tool_input.command` the same way.
Official reference implementation:
`github.com/anthropics/claude-code/blob/main/examples/hooks/bash_command_validator_example.py`

---

## Hook events that can block

`UserPromptSubmit` · `UserPromptExpansion` · **`PreToolUse`** · `PermissionRequest` ·
`PostToolBatch` · `SubagentStop` · `TaskCreated`/`TaskCompleted` · **`Stop`** ·
`TeammateIdle` · `ConfigChange` · `WorktreeCreate` · `PreCompact` · `Elicitation`

**Cannot block:** `SessionStart`, `PostToolUse` (tool already ran), `Notification`,
`MessageDisplay`, `SubagentStart`, `SessionEnd`, `PostCompact`, `CwdChanged`,
`FileChanged`, `InstructionsLoaded`.

Full list is ~30 events — far more than commonly documented in blog posts.

---

## Permissions

```json
{
  "permissions": {
    "allow": ["Bash(npm run test *)", "Read(~/.zshrc)"],
    "ask":   ["Bash(curl *)"],
    "deny":  ["Bash(git push --force*)", "Read(./.env)", "Read(./secrets/**)"],
    "defaultMode": "default",
    "additionalDirectories": []
  }
}
```

**Evaluation order — verbatim:** *"Rules are evaluated in order: deny, then ask,
then allow. The first match in that order determines the outcome, and rule
specificity doesn't change the order."*
→ A broad `deny` beats a narrower `allow`. **Deny rules cannot have exceptions.**

Syntax:
- `Bash(ls *)` — space before `*` enforces a word boundary (matches `ls -la`, not `lsof`)
- `Bash(npm *)` / `Bash(npm:*)` — trailing wildcard
- Path anchors: `//abs`, `~/home`, `/relative-to-settings`, `./relative-to-cwd`
- `WebFetch(domain:example.com)`
- MCP: `mcp__server`, `mcp__server__tool`, `mcp__*` (deny/ask only)
- Param matching (deny/ask only): `Agent(model:opus)`, `Bash(run_in_background:true)`
- **Bash is shell-aware** — `Bash(safe-cmd *)` does NOT grant `safe-cmd && other-cmd`;
  each subcommand is matched independently

> ⚠️ **Only `Edit(path)` and `Read(path)` are checked for file tools.** A path rule
> on `Write`/`NotebookEdit`/`Glob` is **silently never consulted** (startup warning
> fires). This is a real footgun.

> ⚠️ Docs' own warning: **argument-constraining Bash patterns are fragile** —
> defeated by option reordering, redirects, or `$VAR` indirection. For pipe-to-shell,
> deny `curl`/`wget` outright and force `WebFetch(domain:...)`.

**Permission modes:** `default`/`manual`, `acceptEdits`, `plan`, `auto`, `dontAsk`,
`bypassPermissions`.

---

## Settings hierarchy & precedence

| Scope | Path |
|---|---|
| Managed (Linux) | `/etc/claude-code/managed-settings.json` (+ `.d/`) |
| User | `~/.claude/settings.json` |
| Project (shared) | `.claude/settings.json` |
| Project (local, gitignored) | `.claude/settings.local.json` |

**Precedence (highest first):** Managed → CLI args → Local → Project → User.

**Hook arrays and permission arrays MERGE across scopes** rather than the higher
scope replacing the lower — managed + user + project + local hooks for the same
event all register and all fire.

---

## The OS-level sandbox (stronger than hooks)

The schema exposes `sandbox.filesystem.denyRead/allowWrite`,
`sandbox.network.allowedDomains/deniedDomains`, `sandbox.credentials.files/envVars`
— enforced by **seccomp/bubblewrap on Linux**, not by the model or a hook script.

> **Why this matters:** a Python or Node script that opens files directly
> **bypasses Read/Edit permission rules entirely**. Only the sandbox catches that.
> Hooks gate *tool calls*; the sandbox gates *the process*.

---

## Practical caveats (all real, all worth knowing before writing hooks)

1. **Shell-profile contamination.** Shell-form hooks spawn `sh -c`; an unconditional
   `echo` in `~/.bashrc` gets prepended to the hook's stdout and breaks JSON parsing.
   Fix: guard echoes with `if [[ $- == *i* ]]`, or use exec form (`"args": []`).
2. **Stop-hook block cap = 8** consecutive blocks without progress, then Claude Code
   overrides it. Check `stop_hook_active` in stdin and exit 0 if true, or you loop.
3. **`if` fails open** — never a hard boundary.
4. **`PostToolUse` cannot undo** — the tool already ran.
5. **Race on `updatedInput`** — hooks run in parallel; two hooks mutating the same
   tool input is non-deterministic (last finisher wins).
6. **Hooks DO apply to subagents** — confirmed, with `agent_id`/`agent_type` added.
7. **Debugging:** `claude --debug "api,hooks"`, `claude --debug-file <path>`,
   `/hooks` mid-session, `Ctrl+O` for a one-line summary per fired hook.
8. **Hot reload:** editing settings.json mid-session is normally picked up; if
   `/hooks` shows nothing, restart.

---

## ⚠️ UNVERIFIED — test before relying on it

[GitHub issue #39344](https://github.com/anthropics/claude-code/issues/39344) reports
a `PreToolUse` hook returning `"ask"` can silently cause a matching
`permissions.deny` rule to be **bypassed** instead of prompting — which contradicts
the documented precedence. No maintainer resolution found on the thread.

**Implication:** do not rely on a hook `"ask"` decision to backstop a `deny` rule.
Use `deny`/exit-2 for anything that genuinely must not happen, and test with
`--debug` before trusting it.

---

## Community hook collections (unaudited)

`disler/claude-code-hooks-mastery` · `karanb192/claude-code-hooks` ·
`ithiria894/awesome-claude-code-hooks` · `disler/claude-code-damage-control` —
none reviewed by us; treat as reading material, not dependencies.
