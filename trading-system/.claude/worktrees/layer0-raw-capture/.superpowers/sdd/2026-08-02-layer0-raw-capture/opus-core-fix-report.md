# Layer 0 raw capture — core correctness fix report

Date: 2026-08-02
Branch: `worktree-layer0-raw-capture`
Model: Opus 5 (1M context)
Scope touched: `src/capture/raw_writer.py`, `src/capture/capture_ledger.py`,
`src/capture/sequencing.py` and their tests. `frame_codec.py` needed no change.
`venues/` and `venue_recorder.py` were not touched.

## Status

All four Critical and all four Important defects are fixed, each with regression
tests that fail against the pre-fix source and pass after.

| | before | after |
|---|---|---|
| Suite | 60 passed | **89 passed** |
| New/changed tests | — | 30 |
| New tests failing against pre-fix source | 26 | 0 |

```
$ export PATH="$HOME/.local/bin:$PATH" && uv run --python 3.12 pytest -q
........................................................................ [ 80%]
.................                                                        [100%]
89 passed in 0.18s
```

## Commits

| SHA | Unit |
|---|---|
| `a488886` | `fix(sequencing): let a stream slower than the staleness floor learn its cadence` (IMPORTANT 8) |
| `5c2946c` | `fix(capture_ledger): one torn line no longer loses the whole day` (IMPORTANT 7) |
| `03ea320` | `fix(raw_writer): stop truncating, mislabelling and silently accepting damage` (CRITICAL 1–4, IMPORTANT 5–6) |

The four raw_writer defects are one commit deliberately. They are not four
independent changes: they share `_read_lines`, `_open`, `close` and
`reconcile_pair`, and the fixes depend on each other. Append-mode resume
(C1) needs the truncation detection from C3 to know whether the existing pair is
readable; the `n`-authoritative reader (C2) is what makes a resumed `n` mean
anything; the close ordering (I5) is only "repairable" because reconcile locates
gaps by `n`. Splitting them would have required inventing intermediate source
states that never existed and could not be verified end to end. The commit
message documents each defect separately.

## How "fails before" was established

Three of the new exception types are new API, so a straight checkout of the
pre-fix source makes the new test modules fail at import — an honest failure but
a weak one. To get *behavioural* before-evidence, the pre-fix `src/` was restored
from HEAD and a shim appended that defines only the new **names** (empty
`Exception` subclasses and `writing_marker_path`), fixing no behaviour. Every
number below is from that run. The shim was discarded afterwards; it is not in
any commit.

```
$ git checkout -- src/ && cat >> src/capture/raw_writer.py <<'EOF'  # name-only shim
$ uv run --python 3.12 pytest -q -p no:randomly tests/test_raw_writer.py \
    tests/test_raw_writer_durability.py tests/test_capture_ledger.py tests/test_sequencing.py
26 failed, 26 passed in 0.41s
```

---

## CRITICAL 1 — `_open` used `"wb"`, so every open truncated the hour file

**Changed.** Both files now open `"ab"`. `_open` first calls a new
`_count_frames_already_written(raw_path, idx_path)`, which reads the existing
pair and returns the frame count so `self._n` resumes in step with what is
already on disk — without that, `n` would restart at 0 and every resumed entry
would carry a value that no longer matches its position, which is precisely what
C2's fix makes fatal. If the existing pair is torn or already misaligned the
count is unknowable, so the open is refused with a new `HourFileNotAppendable`
rather than extending a damaged file and burying the damage. The count happens
**before** any handle is opened, so a refusal touches nothing.

**Design decision (flagged):** resuming into a damaged hour is refused rather
than best-effort continued. Rationale: `n` must stay equal to a frame's position
or every later entry mislabels its frame, and there is no honest guess for the
resume count. The cost is that a `kill -9` leaves that hour unwritable until
`reconcile_pair` runs. See *Known limitations*.

**Regression tests** (`tests/test_raw_writer_durability.py`):
`test_restarting_mid_hour_appends_instead_of_truncating`,
`test_close_then_append_in_the_same_hour_keeps_earlier_frames`,
`test_out_of_order_timestamp_back_across_an_hour_does_not_destroy_it`,
`test_a_failed_open_does_not_destroy_the_existing_hour`,
`test_resuming_into_a_misaligned_hour_is_refused`.

**Before** (pre-fix source, `--tb=line`):
```
tests/.../test_restarting_mid_hour_appends_instead_of_truncating
E   assert ['{"frame":5}'] == ['{"frame":0}...'{"frame":5}']
tests/.../test_close_then_append_in_the_same_hour_keeps_earlier_frames
E   assert ['{"frame":3}'] == ['{"frame":0}...'{"frame":3}']
tests/.../test_out_of_order_timestamp_back_across_an_hour_does_not_destroy_it
E   assert ['{"frame":"05c"}'] == ['{"frame":"0...rame":"05c"}']
tests/.../test_a_failed_open_does_not_destroy_the_existing_hour
E   Failed: DID NOT RAISE OSError
tests/.../test_resuming_into_a_misaligned_hour_is_refused
E   Failed: DID NOT RAISE HourFileNotAppendable
```

`test_a_failed_open_does_not_destroy_the_existing_hour` reports `DID NOT RAISE`
on pre-fix code for an indirect reason — it injects `EMFILE` on *append-mode*
opens, which the pre-fix code never performs — so the underlying data loss was
also demonstrated directly, injecting on whichever mode each version uses:

```
--- PRE-FIX (HEAD~1 raw_writer) ---
raw bytes before: 36
raised: [Errno 24] Too many open files
raw bytes after : 0          <- the failed open truncated first, then raised
--- FIXED ---
raw bytes before: 36
raised: [Errno 24] Too many open files
raw bytes after : 36         <- untouched
```

**After:**
```
$ uv run --python 3.12 pytest -q -p no:randomly tests/test_raw_writer_durability.py \
    -k 'truncat or append or destroy or misaligned'
5 passed, 8 deselected in 0.03s
```

**Mutation check** — this is the mutation that survived all 32 in-scope tests
three fix rounds running. Reverting `"ab"` → `"wb"`:
```
$ # both open(raw_path,"ab") / open(idx_path,"ab") -> "wb"
$ uv run --python 3.12 pytest -q -p no:randomly | grep -c '^FAILED'
5
```

`zstandard.stream_reader` reading across concatenated frames was confirmed
independently before relying on it (zstandard 0.25.0), along with `decompressobj`
handling multi-frame input and an append-mode file written across three sessions.

---

## CRITICAL 2 — `reconcile_pair` assumed missing index entries are a suffix

**Changed.** `n` is now authoritative.

- `read_pair` verifies `entry.n == position` for every line and raises a new
  `IndexPositionMismatch` when it does not, instead of zipping positionally.
- `reconcile_pair` builds `entry_line_by_n` from the decoded `n` values, computes
  `missing = [n for n in range(len(raw_lines)) if n not in entry_line_by_n]`, and
  writes the index back in `n` order — so a hole in the middle is filled in the
  middle. It also refuses (`UnrepairableIndex`) when `n` values do not ascend, or
  when an entry describes a frame the raw file does not hold (the `idx > raw`
  direction, which previously returned 0 silently).
