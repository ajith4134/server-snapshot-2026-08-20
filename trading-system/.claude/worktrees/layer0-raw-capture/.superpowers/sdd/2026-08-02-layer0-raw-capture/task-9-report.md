# Task 9 report — Universe tracker, point-in-time membership (spec R2)

Branch `worktree-layer0-raw-capture`. Two commits:

- `6faee4e` feat: point-in-time universe membership tracking — the brief verbatim
- `ab59c83` fix(universe_tracker): an empty or implausible universe is refused, not recorded

Suite: **157 passing** (118 baseline + 39 new). No pre-existing test was modified.

---

## What was implemented

`src/capture/universe_tracker.py`

- `UniverseEvent(ts_ns, venue, symbol, kind, detail)` — frozen, `kind ∈ listed|delisted`.
- `diff_universe(previous, current, venue, ts_ns) -> list[UniverseEvent]` — listings first,
  each group sorted, so the output is deterministic.
- `UniverseTracker(root, venue_name, max_delisted_fraction=0.5)` with
  `record_snapshot(symbols, ts_ns) -> list[UniverseEvent]` and `load_last(ts_ns) -> list[str]`.

Layout is the brief's: `<root>/universe/<venue>/<UTC date>/instruments.ndjson` for the
record (one `snapshot` line per observation plus one line per event) and
`<root>/universe/<venue>/last_snapshot.json` for the state the next diff is taken against.

Beyond the brief's skeleton, four things changed, each because the record is permanent and
append-only — **a missing entry is recoverable, a wrong entry is not**:

1. **Implausible snapshots are refused, never recorded** (the hazard — defended below).
2. **The state file is replaced atomically** (`mkstemp` + `fsync` + `os.replace`) instead of
   `write_text`, and **the event record is fsynced before the state advances**.
3. **A damaged state file raises `UnreadableUniverseState`** instead of degrading to
   "no previous universe".
4. **`load_last(ts_ns)` will not return a snapshot recorded after `ts_ns`.** The parameter was
   dead in the brief's version; giving it this meaning removes a lookahead path from the very
   module that exists to stop lookahead.

Exceptions all descend from `UniverseTrackerError`: `ImplausibleUniverseSnapshot`,
`OutOfOrderSnapshot`, `UnreadableUniverseState`. Refusals are raised, not swallowed and not
written anywhere — the caller decides whether to put them in the capture ledger. The tracker
does not import the ledger, so nothing here can write to the anomaly record on its own.

---

## The empty / implausible parse hazard — the decision and why

**The distinction cannot be made from the parsed list.** `parse_instruments` returns `[]` for a
malformed payload and `[]` for a genuinely empty venue — the same value, carrying no evidence.
Anything the tracker infers from `[]` alone is a guess, and a guess written into this file is
permanent and later indistinguishable from truth. So the tracker does not guess. It refuses.

Concretely:

- **Empty is always refused.** Verified live in this project: Hyperliquid 232 perps, Binance
  several hundred. A venue with zero live instruments has never been observed, so `[]` is in
  practice always a failed fetch or a changed payload shape. There is deliberately **no
  override** for this. If a venue ever genuinely empties, that is a halt or a delisting event
  an operator must record deliberately — not something a poll should be able to write.
- **A mass delisting is refused too**, because a *partial* parse failure looks exactly like one
  and is not caught by an emptiness check. The rule: refuse when more than `max_delisted_fraction`
  (default 0.5) of the previous universe would be delisted at once, applied only when the previous
  universe had ≥ 10 symbols — below that the fraction carries no signal and a 3-symbol dev
  universe losing 2 is ordinary. `max_delisted_fraction=1.0` is the operator escape hatch for a
  real mass delisting.
- **Only the delisting direction is guarded.** A mass *listing* is refused by nothing: it is what
  a first snapshot and a new venue both look like, and it does not erase anything.
- **On refusal nothing at all is written** — not the state, not the ndjson. That is what keeps the
  next healthy poll correct: it still diffs against the last good universe, so a failed fetch
  cannot resurface later as a spurious mass listing. Test:
  `test_a_refused_snapshot_leaves_the_next_diff_correct`.

End-to-end, against the real adapter rather than a hand-made list — a Binance error document
(`{"code": -1121, ...}`) parses to `[]` and is refused with the previous 30 symbols left intact:
`test_a_malformed_venue_payload_cannot_reach_the_record`.

