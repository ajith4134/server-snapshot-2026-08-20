# Task 10 report: Capture health — runway, integrity report, and alerts

**Status:** complete. 194 tests passing (157 baseline + 37 new). Branch `worktree-layer0-raw-capture`, working tree clean.

**Commits**

| SHA | What |
|---|---|
| `2a6a724` | `feat: capture health with runway measured in days` — the brief's 5 tests and its implementation, verbatim |
| `63a4333` | `fix(capture_health): absence, a torn ledger and alert floods are all failures` |
| `17fde80` | `fix(capture_health): close every remaining path that reports a silent ok` |

**Files changed**

- `src/capture/capture_health.py` (new, 381 lines)
- `tests/test_capture_health.py` (new, 425 lines, 37 tests)

---

## What was implemented

All five produced interfaces, with the brief's exact values (`WARN_DAYS=30`, `ALERT_DAYS=14`,
`DECISION_DAYS=7`, `health/alerts.ndjson`, `ok|warn|alert|decision_point`) and its five tests kept
verbatim and passing unmodified.

`compute_runway_days(free_bytes, daily_bytes)` — free over daily; a zero rate is infinite runway.
Refuses NaN and negative rates (see *silent ok* below).

`classify_runway(days)` — each boundary belongs to the worse band: exactly 7.0 days is
`decision_point`, not `alert`.

`measure_daily_bytes(root, days=7)` — sums every regular file under `raw/` with an mtime inside the
window (index and quarantined files included: they occupy the disk being measured), and divides by
**days actually observed**, not the width of the window. See deviation below.

`build_report(root, venue, date, free_bytes, daily_bytes)` — the brief's fields plus
`generated_at`, `damaged_ledger_lines`, `corrupting_non_gap`, `raw_data_bytes` and
`capture_status`. Read-only; writes nothing.

`write_alerts(root, report)` — appends to `health/alerts.ndjson` in one fsynced write, returns how
many records reached the disk.

### Deviations from the brief's reference implementation

Three, all narrowing "reports healthy when it isn't". Signatures, thresholds, filenames and the
brief's assertions are untouched.

1. **The write-rate divisor.** The brief divides by `days` unconditionally. A two-day-old archive
   over a seven-day window therefore reports 2/7ths of its true write rate and multiplies the
   runway estimate by 3.5 — on the measured 91 GB free at 2 GB/day that turns a real 45-day runway
   into a reported 159 days, i.e. `ok` instead of the escalation ladder. The divisor is now the
   observed span, floored at one day so an archive an hour old cannot report a 24x inflated rate
   and alarm on its first hour.
2. **Absence is a state, not a zero.** The brief's report cannot distinguish "no gaps recorded"
   from "this stream never connected" — both produce an empty ledger and a clean report. Added
   `capture_status`.
3. **`stat()` and date handling are defensive.** Files rotate, quarantine and vanish under a live
   capture, so an unstat-able file is skipped rather than fatal; a `date` that is not exactly
   `YYYY-MM-DD` is refused rather than silently reading an empty ledger and reporting a clean day.

---

## Hazard 1 — alerts are pull-only and nobody is notified

Stated in the module's own docstring, in those terms:

> **Alerts here are pull-only, and nobody is notified.** There is deliberately no email, Slack or
> webhook in this module: an outbound channel carries credentials and belongs to a later operations
> sub-project. The consequence has to be stated plainly rather than discovered: until that channel
> exists, a silent capture outage produces alerts that nobody reads. `health/alerts.ndjson` is only
> as useful as the habit of opening it.

No network, credential or notification code exists in this module.

## Hazard 2 — alert fatigue: what I decided

**Repeated identical alerts collapse.** An alert already recorded for the same
`(venue, date, reason, severity band)` is not written again. A health report is expected to run on
a schedule; without this, one unresolved condition writes one identical line per run until the file
is worthless — and the reader is trained to ignore it, which is the failure mode, not the nuisance.

Three things are deliberately **not** collapsed, because they are a different situation rather than
the same one restated:

- **A worse runway band.** The band is part of the reason (`runway_warn` → `runway_alert`), so an
  escalation is always a new line.
