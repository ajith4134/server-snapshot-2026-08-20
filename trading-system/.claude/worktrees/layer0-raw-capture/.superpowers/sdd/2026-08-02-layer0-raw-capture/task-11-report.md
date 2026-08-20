# Task 11 report: CLI and live smoke test

Commit: `370d200` — *feat: capture CLI with live venue smoke test*
Branch: `worktree-layer0-raw-capture`. Python 3.12.13 via `uv run --python 3.12`.

## What was implemented

**`src/capture/cli.py`** (new)

- `_stream_frames(venue, specs, duration_seconds) -> AsyncIterator[str]` — connects to
  `venue.ws_url(specs)`, sends `venue.subscribe_messages(specs)` as JSON text (none for
  Binance, which encodes the subscription in the URL; one per spec for Hyperliquid), then
  yields every text frame **verbatim** until the duration is up. The deadline is enforced
  per receive via `asyncio.wait_for`, so a stream that has gone quiet still ends the run.
- `run_capture(venue, specs, root, duration_seconds) -> dict` — feeds that stream to
  `VenueRecorder.consume` inside `contextlib.aclosing` and returns `recorder.stats()`.
- `main(argv=None) -> int` — `--venue`, `--symbols`, `--root`, `--seconds`; prints
  `stats` as JSON on stdout; `python -m capture.cli` works.

**`tests/test_cli_smoke.py`** (new) — 17 tests: 1 live (opt-in `CAPTURE_LIVE=1`) and 16
offline driving the same code path through a fake socket.

### Deviations from the brief's sample code, and why

| Change | Reason |
|---|---|
| Deadline starts **after** the subscription is sent, not before `connect` | `open_timeout=20` means a slow handshake could otherwise eat the entire capture window and return an empty run from a venue that was working. Killed as mutation M13. |
| `contextlib.aclosing` around the frame stream | If `consume()` raises, the async generator is left suspended inside `async with websockets.connect(...)` and the socket stays open until interpreter finalisation. Killed as M9. |
| `timeout=None if math.isinf(remaining) else remaining` | `--seconds 0` means "until interrupted"; the brief passed `inf` straight into `wait_for`. Explicit is safer than relying on `call_later(inf)`. |
| `main` strips whitespace round symbols and refuses an empty list | `" ETHUSDT"` builds a channel the venue does not know, and a venue answers an unknown channel by **sending nothing** — an empty capture that looks exactly like a quiet market. M5/M11. |
| `main` refuses `--seconds` < 0 | `--seconds -5` is a typo; the brief's expression silently turned it into "run forever". M12. |
| `main` catches `KeyboardInterrupt` → exit 130 + stderr note | `--seconds 0` ends by Ctrl-C by design. Verified against a real SIGINT (below), not just a mock. M10. |
| Live test extended (tee, hour union, extra assertions) | See below — the brief's version could pass on a pipeline that re-serialised every frame. |

The live test computes the hour at the **start and the end** of the run and reads both,
rather than assuming one; a capture that straddles an hour boundary rotates files mid-run.

## TDD evidence

1. Tests written first. `uv run --python 3.12 pytest tests/test_cli_smoke.py -q` →
   `ImportError: cannot import name 'cli' from 'capture'` (collection error, 1 error).
2. Implementation written. `pytest tests/test_cli_smoke.py -v` → **15 passed, 1 skipped**
   (live skipped without `CAPTURE_LIVE`).
3. Full suite: **211 passed, 1 skipped** (baseline was 194; +17 new).
   With `CAPTURE_LIVE=1`: **212 passed in 27.23s**.

## Mutation testing — 13 mutations, 13 killed, 0 survivors

Each mutation was applied to `src/capture/cli.py`, the CLI test file run, and the file
restored (script: `scratchpad/run_mutations.py`).

| # | Mutation | Result |
|---|---|---|
| M1 | Never send subscribe messages | KILLED (Hyperliquid subscribe test) |
| M2 | Receive with no deadline | KILLED — 5 tests fail on the 10s `finish_within` bound |
| M3 | `json.dumps(json.loads(frame))` instead of storing verbatim | KILLED (byte-exactness) |
| M4 | Return a fabricated stats dict instead of the recorder's | KILLED |
| M5 | Do not strip whitespace round symbols | KILLED |
| M6 | `--seconds 0` means zero, not forever | KILLED |
| M7 | Write to the working directory instead of `--root` | KILLED |
| M8 | Subscribe to only the first spec | KILLED |
| M9 | Drop `aclosing` (leak the socket when recording fails) | KILLED |
| M10 | Report success (0) after an interrupt | KILLED |
| M11 | Accept an empty symbol list | KILLED |
| M12 | Accept a negative duration | KILLED |
| M13 | Start the deadline before the handshake | KILLED |

