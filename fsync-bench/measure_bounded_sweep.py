"""Worst single stall from the hour-boundary sweep, now that it is sliced.

Compare against measure_fsync_cost.py, which measured the unbounded version at
2,653 ms for 600 writers and 4,173 ms for 1,000.
"""
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path.home() / "trading-system" / "src"))

from capture.raw_writer import RawWriter                                    # noqa: E402
from capture.venue_recorder import VenueRecorder, _MAX_HOUR_CLOSES_PER_FRAME  # noqa: E402
from capture.venues.binance_spot import BinanceSpotVenue                    # noqa: E402

ROOT = Path.home() / "fsync-bench" / "archive"
FRAME = '{"stream":"x@trade","data":{"e":"trade","T":1785685177439,"s":"X","p":"1.0","q":"1.0"}}'
BASE_NS = 1785668400_000_000_000
HOUR_NS = 3_600_000_000_000

venue = BinanceSpotVenue()
recorder = VenueRecorder(venue, venue.tail_specs(["AUSDT"]), ROOT, clock_ns=lambda: BASE_NS)
recorder._settle_writers_whose_hour_ended(BASE_NS)      # arm the boundary, no writers yet

for i in range(1000):
    writer = RawWriter(ROOT, "bench", "trade", f"SYM{i}USDT")
    writer.append(FRAME, BASE_NS, None, None)
    recorder._writers[("trade", f"sym{i}")] = writer

worst_ms = 0.0
frames = 0
while True:
    started = time.perf_counter()
    recorder._settle_writers_whose_hour_ended(BASE_NS + HOUR_NS + frames)
    worst_ms = max(worst_ms, (time.perf_counter() - started) * 1000)
    frames += 1
    if not recorder._hour_close_backlog:
        break

print(f"slice cap = {_MAX_HOUR_CLOSES_PER_FRAME} writers per frame")
print(f"1,000 writers drained over {frames} frame(s)")
print(f"worst single stall: {worst_ms:.0f} ms   (was 4,173 ms in one pass)")
