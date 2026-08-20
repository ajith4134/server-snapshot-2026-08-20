# Data Storage for a Solo-Built Crypto Trading System

Researched: 2026-08-01, by Sonnet 5 subagent (three parallel web-research sweeps), live web search/fetch.
Part of a 6-agent parallel sweep on ML infra + operational discipline for a solo autonomous crypto trading system.

---

## 1. Storage Formats

**Parquet vs Arrow/Feather — VERIFIED.** Different problems, not competitors. Parquet = compressed, columnar, on-disk archival format. Arrow IPC/Feather = in-memory/zero-copy interchange format — Arrow's own docs call Arrow "an ideal in-memory transport layer for data that is being read or written with Parquet files." A reproduced benchmark found Feather-uncompressed 9x larger on disk than Parquet+zstd despite fastest to open. **Verdict: Parquet for the archival tick store. Don't use Feather for anything you intend to keep.**

**Custom binary formats — VERIFIED, a trap to avoid.** Real benchmarks (`ticksio`, "Shinoji Research" blog) show custom delta-encoded binary formats can beat Parquet 2-10x on bytes/tick and throughput. But Shinoji Research built one, got it working, and **chose TimescaleDB over their own faster format** because engineering/maintenance cost wasn't worth it. A NautilusTrader GitHub RFC (issue #3843) proposing a custom format was talked down by the maintainer — Nautilus's Parquet catalog already runs a Rust/DataFusion streaming engine (not naive full-file reads); the custom-format benefit narrowed to a niche (RAM-resident parameter-sweep replay). **Verdict: do not build a custom binary format** — the clearest "don't bother" in this report.

**Partitioning — VERIFIED, no single universal scheme.**
- **NautilusTrader**: `catalog/data/{data_type}/{instrument_id}/{start_ts}_{end_ts}.parquet` — files named by their own timestamp range, disjoint-interval writes enforced, default row-group 5,000 rows. Measured: ~15.2 bytes/tick.
- Other real quant repos (`geminik23/quant-system`, `cryptostore`) use Hive-style `exchange=/symbol=/date.parquet`.
- **Real production cautionary tale (GitHub issue)**: `cryptostore` had a bug where omitting `symbol` from the partition key silently mixed multiple symbols' data in one file. **Always partition explicitly by symbol.**
- File-size target: 128MB-1GB per Parquet file (general data-eng consensus, not crypto-specific). Given volumes in §3 (1-5 GB/day for the whole system), daily-per-symbol partitioning will likely produce sub-target files — plan to batch/compact (weekly/monthly, or consolidate low-volume symbols).

**Compression codec — VERIFIED across multiple sources.** PyArrow/DuckDB default to Snappy; Polars defaults to ZSTD level 3. Benchmark (benschmidt.org): zstd-1 is worse than snappy; zstd-5+ beats snappy and roughly matches gzip. Consensus: zstd is fast enough for hot paths and compresses meaningfully better than snappy; gzip is slow, only worth it for cold archives. **Verdict: ZSTD (level ~5-9) for the archival tick store.**

**kdb+ accessibility — VERIFIED, a genuinely new fact as of late 2025.** Commercial pricing unchanged: AWS Marketplace, kdb Insights Base Platform $70,000/12 months, Enterprise $76,800/12 months. **New**: KX launched **KDB-X Community Edition** (GA Nov 19, 2025) — free, resource-capped, commercial-use-permitted, though install docs show a license banner reading `EXPIRE 2026.12.31`, contradicting "no expiry" marketing — unresolved discrepancy, verify directly with KX before relying on it. Learning curve: q is a genuine APL-lineage array language (terse, right-to-left evaluation, no operator precedence); official docs concede it "can be disconcerting"; typical path is institutional grad-program training. No credible "N weeks to proficiency" figure exists. **Verdict: commercial tier still out of reach; free Community Edition worth a spike but skip kdb+ for a first build** — Parquet+DuckDB gets 90% of the value with zero new language.

**NautilusTrader's data catalog — VERIFIED, relevant if adopted as engine.** `ParquetDataCatalog`: PyArrow + fsspec (local/S3/GCS/Azure), Rust/DataFusion streaming backend for core market-data types (OrderBookDelta, QuoteTick, TradeTick, Bar). Same store used for backtesting and live persistence. **Verdict: if using NautilusTrader, target `ParquetDataCatalog.write_data()` directly — don't build a parallel Parquet layer.**

