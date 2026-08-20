# Post-mortem — six prior attempts

**Provenance**
- Read directly from GitHub via `gh`, 2026-08-01. Repos: `ajith4134/*`.
- Read: file trees, `PROJECT_BRIEF.md`, `trading/strategy/backtest.py`, `trading/strategy/cpcv.py`,
  documentation inventories. **Not** read: the bulk of 864 Python files, the 395KB `INDEX.md`, the
  928KB progress archive.
- Everything below is evidence-based or flagged as inference.

> ⚠️ **This document corrects two earlier mischaracterisations made during the session.** An initial
> read based on top-level file listings and `PROJECT_BRIEF.md` suggested weak engineering. Direct
> source reading contradicted that. The corrections are stated in §2 because they change the
> diagnosis entirely.

---

## 1. The timeline

| Date | Repo | Files | Python | Markdown | Tests |
|---|---|---|---|---|---|
| 2026-05-10 | `ajith-ai-crypto-trading-bot` | 369 | 255 | 2 | 10 |
| 2026-05-14 | `ai-advanced-crypto-bot-final` | 370 | 255 | 2 | — |
| 2026-05-16 | `crypto-linix-server-bot` | 337 | 258 | 2 | — |
| 2026-06-13 | `ai-crypto-trading-bot` | 512 | 316 | 72 | 13 |
| 2026-06-24 | `pattern-brain` | 162 | 119 | 24 | 48 |
| 2026-08-01 | `nse-crypto-bot-final` | **3,009** | **864** | **404** | **243** |

Plus `nse-crypto-bot` (empty, 2026-07-02) and a 2020 GitHub Actions tutorial.

**Six attempts in twelve weeks.** Three of them inside seven days in May.

The three May repos share **byte-identical documentation** (`all_the_changes_uptodate.md` at 17,353
bytes and `HOW_TO_RUN.md` at 15,314 bytes in all three) but have **different code trees** — verified
by hashing the sorted path sets, which differ. They are forks from a common base whose code diverged,
not duplicates.

## 2. Corrections — the engineering was better than it looked

**Correction 1: costs ARE modelled.** `trading/strategy/backtest.py`:

```python
def backtest_signal(signal, ohlcv, *, fee_bps: float = 2.0,
                    slippage_bps: float = 1.0, periods_per_year: int = 252)
    cost_rate = (fee_bps + slippage_bps) / 1e4
    # ret = side * (exit_/entry - 1.0) - 2.0 * cost_rate
```

Round-trip cost is charged, on both legs. That is a real cost model, not an omission.

**Correction 2: CPCV is implemented correctly, with purge AND embargo.**
`trading/strategy/cpcv.py`:

```python
def _purge_train(train, test_blocks, embargo):
    """Return the parts of a train range that survive purge+embargo around every test block."""
    lo = ts                  # purge: anything from test start …
    hi = te + embargo        # … through test end + embargo window

def combinatorial_purged_folds(n_rows, *, n_groups=6, k_test=2, embargo_pct=0.01)
```

The purge boundary and the embargo are both right, and `n_groups=6, k_test=2` is a sane
combinatorial budget. This is the machinery the research spent the day arguing for — **already
built, before this session's research existed.**

**Correction 3: test discipline improved sharply** — 10 → 13 → 48 → **243 test files.** That is a
24× increase across attempts and does not describe a careless project.

## 3. What is actually wrong

### 3.1 The cost model is present but likely mis-parameterised

Defaults are `fee_bps=2.0` and `slippage_bps=1.0` → **6bps round-trip**.

Against verified fee schedules, **Binance spot taker is 10bps per side — 20bps round-trip.** The
default is therefore roughly **3–4× too low** for the venue this project targets. (If the "nse"
naming means Indian equities rather than crypto, the correct figure differs again — but it is not
6bps for crypto.)

**This is more dangerous than having no cost model**, because it looks rigorous. A strategy with
10bps of gross edge shows profit at 6bps of assumed cost and loses money at 20bps of real cost — and
every downstream statistic, including a correctly-computed CPCV distribution, inherits the error.

**Not verified:** whether callers override the defaults. The defaults are what a new strategy gets.

### 3.2 Documentation grew far faster than validated results

Markdown files: **2 → 2 → 2 → 72 → 24 → 404.**