- `RawWriter.append` still increments `_n` immediately after the raw write. That
  behaviour is correct and now load-bearing: the unclaimed `n` is exactly how the
  hole is located.

**Corrected test — stated explicitly.**
`tests/test_raw_writer.py:149 test_append_increments_n_after_raw_write_not_idx_write`
asserted the broken state as correct and has been **replaced**, not preserved, by
`test_frame_after_a_failed_idx_write_keeps_its_own_receipt_time`. Its claim — that
`n` keeps incrementing so values are "not reused" — was true but hollow, because
nothing ever read `n`. The `n`-increment assertions are kept inside the new test;
what it now actually verifies is the guarantee they exist to provide: after a
mid-stream index write failure and a subsequent successful append, frame 1 reads
back as `kind="recovered"`, `t_recv_ns=0`, `seq=None`, and frame 2 keeps its own
`t_recv_ns` and `seq`. No test was weakened or deleted to make anything pass.

**Regression tests:** `tests/test_raw_writer.py::test_frame_after_a_failed_idx_write_keeps_its_own_receipt_time`,
`tests/test_raw_writer_reading.py::test_read_pair_refuses_an_entry_that_does_not_match_its_position`,
`::test_reconcile_inserts_a_recovered_entry_at_the_hole_not_at_the_end`,
`::test_reconcile_refuses_an_index_describing_frames_the_raw_file_lacks`.

**Before:**
```
tests/test_raw_writer.py:216
E   assert [0, 2, 2] == [0, 1, 2]          <- recovered entry appended at the end,
                                              so frame 1 got labelled n=2
tests/.../test_reconcile_inserts_a_recovered_entry_at_the_hole_not_at_the_end:190
E   assert [0, 3, 2, 3] == [0, 1, 2, 3]
tests/.../test_read_pair_refuses_an_entry_that_does_not_match_its_position:168
E   Failed: DID NOT RAISE IndexPositionMismatch
tests/.../test_reconcile_refuses_an_index_describing_frames_the_raw_file_lacks:210
E   Failed: DID NOT RAISE UnrepairableIndex
```

**After:**
```
$ uv run --python 3.12 pytest -q -p no:randomly \
    tests/test_raw_writer_reading.py::test_read_pair_refuses_an_entry_that_does_not_match_its_position \
    tests/test_raw_writer_reading.py::test_reconcile_inserts_a_recovered_entry_at_the_hole_not_at_the_end \
    tests/test_raw_writer_reading.py::test_reconcile_refuses_an_index_describing_frames_the_raw_file_lacks \
    tests/test_raw_writer.py::test_frame_after_a_failed_idx_write_keeps_its_own_receipt_time
4 passed in 0.03s
```

**Mutation checks:**
```
$ # delete the `if entry.n != position: raise IndexPositionMismatch` guard
1 FAILED
$ # reconcile back to `missing = range(len(idx_lines), len(raw_lines))` (suffix assumption)
2 FAILED
```

---

## CRITICAL 3 — a torn zstd tail was accepted silently

**Changed.** `_read_lines` no longer uses `stream_reader(...).read()`. A new
`_decode_concatenated_frames(path, data)` walks the file frame by frame with
`ZstdDecompressor().decompressobj()`, advancing by
`len(data) - position - len(unused_data)`, and raises a new `TruncatedFrameFile`
when a frame's `eof` flag is false, when `ZstdError` is raised, or when a frame
consumes no input. The exception carries `recovered_lines` — the complete lines
decoded before the damage — so the intact prefix is salvageable deliberately
rather than by accident.

**Correction to the brief:** the report suggested `ZstdDecompressor.decompress()`
as the detector. That is not usable here. Verified:
```
decompress() multiframe RAISED: ZstdError could not determine content size in frame header
decompress() trunc      RAISED: ZstdError could not determine content size in frame header
```
It raises on *valid* stream-written frames too, because `stream_writer` emits no
content size in the frame header. `decompressobj().eof` is the working detector
and is what shipped.

Truncation is now detected on *any* file read through `_read_lines`, so the
"raw and idx lose the same group, counts match, read_pair reports success" case
is caught regardless of whether the surviving counts happen to agree.

**Regression tests** (`tests/test_raw_writer_reading.py`):
`test_torn_raw_tail_never_returns_a_partial_line_as_a_frame` (asserts every
returned line is parseable JSON — this one fails on pre-fix code without needing
any new symbol), `test_torn_raw_tail_is_raised_with_the_recoverable_prefix`,
`test_matching_damage_in_both_files_is_still_detected`,
`test_a_final_line_without_its_newline_is_refused`.

**Before:**
```
tests/.../test_torn_raw_tail_never_returns_a_partial_line_as_a_frame:239
E   Failed: a truncated raw file was accepted as complete
tests/.../test_torn_raw_tail_is_raised_with_the_recoverable_prefix:259
E   assert 4 == 12                          <- reopening truncated the earlier frames
tests/.../test_matching_damage_in_both_files_is_still_detected:282
E   Failed: DID NOT RAISE TruncatedFrameFile
tests/.../test_a_final_line_without_its_newline_is_refused:295
E   Failed: DID NOT RAISE TruncatedFrameFile
```

**After:**
```
$ uv run --python 3.12 pytest -q -p no:randomly tests/test_raw_writer_reading.py \
    -k 'torn or newline or damage'
4 passed, 6 deselected in 0.04s
```

**Finding worth recording:** within a *single* zstd frame the recoverable prefix
is often **empty**, because zstd emits nothing until a compressed block
completes — a 13 KB file holding 400 frames is one block, so chopping one byte
loses all of it. Salvage only works across frame boundaries, i.e. for the frames
written by earlier opens. The test asserts exactly that (8 of 12 lines survive
across three write sessions) rather than claiming a salvage guarantee that does
not hold. This is another reason the damage is *raised* rather than reported as
"however much happened to decode".

---

## CRITICAL 4 — `rstrip("\n")` stripped all trailing newlines

**Changed.** `_read_lines` now strips exactly one:

```python
if not text:
    return []
if not text.endswith("\n"):
    raise TruncatedFrameFile(path, "final line has no terminating newline", lines[:-1])
return text[:-1].split("\n")
```

Every line the writer emits is newline-terminated, so this is total: an empty
payload survives as an empty line, and text that does not end in a newline is a
partial final line and is refused (which is also half of the C3 fix).

**Regression tests** (`tests/test_raw_writer_reading.py`):
`test_trailing_empty_payload_does_not_create_a_mismatch`,
`test_consecutive_empty_payloads_each_keep_their_own_line`,
`test_empty_payload_frame_survives_as_an_empty_line` (this last one passes on
pre-fix code — a mid-stream empty payload was never affected, only a trailing
one — and is kept as the companion case).