M2 initially killed only by **hanging the suite forever**. That is a bad failure mode, so
`finish_within()` was added to bound every offline run; M2 now fails cleanly in 50s
(5 failures) instead of hanging. Re-verified after the fix.

## The live run — what really happened

Venue reachable from this host: yes. `wss://fstream.binance.com` handshake succeeds,
`https://fapi.binance.com/fapi/v1/time` returns 200.

### 1. The live test (`CAPTURE_LIVE=1`, 15s, BTCUSDT core specs) — PASSED

It monkeypatches `_stream_frames` with a tee, so the test holds the exact text Binance
sent and compares it against what `read_pair` returns. Assertions that actually fired:
`written > 0`, `dropped == 0`, `malformed == 0`, `unwritable == 0`,
`written == len(on_the_wire)`, `len(pairs) > 0`, `stored_bytes > 0`, every stored payload
present in the set of wire frames, `n == 0` on the first entry, `t_exch_ms == body["E"]`,
`seq == {U,u,pu,T}` from the frame, and `started_ns <= t_recv_ns <= finished_ns`.

### 2. Real CLI run — `python -m capture.cli --venue binance --symbols BTCUSDT,ETHUSDT,SOLUSDT --seconds 30`

```
{"written": 853, "dropped": 0, "control": 0, "malformed": 0, "unwritable": 0}
exit=0   (36.9s wall, 11:34:59–11:35:36 UTC)
```

Files produced (`raw/binance/2026-08-02/`):

| file | bytes on disk |
|---|---|
| `depth_BTCUSDT_2026-08-02T11.ndjson.zst` | 99,553 |
| `depth_BTCUSDT_2026-08-02T11.idx.zst` | 8,350 |
| `depth_ETHUSDT_2026-08-02T11.ndjson.zst` | 114,587 |
| `depth_ETHUSDT_2026-08-02T11.idx.zst` | 8,371 |
| `depth_SOLUSDT_2026-08-02T11.ndjson.zst` | 25,968 |
| `depth_SOLUSDT_2026-08-02T11.idx.zst` | 8,021 |

Read back with `read_pair` — **all 853 frames**:

| stream | frames | `n` contiguous | valid JSON | U/u/pu chained | span | uncompressed → on disk |
|---|---|---|---|---|---|---|
| depth BTCUSDT | 289 | yes | 289/289 | yes | 29.4s | 505,499 → 99,553 B (0.20x) |
| depth ETHUSDT | 289 | yes | 289/289 | yes | 29.5s | 504,165 → 114,587 B (0.23x) |
| depth SOLUSDT | 275 | yes | 275/275 | yes | 29.4s | 145,808 → 25,968 B (0.18x) |

Every entry `kind="data"`, `esc=0`, **no ledger events at all** (no gaps, no malformed,
no unwritable). 1.16 MB of wire text stored in 240 KB.

Re-run on the final code (20s, same symbols): `{"written": 573, "dropped": 0, "control": 0,
"malformed": 0, "unwritable": 0}`, 38,937 / 50,579 / 13,124 raw bytes.

### 3. Byte-exactness: yes, verified two ways

- Live: every stored payload was found in the set of frames teed off the socket
  (`len(unaltered) == len(pairs)`), so what Binance sent is what `read_pair` returns.
- Offline: `test_run_capture_stores_frames_byte_exactly` asserts the stored list is
  `==` the sent list for three frames including non-ASCII, backslashes, quotes and an
  **embedded literal newline** (which exercises the escape/unescape round trip).

### 4. Real SIGINT against `--seconds 0` (not a mock)

Started `python -m capture.cli --venue binance --symbols BTCUSDT --root ... --seconds 0`,
sent `SIGINT` to the process group after 12s:

```
interrupted; captured frames were flushed to disk
exit=130
depth_BTCUSDT_2026-08-02T11.ndjson.zst: 112 frames readable after SIGINT,
    span=11.3s, n contiguous=True
leftover .writing markers: []
```

Data survived the interrupt, the index stayed in step, and no stale `.writing` marker was
left to make a later `reconcile_pair` refuse the hour.

## Finding: three of the four core Binance channels delivered nothing

`core_specs` subscribes to `depth@100ms`, `aggTrade`, `markPrice@1s` and `forceOrder`.
In every live run **only `depth` frames arrived** — no aggTrade, markPrice or forceOrder
file was ever created.

This is not a defect in this task's code. A raw probe with no capture code involved shows
the same, on the same endpoint and connection style:

```
25s on ...streams=btcusdt@aggTrade/btcusdt@markPrice@1s/btcusdt@forceOrder -> {}
20s on ...streams=btcusdt@markPrice                                        -> {}
15s on ...streams=btcusdt@bookTicker            -> {'btcusdt@bookTicker': 3181}
```