- **A tenfold worse count.** Count-based alerts carry a decade band in their key: 1 corrupting gap
  then 4 is one alert; 1 then 40 is two. Drift is quiet, an order of magnitude is not.
- **A different venue or date.**

**Routine `observation_loss` gaps never alert at all.** They are counted in the report and left
there. They are the expected case on a bursty stream — and the gap detector's tuning is explicitly
still under watch — so putting them in the alert file is precisely how it would become unread.
`corrupting` gaps and corrupting non-gap events do alert.

Dedup state lives in the alert file itself (each record carries its own `dedup_key`), so there is no
second store to keep in sync, and a line that will not parse is skipped rather than fatal — the
alternative is one torn line silencing every future alert. Because the file is read and not locked,
two simultaneous reporters can both write the same alert; that duplicate is the failure worth
having, since a lock would let one stuck process stop the other from raising an alarm at all.

## Absence — the failure this component exists to catch

`capture_status` has three values:

- `present` — the venue-day holds raw capture bytes.
- `absent` — it holds none, but capture exists elsewhere under `raw/`. **Alerts** (`capture_absent`).
- `uninitialised` — nothing anywhere has ever been captured. Does **not** alert.

The `uninitialised` band is a deliberate trade-off with a known hole, and it is worth stating: "this
stream stopped" cannot be claimed before the system has ever run, and claiming it would fire on
every fresh install — but the cost is that the very first day of capture cannot raise an absence
alert. If that is judged wrong, one line in `build_report` inverts it (and the brief's
`test_write_alerts_emits_lines_for_bad_states`, which asserts `count == 1` against an empty root,
would then need its expected count changed).

Sidecars are excluded from the presence measurement: only `*.ndjson.zst` counts. A `.writing`
marker is a file with a pid in it, and counting bytes indiscriminately would let an hour that opened
a stream and captured nothing report as `present`.

