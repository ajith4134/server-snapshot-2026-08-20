### Task 8: Venue recorder — async loop with bounded queue

**Files:**
- Create: `src/capture/venue_recorder.py`
- Create: `tests/test_venue_recorder.py`

**Interfaces:**
- Consumes: `RawWriter` (Task 3), `CaptureLedger`/`LedgerEvent` (Task 5), `BinanceDepthTracker`/`HyperliquidStalenessTracker` (Task 6), venue adapters (Task 7)
- Produces:
  - `VenueRecorder(venue, specs, root, queue_size=10000, clock_ns=time.time_ns)` with
    `async def consume(self, frames: AsyncIterator[str]) -> None` and `def stats(self) -> dict`
  - `stats()` returns keys `written`, `dropped`, `control`, `malformed`

- [ ] **Step 1: Write the failing test**

```python
# tests/test_venue_recorder.py
import json
from pathlib import Path

import pytest

from capture.venue_recorder import VenueRecorder
from capture.venues.binance import BinanceVenue
from capture.capture_ledger import read_all, SEVERITY_CORRUPTING


async def _frames(items):
    for item in items:
        yield item


@pytest.mark.asyncio
async def test_writes_frames_and_counts_them(tmp_path: Path):
    venue = BinanceVenue()
    specs = venue.core_specs(["BTCUSDT"])
    rec = VenueRecorder(venue, specs, tmp_path, clock_ns=lambda: 1785648600_000_000_000)

    payloads = [json.dumps({"stream": "btcusdt@depth@100ms", "data": {
        "e": "depthUpdate", "E": 1785650606214, "s": "BTCUSDT",
        "U": 1 + i * 10, "u": 10 + i * 10, "pu": i * 10}}) for i in range(3)]

    await rec.consume(_frames(payloads))
    assert rec.stats()["written"] == 3
    assert rec.stats()["dropped"] == 0


@pytest.mark.asyncio
async def test_broken_chain_records_corrupting_ledger_event(tmp_path: Path):
    venue = BinanceVenue()
    specs = venue.core_specs(["BTCUSDT"])
    rec = VenueRecorder(venue, specs, tmp_path, clock_ns=lambda: 1785648600_000_000_000)

    good = json.dumps({"data": {"e": "depthUpdate", "E": 1, "s": "BTCUSDT",
                                "U": 1, "u": 10, "pu": 0}})
    broken = json.dumps({"data": {"e": "depthUpdate", "E": 2, "s": "BTCUSDT",
                                  "U": 50, "u": 60, "pu": 49}})
    await rec.consume(_frames([good, broken]))

    events = read_all(tmp_path, "binance", "2026-08-02")
    gaps = [e for e in events if e.kind == "gap"]
    assert len(gaps) == 1
    assert gaps[0].severity == SEVERITY_CORRUPTING


@pytest.mark.asyncio
async def test_malformed_frame_is_still_written(tmp_path: Path):
    venue = BinanceVenue()
    rec = VenueRecorder(venue, venue.core_specs(["BTCUSDT"]), tmp_path,
                        clock_ns=lambda: 1785648600_000_000_000)
    await rec.consume(_frames(["this is not json"]))

    assert rec.stats()["malformed"] == 1
    assert rec.stats()["written"] == 1          # written anyway, never discarded
    events = read_all(tmp_path, "binance", "2026-08-02")
    assert any(e.kind == "malformed" for e in events)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `uv run --python 3.12 pytest tests/test_venue_recorder.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'capture.venue_recorder'`

- [ ] **Step 3: Write minimal implementation**

```python
# src/capture/venue_recorder.py
"""Consumes venue frames and routes them to writers, ledger and gap trackers."""
from __future__ import annotations

import json
import time
from pathlib import Path
from typing import AsyncIterator, Callable

from capture.capture_ledger import (
    CaptureLedger, LedgerEvent, SEVERITY_INFO,
)
from capture.raw_writer import RawWriter
from capture.sequencing import BinanceDepthTracker, HyperliquidStalenessTracker


class VenueRecorder:
    def __init__(self, venue, specs, root: Path, queue_size: int = 10_000,
                 clock_ns: Callable[[], int] = time.time_ns) -> None:
        self._venue = venue
        self._specs = specs
        self._root = Path(root)
        self._clock_ns = clock_ns
        self._ledger = CaptureLedger(root, venue.name)
        self._writers: dict[tuple[str, str], RawWriter] = {}
        self._trackers: dict[tuple[str, str], object] = {}
        self._stats = {"written": 0, "dropped": 0, "control": 0, "malformed": 0}

    def _writer_for(self, stream: str, symbol: str) -> RawWriter:
        key = (stream, symbol)
        if key not in self._writers:
            self._writers[key] = RawWriter(self._root, self._venue.name, stream, symbol)
        return self._writers[key]

    def _tracker_for(self, stream: str, symbol: str):
        key = (stream, symbol)
        if key not in self._trackers:
            if self._venue.name == "binance" and stream == "depth":
                self._trackers[key] = BinanceDepthTracker()
            elif self._venue.name == "hyperliquid" and stream == "l2Book":
                self._trackers[key] = HyperliquidStalenessTracker()
            else:
                self._trackers[key] = None
        return self._trackers[key]

    def _record_gap(self, stream: str, symbol: str, report, t_recv_ns: int) -> None:
        self._ledger.record(LedgerEvent(
            ts_ns=t_recv_ns, venue=self._venue.name, stream=stream,
            kind="gap", severity=report.severity,
            detail={"symbol": symbol, **report.detail},
        ))

    async def consume(self, frames: AsyncIterator[str]) -> None:
        async for payload in frames:
            t_recv_ns = self._clock_ns()
            try:
                parsed = json.loads(payload)
            except json.JSONDecodeError:
                self._stats["malformed"] += 1
                self._ledger.record(LedgerEvent(
                    ts_ns=t_recv_ns, venue=self._venue.name, stream="unknown",
                    kind="malformed", severity=SEVERITY_INFO,
                    detail={"bytes": len(payload)},
                ))
                self._writer_for("unknown", "unknown").append(
                    payload, t_recv_ns, None, None, kind="malformed")
                self._stats["written"] += 1
                continue

            meta = self._venue.extract(parsed)
            if meta.kind == "control":
                self._stats["control"] += 1

            tracker = self._tracker_for(meta.stream, meta.symbol)
            if tracker is not None and meta.kind == "data":
                body = parsed.get("data", parsed)
                report = (tracker.check(body) if isinstance(tracker, BinanceDepthTracker)
                          else tracker.check(t_recv_ns))
                if report is not None:
                    self._record_gap(meta.stream, meta.symbol, report, t_recv_ns)

            self._writer_for(meta.stream, meta.symbol).append(
                payload, t_recv_ns, meta.t_exch_ms, meta.seq, kind=meta.kind)
            self._stats["written"] += 1

        self.close()

    def stats(self) -> dict:
        return dict(self._stats)

    def close(self) -> None:
        for writer in self._writers.values():
            writer.close()
        self._ledger.close()
```

- [ ] **Step 4: Run test to verify it passes**

Run: `uv run --python 3.12 pytest tests/test_venue_recorder.py -v`
Expected: PASS (3 tests)

- [ ] **Step 5: Commit**

```bash
git add src/capture/venue_recorder.py tests/test_venue_recorder.py
git commit -m "feat: venue recorder routing frames to writers and ledger"
```

---

