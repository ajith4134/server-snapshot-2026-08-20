# Binance fstream — measured connection limits for universe-wide capture

**Measured 2026-08-08 from this host** against the live venue. Not recalled, not taken from a
summariser. Supersedes any assumption based on Binance's spot documentation.

## Why this was measured

Goal doc §10.3: the broad tail is built (`tail_specs()` on both venues, tested) and wired to nothing.
Wiring it requires knowing how many streams one connection can carry, and the documented figure turns
out to be the wrong constraint.

## The universe

| Fact | Value |
|---|---|
| Binance USDⓈ-M `TRADING` + `PERPETUAL` symbols | **569** |
| Tail channels per symbol (`trade`, `forceOrder`) | 2 |
| **Streams needed for the full tail** | **1,138** |

## What the documentation says — and why it does not apply

From `binance/binance-spot-api-docs/web-socket-streams.md`, fetched raw:

- A single connection can listen to a maximum of **1024 streams**.
- Limit of **300 connections per attempt every 5 minutes per IP**.
- **5 incoming messages per second** per connection.
- A single connection to `stream.binance.com` is valid for **24 hours only** — expect a disconnect at
  the 24-hour mark.

Those are **spot** (`stream.binance.com`). Capture uses **`fstream.binance.com`** — USDⓈ-M futures.

## What was measured on fstream

| Streams | URL length | Result |
|---|---|---|
| 200 | 3,634 | OK, frames flowing |
| 512 | 9,048 | OK, frames flowing |
| 768 | 13,514 | OK |
| 896 | 15,766 | OK |
| **928** | **16,338** | **OK — highest confirmed** |
| 960 | 16,886 | **HTTP 414** |
| 1024 | 17,990 | **HTTP 414** |
| 1138 (full tail) | 19,935 | **HTTP 414** |

> ### The binding constraint on fstream is URL length, not stream count.
>
> The documented 1,024-stream cap is **unreachable via the URL form** — the request line exceeds the
> server's limit first and it answers `414 URI Too Long`. The ceiling sits between 16,338 and 16,886
> characters, consistent with a 16 KiB request-line limit.

## The SUBSCRIBE-over-socket alternative does not work here

Spot supports connecting to a bare stream endpoint and sending `{"method":"SUBSCRIBE","params":[…]}`
over the socket, which sidesteps the URL entirely. Tested against fstream, batching 200 channels per
message with 0.4 s spacing (well inside the 5 msg/s limit):

```
FAIL ConnectionClosedError: received 1008 (policy violation) Invalid request;
                            then sent 1008 (policy violation) Invalid request
```

**fstream rejects it.** The URL form is the only subscription path available, so the URL-length
ceiling is a hard constraint rather than one that can be designed around.

## Consequences for the design

1. **The tail must shard across connections.** 1,138 streams cannot be one socket. At a conservative
   **512 streams per shard** — roughly half the measured ceiling, leaving headroom for longer symbol
   names as the universe changes — the current tail needs **3 connections** per venue.
2. **Shard by measured URL length, not by symbol count.** Symbol names vary in length and the
   universe changes daily; a shard sized in symbols will silently cross 414 the day a batch of
   long-named tokens lists. Build the URL and cut it at a byte budget.
3. **A 414 must be loud.** It is a startup failure that looks like nothing — no frames, no error in
   the ledger unless it is caught and recorded. It belongs in the capture ledger as its own event.
4. **300 connections per 5 min per IP** is not a concern at 3–6 shards, but a reconnect storm across
   shards could approach it. The existing full-jitter backoff already covers this; the shard count
   must be counted against that budget rather than assumed free.
5. **The 24-hour connection life is documented for spot and unverified for fstream.** The supervisor
   already restarts, so this is survivable either way — but it is untested here and should not be
   assumed absent.

## UNVERIFIED

- The 24-hour connection lifetime, the 1,024-stream cap, the 300-connections-per-5-minutes figure and
  the 5-messages-per-second limit are all **documented for spot** and were not confirmed for fstream.
  Only the URL-length ceiling and the SUBSCRIBE rejection were measured on fstream directly.
- The exact URL-length limit was bisected to within 548 characters (16,338 OK / 16,886 fail). The
  16 KiB inference is consistent with the data but was not confirmed against a Binance statement.
- Hyperliquid was not probed. Its subscription model differs — it sends subscribe messages over the
  socket rather than encoding them in the URL — so none of the above transfers to it.
