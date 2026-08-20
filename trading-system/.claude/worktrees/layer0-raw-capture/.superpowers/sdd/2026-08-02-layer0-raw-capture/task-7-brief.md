### Task 7: Venue adapters

**Files:**
- Create: `src/capture/venues/__init__.py`
- Create: `src/capture/venues/binance.py`
- Create: `src/capture/venues/hyperliquid.py`
- Create: `tests/test_venues.py`

**Interfaces:**
- Consumes: nothing
- Produces:
  - `StreamSpec` frozen dataclass: `venue:str, stream:str, symbol:str, channel:str`
  - `ExtractedMeta` frozen dataclass: `t_exch_ms:int|None, seq:dict|None, kind:str, stream:str, symbol:str`
  - `BinanceVenue` with `name`, `core_specs(symbols) -> list[StreamSpec]`, `tail_specs(symbols) -> list[StreamSpec]`, `ws_url(specs) -> str`, `subscribe_messages(specs) -> list[dict]`, `extract(parsed: dict) -> ExtractedMeta`, `instruments_url() -> str`, `parse_instruments(payload: dict) -> list[str]`
  - `HyperliquidVenue` with the same method set

- [ ] **Step 1: Write the failing test**

```python
# tests/test_venues.py
from capture.venues.binance import BinanceVenue
from capture.venues.hyperliquid import HyperliquidVenue


def test_binance_builds_combined_stream_url():
    v = BinanceVenue()
    specs = v.core_specs(["BTCUSDT", "ETHUSDT"])
    url = v.ws_url(specs)
    assert url.startswith("wss://fstream.binance.com/stream?streams=")
    assert "btcusdt@depth@100ms" in url
    assert "btcusdt@aggTrade" in url


def test_binance_extract_reads_both_timestamps_and_chain():
    v = BinanceVenue()
    parsed = {"e": "depthUpdate", "E": 1785650606302, "T": 1785650606300,
              "s": "BTCUSDT", "U": 11192579046493, "u": 11192579053768,
              "pu": 11192579046406}
    meta = v.extract(parsed)
    assert meta.t_exch_ms == 1785650606302
    assert meta.seq == {"U": 11192579046493, "u": 11192579053768,
                        "pu": 11192579046406, "T": 1785650606300}
    assert meta.kind == "data"
    assert meta.symbol == "BTCUSDT"


def test_binance_parses_perp_instruments_only():
    v = BinanceVenue()
    payload = {"symbols": [
        {"symbol": "BTCUSDT", "contractType": "PERPETUAL", "status": "TRADING"},
        {"symbol": "ETHUSDT_240329", "contractType": "CURRENT_QUARTER", "status": "TRADING"},
        {"symbol": "OLDUSDT", "contractType": "PERPETUAL", "status": "BREAK"},
    ]}
    assert v.parse_instruments(payload) == ["BTCUSDT"]


def test_hyperliquid_subscribe_messages_cover_each_spec():
    v = HyperliquidVenue()
    specs = v.core_specs(["BTC"])
    msgs = v.subscribe_messages(specs)
    assert {"method": "subscribe",
            "subscription": {"type": "l2Book", "coin": "BTC"}} in msgs


def test_hyperliquid_extract_flags_control_frames():
    v = HyperliquidVenue()
    meta = v.extract({"channel": "subscriptionResponse", "data": {}})
    assert meta.kind == "control"
    assert meta.seq is None


def test_hyperliquid_extract_reads_snapshot_time():
    v = HyperliquidVenue()
    meta = v.extract({"channel": "l2Book",
                      "data": {"coin": "BTC", "time": 1785650605471, "levels": []}})
    assert meta.kind == "data"
    assert meta.t_exch_ms == 1785650605471
    assert meta.symbol == "BTC"
    assert meta.seq is None            # no sequence numbers exist
```

- [ ] **Step 2: Run test to verify it fails**

Run: `uv run --python 3.12 pytest tests/test_venues.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'capture.venues'`

- [ ] **Step 3: Write minimal implementation**

```python
# src/capture/venues/__init__.py
from dataclasses import dataclass


@dataclass(frozen=True)
class StreamSpec:
    venue: str
    stream: str
    symbol: str
    channel: str


@dataclass(frozen=True)
class ExtractedMeta:
    t_exch_ms: int | None
    seq: dict | None
    kind: str
    stream: str
    symbol: str
```

