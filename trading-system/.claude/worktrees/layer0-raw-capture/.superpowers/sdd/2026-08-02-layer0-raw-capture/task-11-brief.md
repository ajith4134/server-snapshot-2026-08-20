### Task 11: Live smoke test against real venues

Unit tests prove logic. This proves the thing actually captures — the guardrail lesson already recorded in memory.

**Files:**
- Create: `src/capture/cli.py`
- Create: `tests/test_cli_smoke.py`

**Interfaces:**
- Consumes: everything above
- Produces:
  - `async def run_capture(venue, specs, root, duration_seconds: float) -> dict` returning `VenueRecorder.stats()`
  - `main(argv: list[str] | None = None) -> int` for `uv run --python 3.12 python -m capture.cli`

- [ ] **Step 1: Write the failing test**

```python
# tests/test_cli_smoke.py
import os
from pathlib import Path

import pytest

from capture.cli import run_capture
from capture.venues.binance import BinanceVenue
from capture.raw_writer import read_pair, paths_for, hour_key
import time


@pytest.mark.skipif(os.environ.get("CAPTURE_LIVE") != "1",
                    reason="live venue test; set CAPTURE_LIVE=1 to run")
@pytest.mark.asyncio
async def test_captures_real_binance_frames(tmp_path: Path):
    venue = BinanceVenue()
    specs = venue.core_specs(["BTCUSDT"])
    stats = await run_capture(venue, specs, tmp_path, duration_seconds=15)

    assert stats["written"] > 0
    assert stats["dropped"] == 0

    hour = hour_key(time.time_ns())
    raw, idx = paths_for(tmp_path, "binance", "depth", "BTCUSDT", hour)
    pairs = read_pair(raw, idx)
    assert len(pairs) > 0
    # byte-exactness: every stored line must be valid JSON exactly as sent
    import json
    assert json.loads(pairs[0][0]) is not None
```

- [ ] **Step 2: Run test to verify it fails**

Run: `uv run --python 3.12 pytest tests/test_cli_smoke.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'capture.cli'`
(Without `CAPTURE_LIVE=1` it reports SKIPPED once the module exists.)

- [ ] **Step 3: Write minimal implementation**

```python
# src/capture/cli.py
"""Entry point for running capture."""
from __future__ import annotations

import argparse
import asyncio
import json
from pathlib import Path

import websockets

from capture.venue_recorder import VenueRecorder
from capture.venues.binance import BinanceVenue
from capture.venues.hyperliquid import HyperliquidVenue

_VENUES = {"binance": BinanceVenue, "hyperliquid": HyperliquidVenue}


async def _stream_frames(venue, specs, duration_seconds: float):
    """Yields raw text frames for a bounded duration, then stops."""
    url = venue.ws_url(specs)
    loop = asyncio.get_running_loop()
    deadline = loop.time() + duration_seconds
    async with websockets.connect(url, open_timeout=20) as ws:
        for message in venue.subscribe_messages(specs):
            await ws.send(json.dumps(message))
        while loop.time() < deadline:
            remaining = deadline - loop.time()
            try:
                yield await asyncio.wait_for(ws.recv(), timeout=remaining)
            except asyncio.TimeoutError:
                return


async def run_capture(venue, specs, root: Path, duration_seconds: float) -> dict:
    recorder = VenueRecorder(venue, specs, root)
    await recorder.consume(_stream_frames(venue, specs, duration_seconds))
    return recorder.stats()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="capture")
    parser.add_argument("--venue", choices=sorted(_VENUES), required=True)
    parser.add_argument("--symbols", required=True,
                        help="comma-separated, e.g. BTCUSDT,ETHUSDT,SOLUSDT")
    parser.add_argument("--root", default=str(Path.home() / "capture"))
    parser.add_argument("--seconds", type=float, default=0.0,
                        help="0 means run until interrupted")
    args = parser.parse_args(argv)

    venue = _VENUES[args.venue]()
    specs = venue.core_specs(args.symbols.split(","))
    duration = args.seconds if args.seconds > 0 else float("inf")
    stats = asyncio.run(run_capture(venue, specs, Path(args.root), duration))
    print(json.dumps(stats))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

- [ ] **Step 4: Run test to verify it passes**

Run: `CAPTURE_LIVE=1 uv run --python 3.12 pytest tests/test_cli_smoke.py -v`
Expected: PASS (captures real frames for 15 seconds)

Then run the whole suite: `uv run --python 3.12 pytest -v`
Expected: all tests PASS

- [ ] **Step 5: Commit**

```bash
git add src/capture/cli.py tests/test_cli_smoke.py
git commit -m "feat: capture CLI with live venue smoke test"
```

---

