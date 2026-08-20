# Master spec and roadmap for the autonomous crypto trading system

## Context

Weeks of research produced 54 documents in `~/research/` and one built sub-project — Layer 0 raw
capture, 47 commits, 265 tests, in a worktree. `DECISIONS.md` §13 lists "write the full system spec"
as step 2, marked `← next`. It was skipped and step 3 was started instead. The result is real work on
a real foundation, with no document that makes the whole picture legible or binding.

Three findings from today's exploration set the priorities:

**Capture has never run.** No `~/capture/`, no process, no scheduler, zero bytes. The corpus's own
top cross-file idea is "immutable raw data capture, from day one — you cannot re-collect the past."
Every day spent specifying while the recorder is dark is a day of market data that does not exist.

**Two documents both claim authority.** `DECISIONS.md` says it supersedes chat history;
`ARCHITECTURE.md` says it supersedes `SYNTHESIS.md`. Two authorities is the mechanical cause of the
seven contradictions found — including a 7-stage vs 5-stage promotion pipeline and three different
things all called "the ladder".

**The prior repos were never mined.** `nse-crypto-bot-final` contains a correct, tested CPCV/PSR/DSR/
PBO implementation, a 217-claim source-graded microstructure synthesis, and a pre-registered
1.45M-row study finding crypto is intraday *mean-reverting* at 1h. It also records that `@aggTrade`
is silently dead on Binance's futures websocket host — a fact Layer 0 rediscovered from scratch this
week (commit `97d1a8b`). Not reading these repos already cost measurable work.

Intended outcome: a small set of documents split by rate of change, a running recorder, and the
prior work salvaged — so that building resumes against a settled whole picture instead of one axis.

---

## Interview decisions (2026-08-02) that this plan encodes

1. Operator console early, staged: data → research loop → paper trades, one screen that grows.
2. Budget near zero, free data only. No purchased L2 history, no colocation.
3. Brain 3 / sub-second: option kept open by continuing to capture; no Brain 3 code.
4. Archive growth: decide at the 30-day runway warning. **Corrected: that fires in ~45–90 days, not
   200–400.** Free disk is 90 GB; reaching the 400 GB ceiling needs a resize, which needs a reboot,
   which needs blocker B2.
5. Autonomy: fully autonomous in paper and research. Human gate only at real capital.
6. Paper stage: internal fill simulator for scoring, exchange testnet as plumbing rehearsal. Both.

---

## Week 0 — before a single spec line

These four are the only irreversible items. Everything else in this plan can be redone.

1. **Unblock B2 and start the recorder.** Verified on this box: `loginctl enable-linger` is denied,
   `sudo` is denied, cron is not installed and cannot be (`apt-get` needs sudo). The only route is
   pasting `scripts/reboot_probe_startup_script.sh` into the GCE instance's `startup-script`
   metadata, which needs a human in the console. **Blocked on you, not on a decision.**
2. **Start capture, confirm bytes on disk and a non-empty ledger** before anything else proceeds.
3. **D0 console + alert transport.** `build_report()` and `write_alerts()`
   (`src/capture/capture_health.py:213,381`) already compute everything; they are pull-only with no
   scheduler and no outward channel, so a silent stop is invisible. Static HTML regenerated on a
   timer, `<meta refresh>`, no service to babysit. Transport: ntfy (zero credentials) unless you
   prefer Telegram for two-way kill.
4. **Build `archive_offloader`.** B1 is closed — `gs://capture-raw-data4134` is verified writable —
   but nothing offloads and nothing prunes, so 90 GB is a hard wall.

---

## The document set

Split by **rate of change**, not by subject. One master spec mixes invariants that never change with
thresholds that change monthly, and nobody re-reads it. Twenty documents is the experiment already
run — it produced seven contradictions.

| Artifact | Path | Changes | Purpose |
|---|---|---|---|
| `CONSTITUTION.md` | `trading-system/docs/` | Never | The invariants never traded away, project kill criteria, and the authority order. Two pages, hard limit. |
| `SPEC.md` | `trading-system/docs/` | Per phase | The system by layer: what must be true, its schema, its falsifier. The single authority. |
| `contracts/` | `trading-system/src/contracts/` | Per implementation | Typed interface stubs plus the Hypothesis property tests any implementation must pass. **Code, not prose.** |
| `NUMBERS.md` + `thresholds.py` | `docs/` + `src/config/` | Monthly | Every number with its derivation and re-derivation trigger. A test asserts doc and code agree. |
| `ROADMAP.md` | `trading-system/docs/` | Weekly | Phase entry/exit gates; every deferral carries an observable un-defer trigger, never a date. |
| `DECISION-LOG.md` | `trading-system/docs/` | Append-only | One dated line per decision. Where the 409 ideas and 7 contradictions land. Greppable, never read end to end. |
| `OPEN-QUESTIONS.md` | `trading-system/docs/` | Append/close | The only legal place for a question. Each has an owner and a closing trigger. |

