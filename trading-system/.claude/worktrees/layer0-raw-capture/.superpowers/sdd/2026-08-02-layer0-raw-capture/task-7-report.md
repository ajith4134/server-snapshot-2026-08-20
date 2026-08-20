# Task 7 Report: Venue adapters

## What was implemented

- `src/capture/venues/__init__.py` — frozen dataclasses `StreamSpec(venue, stream, symbol, channel)`
  and `ExtractedMeta(t_exch_ms, seq, kind, stream, symbol)`, exactly as specified in the brief.
- `src/capture/venues/binance.py` — `BinanceVenue`:
  - `core_specs`/`tail_specs` build `StreamSpec`s for Binance USDⓈ-M futures channels
    (core: `depth@100ms`, `aggTrade`, `markPrice@1s`, `forceOrder`; tail: same minus depth).
  - `ws_url` builds the combined-stream URL (`wss://fstream.binance.com/stream?streams=...`).
  - `subscribe_messages` returns `[]` — Binance encodes subscriptions in the URL, not over the
    socket, so this is a real "nothing to do here" per the shared interface, not dead code.
  - `extract` reads `E` (event time) into `t_exch_ms`, and for `depthUpdate` frames folds
    `U`/`u`/`pu`/`T` into `seq`. Non-depth frames get `seq=None`.
  - `instruments_url`/`parse_instruments` hit `/fapi/v1/exchangeInfo` and keep only
    `contractType == "PERPETUAL"` and `status == "TRADING"` symbols.
- `src/capture/venues/hyperliquid.py` — `HyperliquidVenue`:
  - `core_specs`/`tail_specs` build specs for `l2Book`/`trades` (core) vs `trades`-only (tail,
    no depth).
  - `ws_url` returns the fixed Hyperliquid endpoint; `subscribe_messages` builds one
    `{"method": "subscribe", "subscription": {"type": ..., "coin": ...}}` per spec, since
    Hyperliquid requires subscribe frames sent over the socket after connecting.
  - `extract` flags `subscriptionResponse`/`pong`/`error`/non-string channels as `kind="control"`,
    and reads `time`/`coin` out of `l2Book`/`trades` data as `kind="data"`. `seq` is always `None`
    — l2Book carries no sequence number of any kind, only a `time` field.
  - `instruments_url`/`parse_instruments` hit `/info` and keep non-delisted `universe` entries.

### Hardening beyond the brief's happy-path tests

The brief flagged `extract()` and `parse_instruments()` as reading untrusted wire data and asked
that malformed frames not raise. Both methods now guard against: the frame not being a dict at
all, `data`/`body` not being a dict, missing/non-string `event`/`channel` fields, non-int
timestamp fields, missing/empty symbol fields, `data` being an empty or malformed list (trades
channel), and instrument-list entries that are non-dicts or missing `symbol`/`name`. On any of
these, `extract()` degrades to a safe `control`/`"unknown"` result instead of raising, and
`parse_instruments()` skips the bad entry rather than crashing the whole parse.

## TDD evidence

**RED** — `uv run --python 3.12 pytest tests/test_venues.py -v` before any implementation existed:

```
ImportError while importing test module '.../tests/test_venues.py'.
tests/test_venues.py:1: in <module>
    from capture.venues.binance import BinanceVenue
E   ModuleNotFoundError: No module named 'capture.venues.binance'
=========================== short test summary info ============================
ERROR tests/test_venues.py
```

Expected and correct: the `capture.venues` package didn't exist yet.

**GREEN** — same command after implementing `__init__.py`, `binance.py`, `hyperliquid.py`:

```
tests/test_venues.py::test_binance_builds_combined_stream_url PASSED
tests/test_venues.py::test_binance_extract_reads_both_timestamps_and_chain PASSED
tests/test_venues.py::test_binance_parses_perp_instruments_only PASSED
tests/test_venues.py::test_hyperliquid_subscribe_messages_cover_each_spec PASSED
tests/test_venues.py::test_hyperliquid_extract_flags_control_frames PASSED
tests/test_venues.py::test_hyperliquid_extract_reads_snapshot_time PASSED
============================== 6 passed in 0.01s ===============================
```

I then added 10 more tests (also RED→GREEN, same cycle, all passed on first implementation
attempt since the hardening was written alongside them) covering the malformed-input cases
above: non-dict frames, missing event/channel fields, empty/malformed instrument-list entries,
list-shaped Hyperliquid `data` (trades), and empty-list data. Final `test_venues.py` run:

