# Task 5: Capture Ledger - Implementation Report

## Summary

Implemented the capture ledger module to record capture anomalies as first-class, queryable events in NDJSON format. All interface requirements met exactly as specified in the brief.

## Implementation Details

### Files Created

1. **`src/capture/capture_ledger.py`** (65 lines)
   - `LedgerEvent` frozen dataclass with fields: `ts_ns`, `venue`, `stream`, `kind`, `severity`, `detail`
   - Severity constants: `SEVERITY_INFO`, `SEVERITY_OBSERVATION_LOSS`, `SEVERITY_CORRUPTING`
   - `CaptureLedger` class with:
     - `__init__(root: Path, venue: str)` - initializes ledger with root directory and venue
     - `record(event: LedgerEvent)` - appends event to NDJSON file, handling date rollovers automatically
     - `close()` - closes open file handle and resets state
   - `read_all(root: Path, venue: str, date: str)` - reads all events for a given UTC date
   - Helper functions:
     - `_date_of(ts_ns: int)` - converts nanoseconds to UTC date string (YYYY-MM-DD)
     - `_path_for(root, venue, date)` - constructs ledger file path

2. **`tests/test_capture_ledger.py`** (33 lines)
   - `test_records_and_reads_back()` - verifies single event roundtrip through record/close/read_all
   - `test_appends_across_multiple_records()` - verifies multiple events accumulate correctly

### Key Design Decisions

1. **NDJSON format** - plain uncompressed JSON, one event per line, for fast incident-time access
2. **Automatic date-based file rotation** - when event timestamp crosses UTC date boundary, closes current file and opens new one under dated subdirectory structure
3. **Append mode with flush** - files opened in append mode ("a") to handle reopening gracefully; flush() after each write ensures data visibility even if process crashes
4. **Empty line tolerance** - `read_all()` uses `if line.strip()` to skip any blank lines
5. **Deterministic JSON** - uses `sort_keys=True` and compact separators for consistent output

## TDD Process

### Step 1: Write Failing Test
Created `tests/test_capture_ledger.py` with two test functions as specified in brief.

### Step 2: Verify Test Fails
```
Command: uv run --python 3.12 pytest tests/test_capture_ledger.py -v

Output:
ModuleNotFoundError: No module named 'capture.capture_ledger'
```
✓ Failed as expected - module doesn't exist yet.

### Step 3: Implement Module
Created `src/capture/capture_ledger.py` with minimal, correct implementation matching the brief exactly.

### Step 4: Verify Tests Pass
```
Command: uv run --python 3.12 pytest tests/test_capture_ledger.py -v

Output:
tests/test_capture_ledger.py::test_records_and_reads_back PASSED         [ 50%]
tests/test_capture_ledger.py::test_appends_across_multiple_records PASSED [100%]

2 passed in 0.01s
```
✓ Both tests pass.

### Step 5: Full Test Suite Verification
```
Command: uv run --python 3.12 pytest tests/ -v

Output:
22 passed in 0.06s
```
✓ All 22 tests pass (20 pre-existing + 2 new). No regressions.

### Step 6: Commit
```
Commit: 9cbe78c feat: capture ledger for gap and anomaly events
Files: src/capture/capture_ledger.py (65 lines), tests/test_capture_ledger.py (33 lines)
```

## Self-Review Findings

### Completeness
✓ All interface requirements implemented exactly as specified:
- `LedgerEvent` dataclass with correct fields and frozen=True
- All three severity constants with exact values
- `CaptureLedger` class with record(), close()
- `read_all()` function with correct signature
- NDJSON format, uncompressed
- UTC date handling

### Quality Analysis

**Data Integrity:**
- Append mode with flush() ensures atomicity at line level
- Empty line handling in read_all prevents parse errors
- Deterministic JSON serialization (sort_keys=True) ensures consistent output
- No data loss on date rollovers - previous file properly closed before opening new one

**State Management:**
- File handle lifecycle well-managed: opened only when needed, properly closed on date changes or explicit close()
- close() is idempotent - safe to call multiple times or before any records
- Date tracking prevents unnecessary file operations

**Error Resilience:**
- read_all() gracefully handles missing ledger files (returns empty list)
- path.parent.mkdir(parents=True, exist_ok=True) handles concurrent directory creation
- File operations use encoding="utf-8" explicitly

### Test Coverage