Three structural points that matter more than the file list:

- **`~/research/DECISIONS.md` and `ARCHITECTURE.md` are demoted in place to "superseded — retained as
  evidence."** All 54 research files become read-only evidence, cited by `file:line`, never restated.
  Two authorities is the bug.
- **The spec lives in the repo, not `~/research/`** — it must be diffable against the commit that
  implements it, and `NUMBERS.md` must be testable against `thresholds.py`.
- **Interfaces are code.** The clock-gated access API has no signature anywhere today, and it is the
  component that makes look-ahead structurally impossible rather than a discipline. Prose pseudocode
  for it would be wrong within a week and then disagree with the code silently. Write
  `src/contracts/clock_gated_reader.py` with leakage property tests beside it; `SPEC.md` states what
  must be true and points at the file. **The tests are the spec that cannot rot.**

Every `SPEC.md` layer section ends with a mandatory **Falsifier** subsection — "this layer is wrong
if X is observed", with the test that observes it. That is Rule 0 applied to a document. Layer 0's:
a planted future value in the raw archive must be invisible to a backtest through the reader.

---

## Salvage from the prior repos

A workstream, not a footnote. Ranked by cost to rediscover.

| Item | Where | Why |
|---|---|---|
| `trading/strategy/cpcv.py`, `guardrails.py` + `tests/test_antioverfit_p20.py`, `test_guardrails_t8.py` | repo-final | Correct, dependency-light CPCV with purge+embargo, PSR, deflated Sharpe, PBO via CSCV, IC — pinned by property tests (PBO ≈0.5 on noise, ≈1.0 on constructed overfit). Exactly Phase 3. No MinBTL there; that we write. |
| `research/gate-rebuild/SYNTHESIS-AND-FIELD-LIST.md` + `ALL-CLAIMS.md` | repo-final | 217 source-graded microstructure claims, and it self-corrects its own overclaim. Days of expert work. |
| `X23-momentum-ignition-preregistration.md` + `X23-RESULT.md` | repo-final | Pre-registered, 1.45M rows, shuffled-null controlled: crypto is intraday **mean-reverting** at 1h, thin edge in dip-buys during downtrends. Nuances "daily direction is random" and is a candidate first family. The methodology is the template. |
| `no_profit_diagnosis_2026-08-01.md`, `live_session_diagnosis_2026-07-27.md` | repo-botonly | Net −₹190k over 2,790 paper trades; gross −₹56k **before** fees. "Even with ZERO fees the system still loses." And: 50k LOC of governance on top of a signal core with no edge. Read before building any more governance. |
| SELinux/systemd incident, `BACKLOG.md:267-284` | repo-botonly | Unsupervised process died with an uninstalled unit; then crash-looped 11× on `203/EXEC` because the venv was labelled `user_home_t`. Directly relevant to the supervisor we must build. |
| `HFT-feasibility.md` | repo-final | Measured 162 ms VM→Binance. Independent confirmation for closing sub-second. |
| `CONVENTIONS.md` §16/§16b | repo-final | Underpowered ≠ unproven ≠ proven-wrong, born from a real bug that shorted noise. |
| `truth_ledger.py`, `discrete_lot_size_down_policy.py`, `exec_choice.py` | both | Per-source reliability with Wilson CIs; composing risk multipliers onto indivisible units; sha256-keyed A/B arms because `PYTHONHASHSEED` randomises per process. |

**Explicitly low value:** `broker_sense/` browser-fingerprint spoofing — the repo's own audit found it
actuates nothing, and it carries ToS exposure. The `autopoiesis/` tree is 11k LOC of MDP and survival
analysis to decide whether to restart a thread; take its reading list (Erlang/OTP, K8s
CrashLoopBackOff, Envoy retry budgets, AWS jitter), not the code.

**Handle with care:** `FOUNDERS_INTENT.md` in repo-final embeds verbatim personal content of a
sensitive nature. It must not be copied into the new project's documents or into anything published.