`markPrice@1s` is a periodic push that cannot legitimately be silent for 25 seconds, and
`bookTicker` on the same URL form delivers 3,181 frames in 15s — so the transport, the URL
format and the parsing are all fine, and something upstream is simply not delivering those
three channels to this host. It needs to be understood before the core tier is trusted as
"captured", but nothing in Layer 0 can fix it and it is out of scope here.

## Self-review findings (fixed before commit)

- The live test originally asserted `raw.stat().st_size > 0` on the **end** hour only —
  a run finishing microseconds after an hour boundary would blow up on a missing file.
  Now sums the bytes across whichever of the two hours exist.
- M2 killing the suite by hanging → added `finish_within()`; a lost deadline now fails.
- Helper named `capture_run_capture_calls` (noun-ish and duplicated the word "capture")
  → renamed `record_run_capture_calls`; it records, and the name says so.
- `run_capture` returning a hand-built dict would have gone unnoticed → added
  `test_run_capture_returns_the_recorders_own_stats` asserting the exact key set.

## Concerns

1. **The three silent Binance channels above.** Highest-value follow-up.
2. **No reconnection.** A `ConnectionClosed` mid-run propagates out of `run_capture`; the
   recorder's `finally` flushes everything to disk, but the process exits with a traceback
   and non-zero. Acceptable for a bounded smoke test, insufficient for continuous capture.
   Deliberately not built — it is a supervision concern, not a CLI one.
3. **`dropped` is structurally 0.** The live test's `assert stats["dropped"] == 0` is
   vacuous until the bounded queue exists (recorded wiring gap; `VenueRecorder.stats`
   already documents this). It is asserted anyway so the contract does not move later.
4. **The capture window excludes the handshake but not the venue's first-frame latency.**
   `--seconds 30` produced 29.4s of frames; the remainder is startup, TLS and the flush.
5. **Suite runtime rose 0.5s → 2.8s.** The offline tests wait out real 0.25–0.4s
   durations rather than faking the clock; `_stream_frames` takes no clock seam and adding
   one to production code purely for tests did not seem worth it.
6. The three wiring gaps named in the task (universe refusals → ledger, `capture_health`
   caller and `free_bytes` producer, bounded queue) were **not** touched.

---

# Addendum: acting on the silent-channel finding

Commit `97d1a8b` — *fix(binance): capture individual trades, and make a silent stream
visible*. Suite: **218 passed, 1 skipped**; **219 passed** with `CAPTURE_LIVE=1`.

## Fix 1 — `aggTrade` → `trade`

`src/capture/venues/binance.py`: `_CORE_CHANNELS` is now
`["depth@100ms", "trade", "markPrice@1s", "forceOrder"]` and `_TAIL_CHANNELS` is
`["trade", "markPrice@1s", "forceOrder"]`. `_EVENT_TO_STREAM` gained `"trade": "trade"`,
so `ExtractedMeta.stream` still equals the `StreamSpec.stream` that subscribed
(`channel.split("@")[0]`) — the Task 7 consistency property. `aggTrade` stays in the map
though nothing subscribes to it, so an archive captured earlier still routes.

**Real frame used in the test** (captured from the live socket, not invented):

```json
{"stream":"btcusdt@trade","data":{"e":"trade","E":1785671500407,"T":1785671500407,
 "s":"BTCUSDT","t":7947131392,"p":"63105.80","q":"0.030","X":"MARKET","m":true,"st":1}}
```

**`seq` stays `None`.** A trade carries `t` (trade id, e.g. `7947131392`), `E`/`T`
timestamps, and nothing resembling depth's `U`/`u`/`pu` chain — there is no
previous-update pointer to reconcile against. `t` is a per-symbol counter and *could*
support a trade-id-continuity check later, but no tracker reads it today and populating
`seq` with it would assert a contract nothing verifies. The id is in the payload verbatim,
so nothing is lost. Flagged for the spec owner rather than decided here.

Tests added to `tests/test_venues.py`:
`test_binance_captures_individual_trades_not_aggregated_ones` and
`test_binance_trade_frame_routes_to_the_stream_its_spec_named`. The pre-existing
`test_binance_builds_combined_stream_url` asserted `btcusdt@aggTrade` and was updated —
it failed first, which is the evidence the change is real.

## Fix 2 — subscribed-but-silent reaches the ledger

`VenueRecorder` gained `silence_grace_seconds: float = 60.0` and
`_record_silent_streams(now_ns)`. It compares the subscribed specs against
`self._writers` (a stream that produced a frame has a writer) and records, for each stream
that produced none:

```
kind="silent_stream", severity=SEVERITY_OBSERVATION_LOSS,
detail={"symbol": ..., "frames_received": 0, "silent_for_seconds": ...}
```

Design points, each one a test:

- **Grace period.** Every stream is silent at startup; without it, every start writes
  events. The claim made is narrow and exact: *nothing arrived in the first N seconds of
  the session*.