**Before:**
```
E   capture.raw_writer.PairLengthMismatch: Pair length mismatch: ...ndjson.zst has 1 lines,
    ...idx.zst has 2 lines. Run reconcile_pair to repair.
E   capture.raw_writer.PairLengthMismatch: Pair length mismatch: ...ndjson.zst has 1 lines,
    ...idx.zst has 3 lines. Run reconcile_pair to repair.
```

**After:**
```
$ uv run --python 3.12 pytest -q -p no:randomly tests/test_raw_writer_reading.py -k 'empty_payload'
3 passed, 7 deselected in 0.02s
```

**Mutation check:**
```
$ # restore `return text.rstrip("\n").split("\n")`
2 FAILED
```

---

## IMPORTANT 5 — `close()` ordering guaranteed the unrepairable direction

**Changed.** Raw is now finished **completely** first — `_raw_z.close()` then
`_raw_fh.close()` — and the index stream's footer is written **only if raw came
down cleanly**. If raw's close fails, the index's unfinished frame is
deliberately abandoned so it cannot gain a tail raw does not have. Every
descriptor is still closed and the marker still removed regardless; errors are
collected and re-raised (single error re-raised as-is, several as an
`ExceptionGroup`), preserving the all-resources-attempted behaviour that
`venue_recorder.close()` depends on.

`flush()` was reordered on the same principle (raw stream + raw handle, then
index stream + index handle).

**Reasoning recorded:** no ordering can guarantee `raw ≥ idx` under an arbitrary
single failure if both closes are always attempted — closing idx first merely
moves the failure. The guarantee requires making the index's completion
*conditional* on raw's, which is what shipped. When raw's close fails both files
end up torn, which C3's detection surfaces rather than hiding.

**Regression tests** (`tests/test_raw_writer_durability.py`):
`test_close_never_leaves_the_index_longer_than_the_raw_file` (the reported
repro), plus two guards that already passed and must keep passing —
`test_close_still_releases_every_descriptor_when_raw_close_fails` and
`test_close_leaves_a_repairable_pair_when_the_index_close_fails`.

**Before:**
```
tests/.../test_close_never_leaves_the_index_longer_than_the_raw_file:368
E   AssertionError: close() left idx=5 lines against raw=0: the one direction
    reconcile_pair cannot repair
```
(matches the reported repro exactly: `raw lines=0 idx lines=5`)

**After:**
```
$ uv run --python 3.12 pytest -q -p no:randomly tests/test_raw_writer_durability.py -k 'close'
5 passed, 8 deselected in 0.03s
```

**Mutation check:**
```
$ # `if raw_is_complete and self._idx_z is not None:` -> `if self._idx_z is not None:`
FAILED tests/test_raw_writer_durability.py::test_close_never_leaves_the_index_longer_than_the_raw_file
```

---

## IMPORTANT 6 — repairing a live hour discarded later entries

**Changed.** `reconcile_pair` now refuses. A `RawWriter` writes a sidecar
`<stream>_<symbol>_<hour>.writing` containing its pid for as long as it holds the
hour open, and removes it in `close()`. New `is_hour_being_written(raw_path)`
returns `(is_live, marker_path, pid)`: a marker whose pid is gone is stale — left
by a crash — and does not block repair; an unparseable marker is treated as live,
because refusing a repair is recoverable and clobbering a live writer's index is
not. `reconcile_pair` raises the new `HourStillBeingWritten` when the hour is
live.

Two other repair behaviours were tightened at the same time, both documented in
the docstring: a torn **index** tail is tolerated (the index is rebuilt wholesale
anyway, so the intact prefix is used and the file is rewritten even when nothing
is "missing"), while a torn **raw** tail propagates `TruncatedFrameFile` — those
frames cannot be reconstructed from anywhere and must not be written out of
existence.

Failure to place the marker (`OSError`) does not cost live frames; the writer
continues without it.

**Regression tests** (`tests/test_raw_writer_durability.py`):
`test_reconcile_refuses_an_hour_a_writer_still_holds_open` (the reported repro:
refuses, then 3 more frames are written and all 6 read back),
`test_the_writing_marker_is_removed_once_the_hour_is_closed`,
`test_a_stale_marker_from_a_dead_process_does_not_block_repair`,
`test_reconcile_rebuilds_an_index_whose_own_tail_is_torn`,
`test_reconcile_refuses_a_torn_raw_file`.

**Before:**
```
tests/.../test_reconcile_refuses_an_hour_a_writer_still_holds_open:427
E   Failed: DID NOT RAISE HourStillBeingWritten
tests/.../test_the_writing_marker_is_removed_once_the_hour_is_closed:442
E   AssertionError: assert False           <- marker never created
tests/.../test_reconcile_rebuilds_an_index_whose_own_tail_is_torn
E   PairLengthMismatch: ...ndjson.zst has 200 lines, ...idx.zst has 0 lines
tests/.../test_reconcile_refuses_a_torn_raw_file:497
E   Failed: DID NOT RAISE TruncatedFrameFile
```

**After:**
```
$ uv run --python 3.12 pytest -q -p no:randomly tests/test_raw_writer_durability.py \
    -k 'marker or holds_open or reconcile'
5 passed, 8 deselected in 0.04s
```

---

## IMPORTANT 7 — one torn line lost the whole day

**Changed.** `read_all` parses line by line, keeps every event that decodes, and
collects the rest on the result. New `DamagedLedgerLine(line_number, text, error)`
and `LedgerReadResult`, which **subclasses `list`** so it iterates and `len()`s
exactly like the event list callers already use, while exposing `.damaged` and an
`.events` property. `ValueError` (covering `json.JSONDecodeError`) and
`TypeError` (valid JSON that is not a `LedgerEvent`) are both captured.

**API-shape decision (flagged):** the natural design is a
`(events, damaged)` tuple or a plain dataclass, but `tests/test_venue_recorder.py`
iterates `read_all(...)` directly and `venue_recorder.py` is out of scope, so the
result had to stay list-shaped. The `list` subclass is the compromise: no caller
changes, damage is reachable rather than silently dropped. If
`venue_recorder`'s tests ever come into scope, this should become a plain
dataclass.

**Regression tests** (`tests/test_capture_ledger.py`):
`test_torn_final_line_does_not_lose_the_intact_events` (the reported repro: 5
events, 10 bytes truncated), `test_a_torn_line_in_the_middle_keeps_the_events_around_it`,
`test_a_line_that_is_json_but_not_an_event_is_reported_damaged`,
`test_an_intact_ledger_reports_no_damage`.

**Before:**
```
E   json.decoder.JSONDecodeError: Unterminated string starting at: line 1 column 112 (char 111)
E   json.decoder.JSONDecodeError: Invalid control character at: line 1 column 61 (char 60)
E   TypeError: LedgerEvent.__init__() got an unexpected keyword argument 'not'
E   AttributeError: 'list' object has no attribute 'damaged'
```

**After:**
```
$ uv run --python 3.12 pytest -q -p no:randomly tests/test_capture_ledger.py
8 passed in 0.02s
```