Also treated as absence-shaped rather than as health: a **damaged ledger** (`damaged_ledger_lines`,
from `read_all`'s `.damaged`) — a ledger that lost its evidence is not a quiet ledger — and
**corrupting events that are not gaps**, i.e. `unwritable_stream_total`, which is a stream being
dropped entirely and is arguably the worst thing in the file.

---

## TDD evidence

### RED — the brief's tests, before any implementation

```
$ uv run --python 3.12 pytest tests/test_capture_health.py -v
tests/test_capture_health.py:4: in <module>
    from capture.capture_health import (
E   ModuleNotFoundError: No module named 'capture.capture_health'
=========================== short test summary info ============================
ERROR tests/test_capture_health.py
!!!!!!!!!!!!!!!!!!!! Interrupted: 1 error during collection !!!!!!!!!!!!!!!!!!!!
```

Expected: the module does not exist yet — exactly what the brief's Step 2 predicts.

### GREEN — after the brief's implementation

```
$ uv run --python 3.12 pytest tests/test_capture_health.py -v
tests/test_capture_health.py::test_report_counts_gaps_by_severity PASSED [ 20%]
tests/test_capture_health.py::test_classify_thresholds PASSED            [ 40%]
tests/test_capture_health.py::test_runway_is_free_over_daily PASSED      [ 60%]
tests/test_capture_health.py::test_runway_is_infinite_when_nothing_written PASSED [ 80%]
tests/test_capture_health.py::test_write_alerts_emits_lines_for_bad_states PASSED [100%]
============================== 5 passed in 0.02s ===============================
$ uv run --python 3.12 pytest -q      →  162 passed in 0.44s
```

Committed as `2a6a724`.

### RED — the hardening round

27 new tests written against the brief's implementation, 17 failing:

```
$ uv run --python 3.12 pytest tests/test_capture_health.py -q -p no:randomly
FAILED test_measure_daily_bytes_divides_by_days_observed_not_by_the_window
FAILED test_measure_daily_bytes_never_divides_by_less_than_a_day
FAILED test_measure_daily_bytes_survives_a_file_that_cannot_be_stat_ed
FAILED test_measure_daily_bytes_refuses_a_window_of_zero_days
FAILED test_a_venue_day_that_captured_nothing_is_absent_not_healthy
FAILED test_a_venue_day_that_captured_data_is_present
FAILED test_a_writing_marker_alone_is_not_captured_data
FAILED test_a_root_that_has_never_captured_anything_is_not_called_absent
FAILED test_absent_capture_raises_an_alert
FAILED test_a_date_that_is_not_a_date_is_refused
FAILED test_damaged_ledger_lines_are_reported_and_alerted
FAILED test_corrupting_events_that_are_not_gaps_are_still_counted
FAILED test_repeating_the_same_alert_does_not_repeat_the_line
FAILED test_a_tenfold_worsening_re_alerts_but_drift_does_not
FAILED test_a_damaged_alert_line_does_not_stop_the_next_alert
FAILED test_every_alert_carries_what_it_is_about
FAILED test_alerts_are_appended_not_rewritten
17 failed, 14 passed in 0.22s
```

Each failure is the absence of a behaviour, not a broken assertion: no `capture_status`, no
`damaged_ledger_lines`, no dedup, no observed-days divisor.

### GREEN — final

```
$ uv run --python 3.12 pytest tests/test_capture_health.py -q      →  37 passed in 0.07s
$ uv run --python 3.12 pytest -q                                   →  194 passed in 0.48s
$ uv run --python 3.12 pytest -q -p no:randomly                    →  194 passed in 0.48s
```

Run repeatedly under `pytest-randomly`'s shuffled ordering; no order dependence.

---

## Mutation testing — 33 mutations, 33 killed

Driver: `scratchpad/kill_mutants.py` — applies each mutation to `capture_health.py`, runs the test
file, restores the original, and refuses to score a mutation whose pattern is not unique (that check
caught two stale patterns after refactors, which would otherwise have been silently "killed").

| # | Mutation | Result |
|---|---|---|
| M1 | zero write rate divides instead of returning `inf` | KILLED |
| M2 | `decision_point` boundary made exclusive | KILLED |
| M3 | `alert` boundary made exclusive | KILLED |
| M4 | `warn` boundary made exclusive | KILLED |
| M5 | bands checked best-first instead of worst-first | KILLED (9 tests) |
| M6 | divide by the window, not days observed (**the brief's own version**) | KILLED |
| M7 | no one-day floor on the divisor | KILLED |
| M8 | mtime window ignored, ancient files counted | KILLED |
| M9 | an unstat-able file is fatal | KILLED |
| M10 | index and quarantined files not counted toward disk use | KILLED |
| M11 | an absent venue-day reported as `uninitialised` | KILLED (4 tests) |
| M12 | a venue-day with no data reported as `present` | KILLED (5 tests) |
| M13 | sidecars counted as captured data | KILLED |
| M14 | damaged ledger lines not reported | KILLED |
| M15 | corrupting non-gap events dropped | KILLED |
| M16 | every event counted as a gap | KILLED |
| M17 | dedup disabled — every run repeats every line | KILLED |
| M18 | count returned includes suppressed alerts | KILLED* |
| M19 | gap count band dropped — a 10x worsening never re-alerts | KILLED |
| M20 | band is the raw count — every count change re-alerts (flood) | KILLED |
| M21 | appended onto a torn last line | KILLED |
| M22 | a malformed date accepted | KILLED |
| M23 | a zero-day window accepted | KILLED |
| M24 | an unparseable existing alert line is fatal | KILLED |
| M25 | dedup key ignores venue and date | KILLED |
| M26 | health looks in the wrong folder for raw data | KILLED (9 tests) |
| M27 | worst condition no longer written first | KILLED |
| M28 | a healthy report does not return 0 | KILLED |
| M29 | gap severities not keyed by severity | KILLED* |
| M30 | fsync dropped (durability) | KILLED* |
| M31 | a NaN write rate flows through as `ok` | KILLED |
| M32 | a negative write rate reads as infinite runway | KILLED |
| M33 | a mistyped severity raises and loses the venue-day | KILLED |

\* **Three survived the first pass** (M18, M29, M30) and are the most useful result here, because
each was a behaviour I believed was tested and was not:

- **M18** — `return len(fresh)` → `return len(alerts)`. Survived because no test had a *partial*
  batch: every existing dedup test deduped everything and returned early. A caller told "2" when one
  line was written would believe an alarm existed that did not.
  Killed by `test_the_count_returned_is_what_reached_the_disk`.
- **M29** — every gap counted as `corrupting` regardless of severity. Survived because no test
  asserted the full `gaps` dict with more than one severity present. This is the alert-fatigue
  mutation: it would promote every routine `observation_loss` gap into a corrupting alert.
  Killed by asserting `report["gaps"] == {"corrupting": 1, "observation_loss": 1, "info": 0}`.
- **M30** — `os.fsync` removed. Nothing checked that a count returned means a line that survives a
  power cut. Killed by `test_an_alert_is_on_disk_before_it_is_reported_as_written`, which traces
  `os.fsync` via `/proc/self/fd` — the pattern already used in `test_universe_tracker.py`.

M31–M33 were found by inspection after the mutation pass, then given tests and mutations of their
own.

---

## Self-review findings (fresh pass over the finished code)

1. **`gaps[event.severity]` could raise on an unhashable severity.** A ledger line can be valid JSON
   with `"severity": ["corrupting"]`, so `read_all` returns it as an event and the dict assignment
   raises `TypeError` — taking down the whole venue-day report. A report that never gets built is
   indistinguishable from a healthy one downstream. Fixed (bucketed as `"unknown"`), tested, and
   mutated as M33.
2. **NaN and negative write rates classified as `ok`.** `NaN <= 0` is False, so a NaN rate produced
   a NaN runway, and every comparison in `classify_runway` then returned `ok`. A negative rate hit
   the `<= 0` branch and returned infinite runway — also `ok`. Both are now refused with a
   `ValueError`. The brief's `compute_runway_days(100, 0) == inf` is unaffected.
3. **`_raw_root` derives the archive location from `raw_writer.paths_for`** rather than restating
   `"raw"`. Getting this wrong fails silently and permanently in the worst direction: the module
   would walk an empty tree, call every stream `uninitialised`, and never alert again. M26 confirms
   the tests catch a wrong folder.
4. **Alert ordering is load-bearing** (whoever opens the file reads the top), so
   `test_the_worst_condition_is_the_first_line` pins runway ahead of gaps; M27 confirms it.
5. **Venue names are not sanitised** into path components. Deliberate and consistent with
   `CaptureLedger`, which does the same: `venue` here comes from operator config, not from the wire.
   `venue_recorder` sanitises `stream`/`symbol` precisely because those *are* wire-derived. Every
   path use in this module is read-only.

## Concerns for the caller

1. **Nobody reads these alerts.** Restating the module docstring because it is the single most
   important fact about this component: there is no notification channel, by design. Until the
   operations sub-project provides one, the value of this file depends entirely on someone opening
   it. A cron that `cat`s `health/alerts.ndjson` into a place a human already looks would close most
   of the gap with no credentials involved.
2. **Nothing calls this yet.** `build_report`/`write_alerts` are not wired into `venue_recorder` or
   any scheduler, and `free_bytes` has no producer — no `shutil.disk_usage` call exists in the
   codebase. The brief scopes `free_bytes` as an argument, so I did not add one, but until something
   calls this on a schedule with a real free-space figure, the component is inert. This is the
   `MEMORY.md` lesson exactly: a green suite proves logic, not firing.
3. **The first day of capture cannot raise an absence alert** (the `uninitialised` trade-off above).
   Flagging it as a decision worth ratifying rather than a defect.
4. **`measure_daily_bytes` walks the whole `raw/` tree.** At 90 days of retention this is on the
   order of 10^5 `stat()` calls (~a second), because the mtime filter cannot be applied before
   walking. Pruning by the date component of the directory name would fix it if the report ever runs
   often enough to matter. Not built — it does not repeat often enough today to be worth the
   coupling.
5. **`raw_data_bytes` excludes quarantined files**, so a venue-day whose only raw file was
   quarantined reports `absent` and alerts. I believe that is correct (loud beats silent), but it is
   a judgement call someone else may want to revisit.