- **Called from the frame loop**, after the frame is routed (so a stream whose first frame
  is the current one is not reported silent in the same breath) — a `--seconds 0` capture
  runs for days and must not learn this at shutdown.
- **Called again from `close()`** — a venue that sent nothing at all never enters the
  frame loop, and that is the worst case, because it leaves no file to notice the absence
  of.
- **Once per stream per session.** Frames keep arriving after the grace expires and
  `close()` runs twice in some paths; an event per frame would drown the ledger.
- **Observation loss, not corrupting.** What was captured is intact; there is less of it
  than was asked for. `capture_health` only buckets non-gap events at `corrupting`
  severity, so these do not disturb its counters.

`consume()` was refactored to make the call site clean: the malformed branch became
`_record_malformed_frame` and the body became `_route_frame`, so the loop is
`try/except/else` + one check rather than a `continue` that would have skipped it.

Not built (deliberately): no new mechanism, no CLI flag, no `stats()` key — the ledger is
the record, and adding a stats key would have moved a contract asserted in Task 11's tests.
A stream that spoke and then stopped is a *different* condition already owned by the
staleness and gap trackers.

## Live re-run with the new channel set — actual numbers

`python -m capture.cli --venue binance --symbols BTCUSDT,ETHUSDT,SOLUSDT --seconds 90`,
11:58:28–12:00:05 UTC:

```
{"written": 10625, "dropped": 0, "control": 0, "malformed": 0, "unwritable": 0}
exit=0
```

All 10,625 frames read back through `read_pair`, every index contiguous, every payload
valid JSON:

| stream | frames | span | uncompressed | on disk |
|---|---|---|---|---|
| depth BTCUSDT | 883 | 90.0s | 1,437,888 B | 285,006 B |
| depth ETHUSDT | 878 | 89.8s | 1,656,267 B | 381,138 B |
| depth SOLUSDT | 832 | 89.9s | 414,027 B | 69,343 B |
| **trade BTCUSDT** | **1,697** | 89.8s | 286,288 B | 13,105 B |
| **trade ETHUSDT** | **5,614** | 89.6s | 940,480 B | 41,649 B |
| **trade SOLUSDT** | **721** | 89.0s | 120,286 B | 6,558 B |
| markPrice ×3 | **0** | — | — | no file |
| forceOrder ×3 | **0** | — | — | no file |

Stored trade payload and its index entry:

```
{"stream":"btcusdt@trade","data":{"e":"trade","E":1785671908693,"T":1785671908693,
 "s":"BTCUSDT","t":7947154547,"p":"62983.90","q":"0.102","X":"MARKET","m":false,"st":1}}
IndexEntry(n=0, t_recv_ns=1785671908763315209, t_exch_ms=1785671908693, seq=None,
           kind='data', esc=False)
```

**And the silence is no longer silent** — `ledger/binance/2026-08-02/events.ndjson`,
6 events, 0 damaged lines:

```
kind=silent_stream severity=observation_loss stream=markPrice
    detail={'frames_received': 0, 'silent_for_seconds': 60.016, 'symbol': 'BTCUSDT'}
kind=silent_stream severity=observation_loss stream=forceOrder   ... 'symbol': 'BTCUSDT'
kind=silent_stream severity=observation_loss stream=markPrice    ... 'symbol': 'ETHUSDT'
kind=silent_stream severity=observation_loss stream=forceOrder   ... 'symbol': 'ETHUSDT'
kind=silent_stream severity=observation_loss stream=markPrice    ... 'symbol': 'SOLUSDT'
kind=silent_stream severity=observation_loss stream=forceOrder   ... 'symbol': 'SOLUSDT'
```

Recorded at 60.016s — mid-run, not at shutdown. `depth` and `trade` produced no events,
because they spoke.

An independent 20s probe with no capture code confirmed the map again on this host:
`ethusdt@trade` 2,621, `btcusdt@trade` 459, `btcusdt@depth@100ms` 196, `solusdt@trade` 57,
`btcusdt@markPrice@1s` **0**, `btcusdt@forceOrder` **0**.

## Mutations — 10 applied, 9 killed, 1 equivalent by design

| # | Mutation | Result |
|---|---|---|
| N1 | No startup grace — flag silence immediately | KILLED |
| N2 | No one-shot guard — re-record on every frame | KILLED |
| N3 | No check at `close()` — total silence unrecorded | KILLED |
| N4 | No check in the frame loop — only at shutdown | KILLED |
| N5 | Also flag streams that did speak | KILLED |
| N6 | `corrupting` instead of `observation_loss` | KILLED |
| N7 | Expected streams keyed without casefolding | KILLED |
| N8 | Revert the core tier to `aggTrade` | KILLED |
| N9 | Route `trade` frames to a stream name no spec uses | KILLED |
| N10 | Drop the explicit `"trade": "trade"` mapping | **SURVIVED — equivalent** |

