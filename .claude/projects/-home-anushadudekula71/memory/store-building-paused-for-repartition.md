---
name: store-building-paused-for-repartition
description: Store building and the status wall are deliberately paused pending the funding repartition; both must be restarted once it lands.
metadata:
  type: project
---

Paused 2026-08-19 while the whole-universe store datasets are converted to the
hour-only layout (SL-16, SL-17, RL-032). **Both must be turned back on when the
conversion lands** — neither restarts itself.

- **Store building**: `store_supervisor.sh` was stopped outright (no OFF switch
  exists in it). Restart with `nohup scripts/store_supervisor.sh`. It was
  OOM-looping: `store.build_polled --dataset funding` reached 7.9 GB reading
  funding's 63,063 fragments, and the kernel killed a python at 7.8 GB at
  10:27:57 that day.
- **Status wall**: paused by the file `~/capture/boards/WALL-OFF`. Delete it to
  resume. The other boards keep regenerating.

Raw capture (`capture.cli`) and the four segment bots were deliberately left
running — the raw tape cannot be re-fetched, while the store is derived from it.

See [[gce-startup-script-is-metadata]] and [[restarting-a-supervisor-on-this-box]].