**What this costs.** If a venue ever really does empty or halve, capture of *that* transition
stops until an operator acts. That is the trade taken deliberately: silence is visible and
fixable, a false mass delisting in a survivorship-bias record is neither.

---

## Partial failure and the crash window

Two writes happen per snapshot, so there is a window between them.

- **Order: event record first, fsynced, then the state.** If the state advanced first and the
  append were then lost, the transition would be gone from the record and *no later diff would
  ever re-emit it* — it diffs against the already-advanced state. In the order chosen, the worst
  case is that the state write is lost and the next run replays the same poll: a repeated snapshot
  line and duplicate events. Visible, and recoverable. Enforced by
  `test_the_event_record_is_durable_before_the_state_advances`, which traces `os.fsync` and
  `os.replace` and asserts the ordering.
- **A crash mid-state-write leaves the old state, not a torn one.** `write_text` truncates in
  place; a short read afterwards would produce a spurious mass listing on the next run. The
  atomic replace makes the state either wholly old or wholly new, and the temp file is unlinked
  on failure so nothing is left behind.
- **Replay is safe.** Re-running the identical poll at the identical `ts_ns` yields no events and
  no state change (`test_replaying_the_same_snapshot_is_accepted_and_changes_nothing`) — this is
  the recovery path for the crash window, so the out-of-order guard rejects only strictly older
  timestamps.
- **A failed event write does not advance the state**
  (`test_a_failed_event_write_does_not_advance_the_state`, no mocking — a plain file blocks the
  date directory).
- **Self-corruption is blocked at the door.** A non-`int` `ts_ns` or a non-list `symbols` would be
  written into the state file and then rejected by this module's own reader on the next run,
  leaving an operator to repair it. Both are refused before anything is written.

---

## TDD evidence

**RED** (brief step 2) — `uv run --python 3.12 pytest tests/test_universe_tracker.py -v`

```
tests/test_universe_tracker.py:3: in <module>
    from capture.universe_tracker import UniverseTracker, diff_universe
E   ModuleNotFoundError: No module named 'capture.universe_tracker'
=========================== 1 error in 0.10s ===============================
```

Expected: the module did not exist yet, so collection could not even import it.

**GREEN** (brief step 4) — same command, after the brief's implementation

```
tests/test_universe_tracker.py::test_snapshot_is_persisted_and_reloadable PASSED [ 25%]
tests/test_universe_tracker.py::test_first_snapshot_lists_everything_as_listed PASSED [ 50%]
tests/test_universe_tracker.py::test_diff_detects_listing_and_delisting PASSED [ 75%]
tests/test_universe_tracker.py::test_second_snapshot_only_reports_changes PASSED [100%]
============================== 4 passed in 0.03s ===============================
```

Full suite at that point: `122 passed in 0.35s`. Committed as `6faee4e`.

**RED again**, hardening round — 35 further tests added first:

```
E   ImportError: cannot import name 'ImplausibleUniverseSnapshot' from 'capture.universe_tracker'
=============================== 1 error in 0.12s ===============================
```

Expected: the guards, their exception types and the `max_delisted_fraction` parameter did not
exist, so the module could not be imported with those names.

**GREEN**, hardening round — `uv run --python 3.12 pytest -q`

```
157 passed in 0.42s
```

Also clean under a second randomised ordering (`pytest-randomly` is installed and active) and
under `-p no:randomly`.

---

## Mutation testing

Harness (scratchpad, not committed):
`/tmp/claude-1001/-home-anushadudekula71/0a15b275-e446-4894-8c28-f6b077d94775/scratchpad/mutate_universe_tracker.py`
— applies one mutation, runs `tests/test_universe_tracker.py`, restores the file in a `finally`.

**21 mutations applied, 21 killed.** Final run:

