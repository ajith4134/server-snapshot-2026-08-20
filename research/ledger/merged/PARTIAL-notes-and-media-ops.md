# Requirements Ledger — PARTIAL — notes-and-media, ops/security/governance/intelligence/observability

**Status: PARTIAL.** The four category-slice merge agents hit the session limit and died before writing
their files. This slice came back as a message from a sub-agent and was transcribed to disk by the
orchestrating session to prevent loss. Content unaltered.

Merged 2026-08-08. 194 source rows read in full. CLAIMED verified against actual files in
`trading-system/src/`; PLANNED verified against full reads of `ARCHITECTURE.md`, `FEATURES.md`,
`DECISIONS.md` and the 2026-08-08 goal doc; ADOPTED verified against CLAUDE.md, `~/.claude/skills/`
and `~/.claude/hooks/`.

**Table 1** — 101 source rows → 95 merged (6 same-idea-across-files pairs collapsed).
**Table 2** — 93 build-process rows. These are practices for how the system gets built, not bot
capabilities. Statuses are ADOPTED / CANDIDATE / DECLINED, judged against CLAUDE.md, skills and hooks.

---

## TABLE 1 — Bot capabilities

### Operations

| Requirement | Status | Phase | Evidence | Notes |
|---|---|---|---|---|
| BitMEX lesson: isolate ancillary features from critical infra | UNRESOLVED | — | none | Not referenced in any design doc |
| Reconciliation: exchange as source of truth | PLANNED | P0 | design only | DECISIONS.md §6 verbatim |
| Continuous REST polling as authoritative state | PLANNED | P0 | `src/capture/rest_poller.py` is the market-data precedent | Order/position-state reconciliation not built |
| K-consecutive-mismatch gate before resync | PLANNED | P0 | design only | ARCHITECTURE Layer 3 Staleness Detector |
| Hard halt on failed startup reconciliation | PLANNED | P0 | design only | DECISIONS.md §6 "refuse to start" — exact match |
| Reconciliation-divergence response tiers | PLANNED | P0 | design only | DECISIONS.md §6 "halt new orders, do not necessarily force-close" |
| **Cost Engine as a first-class component, not a default constant** | **CLAIMED** | Built | `src/cost/fee_fetcher.py`, `src/cost/fee_schedule.py` | `fee_schedule.py` makes exactly this distinction via `FeeSource` |
| Per-exchange API rate-limit compliance | PLANNED | P0 | design only | ARCHITECTURE Layer 3 Rate-Limit Budgeter. No module exists |
| Scheduled auto-sweep to self-custody | PLANNED | P1 | design only | FEATURES.md §7 |
| Rate-limit headroom buffer (operate under 50%) | PLANNED | P0 | design only | The 50% figure is not itself in ARCHITECTURE |
| **Maker/taker fee-tier tracking across exchanges** | **CLAIMED (partial)** | Built | `src/cost/fee_schedule.py` `DECLARED_SCHEDULES` | Only Binance + Hyperliquid populated. Reference-only venues untracked |
| Cloud-region selection for exchange proximity | PLANNED | open | none | DECISIONS.md §12 lists it as explicitly open — measure empirically |
| State/unit-handling validation for autonomous agent actions | PLANNED | P0 | design only | Closest named control is the price collar / fat-finger band |
| Config-schema strict validation | UNRESOLVED | — | none | Not named anywhere |
| chrony over ntpd for VM clock sync | PLANNED | P0 | design only | FEATURES.md §9 lists it P0; **no chrony config found in src/ or scripts/**, so PLANNED not CLAIMED |
| **Tuned recvWindow + clock-offset alerting** | **CLAIMED (partial)** | Built | `src/cost/fee_fetcher.py` `_RECV_WINDOW_MS = 5_000` | recvWindow half built; the `chronyc tracking` alerting half is not |
| **UTC-everywhere discipline** | **CLAIMED** | Built | `src/capture/raw_writer.py` (`utc_date_of`, `dt.timezone.utc`) | Verified by grep |
| Exchange API-change defensive patterns | UNRESOLVED | — | none | Schema validation, changelog subscription, contract tests all absent |
| **Exponential backoff with full jitter on reconnect** | **CLAIMED** | Built | `scripts/capture_supervisor.sh:92`; probe in `src/statuswall/evidence.py` | The status wall has a live probe named for it |
| Shared reconnect semaphore + circuit breaker | UNRESOLVED | — | none | No cross-process semaphore found |
| Write-ahead order-intent log with startup reconciliation | PLANNED | P0 | design only | ARCHITECTURE Layer 3, FEATURES §9 — no execution layer exists yet |
| **Disk-space exhaustion mitigation** | **CLAIMED (partial)** | Built | `src/capture/capture_health.py` runway monitor; `raw_writer.py` ENOSPC handling | logrotate/copytruncate and inode monitoring not verified |

### Security

| Requirement | Status | Phase | Evidence | Notes |
|---|---|---|---|---|
| Wintermute lesson: never use vanity-address key generators | UNRESOLVED | — | none | Tangential to Hyperliquid wallet-key handling, not itself named |
| Sandboxed execution + manual review for agent-generated code | PLANNED | P3 | design only | FEATURES.md §11 "Sandboxed, gated, never auto-promoted" |
| Self-custody via multisig/hardware wallet | PLANNED | P0 | design only | FEATURES.md §10 |
| OS keyring / Secret Service | **DECLINED** | — | — | ARCHITECTURE §3c: "desktop tooling, no home on a headless VM" |
| **sops + age encrypted secrets workflow** | **CLAIMED** | Built | `src/cost/secret_store.py` | Decrypts via subprocess pipe, never writes plaintext to disk |
| Cloud provider secrets manager | UNRESOLVED | — | none | Not chosen, but not explicitly refused either |
| Self-hosted HashiCorp Vault | **DECLINED** | — | — | ARCHITECTURE §5: "adds an unattended component that itself needs securing" |
| Exchange API key IP allowlisting | PLANNED | P0 | design only | FEATURES.md §10 — mandatory on Binance |
| Disabling withdrawal permission on the trading key | PLANNED | P0 | design only | FEATURES.md §10 — both call it the highest-leverage control |
| Separate exchange keys by function (read-only vs execution) | UNRESOLVED | — | none | FEATURES §10 covers per-venue sub-accounts, a different axis |
| Key rotation cadence and safe-swap procedure | PLANNED | P1 | design only | FEATURES.md §10 |
| Exchange self-service key auto-revocation | PLANNED | — | design only | ARCHITECTURE §3: no major exchange exposes it; the firewall is the mechanism |
| Blast-radius containment: trading key isolated from treasury | PLANNED | P0 | design only | FEATURES.md §10 + ARCHITECTURE §3 |
| **Secrets never plaintext-on-disk longer than necessary** | **CLAIMED** | Built | `src/cost/secret_store.py` | "plaintext exists only as a Python string in this process" |
| No exchange credentials in MCP / third-party tool servers | UNRESOLVED | — | none | Consistent in spirit with secret_store.py; no MCP-specific rule written |
| Dual-LLM pattern for untrusted web content | PLANNED | P1 | design only | FEATURES.md §11 + DECISIONS.md §7 — exact match |
| Distrust "95%-effective" guardrail products | PLANNED | — | design only | Embodied by choosing architectural separation over a product |
| Agentic misalignment under simulated goal conflict | UNRESOLVED | — | none | A cited finding, not a named control |
| Air-gapped / sandboxed execution for third-party model weights | PLANNED | P1 | design only | FEATURES.md §10 — same Kronos/xz-utils analogy |

### Governance

| Requirement | Status | Phase | Evidence | Notes |
|---|---|---|---|---|
| Trade-selection authority belongs to the arbiter only | PLANNED | P2 | design only | DECISIONS.md §1 decision 11 |
| Request-add, never take-add | PLANNED | P2 | design only | FEATURES.md §3b |
| Separate model registry entries per bot | PLANNED | P1 | design only | FEATURES.md §3b |
| Shared joint Trial Registry across bots | PLANNED | P1 | design only | FEATURES.md §3b, tagged [MISSED] |
| Per-bot competency level, independently gated | PLANNED | P2 | design only | FEATURES.md §3b |
| "Not yet forever" is a silent rejection | PLANNED | P1 | design only | Rationale behind FEATURES.md §3b signal expiry |
| Arbiter via meta-labeling | PLANNED | P2 | design only | DECISIONS.md §9 |
| Short options excluded from default action space | PLANNED | P3 | design only | DECISIONS.md §9 verbatim |
| No exemptions from the pre-trade risk gate | PLANNED | P0 | design only | DECISIONS.md §6 — same FTX/bZx citations |
| Immutable experiment ledger logging failures | PLANNED | P0 | design only | FEATURES.md §8, DECISIONS.md §5. Merged from 2 sources |
| Stage 0 — unrestricted experimentation | PLANNED | Stage 0 | design only | DECISIONS.md §4 |
| Stage 5 — gated live (small) | PLANNED | Stage 5 | design only | DECISIONS.md §4, incl. the user's button |
| Stage 6 — scaled live | PLANNED | Stage 6 | design only | DECISIONS.md §4 |
| Promotion as a lease, not a deed | PLANNED | — | design only | DECISIONS.md §4 verbatim phrase |
| Demote-on-decay, never delete | PLANNED | — | design only | DECISIONS.md §4 |
| Bounded definition of "self-improving" | PLANNED | §10.9 | design only | DECISIONS.md §7 + goal doc §6 bounded canary. Merged from 2 sources |
| Experiment/trial/promotion ledger schema | PLANNED | P0 | design only | DECISIONS.md §5 calls it a core subsystem; exact schema unpublished |
| No magic-number promotion duration | PLANNED | — | design only | DECISIONS.md §4/§11 give criteria instead of a duration |
| Regulatory quick-disable requirement | PLANNED | — | design only | DECISIONS.md §6 SEC Rule 15c3-5 |
| Trial Registry for searched/fine-tuned models | PLANNED | P0 | design only | ARCHITECTURE Layer 2 |
| Institutional custody cost-benefit | **DECLINED** | — | — | Source's own verdict: economics only work at ~$5M+ |
| Shadow-Before-Swap retrain-promotion gate | PLANNED | Shadow | design only | ARCHITECTURE §2, adopted with the 78.4% figure. Merged from 2 sources |
| Retrain-vs-retire decision framework | PLANNED | — | design only | ARCHITECTURE §2 near-verbatim adoption |
| Tooling-enforced holdout pre-registration | PLANNED | P0 | design only | ARCHITECTURE Layer 2 Holdout Custodian |
| Staged deployment sequence | PLANNED | — | design only | ARCHITECTURE §2 + DECISIONS.md §4 |
| Shadow-trading exit-criteria gate | PLANNED | Shadow | design only | ARCHITECTURE §2 — the ≥95%/≥90%/3-misalignment numbers adopted verbatim |
| Regime-coverage-gated promotion dwell time | PLANNED | P1 | design only | FEATURES.md §8 [MISSED] + ARCHITECTURE §2 |
| Parallel-run with automated divergence flagging | UNRESOLVED | — | none | Man Group precedent, not adopted |
| Champion/challenger traffic-split ramp with reserve rollback | UNRESOLVED | — | none | The 5–20%→100% ramp and 30–90-day reserve window are unnamed |
| Single strong agent over multi-agent committee | PLANNED | — | design only | DECISIONS.md §7(a) near-verbatim, same evidence |
| MacroHFT-style promotion objective | UNRESOLVED | — | none | Adjacent to goal doc §10.5 but not the same |
| Fabricated-metrics social content filter | PLANNED | P2 | design only | Instance of FEATURES.md §11 verification-before-ingestion |

### Intelligence

| Requirement | Status | Phase | Evidence | Notes |
|---|---|---|---|---|
| FinBERT domain-adapted financial sentiment | UNRESOLVED | — | none | FEATURES §1 P3 news feeds is the generic match |
| Regime signal as a weak feature into a meta-model | PLANNED | Phase 5 | design only | ARCHITECTURE Layer 4 near-verbatim, no veto power |
| Decision-conflict resolution under contradictory signals | PLANNED | P1 | design only | DECISIONS.md §9 — both agents high → FLAT |
| AlphaEvolve-style evolutionary program search | PLANNED | — | design only | DECISIONS.md §7 adopts it as the research-loop pattern |
| Majority-vote sampling over multi-model mixing | PLANNED | — | design only | DECISIONS.md §7(a) Self-MoA |
| Bi-temporal memory (recency/importance/relevance + reflection) | PLANNED | — | design only | DECISIONS.md §7 three kinds of memory |
| AOSm consensus-based update rule | UNRESOLVED | — | none | Not named anywhere |

### Observability

| Requirement | Status | Phase | Evidence | Notes |
|---|---|---|---|---|
| Missed-entry rate as monitored metric | PLANNED | P2 | design only | FEATURES.md §3b [MISSED] |
| Three-way P&L attribution (signal / timing / exit alpha) | PLANNED | P2 | design only | FEATURES.md §3b [MISSED]. Distinct from goal doc §10.8's per-*feature* attribution |
| Drawdown as a detector, not just a loss | PLANNED | — | design only | DECISIONS.md §11 verbatim |
| PSI drift threshold | **DECLINED as primary** | — | — | Source verdict: green PSI ≠ fine. Merged from 2 sources |
| KS test drift monitoring | **DECLINED as primary** | — | — | Source verdict: low-priority dashboard, never wire it to a page |
| **WS subscribe-acknowledgment validation trap** | **CLAIMED** | Built | `src/capture/rest_poller.py` | Docstring documents the measured finding and the fix |
| **Idle canary subscription for feed-availability monitoring** | **CLAIMED** | Built | `src/capture/venues/binance.py` — `_CORE_CHANNELS` keeps `forceOrder` | "the difference is deliberate… no REST replacement" |
| **Liquidation-feed unavailability rendered as red/unmeasured** | **CLAIMED** | Built | `src/statuswall/evidence.py` `probe_liquidation_feed` | DECISIONS.md §12.6: the tile stays red |
| Circuit-breaker trigger logging | UNRESOLVED | — | none | Distinct from the unbuilt Correlation Breaker |
| Automated ledger reconciliation | UNRESOLVED | — | none | Accounting-ledger (FTX-style), distinct from position reconciliation |
| KL-divergence / Jensen-Shannon drift metrics | UNRESOLVED | — | none | |
| Wasserstein / EMD drift metric | UNRESOLVED | — | none | |
| Fixed-reference drift detection under non-stationarity | UNRESOLVED | — | none | Rationale, not an adopted requirement |
| Technical-divergence vs statistical-decay diagnostic | PLANNED | P1 | design only | FEATURES.md §8 exact match |
| ADWIN / Page-Hinkley prediction-error-stream monitor | UNRESOLVED | — | none | Called "essential and cheap" by the research; **not named in any design doc** |
| **Sequence-gap + activity-adaptive staleness detection** | **CLAIMED** | Built | `src/capture/sequencing.py` — `BinanceDepthTracker`, `StalenessTracker` | U/u/pu chain check + floor+quantile threshold. Merged from 2 sources |

---

## TABLE 2 — Build-process practices

Statuses judged against CLAUDE.md rules, `~/.claude/skills/`, `~/.claude/hooks/`.

### ADOPTED — 35

Three-layer research stack (Rule 5) · model independence / task-matched model selection (Rule 1,
`model-selection` skill) · plan mode before execution (Rule 6) · pre-build interview technique
(Rule 6, `superpowers:brainstorming`) · minimal CLAUDE.md / delete-when-bloated (counterweight) ·
post-mistake CLAUDE.md update (Rule 6 addendum, `revise-claude-md`) · verification feedback loop
(Rule 0, `verification-before-completion`) · parallel partitioned sessions
(`dispatching-parallel-agents`, `parallel-research`) · skill as reusable procedure (`writing-skills`,
`skill-creator`) · never-bet-against-the-model / information-moat investment (counterweight,
near-verbatim) · three-layer build framework spec/verifier/environment (Rules 6, 0, and the
CLAUDE.md+skills+hooks stack) · uncover the goal not the task (Rule 6, quoted almost verbatim
including the "do the loops" example) · precise explicitly-verified spec decisions (Rule 6) · define
evaluation criteria up front (Rule 0, `requesting-code-review`) · second-model-as-critic
(`code-review`, `feature-dev:code-reviewer`) · external-signal verification (Rule 0,
`hook-verification-needs-a-live-log` memory) · structured CLAUDE.md content · LLM knowledge base as
data moat (Rule 9) · guide vs rule enforcement (Rule 4) · three-bucket action classification (Rule 0
cost-of-error buckets) · 4-condition loop-readiness test (counterweight, `guardrail-check`) · loop
trigger mechanism selection (`loop`, `schedule`) · skill-driven loop development ·
goal-verification inseparability (Rule 0) · loop output+memory logging (MEMORY.md) · third-party
plugin/skill security audit (`guardrail-check`, `security-guidance-plugin-costs` memory) ·
implementation spec before build (Rule 6, `writing-plans`) · CLAUDE.md verification rule +
blast-radius zones (Rule 0, quoted directly) · taste test for automation candidacy (counterweight) ·
80/20 output-quality automation filter (counterweight) · prefer augmentation over full automation
(counterweight) · model tiering by task complexity (Rule 1) · effort-level and extended-thinking
tuning (Rule 1, verbatim) · second-engineer code review discipline (`code-review`,
`requesting-/receiving-code-review`) · parallel workers for independent side-effect-free fetches only
(`dispatching-parallel-agents`).

### DECLINED — 2

| Practice | Reason |
|---|---|
| `mlfinlab` | Source: do not put a licensing risk in the capital-at-risk path — reimplement or use `mlfinpy` |
| Weights & Biases | Source: skip entirely — corporate-use restriction on the free tier, unconfirmed self-hosted licensing |

### CANDIDATE — 56, none currently in CLAUDE.md, a skill, or a hook

Compound engineering loop · maintainer-matters heuristic · avoid platform-dependency lock-in ·
mechanical-work-to-script conversion · mid-session re-verification prompt · fresh-session reset for
stuck problems · inner-loop-to-slash-command conversion · skill-candidate discovery prompt ·
animal-vs-ghost framing · agile spec-building · machine-enforced pipeline status gate · bridge
abstract goals to verifiable output · build loops from smallest proven workflow · Loop Training Mode ·
checkpoints for fuzzy goals · cap installed skills/plugins to limit context cost · explicit subagent
launch instruction · subagents for diverse independent perspectives · build skills only from
just-validated work · gotchas section in skills · autonomous top-tier model for open-ended goals ·
three-independent-pipelines cost acceptance · phased rollout with deterministic-policy fallback ·
documentation-outrunning-validation anti-pattern · unmerged-branch / entry-point-sprawl anti-pattern ·
restart-before-results anti-pattern · no new repository without a gate-passing result · growing
test-suite discipline · FunSearch · AlphaEvolve · ADAS · Eureka · STOP · EvoPrompt · OpenEvolve ·
ShinkaEvolve · trading-specific LLM-evolution strategy search · quality-diversity archive-based
search · fitness-function prerequisite checklist · automated verified identical deployment ·
dead-code / flag-reuse hygiene · MLflow experiment tracking · DVC data-snapshot versioning · full RNG
seeding checklist · snapshot-on-ingest immutable checksummed data · dependency lockfiles · Docker
image digest pinning · logged run-provenance metadata · NumPy version-bump silent numerical changes ·
pandas default-behaviour changes · tzdata retroactive timestamp changes · floating-point
non-associativity across CPU architectures · GPU cuDNN auto-tuning nondeterminism · multi-threaded
race nondeterminism · hidden dict/set iteration-order dependence.

**Two CANDIDATE rows worth flagging:**

- **"Cap installed skills/plugins to 3–5 to limit context cost"** — *contradicted by observed
  practice.* This session's live skill listing carries 40+ skills.
- **"Snapshot-on-ingest immutable checksummed market data"** — this IS implemented, in
  `src/store/parquet_partition.py` (SHA256 manifest). It sits in Table 2 only because Table 2 status
  is judged against CLAUDE.md/skills/hooks, not against the trading system. As a *bot capability* it
  is CLAIMED.

---

## Slice summary

**Table 1 — 95 merged rows:** CLAIMED 12 (several partial, noted in-row) · PLANNED 58 · DECLINED 5 ·
UNRESOLVED 20 · PRIOR-ART 0 (this source is research prose, not a code inventory).

Most PLANNED citations are near-verbatim matches, which means the ledger's source rows and the
project's own design docs were largely mined from the same underlying research. That is reassuring
about coverage and unhelpful for finding gaps.

**Table 2 — 93 rows:** ADOPTED 35 · CANDIDATE 56 · DECLINED 2.

**Honest gap, in the sub-agent's own words:** for borderline rows (chrony/ntpd, several narrative
"lesson" rows) the PLANNED-vs-UNRESOLVED call was made on whether the concept appeared *named* in the
design docs, not on deeper semantic equivalence. A stricter or looser reader could shift a few rows
between those buckets. CLAIMED rows were not re-verified for *completeness* beyond a targeted grep.