```
uv run --python 3.12 pytest tests/test_venues.py -v
============================== 16 passed in 0.03s ===============================
```

**Full suite** — `uv run --python 3.12 pytest -v`:

```
============================== 49 passed in 0.08s ===============================
```

(33 pre-existing + 16 new, 0 failures, 0 warnings — pristine output.)

## Manual sanity check

Ran the adapters directly against the tier shapes from the constraints (core = BTC/ETH/SOL, tail
= no depth):

- `BinanceVenue().ws_url(core_specs(["BTCUSDT","ETHUSDT","SOLUSDT"]))` →
  `wss://fstream.binance.com/stream?streams=btcusdt@depth@100ms/btcusdt@aggTrade/btcusdt@markPrice@1s/btcusdt@forceOrder/...`
- `BinanceVenue().tail_specs(["XRPUSDT"])` → aggTrade/markPrice/forceOrder only, no depth.
- `HyperliquidVenue().subscribe_messages(core_specs(["BTC","ETH","SOL"]))` → one
  `l2Book` + one `trades` subscribe message per coin.
- `HyperliquidVenue().tail_specs(["XRP"])` → `trades` only, no `l2Book`.

## Files changed

- `src/capture/venues/__init__.py` (new)
- `src/capture/venues/binance.py` (new)
- `src/capture/venues/hyperliquid.py` (new)
- `tests/test_venues.py` (new)

## Commit

`d50ab22` — `feat: binance and hyperliquid venue adapters`

## Self-review

- **Completeness**: all methods the interface requires are present on both venues with matching
  signatures. `StreamSpec`/`ExtractedMeta` match the brief's field lists exactly, frozen as
  required.