**Mutation check** — replacing the `damaged.append(...)` with `pass`, i.e.
dropping torn lines silently:
```
3 FAILED
```

---

## IMPORTANT 8 — a stream slower than the floor never learned

**Changed.** Two things, both required.

1. **Warmup learns from every gap.** Previously only non-alarming gaps entered
   the window, so on a stream whose cadence exceeds the floor no gap ever
   qualified and the window stayed empty forever. Now, until `min_samples`
   (default 10) gaps are in hand, every gap is appended regardless of whether it
   alarmed:
   ```python
   if report is None or not self.has_baseline():
       self._gaps.append(gap)
   ```
   Once a baseline exists the original discipline resumes — stalls stay out of
   the learning window — and the floor still suppresses false alarms on fast
   streams. New `has_baseline()` predicate makes the state inspectable.

2. **Cadence is a low quantile, not the median.** New
   `_estimate_cadence_ns()` takes the 25th percentile (`cadence_quantile=0.25`).
   This is not cosmetic: warmup now puts genuine stalls into the window, and the
   existing `test_hyperliquid_stalls_do_not_poison_median` case (seven 60 s
   stalls followed by five 1 s intervals) leaves the median at 30.5 s — a 305 s
   threshold that would swallow the 40 s stall the test requires to be caught.
   Stalls only push gaps upward, so the fast end of the distribution is where the
   true cadence lives; the 25th percentile reads 1 s there and catches it.
   `min_samples` must be ≥ 7 for that test's first six stalls to be flagged
   during warmup; 10 was chosen for statistical sanity and verified against all
   five pre-existing staleness tests.

**Trade-off recorded:** `10 × p25` is a somewhat tighter threshold than
`10 × median` on a bursty stream (for a Poisson arrival process, p25 ≈ 0.29·mean
vs median ≈ 0.69·mean), so a very jittery stream could alarm sooner than before.
`multiple` and `cadence_quantile` are both constructor parameters if that needs
tuning against real venue data. `min` was rejected as the estimator: a single
fast burst in a slow stream would collapse the threshold back to the floor and
reintroduce this exact bug.

The pre-existing behaviours held solid — the staleness floor, stall exclusion
once a baseline exists, and `BinanceDepthTracker`'s state discipline were not
touched and all their tests still pass.

**Regression tests** (`tests/test_sequencing.py`):
`test_hyperliquid_stream_slower_than_the_floor_learns_its_cadence` (200 frames at
8 s against a 5 s floor), `test_hyperliquid_slow_stream_still_flags_a_real_outage`
(a 30-minute outage after learning, with the threshold asserted to be above the
floor so it is the *learned* cadence doing the work).

**Before:**
```
E   AssertionError: 199 false alarms on a steady 8s stream
E   assert 5.0 > 5.0            <- threshold never rose above the floor
```
(matches the reported repro: `frames=200 alarms=199 window_len=0`)

**After:**
```
$ uv run --python 3.12 pytest -q -p no:randomly tests/test_sequencing.py -k 'slower or slow_stream'
2 passed, 9 deselected in 0.01s
```
Measured after the fix: **10 alarms** during warmup instead of 199, then silence;
`has_baseline()` true; a 1800 s outage still flagged.

**Mutation check:**
```
$ # `if report is None or not self.has_baseline():` -> `if report is None:`
2 FAILED
```

---

## `test_hour_key_is_utc` — now genuinely constrains UTC

The old test asserted only the UTC answer, which is what a box already in UTC
returns whether or not `hour_key` asks for it — the mutation dropping
`tz=dt.timezone.utc` survived it. The test now moves the process timezone to
`Asia/Kolkata` (UTC+05:30, no DST) with `monkeypatch.setenv` + `time.tzset()`,
restoring it in a `finally`, and asserts two timestamps: 05:30 UTC (naive read
would say hour 11) and 23:30 UTC (naive read would say the wrong *date* as well).

**Mutation check** — this is the second mutation the brief reported as surviving:
```
$ # dt.datetime.fromtimestamp(ts_ns // 1_000_000_000, tz=dt.timezone.utc)
$ #   -> dt.datetime.fromtimestamp(ts_ns // 1_000_000_000)
$ uv run --python 3.12 pytest -q -p no:randomly tests/test_raw_writer.py::test_hour_key_is_utc
FAILED tests/test_raw_writer.py::test_hour_key_is_utc - AssertionError
1 failed in 0.03s
```

---

## Mutation testing summary

Eight mutations run against the final suite. **All eight killed**; the first two
are the ones the brief reported as surviving all 32 in-scope tests.

| Mutation | Tests failed |
|---|---|
| `open(..., "ab")` → `"wb"` (C1) | 5 |
| `hour_key` drops `tz=dt.timezone.utc` | 1 |
| `read_pair` drops the `entry.n != position` guard (C2) | 1 |
| `reconcile_pair` back to the suffix assumption (C2) | 2 |
| `_read_lines` back to `rstrip("\n")` (C4) | 2 |
| `close()` finishes idx unconditionally (I5) | 1 |
| staleness warmup stops learning above the floor (I8) | 2 |
| `read_all` drops damaged lines silently (I7) | 3 |

## Verified-solid behaviours, confirmed not regressed

The escape codec (`frame_codec.escape_payload` / `unescape_payload`, backslash
and U+2028 round-trips), `BinanceDepthTracker`'s state discipline including the
malformed-message case, the `PairLengthMismatch` refusal, and the staleness floor
all still pass their original tests unchanged. `frame_codec.py` needed no edit.
All 17 `venues/` and `venue_recorder` tests pass untouched.

## New public API

`src/capture/raw_writer.py`
- `RawCaptureError` — base for all pair damage; existing `PairLengthMismatch` now
  subclasses it (still catchable as `Exception` exactly as before).
- `TruncatedFrameFile(path, reason, recovered_lines)`
- `IndexPositionMismatch(raw_path, idx_path, position, entry_n)`
- `UnrepairableIndex(raw_path, idx_path, reason)`
- `HourStillBeingWritten(raw_path, marker_path, pid)`
- `HourFileNotAppendable(raw_path, idx_path, reason)`
- `writing_marker_path(raw_path)`, `is_hour_being_written(raw_path)`
- constants `RAW_SUFFIX`, `IDX_SUFFIX`, `WRITING_MARKER_SUFFIX`

`src/capture/capture_ledger.py`
- `DamagedLedgerLine`, `LedgerReadResult` (list subclass with `.damaged`)

`src/capture/sequencing.py`
- `HyperliquidStalenessTracker(..., min_samples=10, cadence_quantile=0.25)`,
  `has_baseline()`

## Known limitations — not fixed, and why

1. **A torn hour cannot be resumed until it is repaired.** After a `kill -9`,
   `_open` refuses that hour with `HourFileNotAppendable` and live frames for it
   are lost until an operator runs `reconcile_pair`. The alternative — appending
   past a torn frame — would put an unreadable frame in the *middle* of the file,
   which no reader can resync past, destroying everything after it too. Refusing
   loudly was chosen over compounding the damage silently, per invariant 2. A
   future fix would be resync-by-magic-number scanning (`0xFD2FB528`) or rotating
   damaged hours to a `.damaged` sidecar; both are new design, out of scope here.