The test suite verifies:
1. **Single event roundtrip** - records an event, closes, reads back, verifies all fields including detail dict
2. **Multiple event accumulation** - records 3 events in sequence, verifies all are present on read
3. **Date-based routing** - uses documented timestamp 1785648600_000_000_000 ns = 2026-08-02

The tests check real behavior (serialization, file I/O, data preservation) not just that code compiles.

### YAGNI Compliance
✓ No unnecessary features:
- No error handling beyond what tests require
- No logging, metrics, or instrumentation
- No caching or optimization
- No async support (not needed for incident-time queries)
- No validation of event fields
- Exactly what the brief specifies

### Test Output Quality
✓ Clean, pristine test output with no warnings:
```
collected 22 items

tests/test_capture_ledger.py::test_records_and_reads_back PASSED         [  4%]
tests/test_capture_ledger.py::test_appends_across_multiple_records PASSED [  9%]
... (20 other tests) ...
tests/test_scaffolding.py::test_package_imports PASSED                   [100%]

============================== 22 passed in 0.06s ==============================
```

## Code Review Feedback and Fixes

### Issue 1: Silent Data Loss on Non-Serializable Types (CRITICAL)

**Problem:** The original `json.dumps()` call has no fallback for non-JSON-serializable types. If `detail` dict contains `bytes` (a plausible case in Task 8 when reporting malformed payloads), `Decimal`, `set`, or enum, the call raises `TypeError`. This exception occurs inside `record()` — the exact moment when an anomaly needs to be recorded — causing both the loss of the anomaly AND exception propagation into caller code that is already handling an error.

**Fix:** Added `default=str` parameter to `json.dumps()`:
```python
self._fh.write(json.dumps(asdict(event), separators=(",", ":"), sort_keys=True, default=str) + "\n")
```

This ensures any unexpected type degrades gracefully to its string representation rather than losing the event. A lossy record of an anomaly is vastly better than no record.

**Test Added:** `test_handles_non_serializable_types_in_detail()`
- Records event with `bytes` object in detail dict: `{"payload": b"corrupted_bytes_data", ...}`
- Verifies event writes successfully (no TypeError)
- Verifies event reads back with payload stringified: `"b'corrupted_bytes_data'"`
- Confirms all fields preserved

### Issue 2: No Test Coverage for UTC Midnight Rollover

**Problem:** The file-rotation logic (lines 61-66 in `record()`) is the component's main risk and most complex code path, verified only by code inspection.

**Fix:** Added `test_midnight_rollover_routes_to_correct_date()`
- Records two events with deterministically computed timestamps:
  - Event 1: last second of 2026-08-02 (reference + 66599 seconds)
  - Event 2: first second of 2026-08-03 (reference + 86400 seconds)
- Verifies each lands in correct date-based file
- Confirms both read back correctly via separate `read_all()` calls per date
- Uses explicit timestamp calculation relative to known reference (1785648600_000_000_000 ns = 2026-08-02T05:30:00Z) for determinism

### Test Results After Fixes

```
Command: uv run --python 3.12 pytest tests/test_capture_ledger.py -v

tests/test_capture_ledger.py::test_records_and_reads_back PASSED         [ 25%]
tests/test_capture_ledger.py::test_appends_across_multiple_records PASSED [ 50%]
tests/test_capture_ledger.py::test_handles_non_serializable_types_in_detail PASSED [ 75%]
tests/test_capture_ledger.py::test_midnight_rollover_routes_to_correct_date PASSED [100%]

4 passed in 0.02s
```

### Full Test Suite After Fixes

```
Command: uv run --python 3.12 pytest tests/ -v

============================== 24 passed in 0.06s ==============================
```

✓ All 24 tests passing (20 pre-existing + 4 new)
✓ No regressions

## Files Changed

- Modified: `/src/capture/capture_ledger.py` - added `default=str` to json.dumps() call
- Modified: `/tests/test_capture_ledger.py` - added 2 new tests (lines expanded from 33 to ~70)
- Committed: `9cbe78c feat: capture ledger for gap and anomaly events`
- Committed: `0ef6c1d fix: handle non-serializable types in ledger events, add midnight rollover test`

## Verification

✓ All 24 tests passing (20 pre-existing + 4 new ledger tests)
✓ No regressions
✓ Critical data-loss risk eliminated: `default=str` prevents TypeError on non-JSON types
✓ UTC midnight rollover verified: deterministic test confirms file routing across date boundary
✓ Both code review issues addressed and tested
✓ TDD process followed throughout
