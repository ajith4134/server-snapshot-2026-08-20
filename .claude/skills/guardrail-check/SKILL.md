---
name: guardrail-check
description: Verify the enforcement layer is intact and actually firing — hook scripts present, settings.json still registering them, both PreToolUse hooks blocking, the Stop hook suite passing, and third-party plugin hook code unchanged since last review. Use when starting work in a new session, after installing or updating any plugin, after editing settings.json or any hook, or when a hook behaves unexpectedly. This is the execution unit behind the guardrail loop.
---

# Guardrail integrity check

One command, one binary verdict:

```
bash ~/.claude/hooks/tests/guardrail-check.sh
```

`APPROVED` (exit 0) or `NOT APPROVED` (exit 1), plus a reason per check. Every run
appends to `~/.claude/guardrail-history.md`.

## Why a binary verdict

"Is the enforcement layer healthy?" is not loopable. `APPROVED` / `NOT APPROVED` is.
That translation is the whole point — an abstract goal becomes a done-rule, and only
then can a loop exist.

## What it checks, and the failure each one is aimed at

| # | Check | The failure it catches |
|---|---|---|
| 1 | Hook scripts present + executable | A deleted or moved script exits non-2, which is **non-blocking** — the control vanishes silently (#82323) |
| 2 | `settings.json` parses, `PreToolUse` and `Stop` still registered | One malformed matcher silently discards the **entire** hooks config, no diagnostic anywhere (#75081, #82618); other tooling rewrites the file (#78392, #79403) |
| 3 | `block-dangerous-bash.sh` blocks dangerous, allows safe | The hook is registered but its logic broke |
| 4 | Stop hook suite (12 cases) | Regression in the Rule 0 enforcer |
| 5 | Live log exists **and has blocked at least once** | **The 2026-08-01 failure mode**: green suite, inert in production. Logic correct, hook never firing |
| 6 | Third-party plugin hook code unchanged | Plugin auto-updates run new executable code under original install trust, with **no re-consent and no diff** (#73914) |

Check 5 is the one that justifies the whole script. Checks 1-4 prove the logic is right.
Only check 5 proves the layer is alive. Those are different claims, and on 2026-08-01 the
first was true while the second was false.

## On NOT APPROVED

Stop and fix before continuing other work — a broken guardrail fails **open**, so nothing
else will tell you. Check 6 specifically means third-party code changed under you: read
the diff first, and only then update the baseline with
`bash ~/.claude/hooks/tests/guardrail-check.sh` after re-recording
`~/.claude/guardrail-baseline.txt`. Never update the baseline to silence the alarm.

## The 4-Condition Test (why this is loopable at all)

1. **Does it repeat?** Yes — every session, and after every plugin update.
2. **Is there a clear done-rule?** Yes — exit 0.
3. **Can you afford the waste?** Yes — pure bash and python, no model tokens.
4. **Does it have the tools to verify?** Yes — the suite, the live log, the fingerprint.

All four hold, which is why this one is worth looping and most things are not.

## Trigger — decided 2026-08-01

**Skill-triggered only.** No scheduler. It fires when this description matches the work
at hand: a new session, after installing or updating a plugin, after editing
`settings.json` or a hook, or when a hook misbehaves.

`/loop` was rejected because it only runs while a session is open, and plugin
auto-updates land while you are away. `/schedule` (cloud cron, unattended, daily) is the
natural upgrade and the only option that catches a third-party hook change the day it
happens — **revisit it once `~/.claude/guardrail-history.md` shows roughly 10 clean runs.**
Autonomy is earned, not assumed.

## Loop Training Mode — ON

Per video 5's safety pattern, and not yet turned off:

- The check runs, then **pauses for a human read of the output**. It does not self-heal.
- It never edits config. Detection only — remediation is a separate, deliberate act.
- No retry loop. One run, one verdict.

Turn any of this off only after the check has been proven across many runs, and record in
`~/.claude/guardrail-history.md` what changed.

## Battle-testing status (2026-08-01)

Proven to FAIL correctly, not just to pass:

- Missing scripts + invalid `settings.json` against a fake `HOME` → 7 failures, exit 1.
- No plugin scripts present → correctly warns instead of fingerprinting empty input.
  (This was a real bug found by that test: `find` returning nothing still produced the
  hash of empty input, so the empty-detection branch was dead code.)
- Corrupted baseline against the real config → drift detected, exit 1, baseline restored.

A check that has only ever returned APPROVED is untested.

## Note on the dangerous test strings

They live inside the script, not on a command line, because `block-dangerous-bash.sh`
matches the **raw command string** — passing one as an argument would get the test itself
blocked. Documented false positive; this is the documented workaround.