N10 is a true equivalent mutant, reported rather than papered over: `_EVENT_TO_STREAM.get(
event, event)` already returns `"trade"` for an unmapped `trade` event, so the explicit
entry is documentation, not behaviour. No test can kill it without asserting on the dict
itself, which would test the implementation rather than the routing.

N4's first draft was **not** killed — `close()` caught the same streams, so removing the
in-loop check changed nothing observable. That gap was real (it is the difference between
learning at 60s and learning at shutdown of a multi-day run), so
`test_silence_is_reported_during_the_run_not_only_at_shutdown` was added: it reads the
ledger from inside the frame generator, mid-consume. N4 is killed by that test only.

The Task 11 CLI mutation set (M1–M13) was re-run against the refactored `consume`:
**13 killed, 0 survivors**, unchanged.

## Files changed in this addendum

- `src/capture/venues/binance.py` — channel tiers, `trade` mapping, the measurement note
- `src/capture/venue_recorder.py` — `_record_silent_streams`, `_record_malformed_frame`,
  `_route_frame`, constructor state
- `tests/test_venues.py` — real trade frame, 2 new tests, 1 updated
- `tests/test_venue_recorder.py` — 5 new tests, `clock_advancing_by` helper

## Still unresolved (recorded, not fixed)

1. **Funding and liquidations are not captured at all.** `markPrice@1s` (funding rate,
   mark price) and `forceOrder` (liquidations) deliver nothing over the websocket from
   this host. Sourcing them needs a REST polling path (`/fapi/v1/premiumIndex`,
   `/fapi/v1/forceOrders`) — a spec decision about a second capture mechanism, explicitly
   out of scope here. Until that is decided, the archive has no funding and no liquidation
   record, and now says so in the ledger every session.
2. **Why those websocket streams are silent is unknown.** REST has the data, so it is not
   a venue outage. Worth understanding before trusting any channel on this host.
3. **`silence_grace_seconds` is not reachable from the CLI** (constructor default 60s).
   A capture shorter than the grace records nothing — deliberate, but it means the 15s
   live smoke test cannot exercise this path; the 90s run above is the evidence.
4. The three known wiring gaps and reconnection remain untouched.

---

# Addendum 2: review findings

Commit `a4ced5a` — *fix: detect a stream that dies mid-session, and surface silence in
health*. Suite: **230 passed, 1 skipped**; **232 passed** with `CAPTURE_LIVE=1`
(baseline before this round: 218).

## Finding 1 — a stream that speaks once and then dies

The reviewer was right, and the defect was worse than a missing case: the old check
excluded a stream from the moment it produced one frame, and the docstring claimed the
staleness and gap trackers owned that condition. They did not. `_tracker_for` covered only
Binance `depth` (chain) and Hyperliquid `l2Book` (staleness), so `trade`, `markPrice` and
`forceOrder` had no staleness owner at all — the false comment covered exactly the streams
with no cover.

**The part that changes the design:** attaching a tracker to every stream does not fix it
either. Every tracker here is frame-driven — `check()` runs only when a frame arrives — so
a stream that dies sends nothing for its own tracker to run on. Only the venue clock,
ticking on other streams' frames and again at close, can ask on a dead stream's behalf.
Both halves were therefore needed:

1. **`StalenessTracker` for every stream without a sequence chain** (renamed from
   `HyperliquidStalenessTracker`; it works from `t_recv_ns` alone and now owns Binance
   streams, so the venue-specific name was a name that lies). This gives `trade`,
   `markPrice` and `forceOrder` a late-frame owner they never had.
2. **The silence check now judges every subscribed stream on when it last spoke**, not on
   whether it ever spoke. `_note_stream_spoke` records last-seen, frame count and widest
   gap per stream; `_record_silent_streams` reports any stream quiet beyond its threshold,
   once per stream per session, with `frames_received` distinguishing "never answered"
   from "answered and died".

**Threshold: `max(grace, 3 × the widest gap the stream has actually shown)`**, kept in the
recorder. I did not reuse the tracker's threshold for this, and the evidence is in two
tests rather than an opinion:

- `test_a_stream_slower_than_the_stall_rule_never_learns_a_baseline` — a stream whose
  cadence exceeds `stall_multiple × floor` (180s against a 5s floor: a liquidation feed)
  never acquires a baseline, because the learning rule keeps gaps beyond 3× the threshold
  out of the window and the pre-baseline threshold is only the floor. Its
  `_threshold_ns()` therefore stays pinned at 5s forever. Judging silence by it would
  report a healthy liquidation feed dead every session.
- I tried relaxing that learning rule (learn every gap while there is no baseline) and the
  existing `test_hyperliquid_stalls_do_not_poison_median` **caught it immediately**: six
  genuine 60s stalls during warmup then set the routine ceiling and hid every later stall.
  The rule is right; the reversion is committed with a comment recording the attempt.

