# Task 8 Report: Venue recorder

## What was implemented

`src/capture/venue_recorder.py` — `VenueRecorder(venue, specs, root, queue_size=10_000, clock_ns=time.time_ns)`,
with `async def consume(self, frames: AsyncIterator[str]) -> None` and `def stats(self) -> dict`,
exactly matching the brief's interface.

`consume()`:
1. Reads each frame off the async iterator, timestamps it via `clock_ns()`.
2. Parses JSON; on `JSONDecodeError` the frame is still written verbatim (`kind="malformed"`,
   routed to an `("unknown","unknown")` writer) and a `malformed` ledger event is recorded.
   `stats()["malformed"]` increments; `written` still increments too — never discarded.
3. Calls `venue.extract(parsed)` for routing metadata (`stream`, `symbol`, `t_exch_ms`, `seq`, `kind`).
   `control` kind bumps `stats()["control"]`.
4. Picks the right gap tracker (`BinanceDepthTracker` for binance `depth`, `HyperliquidStalenessTracker`
   for hyperliquid `l2Book`, none otherwise) and, for data frames, calls `.check()` with the
   argument shape each tracker expects (parsed body for Binance, `t_recv_ns` for Hyperliquid).
   A non-`None` `GapReport` is recorded as a `gap` ledger event with the report's severity.
5. Writes the frame verbatim via the per-`(stream, symbol)` `RawWriter`, incrementing `written`.
6. On any exit (normal completion, an exception raised while processing a frame, or an exception
   raised by the frame iterator itself) `close()` runs via `finally`, closing every `RawWriter`
   and the `CaptureLedger`.

`stats()` keeps the `dropped` key at 0 always, per the SDD ruling: there is nowhere in this task
for a frame to be dropped to — that only becomes reachable once a bounded queue sits in front of
`consume()` (a later, unwritten task). The key, the zero-assertion in the test, and a comment
naming that future task are all kept, per instruction — no queue was built to make it live.

### Hardening beyond the brief's reference implementation

The brief's own notes flagged three things to consider for this task, all addressed:

1. **Unusual `stream`/`symbol` from `extract()` becoming path components.** `extract()` reads
   `stream`/`symbol` straight off the wire (event name, `body["s"]`, `item["coin"]`, ...).
   `RawWriter`'s `paths_for()` builds a filename as `f"{stream}_{symbol}_{hour}"` and joins it with
   `/`, which treats embedded `/` as path separators — a hostile or corrupted frame carrying
   `"s": "../../evil"` could steer a write outside the venue's intended directory. Added
   `_safe_path_token()`: anything not matching `^[A-Za-z0-9_.-]+$` falls back to `"unknown"`, the
   same bucket already used elsewhere for undeterminable routing fields. All real venue values
   (`"BTCUSDT"`, `"depth"`, `"l2Book"`, ...) match the pattern, so this is a no-op for well-formed
   traffic.
2. **Same `(stream, symbol)` pair appearing with different casing.** `_writer_for`/`_tracker_for`
   now key their dicts on `(stream.casefold(), symbol.casefold())` so `"BTCUSDT"` and `"btcusdt"`
   collapse into one writer (first-seen casing is what lands on disk) instead of silently
   splitting the same logical stream across two files.
3. **Writer or frame-iterator failure mid-loop leaking open handles.** The whole `async for` loop
   now runs inside `try: ... finally: self.close()`, so a `RawWriter.append()` raising, a
   `CaptureLedger.record()` raising, or the frame source itself raising (e.g. a websocket drop)
   still flushes and closes every writer and the ledger before the exception propagates. The
   exception is **not** swallowed — silently continuing past a write failure would be an
   undocumented drop with nowhere to record it (per the ruling above, `dropped` cannot be
   incremented in this task), so the recorder stops and surfaces the failure instead of hiding it.

## Files changed

- `src/capture/venue_recorder.py` (new)
- `tests/test_venue_recorder.py` (new)

## TDD evidence

**RED** — `uv run --python 3.12 pytest tests/test_venue_recorder.py -v` (brief's 3 tests, before
implementation existed):

