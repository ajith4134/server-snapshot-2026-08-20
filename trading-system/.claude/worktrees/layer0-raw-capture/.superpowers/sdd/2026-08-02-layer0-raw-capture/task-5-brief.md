### Task 5: Capture ledger

**Files:**
- Create: `src/capture/capture_ledger.py`
- Create: `tests/test_capture_ledger.py`

**Interfaces:**
- Consumes: nothing
- Produces:
  - `LedgerEvent` frozen dataclass: `ts_ns:int, venue:str, stream:str, kind:str, severity:str, detail:dict`
  - `CaptureLedger(root: Path, venue: str)` with `record(event) -> None`, `read_all(root, venue, date) -> list[LedgerEvent]`, `close() -> None`
  - Severity constants: `SEVERITY_INFO = "info"`, `SEVERITY_OBSERVATION_LOSS = "observation_loss"`, `SEVERITY_CORRUPTING = "corrupting"`

- [ ] **Step 1: Write the failing test**

```python
# tests/test_capture_ledger.py
from pathlib import Path
from capture.capture_ledger import (
    CaptureLedger, LedgerEvent, read_all,
    SEVERITY_CORRUPTING, SEVERITY_OBSERVATION_LOSS,
)


def test_records_and_reads_back(tmp_path: Path):
    ledger = CaptureLedger(tmp_path, "binance")
    ledger.record(LedgerEvent(
        ts_ns=1785648600_000_000_000, venue="binance", stream="depth",
        kind="gap", severity=SEVERITY_CORRUPTING,
        detail={"symbol": "BTCUSDT", "expected_pu": 5, "got_pu": 9},
    ))
    ledger.close()

    events = read_all(tmp_path, "binance", "2026-08-02")
    assert len(events) == 1
    assert events[0].kind == "gap"
    assert events[0].severity == SEVERITY_CORRUPTING
    assert events[0].detail["expected_pu"] == 5


def test_appends_across_multiple_records(tmp_path: Path):
    ledger = CaptureLedger(tmp_path, "hyperliquid")
    for i in range(3):
        ledger.record(LedgerEvent(
            ts_ns=1785648600_000_000_000 + i, venue="hyperliquid",
            stream="l2Book", kind="stale", severity=SEVERITY_OBSERVATION_LOSS,
            detail={"symbol": "BTC"},
        ))
    ledger.close()
    assert len(read_all(tmp_path, "hyperliquid", "2026-08-02")) == 3
```

- [ ] **Step 2: Run test to verify it fails**

Run: `uv run --python 3.12 pytest tests/test_capture_ledger.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'capture.capture_ledger'`

- [ ] **Step 3: Write minimal implementation**

```python
# src/capture/capture_ledger.py
"""Records capture anomalies as first-class, queryable events.

Plain NDJSON, uncompressed: this file is read during incidents, and volume is
tiny compared to market data.
"""
from __future__ import annotations

import datetime as dt
import json
from dataclasses import asdict, dataclass
from pathlib import Path

SEVERITY_INFO = "info"
SEVERITY_OBSERVATION_LOSS = "observation_loss"
SEVERITY_CORRUPTING = "corrupting"


@dataclass(frozen=True)
class LedgerEvent:
    ts_ns: int
    venue: str
    stream: str
    kind: str
    severity: str
    detail: dict


def _date_of(ts_ns: int) -> str:
    return dt.datetime.fromtimestamp(ts_ns / 1e9, tz=dt.timezone.utc).strftime("%Y-%m-%d")


def _path_for(root: Path, venue: str, date: str) -> Path:
    return Path(root) / "ledger" / venue / date / "events.ndjson"


class CaptureLedger:
    def __init__(self, root: Path, venue: str) -> None:
        self._root, self._venue = Path(root), venue
        self._fh = None
        self._date: str | None = None

    def record(self, event: LedgerEvent) -> None:
        date = _date_of(event.ts_ns)
        if date != self._date:
            self.close()
            path = _path_for(self._root, self._venue, date)
            path.parent.mkdir(parents=True, exist_ok=True)
            self._fh = open(path, "a", encoding="utf-8")
            self._date = date
        self._fh.write(json.dumps(asdict(event), separators=(",", ":"), sort_keys=True) + "\n")
        self._fh.flush()

    def close(self) -> None:
        if self._fh is not None:
            self._fh.close()
            self._fh = None
            self._date = None


def read_all(root: Path, venue: str, date: str) -> list[LedgerEvent]:
    path = _path_for(root, venue, date)
    if not path.exists():
        return []
    with open(path, encoding="utf-8") as fh:
        return [LedgerEvent(**json.loads(line)) for line in fh if line.strip()]
```

- [ ] **Step 4: Run test to verify it passes**

Run: `uv run --python 3.12 pytest tests/test_capture_ledger.py -v`
Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add src/capture/capture_ledger.py tests/test_capture_ledger.py
git commit -m "feat: capture ledger for gap and anomaly events"
```

---