So the tracker is not asked a question it cannot answer. The docstrings on both sides now
say exactly that, including the bound on what `StalenessTracker` can claim.

**Not regressing the bursty tuning** (`test_a_healthy_bursty_trade_stream_does_not_alarm`):
300 frames of 40% fast bursts and 60% ~6s cadence produce **9 gap events (3.0%)**, almost
all warmup, and **zero** silent-stream events for `trade`. The earlier round's storm was
57%. Measured, not assumed — I instrumented the run to confirm the tracker was actually
attached (`StalenessTracker` on `trade`) rather than the test passing vacuously.

**One more consequence, found while testing:** a stream too slow to learn a baseline flags
every frame, so with a tracker now attached, `forceOrder` would have written one
observation_loss gap event per frame for the life of the stream. A staleness gap is
therefore recorded only once the tracker `has_baseline()`
(`test_a_stream_too_slow_to_learn_a_cadence_does_not_alarm_on_every_frame`), with the
other half guarded by `test_a_real_stall_on_a_settled_stream_is_still_recorded` — a 600s
hole in a settled 1s stream is still reported.

Also fixed: a stream whose hour is quarantined is still speaking, and must not be reported
dead as well (`test_a_quarantined_stream_is_not_also_reported_dead`).

## Finding 2 — silence reaches the health report

`build_report` now counts `silent_stream` events separately from gaps —
`"silent_streams": 6, "silent_stream_names": ["forceOrder", "markPrice"]` — and
`_build_alerts` raises `silent_streams` carrying the count and the names, banded by order
of magnitude like every other counted alert, so a scheduled report does not repeat it.
Deliberately **not** folded into `gaps["observation_loss"]`, which is the routine bucket
the module never alerts on: a gap is a hole in a working stream, this is a stream that is
not working. The module docstring's "routine observation_loss is never alerted on" now
states the exception rather than being quietly contradicted.

## Also — `--silence-grace-seconds`

One flag, one pass-through, two tests. A run shorter than the grace can never report a
silent stream, which made every short capture look clean; the 15s live smoke test could
not exercise the check at all.

## Live re-run on the final code — actual numbers

`python -m capture.cli --venue binance --symbols BTCUSDT,ETHUSDT,SOLUSDT --seconds 90`,
12:27:31–12:29:11 UTC:

```
{"written": 6241, "dropped": 0, "control": 0, "malformed": 0, "unwritable": 0}
```

| stream | frames | index contiguous | span | on disk |
|---|---|---|---|---|
| depth BTCUSDT | 882 | yes | 89.9s | 246,478 B |
| depth ETHUSDT | 878 | yes | 89.9s | 267,168 B |
| depth SOLUSDT | 828 | yes | 89.9s | 67,775 B |
| trade BTCUSDT | 1,069 | yes | 89.9s | 7,600 B |
| trade ETHUSDT | 2,223 | yes | 88.7s | 15,673 B |
| trade SOLUSDT | 361 | yes | 89.6s | 3,968 B |
| markPrice ×3, forceOrder ×3 | 0 | — | — | no file |

All 6,241 frames read back through `read_pair`. Ledger: 6 events, 0 damaged, all
`silent_stream` at `observation_loss`, recorded at **60.055s** with
`threshold_seconds: 60.0` — and **no new gap events**: attaching a tracker to `trade`
added no noise on a real venue.

Then `build_report` on that same capture, which is the half that was missing before:

```json
{"events_total": 6, "gaps": {"corrupting": 0, "observation_loss": 0, "info": 0},
 "corrupting_non_gap": 0, "silent_streams": 6,
 "silent_stream_names": ["forceOrder", "markPrice"],
 "raw_data_bytes": 608662, "capture_status": "present", "runway_status": "ok"}
```

and `write_alerts` wrote exactly one line:

```json
{"count":6,"date":"2026-08-02","dedup_key":"binance|2026-08-02|silent_streams|0",
 "reason":"silent_streams","streams":["forceOrder","markPrice"],
 "ts":"2026-08-02T12:29:49Z","venue":"binance"}
```

## Mutations — 12 applied, 12 killed, 0 survivors

| # | Mutation | Result |
|---|---|---|
| P1 | No staleness owner for streams without a chain | KILLED |
| P2 | Report staleness before a baseline exists | KILLED |
| P3 | Back to never-spoke only (a dead stream invisible again) | KILLED |
| P4 | Judge every stream by the grace, not its own cadence | KILLED |
| P5 | Drop the grace floor from the threshold | KILLED |
| P6 | Never note that a stream spoke | KILLED |
| P7 | Note liveness only after the quarantine check | KILLED |
| P8 | One silence event for the venue, not per stream | KILLED |
| P9 | Stop counting silent streams in the report | KILLED |
| P10 | Count silent streams but never alert on them | KILLED |
| P11 | Fold silent streams into the routine gap bucket | KILLED |
| P12 | Ignore `--silence-grace-seconds` | KILLED |