---

## Adjudicating the 409 ideas

Not 409 decisions — about 14. Each idea is a table row with an explicit verdict glyph, and the corpus
already self-nominated 57 shortlist items and a cross-corpus top 7. It adjudicated itself twice and
nobody accepted the result.

Four bins, **default is D**, and an idea leaves D only if someone types the line:

- **A — already in the spec.** ~18 today, mechanical.
- **B — admitted now, hard cap of 12.** Drawn only from the 57 self-nominated, filtered by the
  corpus's own test — *does it change what the system does when it is wrong?* — and by *buildable in
  Phase ≤3 with what exists*.
- **C — trigger-deferred.** One line: idea, plus the observable event that promotes it. Absorbs most
  of the 172 HIGH.
- **D — declined in bulk by cluster**, one reason per cluster.

**The epistemics cluster is not 40 features. It is one table plus one rule.** A belief record
(`belief_id, claim, source, acquired_at, epistemic_class ∈ {read, verified, observed}, evidence_refs[],
supporting_trials[], half_life, superseded_by`) and the rule that **only `observed` may size a
position unaided**. Retraction propagation is a recursive query over `evidence_refs`; contradiction
detection is a scheduled query; competence maps and calibration scoring are views. Table into bin B,
every query into bin C. Storage: the same DuckDB file as the ledger. Consolidation cadence: do not
specify — there are zero beliefs, and it will be obvious at 200.

One working day, output appended to `DECISION-LOG.md` so a future session greps a verdict instead of
re-deriving it.

---

## Resolving the seven contradictions

Four dissolve on inspection, two resolve by evidence already in the corpus, one is yours.

| # | Resolution |
|---|---|
| 1 EVT | Not a contradiction — `ARCHITECTURE.md:473` declines it as a *forecast* input on sample size; `IDEAS-STRATEGIC.md:144` rates it HIGH for *parameterising the risk gate*. Declined for alpha; bin C for risk sizing, trigger "≥100 exceedances above the 99th percentile per venue in the archive." |
| 2 Offline RL | Not a contradiction — HIGH is for the pessimism principle as a *sizing rule*, not for offline-RL policies. Adopt the former, decline the latter under the existing rule. |
| 3 Continual learning | Evidence in hand: `continual-learning-and-failure-modes.md:21-27`. Rolling walk-forward retrain is the only adaptation mechanism. Bin D, trigger "a live-validated published result." |
| 4 State-space models | Already settled by an existing rule — `DECISIONS.md:260` requires every neural component to beat LightGBM *and* a linear baseline on our data. **General principle: a contradiction an existing rule already settles is closed by citing the rule, not adding one.** |
| 5 Multi-agent | Needs an explicit line: (a) no LLM judges another LLM as a gate — the deterministic evaluator is the only judge; (b) independently-seeded model populations are permitted, their disagreement is an uncertainty *feature* into sizing, never a veto; (c) BULL/BEAR "debate" declined — they are two models and the arbiter is meta-labelling, there is no text exchange. |
| 6 Ladders | Naming collision, three distinct things. Rename to `drawdown_ladder` (3 rungs, P&L), `operational_state_machine` (5 states, faults), `disk_pressure_ladder` (4 states, already built). Keep all three. |
| 7 Brains vs families | **Yours.** See open questions. |

**Bonus, the 7-vs-5 stage split** — determinable once decision 6 is made. The load-bearing invariant:
**only stages that produce a score increment N.** Testnet rehearsal does not. That is why the two
documents could not agree on a count — one counted rehearsals, the other did not.

---

## Sequence

**Parallel from day one** (independent, side-effect-free, `sonnet` subagents per Rule 1): fee
verification sweep for Binance USDⓈ-M and Hyperliquid (only Binance *spot* and Kraken were ever
fetched live); ledger backend comparison (DuckDB+journal vs SQLite vs MLflow) against append-only /
survives-`kill -9` / cheap `COUNT(*)`; NautilusTrader's own simulated-exchange fill model, because if
it is adequate the fill-simulator section shrinks to a configuration decision.

- **Week 1** — `CONSTITUTION.md`. `SPEC.md` §0–§2. `contracts/clock_gated_reader.py` + leakage tests.
  These three are one unit of work; splitting them produces prose that disagrees with the stub.
- **Week 2** — Bitemporal store and reader implemented against now-real captured data. Note and state
  in §2.2: **the store is a derived layer over an immutable raw archive, so the schema can be got
  wrong and rebuilt at zero data cost** — do not agonise over it. Provenance stamper. Idea-adjudication day.