2. **`reconcile_pair` cannot repair a torn raw tail.** Raw frames are not
   reconstructible; the damage propagates as `TruncatedFrameFile`. The intact
   prefix is available on the exception's `recovered_lines` for manual salvage.

3. **The `.writing` marker's pid check can be fooled by pid reuse.** A crashed
   writer whose pid has since been recycled by an unrelated live process makes
   `reconcile_pair` refuse. This fails safe (refusal, not corruption) and the
   exception message tells the operator to delete the marker. Storing a boot id
   or process start time would close it; it was judged not worth the machinery.

4. **A cleanly-lost tail frame is still undetectable.** If a whole zstd frame
   disappears at an exact boundary from *both* files, nothing at this layer can
   tell. Only *torn* frames are detectable. This is inherent to the format.

5. **`LedgerReadResult` subclasses `list`** rather than being a plain dataclass,
   only because `venue_recorder`'s tests are out of scope (see IMPORTANT 7).

6. **Reading a large existing hour on restart costs one full decompress** of both
   files, once, in `_open`. Fresh hours skip it entirely (the files do not exist).
   The last-entry `n` check is O(1) rather than decoding every index line.

## Reproducing the verification

```bash
export PATH="$HOME/.local/bin:$PATH"
cd /home/anushadudekula71/trading-system/.claude/worktrees/layer0-raw-capture
uv run --python 3.12 pytest -q                     # 89 passed
```

Per-defect:
```bash
uv run --python 3.12 pytest -q -p no:randomly tests/test_raw_writer_durability.py \
  -k 'truncat or append or destroy or misaligned'        # C1  5 passed
uv run --python 3.12 pytest -q -p no:randomly tests/test_raw_writer_reading.py \
  -k 'torn or newline or damage'                         # C3  4 passed
uv run --python 3.12 pytest -q -p no:randomly tests/test_raw_writer_reading.py \
  -k 'empty_payload'                                     # C4  3 passed
uv run --python 3.12 pytest -q -p no:randomly tests/test_raw_writer_durability.py \
  -k 'close'                                             # I5  5 passed
uv run --python 3.12 pytest -q -p no:randomly tests/test_raw_writer_durability.py \
  -k 'marker or holds_open or reconcile'                 # I6  5 passed
uv run --python 3.12 pytest -q -p no:randomly tests/test_capture_ledger.py   # I7  8 passed
uv run --python 3.12 pytest -q -p no:randomly tests/test_sequencing.py \
  -k 'slower or slow_stream'                             # I8  2 passed
```

---

# Round 2 — the liveness defect the fix wave introduced

Date: 2026-08-02
Branch: `worktree-layer0-raw-capture`
Model: Opus 5 (1M context)
Scope touched: `src/capture/raw_writer.py`, `src/capture/sequencing.py`,
`src/capture/venue_recorder.py` (isolation only), `pyproject.toml`, and their tests.

## Status

| | round 1 | round 2 |
|---|---|---|
| Suite | 89 passed | **105 passed** |
| Tests added | — | 16 |
| Order-shuffled | never (see below) | seeds 1, 7, 42, 99, 2026 + control |

All five items are addressed. One additional defect was found in my own round-2
change during self-review and fixed before it shipped (`326f284`).

```
$ export PATH="$HOME/.local/bin:$PATH" && uv run --python 3.12 pytest -q
105 passed in 0.29s
```

## Commits

| SHA | Unit |
|---|---|
| `8ac8e90` | `fix(sequencing): a bursty healthy stream no longer sits in permanent alarm` (IMPORTANT) |
| `0eccee3` | `fix(raw_writer): reconcile_pair repairs a torn raw file, so the refusal has an exit` (CRITICAL half 1 + both MINOR honesty fixes) |
| `8ba57a8` | `fix(venue_recorder): a damaged hour on one stream no longer takes the venue down` (CRITICAL half 2) |
| `a252112` | `test(frame_codec): constrain backslash escaping` (MINOR, kills M16) |
| `33cd13c` | `test: install pytest-randomly so the suite is actually order-shuffled` |
| `326f284` | `fix(raw_writer): repair itself must survive being interrupted` (self-review finding) |

---

## CRITICAL — the refusal now has an exit, and the damage stays in its stream

### Reproduced first, exactly as reported

```
$ uv run --python 3.12 python scratchpad/repro_liveness.py     # BEFORE
append 1:   HourFileNotAppendable: Cannot resume appending to ...
reconcile:  TruncatedFrameFile: ... is truncated (zstd frame starting at byte 0 is incomplete)
append 2:   HourFileNotAppendable: Cannot resume appending to ...
session 1 written: 400
session 2 died: HourFileNotAppendable at written=0
undamaged ETHUSDT stream files created: 0
```

### Half 1 — the remedy terminates

`reconcile_pair` now salvages a torn raw file instead of raising on it. The
design, and why each part of it:

* **Salvage down to the last intact zstd frame, then rewrite.** A torn frame
  followed by newly appended frames is not readable at all, so the damaged tail
  cannot simply be left in place for `append` to extend.
* **Quarantine before overwriting.** `_quarantine_file` copies the original bytes
  to `<name>.quarantine-<UTC>` first. Repair is the only operation in the module
  that destroys data, and it runs precisely when the data is already damaged —
  the worst moment to be wrong about what was salvageable. The suffix goes on the
  end of the full name so a quarantined file never matches a raw/index glob.
* **Drop index entries whose frames did not survive — only when the raw file was
  actually torn.** An index overrunning an *intact* raw file is still
  `UnrepairableIndex`: that is corruption rather than a crash, and the operator
  should look at it. The venue survives that refusal now (half 2), so it is no
  longer a trap.
* **Rebuild a missing index entirely.** `_open` refuses a missing index the same
  way it refuses a torn pair, so refusing to repair it would be the same dead end.
* **Verify appendability afterwards** by calling the same
  `_count_frames_already_written` check `_open` makes. "Repaired" now means "a
  writer can resume", not "the tool ran". This is the property that makes the
  cycle terminate.
* **Return `RepairOutcome`, not an `int`.** `entries_rebuilt` alone reads
  reassuringly on a repair that saved every frame's bytes while losing every
  frame's timestamp.

```
$ uv run --python 3.12 python scratchpad/repro_liveness.py     # AFTER
append 1:   HourFileNotAppendable: ...            <- refusal kept, as ratified
reconcile:  RepairOutcome(entries_rebuilt=0, entries_discarded=400,
                          raw_frames_kept=0, raw_was_salvaged=True,
                          quarantined_paths=(...ndjson.zst.quarantine-...,
                                             ...idx.zst.quarantine-...))
append 2:   OK
```

### Half 2 — the blast radius stops at the stream