The Task 11 CLI set (M1–M13) was re-run against the changed `run_capture`: **13 killed, 0
survivors**. The N-set from addendum 1 is superseded by P1–P8, which mutate the code that
replaced it.

## Files changed

- `src/capture/sequencing.py` — rename, the documented bound on what it can claim, the
  recorded failed experiment on the learning rule
- `src/capture/venue_recorder.py` — `_note_stream_spoke`, rewritten
  `_record_silent_streams`, staleness owner for every stream, baseline gate on staleness
  gap events, corrected docstring
- `src/capture/capture_health.py` — silent streams counted, named and alerted
- `src/capture/cli.py` — `--silence-grace-seconds`
- `tests/` — 14 new tests across `test_sequencing`, `test_venue_recorder`,
  `test_capture_health`, `test_cli_smoke`

## Concerns

1. **A recovered stream is not re-armed.** One event per stream per session: a stream that
   dies, is reported, and comes back will not be reported if it dies again in the same
   session. Chosen against flooding; on a 24/7 recorder that is a real limit.
2. **The silence check runs on frame arrival and at close.** If *every* stream dies at
   once, nothing ticks the venue clock until the run ends — the report then comes at
   shutdown. Catching that needs a timer, which is a supervision concern and was left out.
3. **A capture ending in a natural quiet stretch longer than the grace** records a silent
   stream for a healthy one. `frames_received` distinguishes it, but it is noise.
4. **Warmup staleness gaps are suppressed** by the baseline gate — a genuine stall inside a
   stream's first 10 gaps is not recorded as a gap event. Death is still caught.
5. Unresolved from addendum 1 and unchanged: funding and liquidations are still captured
   by nothing; why those websocket channels are silent while REST serves the same data is
   still unknown.

---

# Addendum 3: re-review findings

Commit `bcc0676` — *fix: a stall must not teach the silence threshold that catches it*.
Suite: **236 passed, 1 skipped**; **237 passed** with `CAPTURE_LIVE=1`.

## The Important finding — confirmed, and worse than a tuning error

The reviewer is right, and it is the Task 6 bug class in a new location: the estimator was
taught by the very stalls it existed to detect. `_note_stream_spoke` folded every gap into
a monotonic `max()` — no cap, no decay, no exclusion — and the threshold was `3 ×` that. A
settled 1s stream taking one genuine 600s stall ended up with an 1800s threshold, so it
could then die for good and 300s of true silence reported nothing. Reproduced exactly as
described, and now a committed test:
`test_a_stall_does_not_teach_the_silence_threshold`.

### The fix, and why it is not exclusion

The obvious fix — "a gap reported as a stall must not teach the threshold" — **does not
work here**, and I have the test to prove it rather than an argument:
`test_a_routinely_slow_stream_still_learns_its_own_cadence`.

On first sight a 200s gap on a 200s-cadence stream is indistinguishable from a 200s stall
on a 1s stream. Any exclusion rule derived from the current threshold (which starts at the
60s grace) throws out the first gap of a slow stream, so the stream never learns anything,
its threshold stays at the grace, and it is reported dead every session. That is the same
false alarm the whole estimator exists to avoid, and it is exactly why `StalenessTracker`
itself cannot answer this question — a stream slower than `stall_multiple × floor` never
acquires a baseline at all.

What actually separates a stall from a slow cadence is **repetition**. So the estimator is
now a **quantile over a bounded window**:

```
routine    = 0.90 quantile of the last 200 frame-to-frame gaps
threshold  = min(1 hour, max(grace, 3 × routine))
```

Every gap is recorded, stalls included. They are not excluded — they are **outvoted**. One
600s stall among 29 1s gaps sits above the 0.90 quantile and moves nothing; 200s gaps that
keep happening *become* the quantile. Each of the three parts is load-bearing and each is
mutation-tested:

| Part | What it prevents | Mutation |
|---|---|---|
| quantile, not max | the stall teaching the threshold | Q1, Q4 |
| bounded window (200) | a stream judged on a cadence it has outgrown | Q3 |
| ceiling (1 hour) | a slow history buying permanent exemption | Q2 |
| floor (the grace) | flagging every stream at startup | Q5 |

The quantile is 0.90 rather than the tracker's 0.99 for a measured reason: with 30 samples
a 0.99 quantile lands on index 29 — the stall itself. Q4 mutates it to 0.99 and the
poisoning test fails again.

**Bounded detection, regardless of history**, is the ceiling's job:
`test_silence_is_reported_within_a_bounded_time_however_slow_the_stream` gives a stream a
3000s cadence and still gets a report, at `threshold_seconds: 3600.0`.

