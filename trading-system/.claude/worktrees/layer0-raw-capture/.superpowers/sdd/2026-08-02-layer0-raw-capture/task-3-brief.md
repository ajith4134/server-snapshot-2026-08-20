### Task 3: Raw writer — byte-exact append and hourly rotation

**Files:**
- Create: `src/capture/raw_writer.py`
- Create: `tests/test_raw_writer.py`

**Interfaces:**
- Consumes: `capture.frame_codec` (`escape_payload`, `IndexEntry`, `encode_index_entry`)
- Produces:
  - `RawWriter(root: Path, venue: str, stream: str, symbol: str)` with methods
    `append(payload:str, t_recv_ns:int, t_exch_ms:int|None, seq:dict|None, kind:str="data") -> int`,
    `flush() -> None`, `close() -> None`
  - `read_pair(raw_path: Path, idx_path: Path) -> list[tuple[str, IndexEntry]]`
  - `hour_key(ts_ns: int) -> str` returning `"YYYY-MM-DDTHH"` in UTC
  - `paths_for(root, venue, stream, symbol, hour) -> tuple[Path, Path]`

- [ ] **Step 1: Write the failing test**

```python
# tests/test_raw_writer.py
from pathlib import Path
from capture.raw_writer import RawWriter, read_pair, hour_key, paths_for


def test_hour_key_is_utc():
    # 2026-08-02T05:30:00Z
    assert hour_key(1785648600_000_000_000) == "2026-08-02T05"


def test_written_bytes_are_identical_to_input(tmp_path: Path):
    payload = '{"e":"depthUpdate","E":1785650606214,"U":98135459427,"u":98135459442}'
    w = RawWriter(tmp_path, "binance", "depth", "BTCUSDT")
    w.append(payload, t_recv_ns=1785648600_000_000_000,
             t_exch_ms=1785650606214, seq={"U": 98135459427, "u": 98135459442})
    w.close()

    raw, idx = paths_for(tmp_path, "binance", "depth", "BTCUSDT", "2026-08-02T05")
    pairs = read_pair(raw, idx)
    assert len(pairs) == 1
    assert pairs[0][0] == payload          # byte-exact
    assert pairs[0][1].n == 0
    assert pairs[0][1].esc is False


def test_index_line_count_matches_raw_line_count(tmp_path: Path):
    w = RawWriter(tmp_path, "binance", "trades", "ETHUSDT")
    for i in range(50):
        w.append(f'{{"i":{i}}}', t_recv_ns=1785648600_000_000_000 + i,
                 t_exch_ms=None, seq=None)
    w.close()
    raw, idx = paths_for(tmp_path, "binance", "trades", "ETHUSDT", "2026-08-02T05")
    pairs = read_pair(raw, idx)
    assert len(pairs) == 50
    assert [p[1].n for p in pairs] == list(range(50))


def test_payload_with_newline_roundtrips(tmp_path: Path):
    payload = '{"a":"x\ny"}'
    w = RawWriter(tmp_path, "hyperliquid", "l2Book", "BTC")
    w.append(payload, t_recv_ns=1785648600_000_000_000, t_exch_ms=None, seq=None)
    w.close()
    raw, idx = paths_for(tmp_path, "hyperliquid", "l2Book", "BTC", "2026-08-02T05")
    pairs = read_pair(raw, idx)
    assert pairs[0][0] == payload
    assert pairs[0][1].esc is True


def test_rotation_creates_new_hour_file(tmp_path: Path):
    w = RawWriter(tmp_path, "binance", "depth", "BTCUSDT")
    w.append('{"h":5}', t_recv_ns=1785648600_000_000_000, t_exch_ms=None, seq=None)
    w.append('{"h":6}', t_recv_ns=1785652200_000_000_000, t_exch_ms=None, seq=None)
    w.close()

    r5, i5 = paths_for(tmp_path, "binance", "depth", "BTCUSDT", "2026-08-02T05")
    r6, i6 = paths_for(tmp_path, "binance", "depth", "BTCUSDT", "2026-08-02T06")
    assert read_pair(r5, i5)[0][0] == '{"h":5}'
    assert read_pair(r6, i6)[0][0] == '{"h":6}'
    # n resets per file
    assert read_pair(r6, i6)[0][1].n == 0
```

