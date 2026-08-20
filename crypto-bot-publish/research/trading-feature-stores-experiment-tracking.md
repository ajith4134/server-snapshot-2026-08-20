# Feature Stores, PIT Correctness, and Experiment Tracking for a Solo Crypto Trading System

Researched: 2026-08-01, by Sonnet 5 subagent, live docs/source/PyPI/GitHub fetches.
Part of a 6-agent parallel sweep on ML infra + operational discipline for a solo autonomous crypto trading system.

---

## Question 1: Feature stores and point-in-time correctness

### How PIT joins mechanically prevent leakage

Two operative timestamps in practice (Feast specifically):
- **event_timestamp**: when the fact occurred in the world (trade print, candle close).
- **created_timestamp**: when the record was actually written/became knowable to your system.

A model must only see, for a training row dated `T`, feature values whose `created_timestamp <= T` — not merely `event_timestamp <= T`. Restated data, late-arriving fills, revised on-chain/fundamentals data, or a batch job that computes "yesterday's" feature 24h late all have an early `event_timestamp` but a late `created_timestamp`. VERIFIED as the correct framing — confirmed against Qlib PIT docs, BagelQuant PIT writeup, and Feast's own source.

**Feast's `get_historical_features()` mechanics — VERIFIED against source** (`feast-dev/feast` master, checked 2026-08-01):
1. Merge feature rows onto `entity_df` on join keys.
2. TTL filter: keep a row only if `timestamp_field <= entity_event_timestamp`, and (if TTL is set) `>= entity_event_timestamp - ttl`. TTL=0/unset ⇒ unbounded lookback.
3. Optional `_apply_created_timestamp_cutoff`.
4. Dedup: sort by `created_timestamp_column` (if declared) then `event_timestamp`, `drop_duplicates(keep="last")` per (join_keys + entity_event_timestamp) — **`created_timestamp` is only a tie-breaker for same-`event_timestamp` rows by default, not an as-of cutoff.**

**Load-bearing finding**: `get_historical_features()` has `filter_by_created_timestamp: bool = False`. Docstring: *"If True, exclude feature values whose created timestamp is later than the entity row's event timestamp, so retrieval only reflects what was known at the event time and backfilled values cannot leak into training data... Defaults to False."* **Feast's leakage protection against restated/late-arriving data is off by default** — you must explicitly populate `created_timestamp_column` on the source AND pass `filter_by_created_timestamp=True`, or you get exactly the leakage bug the tool is supposedly built to prevent. VERIFIED, direct source quote.

TTL/staleness: VERIFIED via docstring — short TTL results in NULLs, not silent leakage or an error.

### Feast architecture — VERIFIED (PyPI/GitHub, checked 2026-08-01)

Current version **0.65.0** (2026-07-20). Three core components + one optional:
- **Offline store**: core/maintainer-supported = Dask (Parquet/file), BigQuery, Snowflake, Redshift. Community-contributed (not guaranteed stable) = PostgreSQL, Spark, Trino, Ray.
- **Online store**: core = SQLite, Redis, DynamoDB, Snowflake, Datastore. Community = PostgreSQL, HBase, Cassandra/AstraDB, Milvus.
- **Registry**: default = local-disk or S3/GCS protobuf file, no DB server required; alternative = SQL-based registry via SQLAlchemy DB.
- **Feature server** (optional): stateless FastAPI/Go REST/gRPC process, only needed for network-callable low-latency lookups by other services.

Minimum footprint: zero extra services (local file registry + Dask/Parquet offline + SQLite online, in-process). Real production topology per Feast's own docs: Redis(-Cluster) online store + SQL-backed Postgres registry (file registry "does not support concurrent writers") + separate feature-server process + materialization CronJobs — 3-5 always-on services, built for many models/services sharing computation.

**Is Feast right for tick/orderbook time-series?** VERIFIED, not just impression:
- Open GitHub issue `feast-dev/feast#6307`: `materialize()`/`materialize_incremental()` load the entire requested range into memory with no chunking; reporter hit OOM on 8GB workers with "sub-minute sensor data" — proposed chunking fix (`#6277`) not yet default.
- Feast's own docs: *"Feast today primarily addresses timestamped structured data"* and *"Feast does not have native streaming integrations."*
- TTL filter is a row-scan/mask, not a time-indexed range query — no CEP/windowing engine.
- No direct maintainer quote saying "not for tick data" was found (inference, not a doc quote) — but the OOM evidence, batch-only materialization, and absence of streaming/CEP support all point the same direction.

