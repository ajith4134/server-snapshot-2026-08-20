### Task 4: Crash recovery — reconcile raw/index pairs

A `kill -9` can leave the raw file with more lines than the index. Truncating would discard captured data; instead rebuild the missing index entries with unknown receipt time.

**Files:**
- Modify: `src/capture/raw_writer.py`
- Create: `tests/test_raw_writer_recovery.py`

**Interfaces:**
- Consumes: `RawWriter`, `read_pair`, `paths_for` from Task 3
- Produces: `reconcile_pair(raw_path: Path, idx_path: Path) -> int` returning number of index entries repaired

> **Contract established in Task 3's review, which this task completes.** `read_pair` **raises**
> a named mismatch exception when the raw and index files have different line counts — it does
> not silently `zip()` to the shorter one, because that returns wrong data instead of reporting
> damage. `reconcile_pair` is the repair path: it rebuilds the missing index entries so a
> subsequent `read_pair` succeeds. Detect and refuse, then repair — never paper over.
>
> This means the test below must call `reconcile_pair` *before* `read_pair`, which it already does.

- [ ] **Step 1: Write the failing test**

```python
# tests/test_raw_writer_recovery.py
from pathlib import Path
import zstandard
from capture.raw_writer import RawWriter, read_pair, paths_for, reconcile_pair
from capture.frame_codec import decode_index_entry


def _truncate_index_by_one(idx_path: Path) -> None:
    dctx = zstandard.ZstdDecompressor()
    with open(idx_path, "rb") as fh:
        lines = dctx.stream_reader(fh).read().decode("utf-8").rstrip("\n").split("\n")
    cctx = zstandard.ZstdCompressor(level=3)
    with open(idx_path, "wb") as fh:
        with cctx.stream_writer(fh) as w:
            for line in lines[:-1]:
                w.write((line + "\n").encode("utf-8"))


def test_reconcile_rebuilds_missing_index_entries(tmp_path: Path):
    w = RawWriter(tmp_path, "binance", "depth", "BTCUSDT")
    for i in range(3):
        w.append(f'{{"i":{i}}}', t_recv_ns=1785648600_000_000_000 + i,
                 t_exch_ms=None, seq=None)
    w.close()

    raw, idx = paths_for(tmp_path, "binance", "depth", "BTCUSDT", "2026-08-02T05")
    _truncate_index_by_one(idx)

    repaired = reconcile_pair(raw, idx)
    assert repaired == 1

    pairs = read_pair(raw, idx)
    assert len(pairs) == 3
    assert pairs[2][0] == '{"i":2}'
    assert pairs[2][1].t_recv_ns == 0      # unknown, not invented
    assert pairs[2][1].kind == "recovered"


def test_reconcile_is_noop_when_aligned(tmp_path: Path):
    w = RawWriter(tmp_path, "binance", "trades", "ETHUSDT")
    w.append('{"i":0}', t_recv_ns=1785648600_000_000_000, t_exch_ms=None, seq=None)
    w.close()
    raw, idx = paths_for(tmp_path, "binance", "trades", "ETHUSDT", "2026-08-02T05")
    assert reconcile_pair(raw, idx) == 0
```

- [ ] **Step 2: Run test to verify it fails**

Run: `uv run --python 3.12 pytest tests/test_raw_writer_recovery.py -v`
Expected: FAIL with `ImportError: cannot import name 'reconcile_pair'`

- [ ] **Step 3: Write minimal implementation**

Append to `src/capture/raw_writer.py`:

```python
def _read_lines(path: Path) -> list[str]:
    """Split strictly on newline.

    NOT str.splitlines(): that also splits on \v, \f, \x1c-\x1e, \x85,
    U+2028 and U+2029, none of which escape_payload guards. Such a payload
    would yield an extra raw line with no matching index entry, and every
    subsequent line would pair with the wrong entry.
    """
    dctx = zstandard.ZstdDecompressor()
    with open(path, "rb") as fh:
        text = dctx.stream_reader(fh).read().decode("utf-8")
    return text.rstrip("\n").split("\n") if text else []


def _write_lines(path: Path, lines: list[str]) -> None:
    cctx = zstandard.ZstdCompressor(level=3)
    with open(path, "wb") as fh:
        with cctx.stream_writer(fh) as w:
            for line in lines:
                w.write((line + "\n").encode("utf-8"))


def reconcile_pair(raw_path: Path, idx_path: Path) -> int:
    """Rebuild index entries for raw lines a crash left undescribed.

    Returns the number of entries repaired. Never discards raw data, and never
    invents a receipt timestamp - unknown times are recorded as 0 with
    kind="recovered" so downstream can exclude them explicitly.
    """
    raw_lines = _read_lines(raw_path)
    idx_lines = _read_lines(idx_path)
    if len(idx_lines) >= len(raw_lines):
        return 0

    repaired = 0
    for n in range(len(idx_lines), len(raw_lines)):
        entry = IndexEntry(n=n, t_recv_ns=0, t_exch_ms=None,
                           seq=None, kind="recovered", esc=False)
        idx_lines.append(encode_index_entry(entry))
        repaired += 1
    _write_lines(idx_path, idx_lines)
    return repaired
```

- [ ] **Step 4: Run test to verify it passes**

Run: `uv run --python 3.12 pytest tests/test_raw_writer_recovery.py -v`
Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add src/capture/raw_writer.py tests/test_raw_writer_recovery.py
git commit -m "feat: reconcile raw/index pairs after crash without data loss"
```

---