- [ ] **Step 2: Run test to verify it fails**

Run: `uv run --python 3.12 pytest tests/test_raw_writer.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'capture.raw_writer'`

- [ ] **Step 3: Write minimal implementation**

```python
# src/capture/raw_writer.py
"""Writes venue frames verbatim, one per line, with a parallel index sidecar."""
from __future__ import annotations

import datetime as dt
from pathlib import Path

import zstandard

from capture.frame_codec import IndexEntry, encode_index_entry, escape_payload, decode_index_entry, unescape_payload


def hour_key(ts_ns: int) -> str:
    moment = dt.datetime.fromtimestamp(ts_ns / 1e9, tz=dt.timezone.utc)
    return moment.strftime("%Y-%m-%dT%H")


def paths_for(root: Path, venue: str, stream: str, symbol: str, hour: str) -> tuple[Path, Path]:
    date = hour.split("T")[0]
    folder = Path(root) / "raw" / venue / date
    stem = f"{stream}_{symbol}_{hour}"
    return folder / f"{stem}.ndjson.zst", folder / f"{stem}.idx.zst"


class RawWriter:
    """Append-only writer for one (venue, stream, symbol). Rotates hourly by UTC."""

    def __init__(self, root: Path, venue: str, stream: str, symbol: str) -> None:
        self._root = Path(root)
        self._venue, self._stream, self._symbol = venue, stream, symbol
        self._hour: str | None = None
        self._raw_fh = self._idx_fh = None
        self._raw_z = self._idx_z = None
        self._n = 0

    def _open(self, hour: str) -> None:
        raw_path, idx_path = paths_for(self._root, self._venue, self._stream, self._symbol, hour)
        raw_path.parent.mkdir(parents=True, exist_ok=True)
        cctx = zstandard.ZstdCompressor(level=3)
        self._raw_fh = open(raw_path, "wb")
        self._idx_fh = open(idx_path, "wb")
        self._raw_z = cctx.stream_writer(self._raw_fh)
        self._idx_z = cctx.stream_writer(self._idx_fh)
        self._hour, self._n = hour, 0

    def append(self, payload: str, t_recv_ns: int, t_exch_ms: int | None,
               seq: dict | None, kind: str = "data") -> int:
        hour = hour_key(t_recv_ns)
        if hour != self._hour:
            self.close()
            self._open(hour)

        escaped, was_escaped = escape_payload(payload)
        entry = IndexEntry(n=self._n, t_recv_ns=t_recv_ns, t_exch_ms=t_exch_ms,
                           seq=seq, kind=kind, esc=was_escaped)
        self._raw_z.write((escaped + "\n").encode("utf-8"))
        self._idx_z.write((encode_index_entry(entry) + "\n").encode("utf-8"))
        self._n += 1
        return entry.n

    def flush(self) -> None:
        if self._raw_z is not None:
            self._raw_z.flush(zstandard.FLUSH_FRAME)
            self._idx_z.flush(zstandard.FLUSH_FRAME)
            self._raw_fh.flush()
            self._idx_fh.flush()

    def close(self) -> None:
        if self._raw_z is None:
            return
        self._raw_z.close(); self._idx_z.close()
        self._raw_fh.close(); self._idx_fh.close()
        self._raw_z = self._idx_z = self._raw_fh = self._idx_fh = None
        self._hour = None


def read_pair(raw_path: Path, idx_path: Path) -> list[tuple[str, IndexEntry]]:
    dctx = zstandard.ZstdDecompressor()
    with open(raw_path, "rb") as fh:
        raw_lines = dctx.stream_reader(fh).read().decode("utf-8").splitlines()
    with open(idx_path, "rb") as fh:
        idx_lines = dctx.stream_reader(fh).read().decode("utf-8").splitlines()
    return [
        (unescape_payload(r), decode_index_entry(i))
        for r, i in zip(raw_lines, idx_lines)
    ]
```

- [ ] **Step 4: Run test to verify it passes**

Run: `uv run --python 3.12 pytest tests/test_raw_writer.py -v`
Expected: PASS (5 tests)

- [ ] **Step 5: Commit**

```bash
git add src/capture/raw_writer.py tests/test_raw_writer.py
git commit -m "feat: byte-exact raw writer with hourly rotation"
```

---

