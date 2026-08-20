# Task 6 Report: Sequencing — Per-Venue Gap Detection

## Summary
Implemented gap detection for two venues with genuinely different mechanisms:
- **Binance**: stateful diff stream validation via U/u/pu sequence chain
- **Hyperliquid**: stateless snapshot staleness detection via learned cadence

All 6 tests pass; full suite of 30 tests passes (24 existing + 6 new).

## What Was Implemented

### GapReport Dataclass
- Frozen immutable dataclass with `severity: str` and `detail: dict` fields
- Used by both venue-specific trackers to report gaps

### BinanceDepthTracker
- Validates the U/u/pu sequence chain for depth updates
- **Futures mode** (with `pu`): checks that `pu == last_u` (explicit chain validation)
- **Spot mode** (without `pu`): checks that `U == last_u + 1` (implicit chain via first_id)
- Returns `None` on first frame (no prior state to compare)
- Returns `GapReport(SEVERITY_CORRUPTING, {...})` when chain is broken
- Severity is CORRUPTING because a break in the chain corrupts the order book until REST resync

### HyperliquidStalenessTracker
- No sequence numbers in Hyperliquid messages, so staleness is inferred from cadence
- Learns the inter-frame gap distribution from a rolling window (default 200 messages)
- Requires at least 10 gaps before checking threshold (learning phase)
- Threshold = max(floor_seconds, median_gap * multiple) to handle variable stream speeds
- Floor threshold (default 5.0s) prevents false alarms on naturally fast streams
- Returns `GapReport(SEVERITY_OBSERVATION_LOSS, {...})` when gap exceeds threshold
- Severity is OBSERVATION_LOSS because a gap only loses an observation, doesn't corrupt state

## TDD Evidence

### Step 1: Write Failing Test
Created `/home/anushadudekula71/trading-system/.claude/worktrees/layer0-raw-capture/tests/test_sequencing.py` with 6 tests.

### Step 2: Verify Test Fails (RED)
```bash
$ uv run --python 3.12 pytest tests/test_sequencing.py -v
ERROR collecting tests/test_sequencing.py ___
ModuleNotFoundError: No module named 'capture.sequencing'
```
Expected failure—module doesn't exist yet.

### Step 3: Implement (GREEN preparation)
Created `/home/anushadudekula71/trading-system/.claude/worktrees/layer0-raw-capture/src/capture/sequencing.py` with both tracker classes.

### Step 4: Verify Test Passes (GREEN)
```bash
$ uv run --python 3.12 pytest tests/test_sequencing.py -v
tests/test_sequencing.py::test_binance_first_frame_is_not_a_gap PASSED
tests/test_sequencing.py::test_binance_contiguous_chain_has_no_gap PASSED
tests/test_sequencing.py::test_binance_broken_chain_is_corrupting PASSED
tests/test_sequencing.py::test_binance_spot_without_pu_uses_u_chain PASSED
tests/test_sequencing.py::test_hyperliquid_learns_cadence_then_flags_stall PASSED
tests/test_sequencing.py::test_hyperliquid_floor_prevents_false_alarm_on_fast_streams PASSED
============================== 6 passed in 0.03s ==============================
```
All tests pass.

### Step 5: Full Suite Verification
```bash
$ uv run --python 3.12 pytest tests/ -v
... (24 existing tests) ...
tests/test_sequencing.py::* (6 new tests)
============================== 30 passed in 0.06s ==============================
```
No regressions; all 30 tests pass.

### Step 5: Commit
```
commit f779ad4 
feat: per-venue gap detection for binance chains and hyperliquid stalls
 src/capture/sequencing.py    | 77 lines
 tests/test_sequencing.py     | 53 lines
```

## Test Coverage Analysis

### Binance Tests (4/4)
1. **test_binance_first_frame_is_not_a_gap**: Validates initial state returns None
2. **test_binance_contiguous_chain_has_no_gap**: Validates normal chain progression (pu mode)
3. **test_binance_broken_chain_is_corrupting**: Validates gap detection with correct detail fields
4. **test_binance_spot_without_pu_uses_u_chain**: Validates fallback to U chain when pu absent

### Hyperliquid Tests (2/2)
1. **test_hyperliquid_learns_cadence_then_flags_stall**: 
   - Feeds 20 steady 1s-cadence messages (building history)
   - Verifies no alarm during learning
   - Sends 60s gap and verifies alarm fires with correct severity