Individual artefacts: `INDEX.md` **395KB** · `PROGRESS_ARCHIVE_2026-06-07.md` **928KB** ·
`DISCUSSION_NOTES.md` **306KB** · `PLAN.md` **174KB** · `scientist_brain_PROGRESS.md` **248KB** ·
`BLUEPRINT_COMPLIANCE_AUDIT.md` **60KB**.

The 928KB progress archive is roughly a quarter of a million tokens — larger than most context
windows, and written in a single month. A `BLUEPRINT_COMPLIANCE_AUDIT` implies a blueprint large
enough that compliance with it needed auditing.

**Inference, not evidence:** planning volume appears to have substituted for validated results. No
document found records a strategy that passed a gate and traded.

### 3.3 The validation target was substituted (from `PROJECT_BRIEF.md`)

> *"Development/test data = synthetic dynamical-system benchmarks with known generating processes
> (default: Mackey-Glass chaos) … so the growing network's accuracy provably rises as it learns
> (crypto daily-direction is ~random and useless for development). Verified: MG baseline 52% →
> ensemble 96.4%, reservoir node 97.1%."*

Mackey-Glass is a deterministic delay differential equation — stationary, non-adversarial, with
genuine signal. Tuning to 97% there tunes to a system that does not resemble the target. The property
treated as the *reason* to use it ("accuracy provably rises") is what makes it misleading.

And the parenthetical is the finding: **"crypto daily-direction is ~random" is the domain telling you
where the edge is not.** Substituting a tractable proxy deferred that confrontation.

### 3.4 Structural signals

- **Default branch is `feat/trading-t8`** — a feature branch, never merged to a main line.
- **Versioned entry points accumulate rather than replace**: `run_brain.py`, `run_brain_agent.py`,
  `run_brain_t8.py` (56KB), `run_alerts_t7.py`, `run_advintel.py`, `run_active.py`.
- **Six repos, three containing "final".**
- Repo created **2026-08-01** — the same day this session began. The restart cadence is still active.

## 4. Diagnosis

**The failure is not engineering competence.** CPCV with correct purge and embargo, a cost model,
243 test files, and a 3,000-file codebase are not the artefacts of someone who cannot build.

**Three mechanisms fit the evidence:**

1. **A calibration error inside correct machinery.** Sophisticated validation consuming a cost
   assumption 3–4× too low produces confident, rigorous-looking, wrong answers. The research finding
   applies exactly: *the statistics are a second line of defence; the first line — costs, holdout,
   data you cannot query out of order — is cheaper and does more work.*
2. **Planning outrunning validation.** Documentation grew ~200× while attempts restarted every few
   weeks. Effort concentrated where feedback is absent.
3. **Restarting before results.** Six attempts in twelve weeks means no attempt ran long enough to
   produce the out-of-sample evidence that would justify continuing or killing it. **A strategy
   needs regime coverage; so does a project.**

## 5. What to carry forward

**Reuse directly — it is already correct:**
- `trading/strategy/cpcv.py` — purge/embargo implementation
- `trading/strategy/backtest.py` — cost-charging structure, with **re-parameterised** defaults
- The test corpus and its growth habit
- The prime directive from `PROJECT_BRIEF.md`, verbatim: *consistent, risk-managed income, not a
  lottery — protect capital, take small risk-managed edges, compound.*
- Dual-mode risk: paper unlimited, live preservation-first
- CPU-first (independently supported — GBT on engineered features beats DL at these horizons)

**Change:**
- **Cost parameters sourced from live fee schedules per venue, never a default constant.** This is
  the Cost Engine in `ARCHITECTURE.md` Layer 1, and its existence as a *component* rather than a
  function argument is the fix.
- Validation target = real market data with honest expectations, never a synthetic proxy chosen for
  its tractability.
- Documentation capped and indexed; a 395KB index is not an index.
- One entry point, replaced not versioned. Merge to a main line.
- **No new repository until the current one has produced a gate-passing result or a recorded reason
  for abandonment.**

## 6. Honest uncertainty

- The bulk of the 864 Python files is unread. There may be strengths and defects not represented here.
- Whether `fee_bps` defaults are overridden by callers is unverified.
- Whether any strategy ever passed a gate is unknown — no such record was found, but absence of
  evidence in a 3,000-file repo is weak evidence.
- The "nse" naming (National Stock Exchange?) versus crypto content is unresolved and affects which
  cost figures are correct.