| # | Mutation | Result |
|---|---|---|
| M1 | listed/delisted directions swapped | KILLED (13 failed) |
| M2 | empty-universe guard removed | KILLED (3 failed) |
| M3 | threshold `>` → `>=` (boundary) | KILLED (1 failed) |
| M4 | min-universe-size `>=` → `>` (boundary) | KILLED (1 failed) |
| M5 | mass-delisting guard removed entirely | KILLED (2 failed) |
| M6 | state advances **before** the events are written | KILLED (2 failed) |
| M7 | atomic state write replaced by `write_text` | KILLED (2 failed) |
| M8 | `fsync` of the event record removed | KILLED (1 failed) |
| M9 | temp file left behind when the replace fails | KILLED (1 failed) |
| M10 | `load_last` returns a future snapshot (lookahead) | KILLED (1 failed) |
| M11 | `load_last` future boundary `>` → `>=` | KILLED (6 failed) |
| M12 | out-of-order guard rejects an identical replay | KILLED (1 failed) |
| M13 | out-of-order guard removed | KILLED (1 failed) |
| M14 | symbols no longer deduplicated and sorted | KILLED (1 failed) |
| M15 | date partition uses local time instead of UTC | KILLED (1 failed) |
| M16 | empty-string symbols accepted | KILLED (1 failed) |
| M17 | damaged state degrades to "no previous universe" | KILLED (3 failed) |
| M18 | snapshot line not written, only events | KILLED (1 failed) |
| M19 | previous universe ignored — everything a first snapshot | KILLED (12 failed) |
| M20 | a bare string accepted as a universe | KILLED (1 failed) |
| M21 | non-integer `ts_ns` accepted and written to state | KILLED (1 failed) |

**Two survivors were found and fixed, not explained away:**

- **M3 survived the first round.** Nothing pinned the behaviour at *exactly* the threshold —
  20 → 10 symbols. Resolved in favour of `>` (the parameter is named `max_delisted_fraction`, so
  0.5 is the largest fraction *allowed*) and pinned by
  `test_delisting_exactly_at_the_threshold_is_still_recorded`.
- **The harness itself was wrong on its first run** and reported 19/19 killed from
  `cwd=SRC.parents[3]` — one directory too high, so pytest collected nothing, returned non-zero,
  and every mutation "died" without a single test running. Caught because "no tests ran in 0.00s"
  appeared in the output. Worth recording: a green mutation report is exactly as capable of lying
  as a green test suite.

---

## Self-review findings (fresh pass after GREEN)

Two real defects found by re-reading the finished code, both fixed and both now covered:

1. **A bare string passed as `symbols` was accepted.** `all(isinstance(s, str) and s for s in
   symbols)` passes for `"BTCUSDT"` — every character is a non-empty string — and the universe
   would have been diffed character by character, recording 7 single-letter listings. I had
   guarded this on the *read* side (`_read_state`) and missed the symmetric case on the write
   side. Fixed with an explicit list/tuple check; `test_a_bare_string_is_not_mistaken_for_a_universe`,
   mutation M20.
2. **A non-integer `ts_ns` would have been written into the state file** and then rejected by
   `_read_state` on the next run, leaving a state file this module cannot read and an operator to
   repair it by hand. Now a `TypeError` before anything is written; M21.

Also reviewed and deliberately left alone: `detail` stays `{}` as the brief specifies; the
snapshot line keeps the brief's exact three fields; the tracker does not import the capture
ledger.

---

## Concerns

1. **Directory entries are not fsynced.** The event file and the state file are each fsynced, but
   the directories holding them are not, so a *power loss* (not a process crash) could in
   principle lose the new file's directory entry while keeping the state. The resulting failure is
   a lost historic transition — missing, not wrong — and the module is written to prefer that
   direction. Note that `raw_writer.py` does not fsync at all, so adding directory fsyncs here
   only would be inconsistent; if this matters it should be decided for the whole capture layer at
   once.
2. **No concurrency control.** Two `UniverseTracker` instances polling the same venue at once
   would read the same state, both append, and one would win the state write — duplicate events,
   and possibly a lost transition. A single capture process is assumed. If that stops being true,
   this needs a lock file, and nothing currently detects the violation.
3. **A refusal is only an exception.** If a caller catches `UniverseTrackerError` and moves on,
   universe capture silently stops advancing. The refusal deliberately does not write to the
   ledger itself (that would couple the modules and put this code in the anomaly record), so the
   wiring task that calls `record_snapshot` must ledger it. This is the one loose end I would
   flag to whoever does the integration.
4. **`_MIN_UNIVERSE_FOR_MASS_DELISTING_GUARD = 10` is a judgement call**, not a measured value —
   it exists so the fraction rule does not fire on small dev universes. It is a module constant
   rather than a parameter to keep the surface small; if a real venue with fewer than 10
   instruments is ever captured, the fraction guard will not protect it (the empty guard still
   will).
5. **The state file inherits `mkstemp`'s 0600 permissions**, where the brief's `write_text` would
   have left 0644. Irrelevant for a single-user box; it would matter if another account needed to
   read the capture tree.

## Files changed

- `src/capture/universe_tracker.py` (created)
- `tests/test_universe_tracker.py` (created, 39 tests)