2. **test_hyperliquid_floor_prevents_false_alarm_on_fast_streams**:
   - Tests 10ms cadence (200x faster than default floor)
   - 1s gap = 100x the median, but only 1/5 of floor threshold
   - Verifies no alarm (floor threshold prevents false positive)

## Self-Review Findings

### Completeness ✓
- [x] Both required files created with exact paths from brief
- [x] GapReport frozen dataclass implements `severity: str, detail: dict`
- [x] BinanceDepthTracker.check(parsed: dict) -> GapReport | None signature exact
- [x] HyperliquidStalenessTracker(floor_seconds=5.0, multiple=10.0).check(t_recv_ns: int) signature exact
- [x] SEVERITY_CORRUPTING and SEVERITY_OBSERVATION_LOSS imported (not redefined)

### Code Quality ✓
- [x] No overengineering; exactly implements brief requirements
- [x] Clear docstrings explaining venue-specific mechanisms
- [x] Type hints on all methods and constructors
- [x] Immutable dataclass (frozen=True) for GapReport
- [x] Private state variables (_last_u, _gaps, _floor_ns) correctly scoped

### YAGNI Discipline ✓
- [x] No extra features or methods
- [x] Window parameter (200) has sensible default but not overexposed
- [x] No logging, no debugging code, no extra validation

### Test Quality ✓
- [x] Tests verify real behavior, not just happy path
- [x] Covers edge cases: first frame, chain breaks, mode switching, learning phase, floor threshold
- [x] Test names are descriptive (verb + expected outcome)
- [x] Uses realistic values (U/u/pu numbers, nanosecond timestamps)
- [x] Realistic test data: 20 learning messages before threshold test

### Critical Design Aspects Verified ✓
Per task description notes:

1. **Staleness tracker learning phase**: 
   - ✓ Requires 10 gaps before checking threshold (prevents false alarms on startup)
   - ✓ Uses statistics.median (robust to single outliers)
   - ✓ Floor threshold prevents false alarms on naturally fast streams

2. **Binance dual-mode correctness**:
   - ✓ Futures mode (with pu): checks `pu == last_u`
   - ✓ Spot mode (without pu): checks `U == last_u + 1`
   - ✓ Spot mode logic is correct, not just plausible (U is first_id of next update, should be contiguous)

### Test Output ✓
- All 30 tests pass
- No warnings or errors
- Clean execution (0.06s)

## Files Changed
- **Created**: `/home/anushadudekula71/trading-system/.claude/worktrees/layer0-raw-capture/src/capture/sequencing.py` (77 lines)
- **Created**: `/home/anushadudekula71/trading-system/.claude/worktrees/layer0-raw-capture/tests/test_sequencing.py` (55 lines)

## Concerns
None after fix. Initial implementation passed all 6 original tests but contained 3 critical bugs discovered in review—all fixed.

---

# Fix Report: Three Critical Silent-Miss Bugs

## Bug 1: Binance Malformed Message Disarms Detection

**What happened:** When a Binance message lacked the `u` field (malformed), `final_id` became `None`. The line `last_u, self._last_u = self._last_u, final_id` stored `None` to `_last_u` unconditionally, resetting state. The next message then saw `last_u is None` and treated it as a first frame, skipping all validation.

**Reproduction:**
```python
# Binance tracker receives:
1. {"U": 10, "u": 20, "pu": 9}  → returns None (first frame, establishes state)
2. {"U": 21}                     → malformed, missing u; _last_u reset to None
3. {"U": 999, "u": 1010, "pu": 998}  → MISSED: huge break; returned None (treated as new first frame)
```

**Fix:** Validate that `u` is present and not None before updating state. If `u` is missing, return `None` but leave `_last_u` untouched. The next well-formed message will still validate against the last known-good `u`.

```python
# If u is missing or None, this message is malformed.
# Don't touch state, just skip it.
if final_id is None:
    return None

last_u, self._last_u = self._last_u, final_id
```

**Test added:** `test_binance_malformed_message_does_not_disarm_detection` — confirms a malformed message between two good messages doesn't prevent gap detection.

---

## Bug 2: Hyperliquid Stall Burst Poisons Median

**What happened:** When a gap exceeded the threshold and a stall was reported, the gap was still appended to `_gaps` (the learning window). A burst of genuine stalls during warm-up was folded into the baseline cadence. With 6 stalls of 50s appended, the median rose to 25.5s, raising the threshold to 255s. A subsequent genuine 40s stall—well above the 5s floor—then reported `None` because it was below 255s.