```
ERROR collecting tests/test_venue_recorder.py
tests/test_venue_recorder.py:6: in <module>
    from capture.venue_recorder import VenueRecorder
E   ModuleNotFoundError: No module named 'capture.venue_recorder'
=========================== short test summary info ============================
ERROR tests/test_venue_recorder.py
!!!!!!!!!!!!!!!!!!!! Interrupted: 1 error during collection !!!!!!!!!!!!!!!!!!!!
=============================== 1 error in 0.09s ===============================
```

Expected and exact match to the brief: the module didn't exist yet.

**GREEN** — same command after implementing `src/capture/venue_recorder.py`:

```
tests/test_venue_recorder.py::test_writes_frames_and_counts_them PASSED  [ 33%]
tests/test_venue_recorder.py::test_broken_chain_records_corrupting_ledger_event PASSED [ 66%]
tests/test_venue_recorder.py::test_malformed_frame_is_still_written PASSED [100%]
============================== 3 passed in 0.03s ===============================
```

### Additional self-added tests for the hardening

Added 3 more tests to `tests/test_venue_recorder.py`, targeting the three concerns above:
`test_unsafe_symbol_does_not_escape_output_directory`,
`test_casing_variants_of_same_symbol_share_one_writer`,
`test_frame_iterator_failure_still_closes_writers_and_ledger`.

To confirm they weren't vacuous, I ran them against a copy of the brief's own unhardened
reference implementation (no sanitization, no casefold, no try/finally) — all three failed there,
exactly as expected:

```
FAILED tests/test_venue_recorder.py::test_unsafe_symbol_does_not_escape_output_directory
FAILED tests/test_venue_recorder.py::test_casing_variants_of_same_symbol_share_one_writer
  AssertionError: expected one depth file, got ['depth_btcusdt_...', 'depth_BTCUSDT_...']
FAILED tests/test_venue_recorder.py::test_frame_iterator_failure_still_closes_writers_and_ledger
  assert 0 == 1  (read_pair returned nothing - the zstd frame was never finalized)
======================= 3 failed, 3 deselected in 0.06s ========================
```

Then restored the hardened implementation and re-ran; all 6 pass:

```
uv run --python 3.12 pytest tests/test_venue_recorder.py -v
tests/test_venue_recorder.py::test_writes_frames_and_counts_them PASSED
tests/test_venue_recorder.py::test_broken_chain_records_corrupting_ledger_event PASSED
tests/test_venue_recorder.py::test_malformed_frame_is_still_written PASSED
tests/test_venue_recorder.py::test_unsafe_symbol_does_not_escape_output_directory PASSED
tests/test_venue_recorder.py::test_casing_variants_of_same_symbol_share_one_writer PASSED
tests/test_venue_recorder.py::test_frame_iterator_failure_still_closes_writers_and_ledger PASSED
============================== 6 passed in 0.04s ===============================
```

### Full suite

`uv run --python 3.12 pytest -v` → **59 passed** (53 pre-existing + 6 in this task), clean output,
no warnings.

## Self-review

- **Completeness**: interface matches the brief exactly (constructor signature, `consume()`,
  `stats()` keys). All 3 brief tests pass unmodified from the spec text.
- **YAGNI discipline**: no queue was built despite `queue_size` being accepted in the constructor
  (kept unused per the ruling, documented in the docstring). No retry logic, no backpressure, no
  metrics beyond the four required stats keys. The three hardening changes are each a few lines,
  scoped tightly to the exact failure mode named in the brief's own "quality bar" note, not a
  general defensive rewrite.
- **Do the tests verify real behaviour?** Yes — confirmed by running the 3 new hardening tests
  against the brief's unhardened reference and watching them fail for the right reason before
  restoring the hardened version and watching them pass.
- **Test output pristine?** Yes, `59 passed`, no warnings, no skipped tests.
- **Interfaces respected**: `RawWriter.append` signature, `LedgerEvent`/`CaptureLedger` from Task 5,
  `BinanceDepthTracker.check(parsed_dict)` vs `HyperliquidStalenessTracker.check(t_recv_ns)` called
  with the correct, different argument shapes per venue, `ExtractedMeta`/`StreamSpec` from Task 7 —
  none of these were modified.
- **Naming**: `_safe_path_token`, `_writer_for`, `_tracker_for`, `_record_gap` — verb+object,
  consistent with the existing style in this file and the rest of the package.

## Concerns