### Alternatives — ruled out, not compared in depth

- **Tecton**: acquired by Databricks (2025); no longer independent. Historically targeted recommenders/fraud/ad-tech, never trading.
- **Hopsworks**: still active. Targets fraud/AML, churn, customer-360, credit scoring — retail-banking-shaped, not trading-signal generation.
- **Featureform**: acquired by Redis, rebranded "Redis Feature Store." No financial/trading marketing before or after.
- Even **Binance's own** production feature store (AWS SageMaker Feature Store) is for account-takeover fraud detection, not trading signals.

### VERDICT: Don't bother with a feature store at $100k-1M solo scale

A feature store solves training-serving skew across multiple consumers and institutional discipline across multiple people. A solo trader retraining on a schedule has neither problem. Feast's leakage guard is just a `merge_asof`-shaped function wrapped in infrastructure you'd otherwise have to run and maintain.

**Concrete alternative, ~80% of the benefit, no daemons:**

1. Every table carries `event_time` and `ingestion_time` (add `availability_time` if a feed has publish lag distinct from ingestion).
2. Parquet partitioned by `date`/`symbol`, sorted ascending by `event_time` within each file.
3. The join — VERIFIED exact signatures:
   - `pandas.merge_asof(left, right, on=None, left_on=None, right_on=None, by=None, tolerance=None, allow_exact_matches=True, direction='backward')`
   - `polars.DataFrame.join_asof(other, left_on=None, right_on=None, on=None, by_left=None, by_right=None, by=None, strategy='backward', tolerance=None, ...)`

   Join features onto decision points using `left_on="decision_time", right_on="availability_time"` (not `event_time`), `direction="backward"`, and set `tolerance` to your max acceptable staleness.
4. Real precedents: Microsoft's **Qlib** stores fundamentals as `(date, period, value, _next)` where `date` is publication date (Qlib PIT docs). SSB's `ssb-timeseries` uses immutable snapshot naming `as_of_<ISO8601timestamp>`. BagelQuant's PIT database blog demonstrates `event_date`/`announce_date`/`pdate`, `start_date = max(announce_date, pdate)`, joined with `pd.merge_asof(..., direction="backward")`.
5. Practical recipe: one Parquet lake, one shared `pit_join(labels_df, features_df, tolerance)` wrapper module, unit-tested against synthetic leakage cases. That module *is* your feature store — a few hundred lines, git-diffable, no Redis, no registry service.

**When this flips**: multiple people retraining/serving concurrently; sub-second online lookups served to many independent downstream services; feature recomputation cost (not leakage risk) becomes the bottleneck; team/regulatory governance requires multi-contributor audit trail. None apply to one engineer running scheduled retrains.

---

## Question 2: Experiment tracking and model registry

### MLflow — VERIFIED, current version **3.15.0** (PyPI upload 2026-07-31)

- **Model Registry stages deprecated**: *"As of MLflow 2.9.0, Model Stages have been deprecated and will be removed in a future major release."* Current pattern is aliases + tags:
  ```python
  from mlflow import MlflowClient
  client = MlflowClient()
  mlflow.register_model(model_uri="<uri>", name="<name>")
  client.set_registered_model_alias("example-model", "champion", 1)
  client.get_model_version_by_alias("example-model", "champion")
  client.set_model_version_tag("example-model", "1", "validation_status", "approved")
  ```
  Load by alias: `models:/MyModel@champion`.
- **Backend store** (`--backend-store-uri`): file path, or SQLAlchemy dialects (sqlite, postgresql, mysql, mssql). **SQLite is now the documented default** for bare `mlflow server`.
- No numeric SQLite concurrency ceiling is published by MLflow — docs only say generically to consider Postgres/MySQL "for production deployments with high concurrency."
- **`--default-artifact-root`**: local filesystem (default), S3, Azure Blob, GCS, Backblaze B2, FTP, SFTP, NFS, HDFS.
- Solo/local: `mlflow server --backend-store-uri sqlite:///mlflow.db --default-artifact-root ./mlartifacts`
- Scale-up: `mlflow server --backend-store-uri postgresql://user:pass@host:port/db --default-artifact-root s3://mlflow-artifacts`
- `log_params`/`log_metrics` → backend store; `log_artifacts` → artifact store (physically separate).
- No server process required for basic logging (`mlflow.set_tracking_uri("file:///path")` works purely locally). **Model Registry requires a database-backed store** — confirmed twice in docs. Plain file store doesn't support the registry; SQLite qualifies.
- MLflow's own doc tier explicitly labeled **"Solo development"** = local file store or local SQLite, `mlflow server` run only on-demand — not a permanent daemon. Remote-server + Postgres + S3 tier explicitly labeled **"Team development."**