`consume` now routes every append through `_append_or_quarantine_stream`. The
first `RawCaptureError` quarantines that `(stream, symbol)` and records an
`unwritable_stream` ledger event; later frames for it are counted under a new
`unwritable` stat rather than retried, because the condition is persistent by
construction and retrying would put a ledger event and a decompress of the
damaged hour behind every arriving frame. `close()` records an
`unwritable_stream_total` per quarantined stream so the size of the loss reaches
the ledger rather than dying with the process.

Only `RawCaptureError` is isolated. It names damage to one hour's files, which is
inherently per-stream. `ENOSPC`, a bad descriptor and `MemoryError` still unwind
the loop — `test_a_non_capture_error_still_unwinds_the_loop` pins that.

```
session 1 written: 400
undamaged ETHUSDT stream files created: 2       (was 0)
```

### Regression tests, fails-before / passes-after

```
$ git show HEAD:src/capture/venue_recorder.py > src/capture/venue_recorder.py   # pre-fix
$ uv run --python 3.12 pytest -q tests/test_venue_recorder.py
FAILED test_a_damaged_hour_does_not_stop_a_sibling_stream_recording
FAILED test_a_quarantined_stream_is_not_retried_per_frame
FAILED test_recording_resumes_after_the_hour_is_repaired
3 failed, 8 passed
$ # restored
11 passed
```

`tests/test_raw_writer_durability.py` (20 passed) adds:
`test_reconcile_repairs_a_torn_raw_file_so_appending_resumes` (the full
refuse → repair → resume cycle), `..._is_idempotent`,
`..._salvages_when_both_files_are_torn`,
`test_a_single_block_hour_loses_all_of_it_to_one_byte`,
`test_a_repair_interrupted_halfway_can_still_be_finished`,
`test_reconcile_rebuilds_an_index_that_is_missing_entirely`,
`test_reconcile_reports_a_missing_raw_file_as_a_capture_error`,
`test_reconcile_of_an_absent_hour_is_a_no_op`.
`test_reconcile_refuses_a_torn_raw_file` was **replaced** — it asserted the
behaviour that is the defect.

### Self-review finding, fixed before shipping (`326f284`)

My first version ordered the two `_write_lines` calls raw-first. Repair runs
after a crash, so it must survive being crashed itself: writing the salvaged
(short) raw file first and dying leaves it beside the original (long) index, the
raw file is no longer torn, and the overrunning index is then correctly refused
as `UnrepairableIndex` — reintroducing the exact dead end being fixed. Index-first
leaves the torn raw file untouched so the next run redoes the whole salvage.
Verified by injecting `OSError` into the second `_write_lines`:

```
raw-first:   UnrepairableIndex: index line 8 carries n=8 but the raw file holds
             only 8 frames, so it describes a frame that does not exist
index-first: repair completes, hour resumes, reads back 9 frames
```

Caution for anyone repeating that experiment: the two orderings are
**byte-identical in file size**, which defeats Python's mtime+size `.pyc` check.
`__pycache__` must be cleared between runs or the experiment silently reports the
previous result. It did exactly that to me once.

### The honest limit of salvage — and why it was not "made cheap"

Salvage granularity is zstd's compressed **block**, not the line. Probed directly
against zstandard 0.25.0 on a torn 400-frame hour (374 bytes, one block):

```
decompressobj         -> 0 bytes, eof False
stream_reader         -> 0 bytes
stream_reader chunked -> 0 bytes
```

Nothing recovers anything from a torn block. An hour written in one open is one
block, so one chopped byte costs all 400 frames — the pair is quarantined,
emptied and made appendable, and `RepairOutcome` says so exactly
(`raw_frames_kept=0, entries_discarded=400`). An hour that survived several opens
keeps every complete frame before the damaged one (8 of 12 in the test).

This is a pre-existing property of the writer's flush cadence, not of the repair,
and only a more frequent zstd frame boundary in `RawWriter` would bound it — a
capture-spec decision about storage cost that I did not make unilaterally. **See
"Open question for the operator" below.**

On the reviewer's related note: the index-chop test no longer rests on
`repaired > 0`. It now asserts the real cost — `entries_rebuilt == 200`, every
entry `kind="recovered"` with `t_recv_ns == 0` — so the loss is visible rather
than implied.

---

## IMPORTANT — p25 no longer reintroduces I8 on bursty streams

### Reproduced first

```
$ uv run --python 3.12 python scratchpad/repro_bursty.py        # BEFORE
frames 0-100: 66   100-200: 69   300-400: 59   500-600: 58
total 374/600 (62%)   p25 = 0.486s   max threshold ever seen = 5.22s
```

### Why a single quantile cannot do it

The two windows are structurally identical bimodal distributions —
`[1s ×5, 60s ×7]` for the stall-contamination case and `[0.5s ×40, 6s ×60]` for
the bursty one. The first needs a threshold below 40s, the second above 6s. No
fixed quantile gives both. The distinguishing information is **temporal**: after
a baseline exists, the stall case alarms almost never while the bursty case
alarms 60% of the time. So the mechanism changed, not the constant.

### The mechanism

Threshold is the widest of three terms, each answering a different question:

| term | question | why it is needed |
|---|---|---|
| `floor_seconds` | how fast is too fast to alarm on? | a 10ms stream would alarm on jitter |
| `multiple` × p25 | how much slower than typical is suspicious? | low, not median, so warmup stalls in the window cannot blind it |
| **p99 of the window** | what does this stream do *routinely*? | **new** — caps the false-alarm rate at ~1% by construction, whatever the distribution's shape |

Plus a uniform learning rule replacing the warmup special case: **learn from every
gap unless it exceeds `stall_multiple` (3×) the threshold.** Being flagged is
deliberately no longer enough to be excluded — that exclusion is what let a wrong
baseline become self-reinforcing, since the window refilled only with gaps that
already agreed with it. A gap merely over the line is evidence the baseline may be
wrong; a gap far beyond it is a stall and stays out, which is what stops a real
outage from teaching the tracker to ignore outages. This also removes the warmup
regime: an 8s gap against a 5s floor is nowhere near 3× it, so a stream slower
than the floor learns its cadence with no special case at all.

### All four requirements, measured simultaneously

| requirement | result |
|---|---|
| uniform 8s stream vs 5s floor learns its cadence | 10 alarms (all warmup), final threshold 80s, `has_baseline()` true |
| bursty-but-healthy does not sit in permanent alarm | **13 / 2 / 1 / 2** per 100 across frames 0-100 / 100-200 / 300-400 / 500-600 (was 51/55/56/58 as measured by the reviewer, 66/69/59/58 on my seed) |
| stalls stay out of the baseline once one exists | `test_hyperliquid_stalls_do_not_poison_median` passes; new `test_a_stall_far_beyond_the_threshold_stays_out_of_the_window` pins it directly |
| floor still suppresses false alarms on fast streams | 10ms stream, 1s gap → no alarm |

Alarm inflation on healthy streams (same shapes the reviewer measured, 600 gaps):

