---
name: supervisors-die-with-the-session
description: Trading supervisors started as Claude background tasks die when the session ends; start them detached with scripts/start_supervisors_detached.sh.
metadata: 
  node_type: memory
  type: project
  originSessionId: d9c4767e-a76b-48e3-9948-ee5060c0068f
  modified: 2026-08-19T08:40:05.358Z
---

Anything started from a Claude Code session — Bash `run_in_background`, or a
plain `&` — is a child of that session and **dies when the session ends**. On
2026-08-19 this killed the four segment bots, the retrainer and the boards
generator three separate times; the last time they were dead eighteen minutes
before a probe was asked and noticed.

**How to start them so they survive:** `bash scripts/start_supervisors_detached.sh`
in `~/trading-system`. It puts each supervisor in its own detached `screen`
(parent PID 1, so session teardown cannot reach it) and is idempotent. Check with
`screen -ls`; attach with `screen -r segment-perp`.

**Why not the alternatives:** there is no `crontab` on this box, `apt-get` needs
a password, and `loginctl enable-linger` returns *Access denied* — so systemd
user units stop at logout too. Detached screen is the only without-root path.

**This does not survive a reboot.** The GCE metadata startup script is what
does, and it runs as root at boot — see [[gce-startup-script-is-metadata]]. The
two mechanisms are separate and both are needed.

Restarting a bot is not free: a learned brain needs 60 sealed one-minute bars
before it can decide at all, so every restart costs it an hour of not trading.
