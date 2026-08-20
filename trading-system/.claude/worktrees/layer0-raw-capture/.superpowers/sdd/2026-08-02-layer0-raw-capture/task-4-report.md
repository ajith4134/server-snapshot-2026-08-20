# Task 4 Report: Crash recovery — reconcile raw/index pairs

## Implementation Summary

Implemented `reconcile_pair(raw_path: Path, idx_path: Path) -> int` to repair raw/index file pairs when a crash leaves the raw file with more lines than the index sidecar. The function rebuilds missing index entries without truncating any raw data and without inventing timestamps.

### Files Changed

1. **src/capture/raw_writer.py** — Added three new functions:
   - `_read_lines(path)`: Decompresses and reads lines using strict `"\n"` splitting (not `str.splitlines()` which splits on 10 additional characters)
   - `_write_lines(path, lines)`: Writes lines back compressed with zstandard
   - `reconcile_pair(raw_path, idx_path)`: Rebuilds missing index entries with `kind="recovered"` and `t_recv_ns=0`

2. **tests/test_raw_writer_recovery.py** — Created new test file with two test cases:
   - `test_reconcile_rebuilds_missing_index_entries`: Verifies that truncated index entries are rebuilt correctly
   - `test_reconcile_is_noop_when_aligned`: Verifies no action is taken when files are already aligned

## TDD Evidence

### RED (Failing Test)
```bash
$ uv run --python 3.12 pytest tests/test_raw_writer_recovery.py -v
E   ImportError: cannot import name 'reconcile_pair' from 'capture.raw_writer'
```
Expected failure: `reconcile_pair` did not exist.

### GREEN (Passing Tests)
```bash
$ uv run --python 3.12 pytest tests/test_raw_writer_recovery.py -v
tests/test_raw_writer_recovery.py::test_reconcile_rebuilds_missing_index_entries PASSED [ 50%]
tests/test_raw_writer_recovery.py::test_reconcile_is_noop_when_aligned PASSED [100%]

============================== 2 passed in 0.02s ===============================
```

### Full Test Suite
```bash
$ uv run --python 3.12 pytest tests/ -v
============================== 19 passed in 0.05s ==============================
```
All 19 tests pass (2 new recovery tests + 17 existing tests, all green).

## Self-Review

### Completeness
- ✓ Implements exact interface specified in brief: `reconcile_pair(raw_path: Path, idx_path: Path) -> int`
- ✓ Returns number of index entries repaired
- ✓ Handles case where index is already aligned (returns 0, no-op)
- ✓ Handles case where raw has more lines than index (rebuilds missing entries)
- ✓ Follows TDD step order exactly as specified

### Quality & Correctness
- ✓ Never truncates raw file (governing invariant from task context)
- ✓ Never invents timestamps (uses `t_recv_ns=0` with `kind="recovered"`)
- ✓ Uses strict `"\n"` splitting, not `str.splitlines()` (matches Task 3 review requirement)
- ✓ Uses `_read_lines` and `_write_lines` helpers for decompression/compression
- ✓ Respects contract from Task 3: `read_pair` raises `PairLengthMismatch`, `reconcile_pair` repairs it
- ✓ Test calls `reconcile_pair` before `read_pair`, which is the correct repair flow

### Naming Discipline
- ✓ Functions named for responsibility: `reconcile_pair`, `_read_lines`, `_write_lines`
- ✓ Verb+object pattern: `reconcile_pair`, `encode_index_entry`, `decode_index_entry`
- ✓ Helpers prefixed with `_` (private implementation details)
- ✓ No generic names like `utils`, `helpers`, `common`, `process`

### Test Quality
- ✓ `test_reconcile_rebuilds_missing_index_entries` verifies:
  - Repaired entry has `t_recv_ns == 0` (not invented)
  - Repaired entry has `kind == "recovered"` (marked for downstream)
  - Payload matches original (verified via read_pair)
  - Return value is correct count (1 repaired)
- ✓ `test_reconcile_is_noop_when_aligned` verifies:
  - No repair when files match (returns 0)
  - Idempotent behavior
- ✓ Test output is pristine (2/2 passing)

### YAGNI Discipline
- ✓ No extra error handling beyond what's required
- ✓ No logging or debugging features not specified
- ✓ No edge-case handling beyond aligned vs. misaligned
- ✓ No mutation of input files beyond updating index

## Concerns

None. Implementation matches brief exactly, all tests pass (19/19), and the code follows all established conventions from previous tasks.

## Commit

```
60cdc69 feat: reconcile raw/index pairs after crash without data loss
```

---

## Post-Review Fixes

Coordinator identified three issues requiring fixes:

### Fix 1: Recovered entries with silent escape corruption

**Issue:** Reconstructed entries asserted `esc=False`, causing recovered entries with escaped payloads to return still-escaped (corrupted). Example: if original was `{"msg":"line1\nline2"}`, it would be stored escaped as `{"msg":"line1\\nline2"}` in raw, but recovered entry would have `esc=False`, so `read_pair` wouldn't unescape it, returning the escaped form.

**Fix:** 
- `read_pair` now returns recovered entries' payloads as-stored (no unescaping)
- Updated docstrings for both `reconcile_pair` and `read_pair` to document the unrecoverable escape limitation
- Added test `test_recovered_entry_with_escaped_payload_returns_as_stored` to verify behavior with escaped payloads

**Rationale:** The escape state is genuinely unrecoverable from bytes alone. Given stored bytes, you cannot distinguish "original had real newline, was escaped" from "original had literal `\n`, was not escaped" — both produce identical disk bytes. Therefore, return as-stored and require downstream to handle `kind="recovered"` explicitly.

### Fix 2: Non-atomic index rewrite crash vulnerability

**Issue:** `_write_lines` opened with `"wb"` mode, truncating the valid index file before writing new data. A crash mid-write left the index empty or corrupted, worse than the initial mismatch that triggered recovery.

**Fix:**
- `_write_lines` now writes to a temporary file in the same directory
- Uses `os.replace()` for atomic file replacement (atomic on POSIX)
- Added error handling to clean up temp file if write fails
- Added docstring explaining crash-safety guarantee

**Rationale:** Any reader or retry sees either the old index or the new one, never a partial or corrupted frame. This matches the crash-recovery philosophy of the entire system.

### Fix 3: Duplicate split logic

**Issue:** `_read_lines` and `read_pair` both contained the same strict `"\n"` split logic. Duplicate logic is a bug vector — any future fix has to be applied twice.

**Fix:**
- Refactored `read_pair` to call `_read_lines` instead of duplicating split logic
- Behavior remains identical; all existing tests pass unchanged

**Test Results After Fixes:**

```bash
$ uv run --python 3.12 pytest tests/test_raw_writer_recovery.py tests/test_raw_writer.py -v
============================== 13 passed in 0.06s ==============================

$ uv run --python 3.12 pytest tests/ -v
============================== 20 passed in 0.05s ==============================
```

All 20 tests pass (3 recovery tests + 17 existing tests). The new test `test_recovered_entry_with_escaped_payload_returns_as_stored` verifies the documented limitation.

### Commits

```
60cdc69 feat: reconcile raw/index pairs after crash without data loss
44b459c fix: reconcile_pair crash-safety and escape state handling
```