`quantile_ns` is now a shared function in `sequencing.py` used by both `StalenessTracker`
and the recorder, so the two answers to "what does this stream routinely do?" cannot drift
apart.

### A test of mine that was not testing what it claimed

My first aging test (one 150s gap, then 200 × 1s) **passed with an unbounded window** — Q3
survived the first mutation round. The quantile alone already outvotes a lone outlier, so
the test proved nothing about the window. A window only matters when a stream *changes
regime*, so it was replaced with
`test_a_stream_that_speeds_up_is_judged_on_its_recent_cadence`: 250 frames 100s apart then
200 frames 1s apart, where an unbounded history keeps the threshold at 300s and the
bounded one returns it to 60s. Q3 is killed by that test only.

## The two smaller items

1. **`test_a_healthy_bursty_trade_stream_does_not_alarm` was vacuous in isolation** — the
   reviewer is right, and my report's claim that I had instrumented it was true of a
   throwaway script, not of the committed test. That is the gap between "I checked" and
   "the suite checks". It now asserts
   `isinstance(rec._trackers[("trade", "btcusdt")], StalenessTracker)` before the rate
   bound, and I re-ran the reviewer's own mutation (`_tracker_for` returning `None`)
   against the single test: it now **fails in isolation**, where before it passed.
2. **`--silence-grace-seconds` accepts no negative value** (`parser.error`, exit 2), like
   `--seconds`. A negative grace collapses every threshold and reports every stream silent
   on its first check.

## Mutations — 10 applied, 10 killed, 0 survivors

| # | Mutation | Result |
|---|---|---|
| Q1 | High-water mark instead of a quantile | KILLED |
| Q2 | No ceiling | KILLED |
| Q3 | Unbounded window | KILLED (only after the regime-change test; **survived** the first round) |
| Q4 | Quantile at 0.99 | KILLED |
| Q5 | No grace floor | KILLED |
| Q6 | Short-circuit stricter than the threshold it stands in for | KILLED |
| Q7 | Exclude flagged stalls instead of outvoting them | KILLED |
| Q8 | No staleness owner (the vacuous-test check) | KILLED |
| Q9 | Shared quantile helper returns the largest gap | KILLED |
| Q10 | Accept a negative silence grace | KILLED |

Q7 is worth naming: it implements the fix the review suggested, and it is killed by
`test_a_routinely_slow_stream_still_learns_its_own_cadence`. That is the defence for
choosing a quantile over exclusion.

## Live re-run — actual numbers

`--venue binance --symbols BTCUSDT,ETHUSDT,SOLUSDT --seconds 90`, 12:47:51 UTC:

```
{"written": 4263, "dropped": 0, "control": 0, "malformed": 0, "unwritable": 0}
```

| stream | frames | index contiguous | span | on disk |
|---|---|---|---|---|
| depth BTCUSDT / ETHUSDT / SOLUSDT | 882 / 877 / 825 | yes | 89.9s | 169,396 / 185,948 / 62,648 B |
| trade BTCUSDT / ETHUSDT / SOLUSDT | 507 / 775 / 397 | yes | ~89s | 4,144 / 6,720 / 4,219 B |
| markPrice ×3, forceOrder ×3 | 0 | — | — | no file |

All 4,263 frames read back. Ledger: 6 `silent_stream` events at **60.003s** with
`threshold_seconds: 60.0` (the grace floor, as it should be for a stream that never
spoke), 0 damaged lines, and **no gap events** — the new estimator added no live noise.
`build_report` → `silent_streams: 6`, `["forceOrder", "markPrice"]`; one alert written.

## Files changed

- `src/capture/sequencing.py` — `quantile_ns` extracted and shared
- `src/capture/venue_recorder.py` — `_recent_gaps_ns` window, `_silence_threshold_ns`,
  the constants and their rationale, docstrings corrected
- `src/capture/cli.py` — negative `--silence-grace-seconds` refused
- `tests/` — 4 new recorder tests, bursty guard made non-vacuous, CLI guard test

## Concerns

1. **A stream whose stalls are routine (>10% of gaps) still raises its own threshold**, up
   to the one-hour cap. That is deliberate — at that frequency the stalls are the stream's
   behaviour — but it means such a stream is detected later, never beyond an hour.
2. **The ceiling is a judgement call.** One hour bounds detection while leaving room for a
   genuinely sparse liquidation feed; a shorter ceiling would detect death sooner at the
   cost of false alarms on sparse streams, which now raise operator-visible alerts.
3. Carried forward unchanged: a recovered stream is not re-armed within a session; if
   every stream dies at once nothing ticks the venue clock until close; funding and
   liquidations are still captured by nothing, and why those websocket channels are silent
   while REST serves the same data is still unknown.
