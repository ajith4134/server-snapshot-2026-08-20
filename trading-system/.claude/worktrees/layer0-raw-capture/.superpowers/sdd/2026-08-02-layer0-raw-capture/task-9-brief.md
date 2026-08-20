### Task 9: Universe tracker (spec R2)

Point-in-time membership. Backtesting against today's symbol list silently conditions on survival, and no purge/embargo scheme catches it.

**Files:**
- Create: `src/capture/universe_tracker.py`
- Create: `tests/test_universe_tracker.py`

**Interfaces:**
- Consumes: venue adapters (Task 7) for `parse_instruments`
- Produces:
  - `UniverseEvent` frozen dataclass: `ts_ns:int, venue:str, symbol:str, kind:str, detail:dict` where kind ∈ `listed|delisted`
  - `diff_universe(previous: list[str], current: list[str], venue: str, ts_ns: int) -> list[UniverseEvent]`
  - `UniverseTracker(root: Path, venue_name: str)` with `record_snapshot(symbols, ts_ns) -> list[UniverseEvent]`, `load_last(ts_ns) -> list[str]`

- [ ] **Step 1: Write the failing test**

```python
# tests/test_universe_tracker.py
from pathlib import Path
from capture.universe_tracker import UniverseTracker, diff_universe

TS = 1785648600_000_000_000


def test_diff_detects_listing_and_delisting():
    events = diff_universe(["BTCUSDT", "OLDUSDT"], ["BTCUSDT", "NEWUSDT"],
                           "binance", TS)
    kinds = {(e.symbol, e.kind) for e in events}
    assert ("NEWUSDT", "listed") in kinds
    assert ("OLDUSDT", "delisted") in kinds
    assert ("BTCUSDT", "listed") not in kinds


def test_first_snapshot_lists_everything_as_listed(tmp_path: Path):
    tracker = UniverseTracker(tmp_path, "binance")
    events = tracker.record_snapshot(["BTCUSDT", "ETHUSDT"], TS)
    assert {e.kind for e in events} == {"listed"}
    assert len(events) == 2


def test_second_snapshot_only_reports_changes(tmp_path: Path):
    tracker = UniverseTracker(tmp_path, "binance")
    tracker.record_snapshot(["BTCUSDT", "ETHUSDT"], TS)
    events = tracker.record_snapshot(["BTCUSDT", "SOLUSDT"], TS + 1)
    kinds = {(e.symbol, e.kind) for e in events}
    assert kinds == {("SOLUSDT", "listed"), ("ETHUSDT", "delisted")}


def test_snapshot_is_persisted_and_reloadable(tmp_path: Path):
    tracker = UniverseTracker(tmp_path, "binance")
    tracker.record_snapshot(["BTCUSDT"], TS)
    reloaded = UniverseTracker(tmp_path, "binance")
    assert reloaded.load_last(TS) == ["BTCUSDT"]
```

- [ ] **Step 2: Run test to verify it fails**

Run: `uv run --python 3.12 pytest tests/test_universe_tracker.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'capture.universe_tracker'`

- [ ] **Step 3: Write minimal implementation**

```python
# src/capture/universe_tracker.py
"""Records point-in-time universe membership.

Without this, any backtest over "all symbols" silently conditions on survival.
Exchanges do not reliably publish historical membership, so it must be captured
as it happens.
"""
from __future__ import annotations

import datetime as dt
import json
from dataclasses import asdict, dataclass
from pathlib import Path


@dataclass(frozen=True)
class UniverseEvent:
    ts_ns: int
    venue: str
    symbol: str
    kind: str
    detail: dict


def _date_of(ts_ns: int) -> str:
    return dt.datetime.fromtimestamp(ts_ns / 1e9, tz=dt.timezone.utc).strftime("%Y-%m-%d")


def diff_universe(previous: list[str], current: list[str],
                  venue: str, ts_ns: int) -> list[UniverseEvent]:
    before, after = set(previous), set(current)
    events = [UniverseEvent(ts_ns, venue, s, "listed", {}) for s in sorted(after - before)]
    events += [UniverseEvent(ts_ns, venue, s, "delisted", {}) for s in sorted(before - after)]
    return events


class UniverseTracker:
    def __init__(self, root: Path, venue_name: str) -> None:
        self._root = Path(root)
        self._venue = venue_name

    def _dir_for(self, ts_ns: int) -> Path:
        return self._root / "universe" / self._venue / _date_of(ts_ns)

    def _state_path(self) -> Path:
        return self._root / "universe" / self._venue / "last_snapshot.json"

    def load_last(self, ts_ns: int) -> list[str]:
        path = self._state_path()
        if not path.exists():
            return []
        return json.loads(path.read_text(encoding="utf-8"))["symbols"]

    def record_snapshot(self, symbols: list[str], ts_ns: int) -> list[UniverseEvent]:
        previous = self.load_last(ts_ns)
        events = diff_universe(previous, symbols, self._venue, ts_ns)

        folder = self._dir_for(ts_ns)
        folder.mkdir(parents=True, exist_ok=True)
        with open(folder / "instruments.ndjson", "a", encoding="utf-8") as fh:
            fh.write(json.dumps({"ts_ns": ts_ns, "kind": "snapshot",
                                 "symbols": symbols}, separators=(",", ":")) + "\n")
            for event in events:
                fh.write(json.dumps(asdict(event), separators=(",", ":"),
                                    sort_keys=True) + "\n")

        state = self._state_path()
        state.parent.mkdir(parents=True, exist_ok=True)
        state.write_text(json.dumps({"ts_ns": ts_ns, "symbols": symbols}),
                         encoding="utf-8")
        return events
```

- [ ] **Step 4: Run test to verify it passes**

Run: `uv run --python 3.12 pytest tests/test_universe_tracker.py -v`
Expected: PASS (4 tests)

- [ ] **Step 5: Commit**

```bash
git add src/capture/universe_tracker.py tests/test_universe_tracker.py
git commit -m "feat: point-in-time universe membership tracking"
```

---

