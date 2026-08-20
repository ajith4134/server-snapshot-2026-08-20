---
name: eviction-retention-lives-in-a-file
description: "Local raw eviction is switched on by ~/capture/eviction-keep-days, not by an env var - and is off when that file is absent."
metadata: 
  node_type: memory
  type: project
  originSessionId: 4a14377f-020e-4b9d-8720-f59019c2dc84
  modified: 2026-08-08T15:31:20.539Z
---

Local raw eviction (`src/ops/raw_eviction.py`, run by `offload_supervisor.sh` after a
clean offload) reads its retention from **`~/capture/eviction-keep-days`**. Currently
`7`. A `KEEP_DAYS` environment variable overrides it; with neither, the value is `0`
and eviction does not run.

It only ever deletes a local file whose object it has just seen listed in the bucket.
Files missing from the bucket, hours holding a live `.writing` marker, and paths that
are not `venue/date` are all kept regardless of age.

**Why:** the setting was originally an environment variable, which is exactly the thing
that does not survive a reboot or a manual restart — it would have stopped evicting
while every log line still looked healthy. Same shape of silence as the bars dataset
going five days stale because nothing in the run log ever mentioned bars.

**How to apply:** to change retention or switch eviction off, write a new number to that
file — it is read inside the supervisor loop, so no restart is needed. To confirm it is
live, look for an `"eviction"` line in `~/capture/offload/runs.ndjson`; `applied: true`
with `removed: 0` means it ran and found nothing outside the window. The startup script
seeds the file only when absent, so a changed value survives reboots — see
[[gce-startup-script-is-metadata]].