---

## 2. Time-Series Databases

**Current versions (VERIFIED, Aug 2026)**: ClickHouse 26.7 (monthly)/26.3.17-lts; TimescaleDB 2.29.0 (2026-07-28, drops PostgreSQL 15 support); QuestDB 9.4.3.

**ASOF JOIN support — VERIFIED, the decisive differentiator for backtesting:**

| DB | Native ASOF JOIN |
|---|---|
| ClickHouse | Yes — `ASOF JOIN`/`ASOF LEFT JOIN` |
| QuestDB | Yes, most full-featured — `ASOF JOIN`, `LT JOIN`, `SPLICE JOIN`, plus `TOLERANCE` clause bounding match staleness |
| TimescaleDB | **No.** Timescale's own blog: Postgres "does not provide a built-in ASOF keyword." Workaround = `LATERAL JOIN` subquery. Real GitHub issue documents a **10x regression** (90s vs 9s) on hypertables from this workaround; Timescale engineer confirmed no easy fix; reporting user abandoned hypertables for that application. |

**Compression — VERIFIED**: ClickHouse and TimescaleDB compress by default (ClickHouse native codecs incl. zstd/delta/gorilla, 2.7-4.2x on non-crypto benchmarks; TimescaleDB columnstore claims 10-20x but is TSL-licensed, not Apache 2.0 — free to self-host internally, not truly open-source). **QuestDB has no compression by default** — requires ZFS filesystem compression or converting old partitions to Parquet (beta, ~9.2.0), a real operational task to remember.

