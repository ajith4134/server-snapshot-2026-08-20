"""Probe Binance + Hyperliquid websocket frames to verify format assumptions.

Checks the three claims the Layer 0 raw format depends on:
  1. frames arrive as TEXT (not binary/compressed)
  2. each frame is SINGLE-LINE (no embedded newlines) -> NDJSON line alignment is safe
  3. frames carry an exchange timestamp and/or sequence number -> gap detection is possible
"""
import asyncio, json, sys
import websockets


async def probe(name, url, subscribe=None, n=6):
    out = {"venue": name, "frames": 0, "text": 0, "binary": 0,
           "multiline": 0, "max_len": 0, "samples": [], "err": None}
    try:
        async with websockets.connect(url, open_timeout=20, close_timeout=5) as ws:
            if subscribe:
                await ws.send(json.dumps(subscribe))
            for _ in range(n):
                msg = await asyncio.wait_for(ws.recv(), timeout=20)
                out["frames"] += 1
                if isinstance(msg, bytes):
                    out["binary"] += 1
                    continue
                out["text"] += 1
                if "\n" in msg or "\r" in msg:
                    out["multiline"] += 1
                out["max_len"] = max(out["max_len"], len(msg))
                if len(out["samples"]) < 2:
                    out["samples"].append(msg[:400])
    except Exception as e:
        out["err"] = f"{type(e).__name__}: {e}"
    return out


async def main():
    results = await asyncio.gather(
        probe("binance-spot-depth",
              "wss://stream.binance.com:9443/ws/btcusdt@depth@100ms"),
        probe("binance-futures-depth",
              "wss://fstream.binance.com/ws/btcusdt@depth@100ms"),
        probe("hyperliquid",
              "wss://api.hyperliquid.xyz/ws",
              subscribe={"method": "subscribe",
                         "subscription": {"type": "l2Book", "coin": "BTC"}}),
    )
    for r in results:
        print("=" * 70)
        print(f"VENUE: {r['venue']}")
        if r["err"]:
            print(f"  ERROR: {r['err']}")
            continue
        print(f"  frames={r['frames']}  text={r['text']}  binary={r['binary']}  "
              f"multiline={r['multiline']}  max_len={r['max_len']}")
        for s in r["samples"]:
            print(f"  SAMPLE: {s}")
            try:
                d = json.loads(s) if len(s) < 400 else None
                if isinstance(d, dict):
                    print(f"    keys: {sorted(d.keys())[:12]}")
            except Exception:
                pass


asyncio.run(main())