None blocking. One judgment call worth flagging: on a writer or ledger write failure, `consume()`
now propagates the exception after closing everything cleanly, rather than swallowing it and
continuing to the next frame. I chose this because silently continuing past a write failure would
be an undocumented data loss with no counter to record it against (the ruling forbids incrementing
`dropped` in this task). This means a single failing write currently halts ingestion for the whole
venue rather than just that one stream — that trade-off seems like the right one, but it's a
design decision by me rather than something the brief specified, so it's worth confirming intent
matches before any later task builds retry/backpressure behaviour on top of it.

---

## Fix round 1 (reviewer: Important)

**Finding:** `close()` aborted on the first failing writer's `close()`, orphaning every writer
after it in iteration order plus the `CaptureLedger` — their buffered zstandard data was never
flushed. Reviewer verified this directly (forced the first writer's `close()` to raise with two
writers open; the second writer's `_raw_z` and the ledger's `_fh` were both still non-`None`
afterward). This fires under the same disk-full condition that motivates the propagate-don't-swallow
design in `consume()`, and it contradicted the docstring's own claim that handles "must still be
closed... rather than leaked."

**Fix — `src/capture/venue_recorder.py`, `close()`:** now attempts every writer's `close()`
regardless of earlier failures, then always attempts `self._ledger.close()`, collecting exceptions
along the way and re-raising after every close was attempted (the single exception directly, or an
`ExceptionGroup` if more than one failed) — mirroring the nested try/finally pattern
`RawWriter.close()` already uses at `raw_writer.py:126-141` for the same reason.

```python
def close(self) -> None:
    errors: list[Exception] = []
    for writer in self._writers.values():
        try:
            writer.close()
        except Exception as exc:
            errors.append(exc)
    try:
        self._ledger.close()
    except Exception as exc:
        errors.append(exc)

    if len(errors) == 1:
        raise errors[0]
    if errors:
        raise ExceptionGroup("errors while closing venue recorder resources", errors)
```

**Covering test:** `test_close_still_closes_remaining_writers_and_ledger_when_one_fails` in
`tests/test_venue_recorder.py`. Opens two writers plus a ledger record (all with live handles),
monkeypatches the first writer's `close` to raise `OSError("disk full")`, calls `rec.close()`, and
asserts: the `OSError` still propagates, the *second* writer's `_raw_z` is `None` (closed), and the
ledger's `_fh` is `None` (closed) — i.e. the failure of the first close did not stop the rest.

Confirmed the test is a real regression check, not a restatement: reverted `close()` to the
pre-fix abort-on-first-failure version and re-ran just this test — it failed with
`assert <ZstdCompressionWriter ...> is None` (the second writer was still open), exactly the bug
the reviewer described. Restored the fix and re-ran; passes.

**Commands and output:**

```
$ uv run --python 3.12 pytest tests/test_venue_recorder.py -v
tests/test_venue_recorder.py::test_writes_frames_and_counts_them PASSED
tests/test_venue_recorder.py::test_broken_chain_records_corrupting_ledger_event PASSED
tests/test_venue_recorder.py::test_malformed_frame_is_still_written PASSED
tests/test_venue_recorder.py::test_unsafe_symbol_does_not_escape_output_directory PASSED
tests/test_venue_recorder.py::test_casing_variants_of_same_symbol_share_one_writer PASSED
tests/test_venue_recorder.py::test_frame_iterator_failure_still_closes_writers_and_ledger PASSED
tests/test_venue_recorder.py::test_close_still_closes_remaining_writers_and_ledger_when_one_fails PASSED
============================== 7 passed in 0.04s ===============================

$ uv run --python 3.12 pytest -v   (full suite, tail)
...
============================== 60 passed in 0.11s ==============================
```

60 passed = 59 from before this fix round + 1 new test. Clean output, no warnings.

**Deferred (not in scope, per reviewer's instruction to record and not fix here):**
- `_tracker_for` compares `stream` (not casefolded) against literal `"depth"`/`"l2Book"` while its
  cache key is casefolded — currently unreachable since no shipped venue emits those stream names
  in any other casing, but worth tightening if that ever changes.
- `stats()["control"]` is incremented but has no test asserting its value.

Files changed in this round: `src/capture/venue_recorder.py`, `tests/test_venue_recorder.py`.
