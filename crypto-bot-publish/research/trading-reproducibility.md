# Reproducibility in a Solo-Operator Crypto Trading/ML System

Researched: 2026-08-01, by Sonnet 5 subagent, live doc fetches (WebSearch quota exhausted mid-task; some fetches blocked/redirected — flagged inline).
Part of a 6-agent parallel sweep on ML infra + operational discipline for a solo autonomous crypto trading system.

Scope: single Linux VM, Python-based stack (NautilusTrader as candidate engine), one operator, real capital.

---

## 1. Seeding

| Component | What to set | Notes |
|---|---|---|
| Python `random` | `random.seed(N)` | Independent PRNG |
| NumPy | `np.random.seed(N)` (legacy) or `rng = np.random.default_rng(N)` (modern) | Legacy global seed and the new `Generator` API are separate state machines — mixing them is a common bug |
| Hash randomization | `PYTHONHASHSEED=<int>` env var, set before interpreter start | VERIFIED (docs.python.org): controls hash salting of str/bytes, driving dict/set iteration order. Does **not** touch NumPy or `random` — a separate axis people forget. |
| PyTorch (if used) | `torch.manual_seed(N)`, `torch.cuda.manual_seed_all(N)`, `cudnn.deterministic=True`, `cudnn.benchmark=False`, `torch.use_deterministic_algorithms(True)` | UNVERIFIED via live fetch this session (pytorch.org randomness page fetch failed twice) — stable, long-documented public API, high confidence from training knowledge, just "not re-verified today." |
| CUDA determinism | `CUBLAS_WORKSPACE_CONFIG=:4096:8` (or `:16:8`), required with `torch.use_deterministic_algorithms(True)` for CUDA ≥10.2 cuBLAS ops | Same caveat as above. |
| TensorFlow (if used) | `tf.random.set_seed(N)`, `TF_DETERMINISTIC_OPS=1` | UNVERIFIED, not checked this session. |
| NautilusTrader | Engine-level `random_seed` config for fill/latency model PRNG | VERIFIED indirectly via WebFetch, but flagged lower-confidence — the summarizer returned oddly specific phrasing that reads possibly synthesized. Treat existence of a `random_seed` knob as credible; verify exact wording against current docs yourself. |
| Data loader workers | `num_workers=0`, or seed each worker via `worker_init_fn` | Multi-process `DataLoader` workers' RNG state is not automatically synced to main-process seed — classic silent non-reproducibility source. |

**What seeding does NOT guarantee:**
- **GPU floating-point non-associativity**: parallel reduction order (sums, matmuls) not fixed by a seed — depends on thread scheduling, kernel selection. `torch.use_deterministic_algorithms(True)` forces deterministic algorithm *choice* at a performance cost, and only for ops with deterministic implementations — some (`scatter_add`, some pooling backward passes) may throw or lack a deterministic variant.
- **Cross-GPU-architecture reproducibility**: a seed doesn't make results bit-identical between e.g. A100 and T4.
- **Cross-version reproducibility**: same seed, different PyTorch/CUDA/cuDNN → different bits. Determinism-within-a-seed is conditioned on identical library versions.
- **Multi-threaded/multi-process anything**: BLAS/OpenMP thread pool scheduling, `concurrent.futures` — wall-clock-timing races a seed doesn't touch.
- **`PYTHONHASHSEED`**: narrow scope, doesn't extend to numpy/random. Matters if code iterates a dict/set whose order leaks into something numeric (e.g. feature vector built by iterating a dict of indicators) — a real, easy-to-miss bug class in trading code that dynamically builds feature sets.
- **CPU-only determinism is much closer to "solved"** than GPU determinism for a fixed library-version stack — a solo backtesting/signal-generation setup on CPU has a meaningfully easier reproducibility problem than GPU-training. Don't over-invest in GPU determinism if the ML component is small (GBTs/small MLP) and CPU suffices.

