# Binance withholds part of its USDⓈ-M websocket from this host

**Measured 2026-08-03** from the GCE instance in `asia-south1-c`. Not inferred, not
read in a forum post — every number below came off a socket opened from this box.

## The finding

`fstream.binance.com` accepts a subscription, lists it as active, and then sends nothing
— for a specific subset of streams, while others on the *same connection* flow normally.

| Stream | Frames | Window |
|---|---:|---|
| `btcusdt@trade` (control) | **2001** | 35 s |
| `btcusdt@depth@100ms` (control) | flowing | — |
| `btcusdt@markPrice@1s` | **0** | 35 s |
| `!markPrice@arr@1s` | **0** | 35 s |
| `btcusdt@forceOrder` | **0** | 35 s |
| `!forceOrder@arr` | **0** | 35 s |
| `btcusd_perp@markPrice@1s` (COIN-M) | **25** | 25 s |
| `btcusdt@aggTrade` (spot) | **63** | 25 s |

`!markPrice@arr@1s` is the one that settles it. Binance guarantees that stream at 1 Hz —
it is not event-driven, so "the market was quiet" cannot explain zero. And COIN-M served
the *identical stream type* to the same host in the same minute.

## What it is not

**Not a wrong stream name.** Checked against Binance's own connector source
(`binance-futures-connector-python`, `websocket/um_futures/websocket_client.py`), which
documents `<symbol>@markPrice@1s`, `!markPrice@arr@1s`, `<symbol>@forceOrder`. Ours matched
exactly. Rule 5 applies here: the names were verified from source, not from memory.

**Not a bad edge node.** Six connections landed on three distinct edge IPs
(`13.231.11.129`, `57.181.1.119`, `54.248.131.63`). All six: `trade` flowed, `markPrice`
silent. Identical behaviour.

**Not a middlebox.** In the combined-stream test, `trade` and `markPrice` shared one TLS
connection; `trade` delivered 1926 frames and `markPrice` zero. Nothing between here and
Binance can selectively drop streams inside a TLS session without breaking it. The
filtering is server-side.

**Not the venue lacking the data.** REST returns it: `/fapi/v1/premiumIndex` → 200 with
live mark, index and settlement prices; `/fapi/v1/aggTrades` → 200 with trades.

## The trap that cost the most time

**A subscribe acknowledgement from this endpoint means nothing.**

```
SUBSCRIBE btcusdt@thisIsNotAStream   ->  {"result": null, "id": 4}
LIST_SUBSCRIPTIONS                   ->  [..., "btcusdt@thisIsNotAStream"]
```

A deliberately fabricated stream name was accepted and then listed as an active
subscription. So the venue does not validate stream names at all, and **silence is the
only symptom a typo and a withheld stream have** — they are indistinguishable from the
client side. Any future "we subscribed successfully" claim about this venue is worthless
as evidence; only frame counts are evidence.

This is also why the original defect stayed invisible: the capture service subscribed,
the venue said nothing was wrong, and three feeds were simply never recorded.

## What was done about it

- **Mark price / index / funding** — recovered by polling `/fapi/v1/premiumIndex` at 1 Hz
  per symbol (`capture.rest_poller`). Request weight 1 per symbol; three symbols spend
  180/min against a 2400/min budget. One body carries mark, index and settlement price
  *plus* `lastFundingRate` and `nextFundingTime`, which answers two P0 catalogue rows.
  Written verbatim under the stream name `premiumIndex` — never re-labelled as
  `markPrice`, because the payload shape differs and one filename holding two shapes
  cannot be decoded later without knowing which day produced which.
- **`markPrice` unsubscribed.** Keeping it would report the stream silent forever and
  bury the source that works.
- **`forceOrder` deliberately kept subscribed.** It is equally silent, but
  `allForceOrders` was withdrawn from the public REST API, so there is no replacement to
  move it to. An idle subscription costs nothing and is the only way this system would
  notice the venue starting to deliver liquidations. **Until then the liquidation feed is
  genuinely unavailable and its tile is genuinely red** — see Rule 8: a feed that does not
  exist must not render as anything else.

## Open

Root cause on Binance's side is unknown and not knowable from here. The instance is in
Mumbai (`asia-south1`) and Binance applies regional restrictions, but that is a hypothesis
this box cannot test — REST works fine from the same IP, which argues against a blanket
geo-block. **If liquidations or a pushed mark price are ever needed, the test is one
`!markPrice@arr@1s` probe: 35 frames in 35 s means it came back.**