**Operational complexity, single VM, solo operator — each has a documented footgun:**
- **ClickHouse**: real incident on a 2GB VPS — internal system logs generated 11M background-merge rows/30s, 98.8% of I/O was ClickHouse "narrating its own internals," default `mark_cache_size` alone exceeded container memory. Canonical failure: "Too many parts" (error 252) from per-tick inserts instead of batching. Needs active tuning on a small VM.
- **QuestDB**: requires kernel tuning before production (`vm.max_map_count`, open-file limits — Ubuntu/RHEL/Debian defaults too low). WAL tables can become "suspended" under memory/disk pressure, needing manual recovery. GitHub issue shows 180-337GB RAM usage and data loss with 800+ tables under sustained load (per-column write-buffer allocation).
- **TimescaleDB**: gentlest curve (it's just Postgres). But `pg_upgrade` across major versions has real GitHub issues hanging/failing from extension interactions — a maintenance burden unique to being a Postgres extension. TimescaleDB 2.29 just dropped PG15 support, forcing exactly this kind of upgrade event.

**Is a TSDB even necessary? — VERIFIED, strong convergent evidence.** Multiple 2024 HN threads: quant practitioners moving off kdb+ to Python+DuckDB+Polars-on-Parquet, citing DuckDB's vectorized engine as subjectively rivaling kdb+ at zero infra cost. A real solo GitHub project pulls complete Coinbase trade history (~166GB compressed Parquet) into DuckDB with no TSDB. Recurring caveat: Parquet is bad for workloads needing frequent updates/late-arriving corrections — fine for immutable raw tick history, not for retroactive correction.

The real dividing line is **not data volume, it's live 24/7 ingestion that must stay immediately queryable while being written** — dedup on reconnect, late-packet handling, backfill-vs-live overlap, idempotency are the genuinely hard problems flat files don't solve for free. One real solo project (`nestor`) runs a full TSDB-based continuous multi-exchange ingestion pipeline on a **$15-20/month VPS** — proving this doesn't require a large box.

**Verdict**: a dedicated TSDB is premature for backtesting/research; worth adding only for live-ingestion, and even then not first.
1. Start with **Parquet + DuckDB/Polars** for everything — historical storage, backtesting, research. Near-zero ops burden, embedded, no server/upgrade treadmill.
2. For the live/hot path, you need *something* stateful for dedup/backpressure/gap-recovery — but this can start as a well-tested ingestion script writing directly to Parquet with your own idempotency keys, not necessarily a TSDB. Reach for a TSDB only after hitting a concrete pain point.
3. **If/when you add a TSDB**, given you need ASOF JOIN and are running solo with no ops team: **ClickHouse or QuestDB, not TimescaleDB.** TimescaleDB's lack of native ASOF JOIN plus the documented LATERAL-join pathology undercuts its main value here, despite the friendliest ops model. Between the two: QuestDB's `TOLERANCE`-bounded ASOF JOIN is purpose-built for trade/quote alignment and its ops model is simpler than ClickHouse's MergeTree tuning — lean QuestDB, but confirm WAL-suspension/per-column-buffer-memory gotchas are manageable for your table count first.

---

## 3. Realistic Volume and Cost

**Binance update frequency — VERIFIED (official docs).** Trade stream: real-time, no batching. L2 diff-depth: 100ms interval confirmed available (`@depth@100ms` suffix; default is 1000ms). Real BTCUSDT trade counts from `data.binance.vision`: ~59 trades/sec on spot for one verified 24h window (Jan 2025) — for one of the most liquid pairs; a 10-30 pair mix will be far lower on average for most pairs.

**Message sizes — ESTIMATE**, constructed from verified schema fields: trade event ≈134 bytes JSON; L2 diff (~2 levels) ≈160-190 bytes; 50-level snapshot ≈~3.2KB.

**GB/day derivation — ESTIMATE, cross-checked against one real project.** Blended 10 trades/sec/pair assumption across trades + 100ms L2 diffs + periodic 50-level snapshot resync:
- ~276 MB/day/pair raw → 2.76 GB/day (10 pairs) to 8.28 GB/day (30 pairs) raw
- After 5-10x Parquet+zstd compression: ~0.3-0.6 GB/day (10 pairs) to ~0.8-1.7 GB/day (30 pairs)
- Cross-check (real GitHub project, order-book-only, 50 symbols, Parquet+ZSTD-9): ~5-7.5 GB/day total, ~2-3x higher than the bottom-up estimate scaled proportionally — suggesting the bottom-up number is conservative/low.
- **Recommended planning range: 1-3 GB/day** for 10-30 pairs, trades+L2(20-50 levels), compressed Parquet. (Tardis.dev's published 15+ TB/day is for the entire market, 200,000+ instruments — not a per-pair comparison.)

**Cloud storage pricing — VERIFIED, current Aug 2026, cross-checked 3+ sources:**

| Storage class | Price | Source |
|---|---|---|
| AWS S3 Standard | $0.023/GB-month | AWS pricing, corroborated by CloudZero/Filebase/Nubbo |
| AWS S3 Glacier Instant Retrieval | $0.004/GB-month | Same |
| AWS S3 Glacier Deep Archive | $0.00099/GB-month | Same |
| AWS EBS gp3 | $0.08/GB-month | AWS EBS pricing |
| Hetzner Cloud Volumes | ~€0.057/GB-month (~$0.066) | Post-April-2026 increase (was €0.044) |

**1-year cost, using 2 GB/day central estimate (730GB after 1 year, accrued gradually, annual ≈ 6.5x steady-state monthly rate):**

| Storage class | 1-year cost |
|---|---|
| S3 Glacier Instant Retrieval | ~$19 |
| S3 Standard | ~$109 |
| Hetzner Volume | ~$311 |
| AWS EBS gp3 | ~$380 |

**Verdict: storage cost is a rounding error regardless of tier — even the most expensive option is under $400/year.** Don't spend engineering time optimizing storage tier/compression for cost; optimize for query convenience. Reasonable lifecycle: local NVMe (often bundled free with VM plan) for live/working data, S3 Standard for a few months of fast reprocessing access, then Glacier for the long tail — natural given the ~20x price spread, not worth over-engineering. Not priced: S3 request/egress costs — immaterial at these volumes but exist if query patterns change.

---

## Summary of Direct Verdicts

- **Parquet**: use it. Don't build a custom binary format.
- **Compression**: ZSTD, not Snappy or Gzip, for the archival store.
- **Partitioning**: symbol-explicit, target ≥128MB files, expect to batch/compact given low daily volume.
- **kdb+**: free Community Edition exists now (worth a spike), commercial tier still $70k+/year, real language learning curve — skip for a first build.
- **TSDB**: premature at stated scale. Start with Parquet + DuckDB/Polars for everything. Add a TSDB only when live-ingestion correctness (not query speed, not storage volume) becomes a felt problem — and then ClickHouse or QuestDB over TimescaleDB (ASOF JOIN).
- **Volume**: 1-3 GB/day compressed is a reasonable planning estimate for 10-30 pairs, full tick + L2 top-20-50. This is an ESTIMATE, not a verified industry figure.
- **Cost**: under $400/year for 1 year of retention on any storage tier. Not worth optimizing.
