### Task 2: Frame codec — newline escaping and index entries

The probe confirmed venue frames contain no newlines today. This is the guard for the day one does, so line alignment can never silently corrupt.

**Files:**
- Create: `src/capture/frame_codec.py`
- Create: `tests/test_frame_codec.py`

**Interfaces:**
- Consumes: nothing
- Produces:
  - `escape_payload(payload: str) -> tuple[str, bool]` — returns (escaped, was_escaped)
  - `unescape_payload(payload: str) -> str`
  - `IndexEntry` frozen dataclass with fields `n:int, t_recv_ns:int, t_exch_ms:int|None, seq:dict|None, kind:str, esc:bool`
  - `encode_index_entry(entry: IndexEntry) -> str` (one JSON line, no trailing newline)
  - `decode_index_entry(line: str) -> IndexEntry`

- [ ] **Step 1: Write the failing test**

```python
# tests/test_frame_codec.py
from capture.frame_codec import (
    escape_payload, unescape_payload, IndexEntry,
    encode_index_entry, decode_index_entry,
)


def test_clean_payload_is_untouched():
    payload = '{"e":"depthUpdate","U":1,"u":2}'
    escaped, was_escaped = escape_payload(payload)
    assert escaped == payload
    assert was_escaped is False


def test_newline_is_escaped_and_roundtrips():
    payload = '{"a":"x\ny"}'
    escaped, was_escaped = escape_payload(payload)
    assert was_escaped is True
    assert "\n" not in escaped
    assert unescape_payload(escaped) == payload


def test_carriage_return_is_escaped_and_roundtrips():
    payload = '{"a":"x\r\ny"}'
    escaped, was_escaped = escape_payload(payload)
    assert was_escaped is True
    assert "\r" not in escaped and "\n" not in escaped
    assert unescape_payload(escaped) == payload


def test_backslash_roundtrips_without_false_escape():
    payload = r'{"a":"C:\path"}'
    escaped, was_escaped = escape_payload(payload)
    assert unescape_payload(escaped) == payload


def test_index_entry_roundtrips():
    entry = IndexEntry(n=7, t_recv_ns=123, t_exch_ms=456,
                       seq={"U": 1, "u": 2}, kind="data", esc=False)
    assert decode_index_entry(encode_index_entry(entry)) == entry


def test_index_entry_allows_missing_exchange_time():
    entry = IndexEntry(n=0, t_recv_ns=1, t_exch_ms=None,
                       seq=None, kind="control", esc=False)
    assert decode_index_entry(encode_index_entry(entry)) == entry
```

- [ ] **Step 2: Run test to verify it fails**

Run: `uv run --python 3.12 pytest tests/test_frame_codec.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'capture.frame_codec'`

- [ ] **Step 3: Write minimal implementation**

```python
# src/capture/frame_codec.py
"""Byte-exact framing helpers.

Raw payloads are stored one per line. A payload containing a literal newline
would break line alignment, so newlines are escaped and the index records that
it happened. Backslash is escaped first so unescaping is unambiguous.
"""
import json
from dataclasses import dataclass, asdict

_ESCAPES = (("\\", "\\\\"), ("\n", "\\n"), ("\r", "\\r"))


def escape_payload(payload: str) -> tuple[str, bool]:
    if "\n" not in payload and "\r" not in payload:
        return payload, False
    out = payload
    for raw, esc in _ESCAPES:
        out = out.replace(raw, esc)
    return out, True


def unescape_payload(payload: str) -> str:
    out: list[str] = []
    i = 0
    while i < len(payload):
        ch = payload[i]
        if ch == "\\" and i + 1 < len(payload):
            nxt = payload[i + 1]
            if nxt == "n":
                out.append("\n"); i += 2; continue
            if nxt == "r":
                out.append("\r"); i += 2; continue
            if nxt == "\\":
                out.append("\\"); i += 2; continue
        out.append(ch)
        i += 1
    return "".join(out)


@dataclass(frozen=True)
class IndexEntry:
    n: int
    t_recv_ns: int
    t_exch_ms: int | None
    seq: dict | None
    kind: str
    esc: bool


def encode_index_entry(entry: IndexEntry) -> str:
    return json.dumps(asdict(entry), separators=(",", ":"), sort_keys=True)


def decode_index_entry(line: str) -> IndexEntry:
    return IndexEntry(**json.loads(line))
```

> Note: `escape_payload` returns the payload unchanged when it contains no
> newline, so the backslash escape never fires on clean frames. That keeps
> byte-exactness for every real frame observed in the probe.

- [ ] **Step 4: Run test to verify it passes**

Run: `uv run --python 3.12 pytest tests/test_frame_codec.py -v`
Expected: PASS (6 tests)

- [ ] **Step 5: Commit**

```bash
git add src/capture/frame_codec.py tests/test_frame_codec.py
git commit -m "feat: frame codec with newline guard and index entries"
```

---