---

## 2. Data Versioning

**Approaches:**
1. **Content-addressed storage (DVC)**: VERIFIED (doc.dvc.org). Caches data by content hash, `.dvc` metafiles in Git pointing at that hash, bytes in configurable remote (S3/GCS/SFTP). A Git commit pins the exact pointer → exact content hash → immutable. vs git-lfs (not directly compared in fetched doc, well-established): git-lfs is "large file pointers via Git's own remote plumbing" — simpler, works inside GitHub-hosted repos, no pipeline/experiment-tracking features. For solo use, git-lfs is lower-overhead if you only need "retrieve exact bytes"; DVC pays off wanting pipeline reproducibility (data version + code version → result) tracked automatically.
2. **Immutable dated Parquet snapshots with checksums**: low-tech, often sufficient — write once, never overwrite, path includes ingest date, SHA256 manifest alongside. Functionally content-addressing without tooling overhead. Frequently the right tradeoff for one person: less to learn, less to break, still gives the guarantee that matters.
3. **Object storage with versioning + lifecycle lock** (S3 versioning + object lock or equivalent): enforces immutability at the storage layer rather than relying on discipline. Worth it once real capital risk is at stake.

**Trading-specific gotcha — exchange data revision:**

Exchanges/data vendors do revise historical data after the fact — corrected/cancelled trades retroactively removed/flagged, OHLCV recomputed from corrected trade tape, REST historical endpoints reflecting *current* DB state rather than what was true at first query. Re-pulling "the same" date range 6 months later can silently return different numbers even with identical endpoint/code.

