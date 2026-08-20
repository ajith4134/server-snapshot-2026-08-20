# Claude Code hook failure modes and footguns

**Provenance**
- Researched by: subagent (`general-purpose`), model **sonnet**, per Rule 1
- Date: 2026-08-01
- Run via: `parallel-research` skill (area 4 of 4)
- Sources: `gh api repos/anthropics/claude-code/issues/<n>` for live state (not search snippets);
  doc quotes grep'd from raw markdown via `curl -sL https://code.claude.com/docs/en/hooks.md`,
  not the WebFetch summarizer
- Tool use: 21 calls, ~84K subagent tokens, 337s

> Harness flagged this output as instruction-shaped (`settings-json`, `bypass-permissions`,
> `system-reminder-tag`). Descriptive research, reviewed, nothing executed from it.

---

## ACT ON THIS FIRST: `last_assistant_message`

Verbatim from the docs (hooks.md line 2194):

> "In addition to the common input fields, Stop hooks receive `stop_hook_active`,
> `last_assistant_message`, `background_tasks`, and `session_crons`. The `stop_hook_active`
> field is `true` when Claude Code is already continuing as a result of a stop hook. Check
> this value or process the transcript to avoid blocking on a condition that will never
> resolve. **Claude Code overrides the hook and ends the turn after 8 consecutive blocks.**"