- **Week 3** — `SPEC.md` §3 and the Cost Engine, fee sweep landed. Fill-simulator decision. `NUMBERS.md`
  first pass. D1 console.
- **Week 4** — `SPEC.md` §5, experiment ledger, trial registry, holdout custodian — **porting
  `cpcv.py` and `guardrails.py` rather than rewriting.** Then the falsifier: run the whole search over
  pure random-walk data, and if anything promotes, the layer is broken. Run it before any real search.
- **Weeks 5–6** — Contradictions written into `DECISION-LOG.md`. `ROADMAP.md`. First carry strategy
  hand-written through stages 0–4. D2 console.

**Not in this window:** LLM strategy generation, portfolio code, options, Brain 3 code, live capital,
testnet.

---

## Not specified yet, and why

- **The strategy generator.** Specify only the interface — emits a program plus a mechanism
  declaration, receives a score from an evaluator it cannot write to. ~30 lines. You cannot design a
  DSL before hand-writing three strategies in it; an autonomous 24/7 loop needs API credits, which is
  a number not yet set; and this is the purest case of the counterweight in `CLAUDE.md` —
  **the evaluator is the durable asset, the generator is scaffolding.**
- **Memory storage technology and consolidation cadence.** Zero beliefs exist.
- **Options layer, portfolio allocator, Thompson sampling, RMT, CVXPY, NumPyro.** All need ≥2 live
  strategies. One page naming components and triggers.
- **Meta-model over the ledger.** Bin C, trigger 500 registry entries.
- **Any architecture diagram of a thing that does not exist**, and any "future work" section — that
  is what `OPEN-QUESTIONS.md` with triggers is for.

---

## Verification

Rule 0, stated before the work:

- **Capture running:** `ls ~/capture/raw/` shows files growing; ledger has events; `build_report()`
  returns `capture_status: "present"`. Re-check after a deliberate reboot to prove B2.
- **Console and alerting:** kill the recorder, confirm a push notification arrives and the console
  shows the stream age climbing. A console that has never fired an alert is unverified.
- **Clock-gated reader:** plant a future value in the archive; a Hypothesis property test asserts no
  backtest query returns it at any `sim_clock`. Also an import-lint test that fails if any module
  outside the reader opens a parquet file.
- **Search integrity:** run the full search over random-walk data. Anything promoted is a defect.
- **Ported code:** `cpcv.py` and `guardrails.py` tests pass unmodified in the new repo before use.
- **`NUMBERS.md`:** a test asserts every value matches `thresholds.py`.
- **Spec/code agreement:** each `SPEC.md` layer's Falsifier is a real test that runs in CI.

---

## Open questions — yours, exact wording

1. **Do we retire the three-brain frequency axis entirely** — keeping the skill-tree gate metaphor,
   re-scoping BULL/BEAR/ARBITER to meta-labelling inside a family? `ARCHITECTURE.md:23-36` already
   supersedes the frequency axis but never redrew the triad under it. Recommendation: yes. Under this,
   Brain 3 is not deferred, it is dissolved — sub-second is a latency class the family table already
   closed, and your decision to keep capturing its data stands unchanged.
2. **Will you paste the startup script into the GCE instance metadata today?** If you do not have
   console access to that project, say so now — capture cannot survive a reboot and the disk resize
   needs one.
3. **Offload to GCS at roughly $1–13/month, or stay local-only with a hard stop at 45–90 days?**
   "Near zero" has to resolve to a number. Recommendation: Coldline with a lifecycle rule, ~$5/month.
4. **Promote-to-live control: CLI requiring a typed strategy id plus the hash of the promotion report
   it approves, or a button on the console?** Recommendation: CLI with the hash. A button can be
   clicked; a hash cannot be pasted without having opened the report.
5. **Alert transport: ntfy (no credentials, push only) or a Telegram bot (a token to manage, but kill
   from your phone)?**
6. **Monthly API-credit ceiling for the autonomous research loop?** If zero, we hand-write the carry
   family and the generator is not specified until Phase 6. Recommendation: zero for now — the
   largest YAGNI cut available.
7. **Fable and the 30-day retention requirement** — `ARCHITECTURE.md:450` says settle this cold,
   before the escalation protocol first fires. Proprietary strategy code is about to exist. Is Fable
   usable on this project's code, yes or no?
