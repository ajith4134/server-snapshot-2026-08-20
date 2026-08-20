---
name: gce-startup-script-is-metadata
description: "The running startup script lives in GCE instance metadata, not in the repo file - and it silently drifted three supervisors behind."
metadata: 
  node_type: memory
  type: project
  originSessionId: 4a14377f-020e-4b9d-8720-f59019c2dc84
  modified: 2026-08-10T10:40:33.675Z
---

`scripts/gce_startup_script.sh` in `trading-system` is a **copy**. The version that
actually runs on boot is the instance's `startup-script` metadata value. Editing the
repo file changes nothing until it is installed.

Install and verify from the VM:

```
gcloud compute instances add-metadata instance-20260801-081737 \
  --zone=asia-south1-c --metadata-from-file startup-script=scripts/gce_startup_script.sh
curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/attributes/startup-script
```

**Why:** on 2026-08-08 the live metadata was three supervisors behind the repo file —
it started boards, binance core capture and hyperliquid only. No store builds, no
offload, no spot capture, no `ALL` broad-universe flag. A reboot would have brought the
box up with the archive un-backed-up, and nothing would have reported it.

The file's own header had claimed metadata could not be set from the VM, citing 403s on
`storage.buckets.create` and `services.list` from 2026-08-03. Those are different
permissions — `compute.instances.setMetadata` is granted, and the write succeeds. The
claim had been believed rather than retested.

**It recurred on 2026-08-10, and that time a reboot actually happened.**
`bars_supervisor.sh` was split out of `store_supervisor.sh` at 08:15 and committed; the
box rebooted at 09:53 on metadata that had never heard of it. Bars stopped building
and nothing reported it — `ps` showed eight supervisors where there should have been
nine. Adding a supervisor to the repo file is not adding a supervisor.

**How to apply:** after editing that script, install it and then read it back from the
metadata server and diff. `add-metadata`'s "Updated [...]" message is not verification.
Same for any long-running supervisor whose settings live in the environment — see
[[eviction-retention-lives-in-a-file]].