- **YAGNI**: no extra methods, no venue registry, no config plumbing, no retry/backoff logic —
  none of that was asked for in this task. The only addition beyond the brief's literal step-3
  code is defensive input validation in `extract()`/`parse_instruments()`, which the brief itself
  asked for by name ("think about what each does when a field is missing... the nasty cases are
  yours to consider").
- **Do the tests verify real behaviour?** Yes — each hardening test asserts on the actual
  `ExtractedMeta`/`list[str]` returned for a specific malformed shape, not just "does not raise."
- **Known, accepted gap (inherited from the brief, not introduced here) — FIXED, see below**:
  Binance's `forceOrder` (liquidation) messages were believed to nest the order's `symbol` under
  an `"o"` sub-object rather than at top level. `extract()`'s `body.get("s", "unknown")` — taken
  verbatim from the brief's reference implementation — would therefore return `"unknown"` for
  `forceOrder` symbol. See the "Fix round" section below for resolution.
- **Test output**: pristine — 49 passed, 0 warnings, 0 skipped (pre-fix; 51 passed post-fix, see
  below).

## Concerns (superseded — see "Fix round" below)

Only the `forceOrder` nested-symbol note above. It does not affect any test in this task's brief
and was inherited from the verbatim reference implementation rather than introduced by my
hardening, so I did not change it without direction. Flagging it for whoever builds the
`forceOrder`/liquidation consumer downstream.

---

## Fix round: shape-agnostic symbol extraction

The coordinator asked me to address the `forceOrder` symbol-nesting concern before review, with
one important correction to how I'd framed it:

**What is and isn't verified.** The coordinator subscribed live to
`wss://fstream.binance.com/ws/!forceOrder@arr` for 90 seconds — no liquidation fired in that
window (they're episodic), so the live probe did not settle the frame shape. The Binance docs
page returned 0 bytes (JS-rendered, no static content to curl). **So my original claim that
`forceOrder` nests `symbol` under `"o"` is not confirmed from an authoritative source** — I should
not have stated it as fact in the original report. It's a plausible claim based on general
familiarity with Binance's liquidation-stream shape, not something this task's probe verified,
and I'm correcting that framing here.

**Why the fix doesn't depend on resolving that uncertainty.** Since the correct fix is the same
whether the symbol lives at top level (confirmed by the probe for `depthUpdate`, `aggTrade`, etc.)
or nested under `o` (unverified claim for `forceOrder`), I made `extract()`'s symbol lookup
shape-agnostic rather than betting on one shape: try top-level `s` first (the confirmed path for
every event type this task's probe actually observed), then fall back to `o.s` if `o` is a dict
containing it, then `"unknown"` if neither is present. This is also safe against a frame shape
that does neither.

**Data-safety note, unchanged by any of this**: the raw bytes were never at risk before or after
this fix. `raw_writer` stores each frame verbatim regardless of what `extract()` does with it —
`extract()` only feeds per-symbol *file routing* metadata. Getting the symbol wrong would have
misrouted a liquidation frame to the wrong symbol's file, not lost it; the frame itself is always
recoverable from the raw stream by hour/venue even if metadata extraction had degraded to
`"unknown"`.

### Change made

`src/capture/venues/binance.py`, `extract()`:

```python
symbol = body.get("s")
if not isinstance(symbol, str) or not symbol:
    # Not every event puts the symbol at top level - forceOrder nests
    # order fields under "o". Fall back there before giving up.
    nested = body.get("o")
    symbol = nested.get("s") if isinstance(nested, dict) else None
    if not isinstance(symbol, str) or not symbol:
        symbol = "unknown"
```

No change to `t_exch_ms` or any other field — the coordinator was explicit that widening should
be scoped to a concrete reason, and there was none for the timestamp field. No forceOrder body
parser was added; `extract()` still only pulls the one routing field it needs.

### Tests added

`tests/test_venues.py`:

- `test_binance_extract_reads_top_level_symbol_when_present` — an `aggTrade`-shaped frame with
  `s` at top level still resolves to that symbol (regression guard for the existing/confirmed
  path).
- `test_binance_extract_falls_back_to_nested_order_symbol_for_force_order` — a `forceOrder`-shaped
  frame with `symbol` only under `o.s` resolves to that nested value instead of `"unknown"`.

### Commands and output

`uv run --python 3.12 pytest tests/test_venues.py -v`:

```
collected 18 items

tests/test_venues.py::test_binance_builds_combined_stream_url PASSED
tests/test_venues.py::test_binance_extract_reads_both_timestamps_and_chain PASSED
tests/test_venues.py::test_binance_parses_perp_instruments_only PASSED
tests/test_venues.py::test_hyperliquid_subscribe_messages_cover_each_spec PASSED
tests/test_venues.py::test_hyperliquid_extract_flags_control_frames PASSED
tests/test_venues.py::test_hyperliquid_extract_reads_snapshot_time PASSED
tests/test_venues.py::test_binance_extract_does_not_raise_on_missing_event_field PASSED
tests/test_venues.py::test_binance_extract_does_not_raise_on_non_dict_frame PASSED
tests/test_venues.py::test_binance_extract_reads_top_level_symbol_when_present PASSED
tests/test_venues.py::test_binance_extract_falls_back_to_nested_order_symbol_for_force_order PASSED
tests/test_venues.py::test_binance_extract_depth_update_missing_chain_fields_has_no_seq PASSED
tests/test_venues.py::test_binance_parse_instruments_skips_malformed_entries PASSED
tests/test_venues.py::test_binance_parse_instruments_handles_missing_or_wrong_shaped_symbols PASSED
tests/test_venues.py::test_hyperliquid_extract_handles_missing_data PASSED
tests/test_venues.py::test_hyperliquid_extract_handles_list_shaped_data PASSED
tests/test_venues.py::test_hyperliquid_extract_handles_empty_list_data PASSED
tests/test_venues.py::test_hyperliquid_extract_does_not_raise_on_non_dict_frame PASSED
tests/test_venues.py::test_hyperliquid_parse_instruments_skips_delisted_and_malformed PASSED
============================== 18 passed in 0.04s ===============================
```

Full suite, `uv run --python 3.12 pytest -v`:

```
============================== 51 passed in 0.08s ===============================
```

(33 pre-existing + 18 in `test_venues.py`, 0 failures, 0 warnings.)

### Commit

`7d325c7` — `fix: shape-agnostic symbol extraction for binance forceOrder frames`

### Concerns after the fix

None outstanding. The `forceOrder` shape is still not confirmed from an authoritative source
(that remains genuinely unverified, not just previously under-caveated), but the fix no longer
depends on which shape is correct, and raw capture was never affected either way.

---

## Fix round 2: `instruments_url()` cannot express Hyperliquid's request shape

Review came back **Approved** (no Critical/Important findings) — `extract()`/`parse_instruments()`
traced against every adversarial input and confirmed unable to raise, stream-name derivation
verified consistent between `StreamSpec` and `ExtractedMeta`, the round-1 `forceOrder` fix
accepted as correct, and the `seq = {...} or None` normalization singled out as an improvement
over the brief's reference code.

One item the reviewer couldn't verify was checked live by the coordinator and confirmed as a real
gap:

```
GET  https://api.hyperliquid.xyz/info                   -> 405 Method Not Allowed
POST https://api.hyperliquid.xyz/info  {"type":"meta"}  -> 232 universe entries, isDelisted present
GET  https://fapi.binance.com/fapi/v1/exchangeInfo      -> 200
```

`instruments_url()` returned a bare URL, which implies GET. Binance's `exchangeInfo` is GET, but
Hyperliquid's `/info` is POST-only and requires a `{"type": "meta"}` body — a bare URL cannot
express that. Task 9's universe tracker, built on this interface, would have issued a GET to
Hyperliquid, gotten a 405, and (per `parse_instruments`'s existing malformed-payload guards)
returned an empty instrument list — read downstream as "everything delisted," silently, which is
exactly the R2 point-in-time-universe-membership failure the interface exists to prevent.

`parse_instruments`'s `isDelisted` filter itself was independently confirmed correct against the
live payload and was left unchanged, per instruction.

### Change made

Replaced `instruments_url() -> str` with `instruments_request() -> tuple[str, str, dict | None]`
on both venues, returning `(method, url, json_body)`:

`src/capture/venues/binance.py`:
```python
def instruments_request(self) -> tuple[str, str, dict | None]:
    return ("GET", _INSTRUMENTS_URL, None)
```

`src/capture/venues/hyperliquid.py`:
```python
def instruments_request(self) -> tuple[str, str, dict | None]:
    return ("POST", _INSTRUMENTS_URL, {"type": "meta"})
```

`instruments_url()` was removed outright rather than kept alongside the new method — a repo-wide
`grep -rn "instruments_url"` after the change confirmed zero remaining references, matching the
reviewer's earlier repo-wide check that no caller existed yet. Keeping a misleading accessor next
to a correct one would only invite a future call site to pick the wrong one.

### Tests added

`tests/test_venues.py`:

- `test_binance_instruments_request_is_a_plain_get` — asserts the exact triple
  `("GET", "https://fapi.binance.com/fapi/v1/exchangeInfo", None)`.
- `test_hyperliquid_instruments_request_is_a_post_with_meta_body` — asserts the exact triple
  `("POST", "https://api.hyperliquid.xyz/info", {"type": "meta"})`.

Both assert only the returned values — no live network call in either test, per instruction.

### Commands and output

`uv run --python 3.12 pytest tests/test_venues.py -v`:

```
collected 20 items

tests/test_venues.py::test_binance_builds_combined_stream_url PASSED
tests/test_venues.py::test_binance_extract_reads_both_timestamps_and_chain PASSED
tests/test_venues.py::test_binance_instruments_request_is_a_plain_get PASSED
tests/test_venues.py::test_binance_parses_perp_instruments_only PASSED
tests/test_venues.py::test_hyperliquid_instruments_request_is_a_post_with_meta_body PASSED
tests/test_venues.py::test_hyperliquid_subscribe_messages_cover_each_spec PASSED
tests/test_venues.py::test_hyperliquid_extract_flags_control_frames PASSED
tests/test_venues.py::test_hyperliquid_extract_reads_snapshot_time PASSED
tests/test_venues.py::test_binance_extract_does_not_raise_on_missing_event_field PASSED
tests/test_venues.py::test_binance_extract_does_not_raise_on_non_dict_frame PASSED
tests/test_venues.py::test_binance_extract_reads_top_level_symbol_when_present PASSED
tests/test_venues.py::test_binance_extract_falls_back_to_nested_order_symbol_for_force_order PASSED
tests/test_venues.py::test_binance_extract_depth_update_missing_chain_fields_has_no_seq PASSED
tests/test_venues.py::test_binance_parse_instruments_skips_malformed_entries PASSED
tests/test_venues.py::test_binance_parse_instruments_handles_missing_or_wrong_shaped_symbols PASSED
tests/test_venues.py::test_hyperliquid_extract_handles_missing_data PASSED
tests/test_venues.py::test_hyperliquid_extract_handles_list_shaped_data PASSED
tests/test_venues.py::test_hyperliquid_extract_handles_empty_list_data PASSED
tests/test_venues.py::test_hyperliquid_extract_does_not_raise_on_non_dict_frame PASSED
tests/test_venues.py::test_hyperliquid_parse_instruments_skips_delisted_and_malformed PASSED
============================== 20 passed in 0.04s ===============================
```

Full suite, `uv run --python 3.12 pytest -v`:

```
============================== 53 passed in 0.08s ===============================
```

(33 pre-existing + 20 in `test_venues.py`, 0 failures, 0 warnings.)

### Commit

`a69e940` — `fix: replace instruments_url with instruments_request to carry method+body`

### Concerns after this fix round

None outstanding.
