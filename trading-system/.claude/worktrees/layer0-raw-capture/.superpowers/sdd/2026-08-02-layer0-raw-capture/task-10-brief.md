### Task 10: Capture health — runway and integrity report

**Files:**
- Create: `src/capture/capture_health.py`
- Create: `tests/test_capture_health.py`

**Interfaces:**
- Consumes: `capture.capture_ledger.read_all`
- Produces:
  - `compute_runway_days(free_bytes: int, daily_bytes: float) -> float`
  - `classify_runway(days: float) -> str` returning `ok|warn|alert|decision_point`
  - `measure_daily_bytes(root: Path, days: int = 7) -> float`
  - `build_report(root: Path, venue: str, date: str, free_bytes: int, daily_bytes: float) -> dict`
  - `write_alerts(root: Path, report: dict) -> int` returning alert count

- [ ] **Step 1: Write the failing test**

```python
# tests/test_capture_health.py
import json
from pathlib import Path

from capture.capture_health import (
    compute_runway_days, classify_runway, build_report, write_alerts,
)
from capture.capture_ledger import (
    CaptureLedger, LedgerEvent, SEVERITY_CORRUPTING,
)

TS = 1785648600_000_000_000


def test_runway_is_free_over_daily():
    assert compute_runway_days(100_000_000_000, 2_000_000_000) == 50.0


def test_runway_is_infinite_when_nothing_written():
    assert compute_runway_days(100, 0) == float("inf")


def test_classify_thresholds():
    assert classify_runway(90) == "ok"
    assert classify_runway(25) == "warn"
    assert classify_runway(10) == "alert"
    assert classify_runway(5) == "decision_point"


def test_report_counts_gaps_by_severity(tmp_path: Path):
    ledger = CaptureLedger(tmp_path, "binance")
    ledger.record(LedgerEvent(TS, "binance", "depth", "gap",
                              SEVERITY_CORRUPTING, {"symbol": "BTCUSDT"}))
    ledger.close()

    report = build_report(tmp_path, "binance", "2026-08-02",
                          free_bytes=100_000_000_000, daily_bytes=2_000_000_000)
    assert report["gaps"]["corrupting"] == 1
    assert report["runway_days"] == 50.0
    assert report["runway_status"] == "ok"


def test_write_alerts_emits_lines_for_bad_states(tmp_path: Path):
    report = build_report(tmp_path, "binance", "2026-08-02",
                          free_bytes=4_000_000_000, daily_bytes=2_000_000_000)
    count = write_alerts(tmp_path, report)
    assert count == 1
    lines = (tmp_path / "health" / "alerts.ndjson").read_text().splitlines()
    assert json.loads(lines[0])["reason"] == "runway_decision_point"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `uv run --python 3.12 pytest tests/test_capture_health.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'capture.capture_health'`

- [ ] **Step 3: Write minimal implementation**

```python
# src/capture/capture_health.py
"""Answers 'is capture healthy?' with evidence rather than assumption.

Runway is measured in days remaining, not percent used, because percent
thresholds mean nothing when the write rate changes.
"""
from __future__ import annotations

import json
import time
from pathlib import Path

from capture.capture_ledger import read_all

WARN_DAYS = 30.0
ALERT_DAYS = 14.0
DECISION_DAYS = 7.0


def compute_runway_days(free_bytes: int, daily_bytes: float) -> float:
    if daily_bytes <= 0:
        return float("inf")
    return free_bytes / daily_bytes


def classify_runway(days: float) -> str:
    if days <= DECISION_DAYS:
        return "decision_point"
    if days <= ALERT_DAYS:
        return "alert"
    if days <= WARN_DAYS:
        return "warn"
    return "ok"


def measure_daily_bytes(root: Path, days: int = 7) -> float:
    raw_root = Path(root) / "raw"
    if not raw_root.exists():
        return 0.0
    cutoff = time.time() - days * 86400
    total = sum(
        path.stat().st_size
        for path in raw_root.rglob("*.zst")
        if path.stat().st_mtime >= cutoff
    )
    return total / days


def build_report(root: Path, venue: str, date: str,
                 free_bytes: int, daily_bytes: float) -> dict:
    events = read_all(root, venue, date)
    gaps = {"corrupting": 0, "observation_loss": 0, "info": 0}
    for event in events:
        if event.kind == "gap":
            gaps[event.severity] = gaps.get(event.severity, 0) + 1

    runway = compute_runway_days(free_bytes, daily_bytes)
    return {
        "venue": venue,
        "date": date,
        "events_total": len(events),
        "gaps": gaps,
        "free_bytes": free_bytes,
        "daily_bytes": daily_bytes,
        "runway_days": runway,
        "runway_status": classify_runway(runway),
    }


def write_alerts(root: Path, report: dict) -> int:
    alerts = []
    if report["runway_status"] != "ok":
        alerts.append({"reason": f"runway_{report['runway_status']}",
                       "runway_days": report["runway_days"]})
    if report["gaps"].get("corrupting", 0) > 0:
        alerts.append({"reason": "corrupting_gaps",
                       "count": report["gaps"]["corrupting"]})

    if alerts:
        folder = Path(root) / "health"
        folder.mkdir(parents=True, exist_ok=True)
        with open(folder / "alerts.ndjson", "a", encoding="utf-8") as fh:
            for alert in alerts:
                fh.write(json.dumps({**alert, "venue": report["venue"],
                                     "date": report["date"]},
                                    separators=(",", ":"), sort_keys=True) + "\n")
    return len(alerts)
```

- [ ] **Step 4: Run test to verify it passes**

Run: `uv run --python 3.12 pytest tests/test_capture_health.py -v`
Expected: PASS (5 tests)

- [ ] **Step 5: Commit**

```bash
git add src/capture/capture_health.py tests/test_capture_health.py
git commit -m "feat: capture health with runway measured in days"
```

---