| stream | p25 (reported) | median (reported) | **this fix** |
|---|---|---|---|
| exponential mean 3s | 61 | 3 | **7** |
| exponential mean 20s | 43 | 9 | **23** (19 of them in the first 100 frames) |
| bursty | 339 | 5 | **20** (13 of them in the first 100) |

Genuine outages still detected: 30-minute outage on the 8s stream (threshold 80s),
on the bursty stream (threshold 6.3s), and 60s stall on a 1s stream (threshold 10s).

### Fails-before / passes-after

```
$ git show HEAD:src/capture/sequencing.py > src/capture/sequencing.py   # pre-fix
$ uv run --python 3.12 pytest -q tests/test_sequencing.py
FAILED test_bursty_healthy_stream_does_not_alarm_forever
FAILED test_bursty_stream_still_flags_a_real_outage
    assert report.detail["threshold_seconds"] > 5.0
E   assert 5.0 > 5.0
2 failed, 12 passed
$ # restored
14 passed
```

`test_a_stall_far_beyond_the_threshold_stays_out_of_the_window` passes both
before and after, by design — it guards the new learning rule rather than
reproducing the defect. Stated plainly rather than counted as before-evidence.

---

## MINOR — mutation M16 is now killed

`test_backslash_roundtrips_without_false_escape` used a payload with no newline,
so it took `escape_payload`'s early return and never reached the escape table;
`test_newline_is_escaped_and_roundtrips` had a newline but no backslash.

Two new tests use both in one payload. The mutant's failure is silent corruption,
not cosmetic: escaping the newline without first doubling the backslash makes the
literal characters `\` `n` indistinguishable from an escaped newline, so
`unescape_payload` returns a newline the venue never sent.

```
$ # mutant: _ESCAPES = (("\n", "\\n"), ("\r", "\\r"))     # backslash entry removed
$ uv run --python 3.12 pytest -q
FAILED tests/test_frame_codec.py::test_backslash_and_newline_in_one_payload_roundtrip
FAILED tests/test_frame_codec.py::test_a_payload_of_only_backslashes_before_a_newline_roundtrips
2 failed, 102 passed
$ # restored
104 passed
```

**M16 killed.**

---

## MINOR — two honesty fixes

**`raw_writer.py` marker comment.** The claim "repair stays safe because the pair
is still length-checked before and after any repair" was false, and confirmed so:
with `ENOSPC` forced on the marker write, `reconcile_pair` on a live hour
proceeds. The comment now states what actually happens — `is_hour_being_written`
reports the live hour as idle, repair swaps the index inode out from under the
writer's descriptor, and every entry written afterwards is lost — why the
post-repair check cannot prevent it (it runs before those entries exist), and why
opening without a marker is still preferred to losing the stream outright.

**`reconcile_pair` with a missing index.** No longer raises a bare
`FileNotFoundError`. A missing *index* is not an error at all — it is the extreme
of the damage repair exists to fix, and is rebuilt from the raw file. A missing
*raw* file raises the new `MissingPairFile(RawCaptureError)`.

---

## `-p no:randomly` — claim retracted and then made true

The reviewer is right: `pytest-randomly` was not installed, so every
`-p no:randomly` in the round-1 report disabled a plugin that was not there and
the suite had never been shuffled. Rather than drop the claim, the tool is
installed (`pyproject.toml` dev group) and the claim verified:

```
seed 1: 105 passed        seed 7: 105 passed        seed 42: 105 passed
seed 2026: 105 passed     seed 99: 105 passed
control (-p no:randomly): 105 passed
```

---

## Open question for the operator (not decided unilaterally)

**`RawWriter` never emits a zstd frame boundary until close/rotate, so an hour
written in one open is a single compressed block, and one torn byte costs the
entire hour.** Repair cannot improve on that — verified against all three
zstandard decode paths. Bounding it means calling `flush(FLUSH_FRAME)` (which
`RawWriter.flush()` already implements) on a cadence, which trades compression
ratio and syscalls for a bounded worst-case loss. That is a capture-spec decision
about storage cost versus durability, not a repair-tool one, so it is flagged
rather than chosen. Today's worst case is: one `kill -9` loses up to a full hour
of one stream's frames, quarantined rather than destroyed, and the venue keeps
recording everything else.

## Reproducing the verification

```bash
export PATH="$HOME/.local/bin:$PATH"
cd /home/anushadudekula71/trading-system/.claude/worktrees/layer0-raw-capture
uv run --python 3.12 pytest -q                          # 105 passed
uv run --python 3.12 pytest -q --randomly-seed=42       # 105 passed, shuffled
```

Per defect:
```bash
uv run --python 3.12 pytest -q tests/test_raw_writer_durability.py \
  -k 'torn or interrupted or missing or absent or single_block'   # CRITICAL half 1
uv run --python 3.12 pytest -q tests/test_venue_recorder.py \
  -k 'damaged or quarantined or resumes or non_capture'           # CRITICAL half 2