**Could not confirm a specific documented Binance policy live this session** (fetch didn't resolve, WebSearch quota exhausted before broader search) — treat "exchanges revise historical data" as UNVERIFIED-by-citation-today but high-confidence from general market-data-engineering knowledge, one of the most commonly cited reasons live-vs-backtest data pipelines diverge.

**Practical mitigation, the one unambiguous piece of advice in this section**: **snapshot on ingest, immutable, checksummed. Never re-pull historical data for backtesting.** Re-querying "the same" historical window later is not a reproducibility strategy — it's a silent-drift generator. A real data-bug correction is a *new* dataset version, not an overwrite — keep both, know which backtest used which.

---

## 3. Dependency Pinning

- **Lockfiles** (`uv.lock`, `poetry.lock`, `pip-compile --generate-hashes` output): pin the exact resolved version of every transitive dependency. A loose `numpy>=1.24` can resolve differently six months apart even with the file untouched.
- **System-level**: CUDA toolkit, cuDNN version, and — commonly missed — **BLAS implementation**. Domain-knowledge fact (not re-fetched live this session, settled numerical-computing fact): OpenBLAS vs Intel MKL vs Apple Accelerate can produce *different floating point results* for the same matrix op due to different reduction/blocking strategies. `numpy.show_config()` shows which BLAS is linked — two "identical" `pip install numpy==1.26.4` on different machines can silently link different BLAS backends by platform/wheel source, producing different low-order bits in linear algebra results (matters more for covariance/regression/portfolio-optimization workloads).
- **Docker image digest pinning**: VERIFIED (Docker docs). A tag is a **mutable pointer** — maintainers push new bytes under the same tag (patches, base-image updates). Pulling by digest (`image@sha256:...`) is the only guarantee of byte-identical contents. `FROM python:3.11-slim` is not enough for reproducibility — record the resolved digest at build time and pin to it. Tradeoff: no automatic security patches for that pinned image — correct and accepted for an archival/backtest container, distinct from the live-trading container which can track patches.
- **True bit-for-bit reproducibility** requires: locked Python deps + pinned system BLAS/CUDA + digest-pinned container + fixed CPU/GPU architecture (or CPU-only) + all seeding from §1. Real engineering surface — see §5 for whether it's worth building fully (mostly no, for a solo operator).

---

## 4. What Actually Breaks Reproducibility in Practice

1. **Silent numerical algorithm changes on minor version bumps.** VERIFIED (NumPy 2.0 release notes, fetched live, quoted directly): NEP 50 changed type promotion rules — "mixed-dtype operations may now produce different output dtypes and potentially lower precision results" from a version bump alone, no code change. Unstable sort defaults (`argsort`, `argpartition`) explicitly changed 1.26.x→2.0.0 (SIMD/algorithm changes) — "may return slightly different results." Feature pipelines sorting anything (ranking signals, order-book levels) without explicit stable-sort can change output from a NumPy upgrade alone.
2. **`copy=False` raising instead of silently copying** (NumPy 2.0, same source) — "breaks loudly" (good). Contrast: FFT now runs natively in float32 for float32 input instead of always upcasting to double (same source) — quietly different precision, zero warning.
3. **Pandas default behavior changes across versions** — copy-on-write semantics (2.x), default dtype inference, deprecated `.append()`/chained-assignment behavior. NOT independently re-verified this session (quota exhausted) — flagged UNVERIFIED-by-fresh-citation but one of the most commonly reported real-world breakage sources in quant Python shops, high prior confidence.
4. **tzdata updates retroactively change historical timestamp math.** VERIFIED (IANA tz docs): tzdata explicitly encodes "a history of offsets from Universal Time," and updates can affect how *past* dates convert local↔UTC when governments retroactively legislate DST rule changes (this genuinely happens). A backtest doing timezone-aware conversion (exchange-local trading hours, session alignment) can silently shift which bar a historical timestamp falls into after a routine OS tzdata package update, no code change.
5. **Exchange API deprecation.** Old REST endpoints sunset/change behavior — original ingestion code may not run anymore against the live API. Doesn't corrupt already-snapshotted data, but "re-run ingestion from scratch to reproduce" is not a valid recovery path — only "re-run against the frozen snapshot" is.
6. **Floating point non-associativity across CPU architectures.** `(a+b)+c != a+(b+c)`; different vector instruction sets (AVX2/AVX-512/ARM NEON) order operations differently for "the same" call. Developing on a laptop (e.g. Apple Silicon) and running production on cloud x86_64 means don't expect bit-identical results even with identical code/seeds/versions — architecture-level, below Python's control.
7. **GPU non-determinism from cuDNN algorithm auto-tuning** (`cudnn.benchmark=True` picks the fastest kernel for input shape at runtime, can vary run-to-run) — distinct from the seeding issue in §1.
8. **Multi-threaded data loaders/thread pools racing.** `ThreadPoolExecutor`, multi-worker `DataLoader`, BLAS's internal OpenMP pool — wall-clock-dependent execution order no seed fixes.
9. **Docker tag drift.** Someone rebuilds `python:3.11-slim` upstream (security patch) — VERIFIED tags are mutable, re-pulling "the same" tag isn't guaranteed same bytes. A Dockerfile pinned only by tag, built fresh six months later, is not the same image even with byte-identical Dockerfile text.
10. **Loose top-level pins resolving differently over time.** `numpy>=1.24` with no lockfile resolves to whatever's latest-compatible *today*, not what it was originally — the single most common "I thought I pinned my deps" mistake.
11. **Hidden dict/set iteration order dependence** — code building a feature vector by iterating a dict without explicit sort, combined with `PYTHONHASHSEED` unset (VERIFIED) — different hash seed per process run → different dict iteration order → different feature-column ordering, silently.

---

## 5. Direct Verdict

**Minimum viable reproducibility for a solo trader running real capital — cheap relative to the risk:**

1. **Lockfile, not loose pins**: `uv.lock` (fast, modern, increasingly default for new Python projects) or `poetry.lock`. Near-free, eliminates the most common failure (#10 above).
2. **Docker image pinned by digest** for the research/backtest environment specifically (the live-trading container can legitimately track patches — different concern). Record digest at build time, store next to results.
3. **Snapshot-on-ingest, immutable, checksummed market data.** Parquet + SHA256 manifest is enough — full DVC pipeline machinery not required unless you specifically want automatic data-version↔code-version↔result linkage. Never re-pull historical data — always replay from frozen snapshot. Highest-leverage single practice in this whole report, because it's the one gotcha (exchange data revision) that no amount of code/seed discipline fixes.
4. **Seed everything in §1's table that applies to your actual stack** — skip GPU-specific items entirely if not training on GPU (tree-based/small models on CPU sidestep most of the GPU non-determinism class, a real reason to prefer that path for a solo operator absent a specific deep-learning need).
5. **Set `PYTHONHASHSEED`** wherever dict/set ordering could leak into numeric output — five minutes of work, closes a real subtle bug class.
6. **Log the resolved environment with every backtest run**: lockfile hash, Docker digest, data snapshot ID/checksum, seed values, git commit — as metadata attached to the result. This is the actual mechanism that answers "what produced this six months ago" — a lookup, not a re-derivation.

**Overkill, not worth it at this scale:**

- **Bit-for-bit GPU determinism engineering** — chasing every non-deterministic op — unless a large GPU-trained model's edge genuinely depends on epsilon-level numeric differences (in which case that's a strategy robustness problem, not a reproducibility problem). "Same signals, not necessarily bit-identical numbers" is the right bar.
- **Pinning system BLAS/CUDA to exact patch version across architectures**, unless doing heavy linear algebra at scale (large portfolio optimization).
- **Full DVC pipeline tooling** (`dvc.yaml` graphs, `dvc repro`) — valuable for teams with many collaborators/complex pipelines; for one person, cognitive overhead usually isn't repaid. Immutable snapshots + a lockfile + a README/manifest of "which snapshot went with which backtest" gets ~90% of the value for ~10% of the setup cost.
- **Chasing tzdata pinning to the OS level** — worth knowing about (real, verified above), not worth building infrastructure around unless actually bitten by it. Reasonable middle ground: record the tzdata version in run metadata (point 6) to diagnose after the fact rather than prevent preemptively.

**The one-line opinion**: size reproducibility infrastructure to "can I explain and re-derive why this backtest said what it said," not "can I regenerate bit-identical floats." The former is cheap (lockfile + digest-pinned container + immutable snapshots + logged metadata); the latter is a multi-week engineering project appropriate for a quant fund's infra team, not a one-person shop's opportunity cost.

---

### Sources used this session
- [PYTHONHASHSEED — Python docs](https://docs.python.org/3/using/cmdline.html#envvar-PYTHONHASHSEED) — fetched, quoted
- [DVC: Versioning Data and Models](https://doc.dvc.org/use-cases/versioning-data-and-models) — fetched, quoted
- [NautilusTrader GitHub README](https://github.com/nautechsystems/nautilus_trader) — fetched; determinism/live-parity claims quoted (separate docs-site fetch flagged lower-confidence, verify wording directly)
- [NumPy 2.0.0 Release Notes](https://numpy.org/doc/stable/release/2.0.0-notes.html) — fetched, quoted extensively
- [IANA tz database link page](https://data.iana.org/time-zones/tz-link.html) — fetched, quoted
- [Docker docs — image pull, tags vs digests](https://docs.docker.com/engine/reference/commandline/pull/) — fetched, quoted
- PyTorch randomness docs — fetch failed twice (redirect handling); claims flagged UNVERIFIED-by-live-fetch-today, based on stable long-standing API knowledge instead
- Exchange historical-data-revision behavior (Binance) — fetch returned no usable content; WebSearch quota exhausted before broader search; flagged UNVERIFIED-by-citation, high-confidence-by-domain-knowledge
- Pandas default-behavior-change claims — not independently checked this session; flagged UNVERIFIED-by-citation-today