The transcript flush race we discovered empirically today is a **known open bug**:
[#74340](https://github.com/anthropics/claude-code/issues/74340) — "Stop hook fires *before*
the final assistant message is flushed to `transcript_path`; a hook that parses the transcript
for the last message gets the previous turn's text intermittently."

**The documented fix is to read `last_assistant_message` from the JSON input instead of
parsing the transcript.** Our bounded-re-read patch treats the symptom. Applied 2026-08-01.

Related: [#75435](https://github.com/anthropics/claude-code/issues/75435) hooks break after
compaction (`transcript_path` frozen/stale); [#76362](https://github.com/anthropics/claude-code/issues/76362)
Stop hooks cannot see the compacted portion. Both are more reasons not to depend on the
transcript file.

## The 8-block cap is not a reliable backstop

- [#78121](https://github.com/anthropics/claude-code/issues/78121) — Stop hook re-fires despite
  `stop_hook_active: true`; a `/goal` loop spun ~9 times, "roughly 20 minutes and 35K tokens of
  pure post-completion spin," with the 8-block cap failing to stop it.
- [#69201](https://github.com/anthropics/claude-code/issues/69201) — `stop-hook-git-check.sh`
  false-positives on SSH-signed commits (`%G?=N`), producing an "unbreakable Stop-hook loop."
- [#77686](https://github.com/anthropics/claude-code/issues/77686) — a slow-but-correct Stop
  hook is "silently defeated by repetition": the block-cap override is indistinguishable from a
  legitimate pass, so a policy check is bypassable by retrying past the cap.

Our own `stop_hook_active` guard remains the real protection. The cap is a backstop only.

## Exit codes — verbatim (lines 672–699)

> "**Exit 2** means a blocking error. Claude Code ignores stdout and any JSON in it. Instead,
> stderr text is fed back to Claude as an error message."
>
> "**Any other exit code** is a non-blocking error for most hook events... Execution continues."
>
> "Claude Code treats exit code 1 as a non-blocking error and proceeds with the action, even
> though 1 is the conventional Unix failure code. If your hook is meant to enforce a policy,
> use `exit 2`. The exception is `WorktreeCreate`, where any non-zero exit code aborts."

Confirms our fact #1. **New**: for `Stop`, exit 2 means *prevents Claude from stopping* — so a
buggy Stop hook fails toward **looping**, not toward silently ending.

**Version footgun** (line 678): "A hook that exits 2 while printing JSON that fails schema
validation still blocks... **Before v2.1.214**, Claude Code treated that combination as a
non-blocking error and the action proceeded."

## Timeouts — verbatim (line 343)

> "Defaults: 600 for `command`, `http`, and `mcp_tool`; 30 for `prompt`; 60 for `agent`.
> `UserPromptSubmit` lowers the `command`... default to 30, and `MessageDisplay` to 10.
> `SessionEnd` hooks share a 1.5-second budget."

Ours set explicit timeouts (10/10/15), so the 600s default does not apply. A timed-out hook is
**canceled and its output discarded** — fail-open by silence.

## Structured JSON output — the protocol we are NOT using

> "You must choose one approach per hook, not both: either use exit codes alone, or exit 0 and
> print JSON. Claude Code only processes JSON on exit 0. If you exit 2, any JSON is ignored."

Universal fields: `continue` (takes precedence over event-specific decisions), `stopReason`,
`suppressOutput`, `systemMessage`, `terminalSequence`.
`Stop`/`SubagentStop` use top-level `decision: "block"` + `reason`, plus
`hookSpecificOutput.additionalContext`. `PreToolUse` uses `hookSpecificOutput.permissionDecision`
(`allow`/`deny`/`ask`/`defer`) + `permissionDecisionReason` + optional `updatedInput`.

Our exit-code approach is valid and simpler. No change needed.

Output cap: 10,000 chars, then saved to file and replaced with a preview.

## Silent-failure taxonomy

| Cause | Issue | Mechanism |
|---|---|---|
| One malformed sibling entry poisons the whole event | #82618, #75081 | Parser rejects the entire hooks config on one bad `matcher`; **zero diagnostic** anywhere — `/doctor`, startup, verbose all silent. One reporter measured a ~30-hour outage across ~109 hooks |
| Deleted/moved hook script | #82323, #65378 | Non-2 exit = non-blocking = **fails open**. A `git checkout` that removes a script silently ungates every later session |
| Spawn fails before the body runs | #65378 | `posix_spawn('/bin/sh', {cwd: session_cwd})` — if that cwd was deleted, `ENOENT` before line 1. A `cd "$HOME"` at the top of your script **cannot** save you |
| Runtime-specific dispatch gap | #71022, #69260, #76897 | Per-turn dispatch differs by runtime; not kept in parity. Hooks do not fire for subagents (#69260) |
| settings.json clobbered by other tooling | #78392 (440 occurrences), #79403 | Extension/`/model` toggle rewrites the file, dropping `hooks` entirely |
| Wrong-typed async output field | docs line 3035 | Dropped field-by-field, visible only with `--debug` |

Also #75081: **the tolerance for what counts as an invalid matcher changed across an
auto-update**, so a config working for weeks broke silently after a background update — and
only *new* sessions were affected, making it look like a time-based Heisenbug.

## Security

Docs disclaimer lives on the **hooks reference page, not the security page**:

> "⚠️ Command hooks execute shell commands with your full user permissions. They can modify,
> delete, or access any files your user account can access."

Best practices listed: validate inputs, always quote shell variables, block `..` path traversal,
use absolute paths, skip sensitive files.

**Third-party/plugin hook trust is thin.** The only documented control is enterprise
`allowManagedHooksOnly`. And [#73914](https://github.com/anthropics/claude-code/issues/73914):
"Marketplace plugin updates load newly-pulled executable code under initial-install trust, with
**no re-consent or diff**." [#77989](https://github.com/anthropics/claude-code/issues/77989) is
an unbuilt feature request for install-time re-validation. Directly relevant to the Caveman
plugin: approved once, every future auto-update's hook code runs unreviewed.

**`@file` references bypass PreToolUse entirely** (line 1396, verbatim):

> "PreToolUse runs only when Claude calls a tool. Files you reference with `@` in your prompt
> are added without any tool call... no PreToolUse hook fires for them, including hooks matching
> `Read`. To block specific paths from `@` references, use a `Read` deny rule instead."

Confirmed in practice by [#72236](https://github.com/anthropics/claude-code/issues/72236) for
exactly the `.env`-blocking case. **Our setup is already correct here**: `protect-files.sh`
matches `Edit|Write|NotebookEdit` (writes, not reads), and reads are blocked by
`permissions.deny` `Read()` rules — which is precisely the documented mitigation.

## Environment divergence — know before expanding

- **`--bare` skips hooks entirely** (headless.md): "reduce startup time by skipping
  auto-discovery of hooks, skills, plugins, MCP servers, auto memory, and CLAUDE.md." If we ever
  script `claude -p --bare` in CI, the whole enforcement layer is silently absent.
- Desktop app: Notification and plugin hooks never fire (#81788, #72025).
- VS Code extension panel: per-turn hooks dead (#71022, #76413).
- Remote Control: `remote-control.md` has **zero** mentions of "hook." Gaps filled by #73924
  (SessionEnd never fires for long-lived sessions — "the hook system assumes sessions are
  mortal"), #80827 (macOS workers freeze mid-turn until physical HID input), #82082 (Zod
  validation error in the stdin control protocol is fatal to the whole headless session).

Our plain-terminal Linux setup is the best-supported path. This section is "know before you
expand," not "fix now."

## Don't bother

- Exit 1 vs 2 ambiguity — well-specified, read once, done.
- `terminalSequence` escape — already fail-closed by allowlist (OSC 0/1/2/9/99/777, BEL only).
- `PostToolUse` as a security boundary — docs are explicit it is cosmetic: "the tool has already
  run... any files written, commands executed, or network requests sent have already taken
  effect." Redacts what Claude sees, not what happened.
- The decompiled internal cache details from #24057 — not citable.

## UNVERIFIED — preserved

- Per-event exit-2 table summarized, not reproduced verbatim in full.
- #77167 ("four payload field divergences vs shipped behavior, 2.1.207") itemizes doc/reality
  mismatches; the four specific fields were not enumerated in this report.
- #66203: multi-hook `PreToolUse` semantics — execution order, `updatedInput` visibility across
  hooks, conflict resolution — all undocumented. We run two PreToolUse hooks with different
  matchers, so ordering has not bitten us, but it is unspecified.
- #55867/#75071 closed as duplicates of unspecified canonical issues, not chased.
