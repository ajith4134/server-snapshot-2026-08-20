---
name: restarting-a-supervisor-on-this-box
description: "Three traps when restarting a trading-system supervisor loop — pkill -f self-match, TERM not landing during sleep, and editing a running bash script."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: dddd9e47-d693-497e-ad61-54a2d8c1a103
  modified: 2026-08-08T17:02:40.777Z
---

Restarting one of the `scripts/*_supervisor.sh` loops has three traps, all hit on
2026-08-08 in one sitting:

1. **`pkill -9 -f "store_supervisor.sh"` kills the shell issuing it.** The pattern
   matches the invoking command line too, so the launch that follows in the same
   command never runs and nothing is left running. Kill by PID, or launch in a
   separate tool call.
2. **`kill <pid>` does not land while the loop is in `sleep 3600`.** The script's
   `trap 'exit 0' TERM INT` only fires after the current foreground command
   returns, so a plain TERM leaves it alive up to an hour and a "replacement"
   started beside it means two supervisors racing. `kill -9` is safe: the
   partition writer refuses a rewrite, so a killed mid-build day just collides on
   the next pass.
3. **Editing a running `.sh` changes its behaviour mid-flight.** Bash reads the
   script incrementally by byte offset, so an edit while it sleeps can make it
   resume into the wrong place. Any edit to a supervisor means restarting it.

**Why:** each trap ends with either zero supervisors or two, and both look fine
until the run log is read.

**How to apply:** edit, commit, then in its own call
`cd ~/trading-system && setsid nohup ./scripts/<name>.sh <interval> </dev/null >/dev/null 2>&1 &`,
then confirm with `ps -eo pid,ppid,lstart,args | grep [s]upervisor` that exactly
one exists, and read the run log for a line from the new pass — not just the
process list. Related: [[gce-startup-script-is-metadata]].