```python
# src/capture/venues/binance.py
"""Binance USDs-M perpetual futures. Spot is deliberately not captured - see spec 11 Q4."""
from __future__ import annotations

from capture.venues import ExtractedMeta, StreamSpec

_WS_BASE = "wss://fstream.binance.com/stream?streams="
_INSTRUMENTS_URL = "https://fapi.binance.com/fapi/v1/exchangeInfo"

_CORE_CHANNELS = ["depth@100ms", "aggTrade", "markPrice@1s", "forceOrder"]
_TAIL_CHANNELS = ["aggTrade", "markPrice@1s", "forceOrder"]


class BinanceVenue:
    name = "binance"

    def _specs(self, symbols: list[str], channels: list[str]) -> list[StreamSpec]:
        return [
            StreamSpec(self.name, channel.split("@")[0], symbol, f"{symbol.lower()}@{channel}")
            for symbol in symbols
            for channel in channels
        ]

    def core_specs(self, symbols: list[str]) -> list[StreamSpec]:
        return self._specs(symbols, _CORE_CHANNELS)

    def tail_specs(self, symbols: list[str]) -> list[StreamSpec]:
        return self._specs(symbols, _TAIL_CHANNELS)

    def ws_url(self, specs: list[StreamSpec]) -> str:
        return _WS_BASE + "/".join(spec.channel for spec in specs)

    def subscribe_messages(self, specs: list[StreamSpec]) -> list[dict]:
        return []          # subscription is encoded in the URL

    def extract(self, parsed: dict) -> ExtractedMeta:
        body = parsed.get("data", parsed)
        event = body.get("e")
        if event is None:
            return ExtractedMeta(None, None, "control", "unknown", "unknown")

        seq = None
        if event == "depthUpdate":
            seq = {k: body[k] for k in ("U", "u", "pu", "T") if k in body}
        stream = {"depthUpdate": "depth", "aggTrade": "aggTrade",
                  "markPriceUpdate": "markPrice", "forceOrder": "forceOrder"}.get(event, event)
        return ExtractedMeta(body.get("E"), seq, "data", stream, body.get("s", "unknown"))

    def instruments_url(self) -> str:
        return _INSTRUMENTS_URL

    def parse_instruments(self, payload: dict) -> list[str]:
        return sorted(
            item["symbol"]
            for item in payload.get("symbols", [])
            if item.get("contractType") == "PERPETUAL" and item.get("status") == "TRADING"
        )
```

```python
# src/capture/venues/hyperliquid.py
"""Hyperliquid perps. l2Book carries no sequence numbers - staleness only."""
from __future__ import annotations

from capture.venues import ExtractedMeta, StreamSpec

_WS_URL = "wss://api.hyperliquid.xyz/ws"
_INSTRUMENTS_URL = "https://api.hyperliquid.xyz/info"

_CORE_TYPES = ["l2Book", "trades"]
_TAIL_TYPES = ["trades"]


class HyperliquidVenue:
    name = "hyperliquid"

    def _specs(self, symbols: list[str], types: list[str]) -> list[StreamSpec]:
        return [StreamSpec(self.name, t, symbol, t) for symbol in symbols for t in types]

    def core_specs(self, symbols: list[str]) -> list[StreamSpec]:
        return self._specs(symbols, _CORE_TYPES)

    def tail_specs(self, symbols: list[str]) -> list[StreamSpec]:
        return self._specs(symbols, _TAIL_TYPES)

    def ws_url(self, specs: list[StreamSpec]) -> str:
        return _WS_URL

    def subscribe_messages(self, specs: list[StreamSpec]) -> list[dict]:
        return [
            {"method": "subscribe",
             "subscription": {"type": spec.stream, "coin": spec.symbol}}
            for spec in specs
        ]

    def extract(self, parsed: dict) -> ExtractedMeta:
        channel = parsed.get("channel")
        if channel in (None, "subscriptionResponse", "pong", "error"):
            return ExtractedMeta(None, None, "control", str(channel), "unknown")
        data = parsed.get("data") or {}
        if isinstance(data, list):
            symbol = data[0].get("coin", "unknown") if data else "unknown"
            t_ms = data[0].get("time") if data else None
        else:
            symbol = data.get("coin", "unknown")
            t_ms = data.get("time")
        return ExtractedMeta(t_ms, None, "data", channel, symbol)

    def instruments_url(self) -> str:
        return _INSTRUMENTS_URL

    def parse_instruments(self, payload: dict) -> list[str]:
        universe = payload.get("universe", [])
        return sorted(
            item["name"] for item in universe if not item.get("isDelisted", False)
        )
```

- [ ] **Step 4: Run test to verify it passes**

Run: `uv run --python 3.12 pytest tests/test_venues.py -v`
Expected: PASS (6 tests)

- [ ] **Step 5: Commit**

```bash
git add src/capture/venues tests/test_venues.py
git commit -m "feat: binance and hyperliquid venue adapters"
```

---