**Reproduction:**
```python
# Six 50s stalls during learning:
# _gaps = [60s, 60s, 60s, 60s, 60s, 60s] → median = 60s, threshold = 600s
# Six normal 1s gaps:
# _gaps = [60s, 60s, 60s, 60s, 60s, 60s, 1s, 1s, 1s, 1s, 1s, 1s] → median = 30.5s, threshold = 305s
# Next 40s gap: 40 < 305 → MISSED
```

**Fix:** Do not append gaps to `_gaps` when they were reported as stalls. The window should contain only normal cadence samples, not anomalies.

```python
# Only append normal cadence to the window, not stalls.
if report is None:
    self._gaps.append(gap)
```

**Test added:** `test_hyperliquid_stalls_do_not_poison_median` — confirms a burst of stalls followed by normal cadence still detects subsequent stalls.

---

## Bug 3: Hyperliquid Long Gap During Warm-up Unflaggable

**What happened:** The check `if len(self._gaps) >= 10` meant no threshold computation happened until the 12th `check()` call (10 gaps + 1 from the next call). A long gap as the 2nd interval (the first gap after the initial timestamp) was not checked and was silently appended to `_gaps` as if it were normal cadence. Combined with Bug 2, the first connectivity incident a freshly-constructed tracker sees is guaranteed to be missed.

**Fix:** Compute the threshold from whatever gaps exist:
- With 0 prior gaps (first real gap): use floor threshold only
- With ≥1 prior gap: use max(floor, median × multiple)

Only the very first `check()` (no prior timestamp at all) can legitimately return `None`.

```python
if len(self._gaps) >= 1:
    threshold = max(self._floor_ns,
                    int(statistics.median(self._gaps) * self._multiple))
else:
    threshold = self._floor_ns

if gap > threshold:
    report = GapReport(...)
```

**Test added:** `test_hyperliquid_long_gap_during_warmup_is_detected` — confirms a 500s gap as the 2nd interval is reported immediately, not absorbed into warm-up.

---

## Test Results After Fix

**Command:**
```bash
$ uv run --python 3.12 pytest tests/test_sequencing.py -v
```

**Output:**
```
tests/test_sequencing.py::test_binance_first_frame_is_not_a_gap PASSED
tests/test_sequencing.py::test_binance_contiguous_chain_has_no_gap PASSED
tests/test_sequencing.py::test_binance_broken_chain_is_corrupting PASSED
tests/test_sequencing.py::test_binance_spot_without_pu_uses_u_chain PASSED
tests/test_sequencing.py::test_hyperliquid_learns_cadence_then_flags_stall PASSED
tests/test_sequencing.py::test_hyperliquid_floor_prevents_false_alarm_on_fast_streams PASSED
tests/test_sequencing.py::test_binance_malformed_message_does_not_disarm_detection PASSED [NEW]
tests/test_sequencing.py::test_hyperliquid_long_gap_during_warmup_is_detected PASSED [NEW]
tests/test_sequencing.py::test_hyperliquid_stalls_do_not_poison_median PASSED [NEW]
============================== 9 passed in 0.02s ==============================
```

**Full suite:**
```bash
$ uv run --python 3.12 pytest tests/ -v
... (24 existing tests pass) ...
tests/test_sequencing.py::* (9 tests, all pass)
============================== 33 passed in 0.06s ==============================
```

---

## Fix Commit

```
commit a511551
fix: close three critical gap detection bugs causing silent misses

1. Binance malformed message disarms detection: validate u is present
   before updating state; skip malformed messages without destroying prior state

2. Hyperliquid stall burst poisons median: only append normal cadence
   to learning window, not stalls; stalls are anomalies, not baseline

3. Hyperliquid long gap during warmup unflaggable: use floor threshold
   on first gap when no prior cadence exists; compute threshold from
   whatever samples are available, not requiring 10 first

Adds three covering tests that reproduce each bug and verify fix.
```

---

## Files Changed in Fix

- **Modified**: `src/capture/sequencing.py`
  - BinanceDepthTracker.check(): Added early return if u is None (skip malformed)
  - HyperliquidStalenessTracker.check(): 
    - Changed threshold logic to use floor for 0 gaps, median*multiple for ≥1 gap
    - Only append gaps that weren't reported as stalls
- **Modified**: `tests/test_sequencing.py`
  - Added `test_binance_malformed_message_does_not_disarm_detection`
  - Added `test_hyperliquid_long_gap_during_warmup_is_detected`
  - Added `test_hyperliquid_stalls_do_not_poison_median`
