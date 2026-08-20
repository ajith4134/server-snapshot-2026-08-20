### Task 6: Sequencing — per-venue gap detection

The probe established these are genuinely different mechanisms. Binance depth is stateful diffs with a sequence chain; Hyperliquid `l2Book` is stateless snapshots with no sequence number at all.

**Files:**
- Create: `src/capture/sequencing.py`
- Create: `tests/test_sequencing.py`

**Interfaces:**
- Consumes: `SEVERITY_CORRUPTING`, `SEVERITY_OBSERVATION_LOSS` from `capture.capture_ledger`
- Produces:
  - `GapReport` frozen dataclass: `severity:str, detail:dict`
  - `BinanceDepthTracker()` with `check(parsed: dict) -> GapReport | None`
  - `HyperliquidStalenessTracker(floor_seconds: float = 5.0, multiple: float = 10.0)` with
    `check(t_recv_ns: int) -> GapReport | None`

- [ ] **Step 1: Write the failing test**

```python
# tests/test_sequencing.py
from capture.sequencing import BinanceDepthTracker, HyperliquidStalenessTracker
from capture.capture_ledger import SEVERITY_CORRUPTING, SEVERITY_OBSERVATION_LOSS

S = 1_000_000_000  # one second in ns


def test_binance_first_frame_is_not_a_gap():
    t = BinanceDepthTracker()
    assert t.check({"U": 10, "u": 20, "pu": 9}) is None


def test_binance_contiguous_chain_has_no_gap():
    t = BinanceDepthTracker()
    t.check({"U": 10, "u": 20, "pu": 9})
    assert t.check({"U": 21, "u": 30, "pu": 20}) is None


def test_binance_broken_chain_is_corrupting():
    t = BinanceDepthTracker()
    t.check({"U": 10, "u": 20, "pu": 9})
    report = t.check({"U": 40, "u": 50, "pu": 39})
    assert report is not None
    assert report.severity == SEVERITY_CORRUPTING
    assert report.detail["expected_pu"] == 20
    assert report.detail["got_pu"] == 39


def test_binance_spot_without_pu_uses_u_chain():
    t = BinanceDepthTracker()
    t.check({"U": 10, "u": 20})
    assert t.check({"U": 21, "u": 30}) is None
    report = t.check({"U": 99, "u": 120})
    assert report is not None
    assert report.severity == SEVERITY_CORRUPTING


def test_hyperliquid_learns_cadence_then_flags_stall():
    t = HyperliquidStalenessTracker(floor_seconds=5.0, multiple=10.0)
    base = 1785648600 * S
    for i in range(20):
        assert t.check(base + i * S) is None          # steady 1s cadence
    report = t.check(base + 20 * S + 60 * S)          # 60s later
    assert report is not None
    assert report.severity == SEVERITY_OBSERVATION_LOSS
    assert report.detail["gap_seconds"] >= 60


def test_hyperliquid_floor_prevents_false_alarm_on_fast_streams():
    t = HyperliquidStalenessTracker(floor_seconds=5.0, multiple=10.0)
    base = 1785648600 * S
    for i in range(20):
        t.check(base + int(i * 0.01 * S))             # 10ms cadence
    # 1s gap: 100x the median, but under the 5s floor -> not an alarm
    assert t.check(base + int(20 * 0.01 * S) + S) is None
```

- [ ] **Step 2: Run test to verify it fails**

Run: `uv run --python 3.12 pytest tests/test_sequencing.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'capture.sequencing'`

- [ ] **Step 3: Write minimal implementation**

```python
# src/capture/sequencing.py
"""Gap detection. Deliberately different per venue - see spec 5.4.

Binance depth is a stateful diff stream: a break in the chain corrupts the book
until a REST resync. Hyperliquid l2Book is stateless snapshots: a gap loses an
observation but nothing is corrupted, so only staleness can be detected.
"""
from __future__ import annotations

import statistics
from collections import deque
from dataclasses import dataclass

from capture.capture_ledger import SEVERITY_CORRUPTING, SEVERITY_OBSERVATION_LOSS


@dataclass(frozen=True)
class GapReport:
    severity: str
    detail: dict


class BinanceDepthTracker:
    """Validates the U/u/pu chain. Uses pu when present (futures), else u (spot)."""

    def __init__(self) -> None:
        self._last_u: int | None = None

    def check(self, parsed: dict) -> GapReport | None:
        first_id, final_id = parsed.get("U"), parsed.get("u")
        prev_final = parsed.get("pu")
        last_u, self._last_u = self._last_u, final_id
        if last_u is None:
            return None

        if prev_final is not None:
            if prev_final == last_u:
                return None
            return GapReport(SEVERITY_CORRUPTING,
                             {"expected_pu": last_u, "got_pu": prev_final})

        if first_id == last_u + 1:
            return None
        return GapReport(SEVERITY_CORRUPTING,
                         {"expected_U": last_u + 1, "got_U": first_id})


class HyperliquidStalenessTracker:
    """No sequence numbers exist, so cadence is learned and stalls are inferred.

    Fires at `multiple` x the rolling median inter-frame gap, floored at
    `floor_seconds` so fast streams do not alarm on ordinary jitter.
    """

    def __init__(self, floor_seconds: float = 5.0, multiple: float = 10.0,
                 window: int = 200) -> None:
        self._floor_ns = int(floor_seconds * 1e9)
        self._multiple = multiple
        self._gaps: deque[int] = deque(maxlen=window)
        self._last_ns: int | None = None

    def check(self, t_recv_ns: int) -> GapReport | None:
        last, self._last_ns = self._last_ns, t_recv_ns
        if last is None:
            return None
        gap = t_recv_ns - last
        report = None
        if len(self._gaps) >= 10:
            threshold = max(self._floor_ns,
                            int(statistics.median(self._gaps) * self._multiple))
            if gap > threshold:
                report = GapReport(SEVERITY_OBSERVATION_LOSS, {
                    "gap_seconds": gap / 1e9,
                    "threshold_seconds": threshold / 1e9,
                })
        self._gaps.append(gap)
        return report
```

- [ ] **Step 4: Run test to verify it passes**

Run: `uv run --python 3.12 pytest tests/test_sequencing.py -v`
Expected: PASS (6 tests)

- [ ] **Step 5: Commit**

```bash
git add src/capture/sequencing.py tests/test_sequencing.py
git commit -m "feat: per-venue gap detection for binance chains and hyperliquid stalls"
```

---