### DVC — VERIFIED, current version **3.67.1** (release date ambiguous between PyPI/GitHub — flagged UNVERIFIED, re-check before relying)

- `.dvc` files: small YAML pointers (`path`, `md5`, `size`, `nfiles`) committed to git; bytes live content-addressed in `.dvc/cache`.
- Link strategy: reflink first (Btrfs/XFS/OCFS2/APFS), falls back to copy; hardlink/symlink opt-in.
- `dvc.yaml` declares pipeline stages (`cmd`, `deps`, `outs`, `params`); `dvc.lock` records resolved hashes. `dvc repro` re-runs only stages whose inputs changed.
- Remotes: S3, GCS, Azure Blob, Google Drive, Aliyun OSS, SSH/SFTP, HDFS/WebHDFS, HTTP(S), WebDAV, local.
- Solves something MLflow doesn't: MLflow tracks *runs*; DVC ties a *data snapshot* to a git commit via content hash. Compose them: `dvc add`/`dvc push` raw data, commit `.dvc` pointer, log the DVC hash as an MLflow tag per run.

### Weights & Biases — VERIFIED

- Free tier: 5GB storage/month, up to 5 seats — **"corporate use is not allowed"** (personal-development license only; ambiguous/risky for someone trading real capital through an entity). Paid Pro starts at $60/month.
- Artifacts lineage: `wandb.Artifact()`, `run.log_artifact()`, `run.use_artifact()` chain into a traversable DAG.
- Offline mode (`WANDB_MODE=offline`) exists but loses the hosted-dashboard value prop until `wandb sync`. Self-hosted "W&B Server" requires a license — UNVERIFIED whether individuals can self-serve vs. enterprise sales gate.

### VERDICT and recommendation

**Skip W&B entirely.** Backtest results/feature importances/hyperparameters are your edge — the free tier's "no corporate use" clause is a real compliance ambiguity, self-hosting isn't confirmed self-serve, and team-collaboration features solve a coordination problem a team of one doesn't have.

**Use MLflow, self-hosted, no permanent server initially.**
```bash
export MLFLOW_TRACKING_URI=sqlite:///mlflow.db
```
```python
import mlflow
mlflow.log_params({...}); mlflow.log_metrics({...}); mlflow.log_artifacts("path/to/dir")
```
When you want the UI/registry (SQLite qualifies as the DB backend):
```bash
mlflow server --backend-store-uri sqlite:///mlflow.db --default-artifact-root ./mlartifacts --host 127.0.0.1
```
Run on-demand, bound to localhost, not a 24/7 daemon. Promote via aliases, not deprecated stages.

**Move backend store to Postgres** only when you introduce genuinely concurrent writers to the same tracking store (parallel backtest/training workers) — not before. Postgres can still run locally on the same VM.

**Add DVC later, not now** — once you have a raw-data pipeline whose inputs genuinely change over time and "did this backtest run against stale/different data" becomes a real risk you've hit.

---

## Flagged for re-verification before building on this

- DVC 3.67.1 release date: PyPI/GitHub disagreed by exactly one year in the sub-agent's fetch — re-check both directly.
- W&B Self-Managed licensing for individuals: product exists and requires a license; unconfirmed whether individuals can obtain one without enterprise sales.
- W&B offline-mode exact feature loss: mode exists; precise dashboard/collaboration feature diff not doc-quoted, only inferred.
- Feast tick/orderbook unsuitability: strongly evidenced (OOM issue, no streaming/CEP, "timestamped structured data" doc language) but no direct maintainer quote — well-supported inference, not verbatim claim.
- SQLite concurrency ceiling for MLflow: no specific number in MLflow's docs; any numeric claim is general SQLite knowledge, not MLflow-documented.