uv run --python 3.12 pytest -q tests/test_sequencing.py -k 'bursty or stall_far'  # IMPORTANT
uv run --python 3.12 pytest -q tests/test_frame_codec.py -k backslash             # M16
```

---

# Round 3 — periodic zstd frame boundary (operator ruling)

Date: 2026-08-02
Model: Opus 5 (1M context)
Scope touched: `src/capture/raw_writer.py` and `tests/test_raw_writer_durability.py`.
Compression level and the two-file layout unchanged, as directed.

## Status

Implemented as ruled: `flush(FLUSH_FRAME)` on both streams every ~30 seconds of
stream time, driven by `t_recv_ns`.

| | round 2 | round 3 |
|---|---|---|
| Suite | 105 passed | **118 passed** |
| Tests added | — | 13 |
| Failing against the round-2 source | — | 13 |
| Order-shuffled | seeds 1/7/42/99/2026 | seeds 3/11/42 + control |

```
$ export PATH="$HOME/.local/bin:$PATH" && uv run --python 3.12 pytest -q
118 passed in 0.54s
```

Commit: `c09c92b` `feat(raw_writer): emit a zstd frame boundary every 30s of stream time`

## What changed

* `flush_interval_seconds` constructor parameter, default `30.0`.
* `_flush_if_interval_elapsed(t_recv_ns)` runs **after both lines are written**,
  never between them — a boundary emitted mid-frame would put a raw line on one
  side of it and its index entry on the other, which is the mismatch every other
  ordering rule in this module exists to avoid.
* Cadence measured against the frame's own timestamp. No wall clock is read in
  this path at all: hour rotation is already timestamp-driven, replay of a
  recorded stream must produce byte-identical files, and a test must not have to
  wait 30 real seconds to observe a boundary.
* A timestamp reaching backwards **resets the reference without emitting a
  boundary**. Late arrivals are ordinary on a live socket, and treating one as
  "the interval elapsed" would emit a frame per late arrival. The cost of
  guessing wrong here is compression ratio, so it is spent on the side that does
  not fragment the file.
* `_last_flush_ns` is reset in both `_open` and `close`.

## Drift between raw and index — yes, in exactly one direction

They can drift, and it is the harmless one. `flush()` does raw first
(`_raw_z.flush(FLUSH_FRAME)` → `_raw_fh.flush()` → then the index). So:

* **Index flush fails after raw succeeded** (ENOSPC is the realistic cause): the
  raw file has a boundary the index lacks, and a crash leaves the index holding
  *fewer* complete entries than the raw file holds frames. That is the direction
  `reconcile_pair` repairs — the missing entries come back as `kind="recovered"`,
  costing their timestamps and nothing else.
* **The reverse cannot happen.** The index is never flushed before raw, and an
  exception on the raw side stops the sequence before the index is touched.

`test_a_failed_index_flush_drifts_only_in_the_repairable_direction` injects
`ENOSPC` into the index flush and asserts `idx_lines <= raw_lines`, then that the
pair still repairs back to appendable.

## Tests — fails before, passes after

```
$ git show HEAD:src/capture/raw_writer.py > src/capture/raw_writer.py   # round-2 source
$ uv run --python 3.12 pytest -q tests/test_raw_writer_durability.py
13 failed, 20 passed
$ # restored
118 passed
```

| test | asserts |
|---|---|
| `test_a_torn_hour_loses_only_the_frames_since_the_last_flush` | **91 of 100 frames recovered**, and they are exactly frames 0-90 |
| `test_without_the_cadence_the_same_damage_costs_the_whole_hour` | the contrast: 1 zstd frame, `recovered_lines == []` |
| `test_frames_at_risk_are_bounded_by_the_configured_interval` | 5 interval/cadence combinations, `at_risk <= interval/cadence + 1` |
| `test_a_smaller_flush_interval_emits_more_frames` | 5s/10s/30s → exactly 20/10/4 zstd frames on synthetic timestamps |
| `test_flush_keeps_raw_and_index_frame_aligned` | raw and index frame counts equal, line counts equal |
| `test_an_out_of_order_timestamp_does_not_emit_a_boundary` | 6 late arrivals → still 1 frame, all 6 readable |
| `test_rotation_still_works_with_flushing_enabled` | both hours intact, `n` contiguous across a late frame reaching back over the boundary |
| `test_repair_and_resume_still_terminate_with_flushing_enabled` | round 2's cycle, now salvaging **91 frames where it salvaged 0** |
| `test_a_failed_index_flush_drifts_only_in_the_repairable_direction` | drift direction, then repair back to appendable |

---

## Measurement — my numbers differ from the ruling's table, and it matters

I re-measured before reporting, and got a materially different picture. Both
measurements are reproducible; I believe the difference is *what was being
measured*, not an error, and the reconciliation is below. Flagging it because it
changes where the benefit actually lands — not to relitigate the ruling, which is
implemented as directed.

### Method

A `kill -9` does not truncate a file at a random offset — it keeps everything the
OS already received and loses only what is still in the writer's buffers. So loss
is measured by appending frames one at a time and, at sampled moments, reading the
file as the OS holds it (the Python file buffer and zstd's internal input buffer
are gone) and counting how many appended frames are unreadable.

*(My first two attempts at this were wrong and are worth recording: the first
crossed an hour boundary so the file held half the frames; the second truncated
at uniformly random byte offsets, which measures "cut the file in half", not a
crash. Both are in the scratchpad.)*

### Result — one hour, one file, frames lost to `kill -9`

```
depth stream, 36,000 frames/hour (10/s, 40-level book, 35.2 MB raw)
  cadence   size      vs none   worst   median   design bound
  none      9.587 MB   +0.00%     134       68   unbounded
  ~100s     9.513 MB   -0.78%     134       65   1001
  ~30s      9.623 MB   +0.37%     134       59   301
  ~10s      9.826 MB   +2.49%      99       50   101

slow l2Book, 450 frames/hour (8s cadence, 0.44 MB raw)
  cadence   size      vs none   worst   median   design bound
  none      0.120 MB   +0.00%     134       62   unbounded
  ~100s     0.131 MB   +9.04%      12        6   13
  ~30s      0.142 MB  +18.70%       3        2   4
  ~10s      0.158 MB  +31.64%       1        1   2
```

### Three findings

**1. The benefit lands on slow streams, not fast ones.** zstd's own ~128 KB block
boundary already bounds loss to about 134 frames. On a 10/s depth stream that is
~13 seconds of data, so a 30s cadence is *looser* than what zstd was doing
anyway and changes the worst case not at all (134 → 134). On an 8s-cadence
l2Book, 134 frames is **~18 minutes** of data, and the cadence cuts it to 3
frames. That is a large, real win — just not on the stream the ruling's table was
measured on.

**2. The storage cost is inverted the same way.** +0.37% on the depth stream
(the ruling estimated +1.8%), but **+18.7%** on the slow l2Book — the concern I
flagged in round 2, now measured. In absolute terms it is 22 KB/hour, so it does
not threaten the disk runway; it is only the percentage that looks alarming.
Cost is highest exactly where the benefit is highest, and both are negligible in
bytes.

**3. My own round-2 claim was too strong, and I am correcting it.** I wrote that
"one chopped byte costs the whole hour". That is true only when the hour's data
fits in a **single zstd block** — the round-2 repro was 400 frames compressing to
374 bytes. At realistic hour sizes a single zstd *frame* contains many *blocks*,
and a torn tail loses only the last incomplete block. The round-2 tests and the
limitation note in `reconcile_pair`'s docstring are still accurate as written
(they describe the single-block case explicitly), but the general framing was
overstated.

### Reconciling with the ruling's table

The ruling's "worst-case loss: 19.66 MB, the whole hour" is almost certainly the
**pre-round-2** worst case, and it was correct then: before `reconcile_pair`
could salvage a torn raw file, a torn hour was unreadable *and* unrepairable, so
the entire hour was lost regardless of how much of it was decodable. Round 2's
salvage is what turned "the whole hour" into "the unflushed tail". Measured
against the post-round-2 code, the marginal value of the cadence is the 134 → 3
improvement on slow streams.

Both numbers are right for the code they describe. The ruling's cost/benefit
still holds — it is just that the benefit now comes from a different place than
the table implies.

### Not changed on my own authority

If the intent is to bound fast streams too, 30s does not do it and the interval
would need to be ~10s, or the trigger would need a byte-count term alongside the
time term. That is a fresh cost/benefit decision on the same axis the operator
just ruled on, so it is flagged, not taken.

## Reproducing

```bash
export PATH="$HOME/.local/bin:$PATH"
cd /home/anushadudekula71/trading-system/.claude/worktrees/layer0-raw-capture
uv run --python 3.12 pytest -q                       # 118 passed
uv run --python 3.12 pytest -q --randomly-seed=42    # 118 passed, shuffled
uv run --python 3.12 pytest -q tests/test_raw_writer_durability.py \
  -k 'flush or cadence or boundary or interval or torn_hour'
```
