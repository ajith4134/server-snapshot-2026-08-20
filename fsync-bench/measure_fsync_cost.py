"""What a flush and an hour-boundary close actually cost on the event loop.

Run against ext4 under $HOME, never /tmp - /tmp is tmpfs here, where fsync is
nearly free and would answer a question nobody asked. Run while the captures are
live, because contention is the condition being investigated.
"""
import os
import statistics
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path.home() / "trading-system" / "src"))

from capture.raw_writer import RawWriter          # noqa: E402

ROOT = Path.home() / "fsync-bench" / "archive"
FRAME = '{"stream":"x@trade","data":{"e":"trade","T":1785685177439,"s":"X","p":"1.0","q":"1.0"}}'
HOUR_NS = 3_600_000_000_000
BASE_NS = 1785668400_000_000_000


def measure_bare_fsync(samples: int = 200) -> list[float]:
    """Latency of one append+fsync, the unit every flush is built from."""
    path = ROOT / "bare.bin"
    path.parent.mkdir(parents=True, exist_ok=True)
    timings = []
    with open(path, "ab") as handle:
        for _ in range(samples):
            handle.write(b"x" * 512)
            handle.flush()
            started = time.perf_counter()
            os.fsync(handle.fileno())
            timings.append((time.perf_counter() - started) * 1000)
    return timings


def measure_sweep_close(writers_count: int) -> tuple[float, float]:
    """Wall time to close `writers_count` writers in one pass, as the sweep does.

    Returns (total_ms, per_writer_ms). Each close writes a zstd footer to both
    files, fsyncs both, and releases the marker - so this is the real cost of the
    hour-boundary sweep, which loops over every writer synchronously.
    """
    writers = []
    for i in range(writers_count):
        writer = RawWriter(ROOT, "bench", "trade", f"SYM{i}USDT")
        writer.append(FRAME, BASE_NS, None, None)
        writers.append(writer)

    started = time.perf_counter()
    for writer in writers:
        writer.close_if_hour_ended(BASE_NS + HOUR_NS)
    total_ms = (time.perf_counter() - started) * 1000
    return total_ms, total_ms / writers_count


if __name__ == "__main__":
    fsyncs = measure_bare_fsync()
    fsyncs.sort()
    print(f"bare fsync on ext4, {len(fsyncs)} samples:")
    print(f"  median {statistics.median(fsyncs):.2f} ms   "
          f"p95 {fsyncs[int(len(fsyncs) * 0.95)]:.2f} ms   max {fsyncs[-1]:.2f} ms")

    for count in (100, 600, 1000):
        total_ms, per = measure_sweep_close(count)
        print(f"hour-boundary sweep closing {count} writers: "
              f"{total_ms:.0f} ms total ({per:.2f} ms each)")
        print(f"    -> the event loop is blocked for {total_ms / 1000:.2f} s in one pass; "
              f"ping_timeout is 20 s and max_queue is 16")
