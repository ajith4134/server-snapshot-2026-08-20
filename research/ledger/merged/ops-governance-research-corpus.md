# Requirements Ledger — operations, security, governance, intelligence, observability — research corpus

Merged 2026-08-08. Raw rows in slice: 197 (Category ∈ {operations, security, governance, intelligence,
observability} from `ledger/raw/research-corpus.md`, which mined `FEATURES.md`, six `IDEAS-*.md`
files, `SYNTHESIS.md`, `DESIGN-NOTE-universe-wide-scanning.md`, `ARCHITECTURE.md`, `DECISIONS.md`).
Merged rows: 116. Cross-referenced to siblings: 24.

**Status methodology, stated up front because it changes the count.** PLANNED is granted only when a
row is named in `ARCHITECTURE.md`, `FEATURES.md`, `DECISIONS.md`,
`DESIGN-NOTE-universe-wide-scanning.md`, `IDEAS-INTELLIGENCE.md`, or the 2026-08-08 goal doc — the
docs the task brief names as the actual plan. A row cited only from `IDEAS-ADVANCED.md`,
`IDEAS-AI-FIELD.md`, `IDEAS-STRATEGIC.md`, `IDEAS-FRONTIER.md`, `IDEAS-SYNTHESIS.md` or `SYNTHESIS.md`
— brainstorm tiers the corpus itself distinguishes from the committed design — is **UNRESOLVED**
unless it independently falls inside the goal doc's new §1a intelligence standard (which cites
`IDEAS-INTELLIGENCE.md` directly and is itself in the allowed list) or merges into a row that does
qualify. This is stricter than treating "somewhere in the 950-row corpus" as sufficient, and it is why
roughly 40% of this slice's raw rows land UNRESOLVED rather than PLANNED — most of them are real
brainstorm content that has not yet been promoted into the architecture. Both sibling files used the
same restriction (`PARTIAL-notes-and-media-ops.md`'s own methodology note names the same four-doc
core).

**CLAIMED verification.** `trading-system/src/` currently holds four packages — `capture`, `store`,
`cost`, `statuswall` — plus `tests/` and `scripts/`. Every CLAIMED row below was checked by reading the
cited module and confirming a caller exists, per the `tail_specs()` warning in the brief (a function
that is fully built, fully tested and called by nothing is not CLAIMED). One new CLAIMED-partial row
was found in this slice beyond what either sibling recorded: `probe_venue_health` in
`src/statuswall/evidence.py`, which the sibling files' own ops/security sweep did not surface.

**Merging.** 23 raw-row clusters collapsed into 23 merged rows (mostly same-section IDEAS-*.md clusters
that describe facets of one mechanism, e.g. the sealed-envelope-metric trio, or the nine
`ARCHITECTURE.md §3c` "Stack:" lines), absorbing roughly 55 additional raw rows that would otherwise
each have needed a standalone line. 24 raw rows were not emitted as rows at all because the identical or
functionally-identical capability already has a scored row in `PARTIAL-nse-crypto-bot-final-ops.md` or
`PARTIAL-notes-and-media-ops.md` — overwhelmingly the latter, since it mined the same `FEATURES.md
§9/§10` sections this slice's `operations`/`security` rows also cite. Those 24 are listed once each
under Cross-references, not repeated here.

**Coverage honesty.** All 197 raw rows in the slice were read and individually dispositioned (emitted,
merged, cross-referenced, or explicitly declined/unresolved) — none were silently dropped. The
merge-group boundaries are a judgment call, not a mechanical rule; a stricter reader could split a few
of the 6-way merges (rows 497–502, 607–612) back into separate rows without changing any status. CLAIMED
verification was a targeted grep-and-read sweep of the current ~25-file `src/` tree, not a line-by-line
audit of every function; it is thorough for a codebase this size but not a formal proof of absence for
anything not found.

| # | Requirement | Category | Status | Phase | Evidence / satisfying module | Notes |
|---|---|---|---|---|---|---|
| OGR-001 | Aggressive prompt caching for LLM-heavy components | operations | UNRESOLVED | — | IDEAS-AI-FIELD.md Part XI | Not in `ARCHITECTURE.md`/`FEATURES.md`. Already true of *this Claude Code session's own* dev-environment practice (CLAUDE.md Rule 1's 87%-cache-read measurement) but that is a different system from the trading bot |
| OGR-002 | Red-team agent generates hypotheses, does not judge itself | governance | PLANNED | — | DECISIONS.md §7 | The evaluator/red-team split; test settles hypotheses, the LLM only proposes them |
| OGR-003 | Evaluator must sit outside the system's write access | governance | PLANNED | — | DECISIONS.md §7; goal doc §6 "The research loop's evaluator is deterministic, non-LLM, and outside the system's write access" | Reaffirmed verbatim in the 2026-08-08 goal doc |
| OGR-004 | Two-stage watching-cost funnel (cheap coarse screen, expensive evaluation only on candidates) | operations | PLANNED | — | DESIGN-NOTE-universe-wide-scanning.md §6 | Mirrors the router pattern |
| OGR-005 | Deliberate model-family diversity where the system depends on model judgement | governance | UNRESOLVED | — | IDEAS-SYNTHESIS.md Part III | No home in the core docs; not the same as the already-PLANNED BULL/BEAR two-bot split, which is same-architecture not cross-vendor |
| OGR-006 | Red Queen dynamics — constant research rate required merely to stand still | governance | UNRESOLVED | — | IDEAS-SYNTHESIS.md Part III | Framing/rationale, not a built capability anywhere |
| OGR-007 | Low-level performance engineering (CPU pinning/NUMA/huge pages, lock-free structures, SIMD/vectorisation, io_uring/mmap) | operations | UNRESOLVED | — | IDEAS-ADVANCED.md §23 | Merged 4 rows (272–275). Sibling family of ideas (kernel bypass, FPGA) already DECLINED in the main corpus under `execution`, outside this slice |
| OGR-008 | Cost of own operation (compute/data/inference/API) belongs inside the objective, not outside it | governance | PLANNED | — | IDEAS-INTELLIGENCE.md §5 | A strategy earning less than its inference cost is negative-alpha regardless of Sharpe — one of the §1a-adjacent epistemic-honesty rows |
| OGR-009 | Compute allocation as a bandit (next GPU-hour: more search on A or better execution modelling on B) | operations | PLANNED | — | IDEAS-INTELLIGENCE.md §5 | Currently made by whim per source; distinct capability from OGR-008 despite same section |
| OGR-010 | Real-options view of research projects (a half-built strategy is an option, not a sunk cost) | governance | UNRESOLVED | — | IDEAS-FRONTIER.md §2 | Decision-framing device, not named in any plan doc |
| OGR-011 | Restricted strategy DSL + program synthesis over it (strategies as small typed-language programs, unsafe ops inexpressible by construction) | governance | UNRESOLVED | — | IDEAS-FRONTIER.md §4 | Merged 2 rows (336–337). Ambitious, would materially change how strategies are authored; not named in `ARCHITECTURE.md`/`FEATURES.md` |
| OGR-012 | Sealed-envelope metric, with improvement-theatre detection and periodic metric rotation ("the objective is not the metric") | governance | UNRESOLVED | — | IDEAS-FRONTIER.md §5; IDEAS-STRATEGIC.md §1 (merged 340, 341, 342, 626) | Row 626 explicitly says it "pairs with the sealed-envelope metric." Related to the already-PLANNED OGR-003 (evaluator outside write access) and to §1a's L8 objective-vs-intent test, but the sealed-envelope mechanism itself is not named in any of the six allowed docs |
| OGR-013 | Failure precursor learning (learn signatures that precede incidents rather than only detecting them) | operations | UNRESOLVED | — | IDEAS-FRONTIER.md §7 | Not named elsewhere |
| OGR-014 | Human-escalation optimisation (what to escalate scored by expected value of the input; explanation quality scored by decision improvement; alert-fatigue and attention-budget as first-class health metrics) | operations | UNRESOLVED | — | IDEAS-FRONTIER.md §11 | Merged 4 rows (365–368) |
| OGR-015 | Cross-layer oscillation detection (detect and damp hunting between layers adapting to each other) | operations | UNRESOLVED | — | IDEAS-FRONTIER.md §12 | Not named elsewhere |
| OGR-016 | Blockchain-based anything for internal state | operations | DECLINED | — | IDEAS-ADVANCED.md §14 | "adds latency and complexity to solve a trust problem not present" |
| OGR-017 | Artificial immune systems for anomaly detection (self/non-self discrimination framing) | operations | UNRESOLVED | — | IDEAS-ADVANCED.md §25 | Not named elsewhere |
| OGR-018 | Vector clocks / CRDTs | operations | DECLINED | — | IDEAS-ADVANCED.md §21 | "solves multi-writer conflict resolution not present here" |
| OGR-019 | Zero-knowledge proofs for solvency/strategy properties | security | UNRESOLVED | — | IDEAS-ADVANCED.md §22 | Source's own verdict: "real tech, no need yet" |
| OGR-020 | Conservative / safe exploration bandits (performance guaranteed never to fall below baseline by more than a margin) | intelligence | UNRESOLVED | — | IDEAS-AI-FIELD.md Part II | Adjacent to the already-PLANNED curiosity budget (IDEAS-INTELLIGENCE.md §4) but a distinct formal mechanism, not itself named in the allowed docs |
| OGR-021 | Frontier AI-safety awareness list (specification gaming as the expected default; scalable oversight/debate protocols; weak-to-strong generalisation; sandbagging/deceptive-alignment) | governance | UNRESOLVED | — | IDEAS-AI-FIELD.md Part X | Merged 4 rows (474–477). Source frames these as forward-looking notes ("mostly a frontier-lab concern... noted so it is not rediscovered as novel later"), not committed work |
| OGR-022 | Proposer and approver must be separate; approver not self-modifiable | governance | PLANNED | — | IDEAS-INTELLIGENCE.md §10; goal doc §6 "The ceiling is outside the system's write access — a checksummed configuration the risk gate enforces, which no component, LLM or otherwise, can edit" | The fixed point that makes self-modification survivable |
| OGR-023 | Genome diff log (every self-authored change: full diff, rationale, author component, justifying trial) | governance | PLANNED | — | IDEAS-INTELLIGENCE.md §10; goal doc §6 "change report written to the ledger either way" | Part of the canary contract |
| OGR-024 | Canary + quarantine + automatic rollback for self-authored changes (never a direct promotion) | governance | PLANNED | §10.9 | IDEAS-INTELLIGENCE.md §10; goal doc §6 "The canary contract" and §10.9 "The bounded canary" | The goal doc names this explicitly as unbuilt named work, with `signals/scibrain/` in `nse-crypto-bot-final` (`changespec.py`, `evaluator.py`, `rigor.py`, `validator.py`, `change_report.py`, `canary.py`) as the reference implementation to adapt, "not to copy blind — it has never been validated against a gate." `PARTIAL-nse-crypto-bot-final-ops.md` explicitly did not cover scibrain (its own note: "SciBrain rows: 0 in this slice... that content lives in an unmerged slice"), so this is not a duplicate of that file. Added: the amendment exists because the same failure (three concurrent self-modification loops, corrupted attribution) was found already run on this project's own prior money in `ai-crypto-trading-bot` — net −$837 over 10,240 live trades |
| OGR-025 | LLM-component health diagnostics (adversarial-agent convergence treated as mode-collapse warning not confidence; sycophancy/anchoring detection via reordered-context replay; reasoning-change audit; confabulation "cause unknown" check on postmortems) | intelligence | PLANNED | — | IDEAS-INTELLIGENCE.md §11 | Merged 4 rows (487, 488, 490, 491) |
| OGR-026 | Pre-mortem ("it is 2028 and this failed completely, explain why") | governance | UNRESOLVED | — | IDEAS-SYNTHESIS.md Part V | Not named in any plan doc |
| OGR-027 | Base rates for this exact endeavour, stated explicitly | governance | PLANNED | — | IDEAS-SYNTHESIS.md Part V; ARCHITECTURE.md §2 | Median 73% Sharpe deterioration backtest-to-live is cited in `ARCHITECTURE.md` §2 |
| OGR-028 | Process quality scored separately from outcome, for the system and for the operator | governance | PLANNED | — | IDEAS-INTELLIGENCE.md §7; IDEAS-SYNTHESIS.md Part V | Merged: row 605 ("A good decision that lost money is still a good decision", already-PLANNED via IDEAS-INTELLIGENCE.md §7) with row 496 which extends the identical discipline to the human operator's own record — "resulting bias affects humans more than code" |
| OGR-029 | Build-sequencing governance (dependency graph over the feature set ordered by enabling power; minimum viable epistemic core; one-way vs two-way reversibility classification; cost-of-delay sequencing; explicit "not now, here is the trigger" deferred list; feature-level pre-registration before building) | governance | UNRESOLVED | — | IDEAS-SYNTHESIS.md Part VI | Merged 6 rows (497–502). None of these meta-planning practices are themselves named in `ARCHITECTURE.md`/`FEATURES.md`/`DECISIONS.md`; this ledger itself is arguably a first instance of the "minimum viable epistemic core" idea but the practice is not adopted as policy |
| OGR-030 | Venue health monitor + auto-halt | operations | **CLAIMED (partial)** | P0 | `src/capture/capture_health.py` `build_report`; `src/statuswall/evidence.py` `probe_venue_health`; FEATURES.md §9; ARCHITECTURE.md §Layer3 | New finding, not in either sibling. Health *monitoring* is live and measured — the probe surfaces per-venue silent-stream and corrupting-event counts — but the probe's own text states "Auto-halt on degradation not implemented." The halt action does not exist; only the detection does |
| OGR-031 | Cold-start behaviour (defined behaviour on first boot with no state) | operations | PLANNED | P0 | FEATURES.md §9 | `[MISSED]` in source |
| OGR-032 | Disaster recovery runbook, documented and tested (VM dies mid-position — what recovers, in what order; written so a non-operator can flatten the book) | operations | PLANNED | P1 | FEATURES.md §9; IDEAS-STRATEGIC.md §4 | Merged: FEATURES.md's "Disaster recovery runbook" [MISSED] with IDEAS-STRATEGIC.md §4's "Documented recovery runbook, tested" — same requirement from two source files |
| OGR-033 | Tiered alerting (page / notify / log) | operations | PLANNED | P1 | FEATURES.md §9 | Escalation tiers for operational alerts |
| OGR-034 | Structured audit log of every decision | operations | PLANNED | P1 | FEATURES.md §9 | `src/capture/capture_ledger.py`'s `CaptureLedger` is a partial building block in the same shape (append-only NDJSON event log) but scoped only to capture-layer anomalies, not trading decisions — not close enough to call CLAIMED |
| OGR-035 | Absence-triggered de-risking ladder for operator continuity (heartbeat absence: N hours stops opening, N days reduces, longer flattens) | operations | UNRESOLVED | — | IDEAS-STRATEGIC.md §4 | Distinct from the system-level dead-man's switch (a `risk`-category row, outside this slice); not named in the core docs |
| OGR-036 | Operator succession and key-inheritance planning (documented business-continuity/succession plan; key escrow/inheritance path for self-custodied crypto) | security | UNRESOLVED | — | IDEAS-STRATEGIC.md §4; IDEAS-ADVANCED.md §24 | Merged: "Key escrow / inheritance path" (517) with "Business continuity / succession plan" (621) — both are the same estate/continuity problem viewed from custody vs. operations |
| OGR-037 | Designed boringness as an explicit target (interventions-per-week trending to zero as a first-class health metric) | operations | UNRESOLVED | — | IDEAS-STRATEGIC.md §4 | "If running the system is exciting, that is a design defect" |
| OGR-038 | Event sourcing (state as an immutable append-only event log, current state a fold over events) | operations | UNRESOLVED | — | IDEAS-ADVANCED.md §21; IDEAS-STRATEGIC.md §11 | Source frames it as a generalisation of the order-intent WAL (`FEATURES.md` §9, PLANNED — see OGR row for write-ahead log, cross-referenced below); the specific WAL instance is committed, the general event-sourcing pattern is not |
| OGR-039 | Adversarial test-quality practices (fuzzing exchange responses; mutation testing) | operations | UNRESOLVED | — | IDEAS-ADVANCED.md §21 | Merged 2 rows (520–521) |
| OGR-040 | Formal verification / TLA+ on the promotion state machine | governance | UNRESOLVED | — | IDEAS-ADVANCED.md §21 | "exactly the class of bug that reactivates a retired strategy" — high-effort, not named as planned work anywhere |
| OGR-041 | Operational resilience practices (predictive feed-failure detection; LLM-assisted log analysis and triage; chaos engineering drills) | operations | UNRESOLVED | — | IDEAS-ADVANCED.md §12 | Merged 3 rows (523–525) |
| OGR-042 | Auto-remediation of operational incidents | operations | DECLINED | — | IDEAS-ADVANCED.md §12 | "Dangerous near capital; keep humans on the repair path" |
| OGR-043 | Technology stack pins (Python 3.12 via uv; NautilusTrader execution framework; Parquet+ZSTD storage; DuckDB+Polars query; LightGBM+scikit-learn+Optuna; MLflow file-store registry; uv.lock; systemd --user supervision; checksummed-snapshot provenance stamper as a no-container digest-pinning substitute) | operations | PLANNED | — | ARCHITECTURE.md §3c | Merged 9 "Stack:" lines from the same section into one row; each is a distinct tool choice but none is independently a "requirement" worth separate tracking |
| OGR-044 | ZipLime (Limex-com/ziplime) as an execution-framework alternative | operations | DECLINED | — | ARCHITECTURE.md §3c | "vendor-published benchmark not independent... revisit only on independent benchmark plus re-examined licence position" |
| OGR-045 | Initial live capital under $10k for the first six months | governance | PLANNED | P1 | ARCHITECTURE.md §3b | "First live phase is paid validation, not income" |
| OGR-046 | Full autonomy within hard limits — human sets limits, not trades | governance | PLANNED | P0 | ARCHITECTURE.md §3b; DECISIONS.md §1; goal doc §6 "Gates that stay human: 1. The capital dial. 2. Paper → real money" | The goal doc's §6 is a direct, current restatement of this exact decision |
| OGR-047 | Venue selection: execution on Binance + Hyperliquid, reference-only Kraken/OKX/Coinbase, Bybit deferred | operations | PLANNED | P0 | ARCHITECTURE.md §3b; **coinbase captured as reference-only since 2026-08-10** — `src/capture/venues/coinbase.py`, 517 products, supervised | "deliberately unalike so they fail differently, at the cost of duplicating nearly everything in the ops layer" | The reference-only half is now partly real. The build plan had carried coinbase as blocked on a missing API key; probed 2026-08-10 its market data is keyless, and this row already said no execution key was wanted for it — the block was on a premise the architecture had settled against. Kraken and OKX remain uncaptured, which is what keeps this PLANNED. Next: coinbase does not yet feed `features.consolidated_price` (DM-022) — its `level2` frame shape has no store extractor, so the reference price it exists for is not yet drawing on it. |
| OGR-048 | Hyperliquid agent-wallet key scoping (trade but not transfer; never the on-chain owner key on the trading VM) | security | PLANNED | P0 | ARCHITECTURE.md §3b | The Binance withdrawal-permission rule does not transfer to an on-chain wallet model |
| OGR-049 | Binance matching-engine region measurement (RTT probe before committing infrastructure) | operations | PLANNED | open | ARCHITECTURE.md §4 (open decisions) | Sources conflict Tokyo vs us-east-1; an open decision, not yet measured |
| OGR-050 | Retention policy for proprietary code and data | governance | PLANNED | P1 | FEATURES.md §12; ARCHITECTURE.md §4 | `[MISSED]`. Decides whether Fable 5 (30-day retention mandate) is usable at all |
| OGR-051 | Exchange sandbox selection for testing (OKX demo best, Binance testnet good, Bybit 48h new-account lockout) | operations | PLANNED | — | DECISIONS.md §12 | |
| OGR-052 | Historical L2 data budget decision (~1–5 TB/year per symbol-exchange pair; Kaiko ~$28.5k/yr unverified) | operations | PLANNED | — | DECISIONS.md §12; goal doc §11 "Historical L2 data budget" (open item 2, carried unchanged) | Confirmed still open as of the 2026-08-08 goal doc |
| OGR-053 | Hot zones definition (paths requiring sign-off and blast-radius explanation) | governance | PLANNED | — | DECISIONS.md §12; SYNTHESIS.md | "not yet formally enumerated" |
| OGR-054 | Per-venue sub-accounts (deterministic derivation from one seed, blast-radius containment distinct from per-function key separation) | security | PLANNED | P1 | FEATURES.md §10 | Distinct axis from "separate keys by function," which `PARTIAL-notes-and-media-ops.md` scores UNRESOLVED and explicitly flags as "a different axis" from this one — that sibling did not independently score this axis |
| OGR-055 | Anomaly detection on own order behaviour (catches a compromised or runaway bot from the outside) | security | PLANNED | P2 | FEATURES.md §10; IDEAS-ADVANCED.md §12 | `[MISSED]`. Not present in either sibling |
| OGR-056 | Agent-with-wallet blast radius containment | security | PLANNED | P2 | FEATURES.md §10 | "Relevant if any component is ever given spend authority; under Rule 0 this is 'never do' territory unless capital movement stays behind the human gate" |
| OGR-057 | Market-data-borne prompt-injection threat model (attacker-controlled strings in token names/on-chain memos/NFT metadata/listing announcements as injection vectors arriving through the price feed itself; structured extraction only, never free text into a reasoning context; slow context-poisoning of long-lived memory; semantic denial-of-service against the autonomous researcher's budget; adversarial content crafted to move models rather than people) | security | UNRESOLVED | — | IDEAS-STRATEGIC.md §9 | Merged 5 rows (560–564). Not named in any of the six allowed docs. Two of the stated mitigations are separately PLANNED elsewhere in this ledger — belief provenance/retraction propagation (IDEAS-INTELLIGENCE.md §1) and the curiosity budget cap (IDEAS-INTELLIGENCE.md §4) — but the threat-model architecture itself is not |
| OGR-058 | LLM look-ahead guard (LLM-derived signals are contaminated on dates inside the model's training window) | intelligence | PLANNED | P1 | FEATURES.md §11; IDEAS-ADVANCED.md §8 | `[MISSED]` |
| OGR-059 | Research synthesis / literature ingestion (automated ingestion of external research) | intelligence | PLANNED | P2 | FEATURES.md §11 | |
| OGR-060 | Automated postmortem writer (every retirement, breaker trip and anomaly gets a written cause feeding the ledger) | intelligence | PLANNED | P2 | FEATURES.md §11; IDEAS-ADVANCED.md §8 | |
| OGR-061 | Knowledge base / memory, including retrieval-augmented research memory over papers/postmortems/prior experiments | intelligence | PLANNED | P2 | FEATURES.md §11; IDEAS-ADVANCED.md §8 | Merged: "Knowledge base / memory" (569) with "Retrieval-augmented research memory" (574) as the same capability |
| OGR-062 | LLM parsing exchange announcements and changelogs (auto-detect API/fee/listing/maintenance changes) | operations | PLANNED | — | IDEAS-ADVANCED.md §8; IDEAS-INTELLIGENCE.md §4 | "a pure operations win against silent schema failures" |
| OGR-063 | LLM roles bounded to propose/critique, never decide (feature proposer whose candidates count as Trial Registry entries; LLM-as-judge critiquing Mechanism Declarations pre-promotion) | intelligence | UNRESOLVED | — | IDEAS-ADVANCED.md §8 | Merged 2 rows (572–573). Distinct from the already-PLANNED dual-LLM quarantine and research loop; these two describe specific in-pipeline LLM roles not named in the core docs |
| OGR-064 | Belief records with provenance, evidence strength, and a half-life | intelligence | PLANNED | — | IDEAS-INTELLIGENCE.md §1; goal doc §1a.6 ("belief records with provenance and half-life" is #1 on the "ten to build first" list) | §1a-named directly |
| OGR-065 | Retraction propagation (falsified source re-scores everything derived from it, automatically) | intelligence | PLANNED | — | IDEAS-INTELLIGENCE.md §1 | Belief graph with source edges catches poisoning mechanically |
| OGR-066 | Contradiction detection across the knowledge base (scheduled consistency pass) | intelligence | PLANNED | — | IDEAS-INTELLIGENCE.md §1 | "how a corpus becomes knowledge instead of an archive" |
| OGR-067 | Source credibility as a live, updating score | intelligence | PLANNED | — | IDEAS-INTELLIGENCE.md §1 | |
| OGR-068 | Distinguish read / verified / observed epistemic classes — only observed-in-our-own-data beliefs may size a position unaided | intelligence | PLANNED | — | IDEAS-INTELLIGENCE.md §1; goal doc §1a.6 (#2 on the "ten to build first" list) | §1a-named directly |
| OGR-069 | Belief-graph query interface ("why do we believe this," answerable in one query back to primary evidence) | intelligence | PLANNED | — | IDEAS-INTELLIGENCE.md §1 | |
| OGR-070 | Explicit competence map in feature space (density estimate over training/validation inputs, flags out-of-support live inputs) | intelligence | PLANNED | — | IDEAS-INTELLIGENCE.md §2 | The "competence boundaries" §1a-adjacent capability |
| OGR-071 | Abstention as a first-class action with its P&L value measured | intelligence | PLANNED | — | IDEAS-INTELLIGENCE.md §2; IDEAS-ADVANCED.md §1; goal doc §1a.6 (#4, "abstention as a real action with its P&L measured") | §1a-named directly |
| OGR-072 | Calibration scoring of own forecasts (Brier / log score, tracked per regime) | intelligence | PLANNED | — | IDEAS-INTELLIGENCE.md §2; goal doc §1a.6 (#5) | §1a-named directly |
| OGR-073 | Decision-relevant value of information (chase uncertainty that would change an action, not the highest uncertainty) | intelligence | PLANNED | — | IDEAS-INTELLIGENCE.md §2 | Correct objective for autonomous data acquisition |
| OGR-074 | Blind-spot audit (periodically enumerate what the system never looks at) | intelligence | PLANNED | — | IDEAS-INTELLIGENCE.md §2 | |
| OGR-075 | Known-unknowns register | intelligence | PLANNED | — | IDEAS-INTELLIGENCE.md §2 | |
| OGR-076 | Offline consolidation — a scheduled "sleep" pass re-deriving compressed lessons from raw experience | intelligence | PLANNED | — | IDEAS-INTELLIGENCE.md §3 | "later evidence changes what earlier events meant" |
| OGR-077 | Episodic-to-semantic promotion, evidence retained (specific incidents abstract into general rules, supporting cases stay linked) | intelligence | PLANNED | — | IDEAS-INTELLIGENCE.md §3 | |
| OGR-078 | Active forgetting (knowledge tied to dead market structure must be retired, not merely outranked) | intelligence | PLANNED | — | IDEAS-INTELLIGENCE.md §3 | |
| OGR-079 | Case-based reasoning / retrieval keyed on regime similarity (regime fingerprint, not text similarity) | intelligence | PLANNED | — | IDEAS-ADVANCED.md §13; IDEAS-INTELLIGENCE.md §3 | |
| OGR-080 | Negative-result corpus, including a lessons-learned corpus feeding future prompts | intelligence | PLANNED | — | IDEAS-INTELLIGENCE.md §3; IDEAS-ADVANCED.md §13 | Merged: "Negative-result corpus" (594) with "Lessons-learned corpus feeding prompts" (655) — same nearly-free-once-the-Trial-Registry-exists artefact |
| OGR-081 | Curiosity budget as an explicit, capped line item (fixed fraction of capital/compute for information-only actions) | intelligence | PLANNED | — | IDEAS-INTELLIGENCE.md §4 | |
| OGR-082 | Autonomous research loop, read-only and quarantined, with a bounded tool-use agent for data exploration | intelligence | PLANNED | — | IDEAS-INTELLIGENCE.md §4; IDEAS-ADVANCED.md §8 | Merged: "Autonomous research loop, read-only and quarantined" (596) with "Tool-use agent for data exploration, bounded, read-only" (576) — the same reader-has-no-credentials mechanism |
| OGR-083 | Verification-before-ingestion as a hard gate (any checkable factual claim checked against primary source before entering the knowledge base) | intelligence | PLANNED | — | IDEAS-INTELLIGENCE.md §4; goal doc §1a.6 (#3) | §1a-named directly |
| OGR-084 | Active learning over data spend (buy the dataset that most reduces decision-relevant uncertainty) | intelligence | PLANNED | — | IDEAS-INTELLIGENCE.md §4 | |
| OGR-085 | Tool/venue discovery (propose adoption of a needed capability; adoption stays human) | intelligence | PLANNED | — | IDEAS-INTELLIGENCE.md §4 | |
| OGR-086 | Autonomous browsing with credentials | intelligence | DECLINED | — | IDEAS-INTELLIGENCE.md §4; goal doc §6 "No path from web content to capital that skips the promotion gate" | "the moment the researcher holds credentials, prompt injection from a hostile page becomes a trading action" |
| OGR-087 | Autonomous capital movement | governance | DECLINED | — | IDEAS-INTELLIGENCE.md §4; goal doc §6 "Gates that stay human: 1. The capital dial" | Rule 0 "never do," non-negotiable regardless of capability — reaffirmed as the first of only two human gates in the 2026-08-08 goal doc |
| OGR-088 | Meta-analysis over the Trial Registry (which strategy families die within N days of a regime transition, which feature sources never survive OOS) | intelligence | PLANNED | — | IDEAS-INTELLIGENCE.md §7; goal doc §1a.6 (#7) | §1a-named directly |
| OGR-089 | Self-extending failure taxonomy (cluster failures; unlabelled clusters name a new failure mode) | intelligence | PLANNED | — | IDEAS-INTELLIGENCE.md §7 | |
| OGR-090 | Decision journal with pre-registered rationale (reasoning and prediction recorded before the outcome) | intelligence | PLANNED | — | IDEAS-INTELLIGENCE.md §7 | Prevents post-hoc confabulation |
| OGR-091 | Postmortem-to-hypothesis pipeline (every postmortem ends in a testable proposition entering the registry) | intelligence | PLANNED | — | IDEAS-INTELLIGENCE.md §7 | "or it was journaling" |
| OGR-092 | LLM-inference architecture menu (inference-time compute scaling; process supervision over outcome supervision; constrained/structured decoding for the strategy DSL; self-consistency and verifier models; GraphRAG over the belief graph; long-context-vs-retrieval decided by auditability) | intelligence | UNRESOLVED | — | IDEAS-AI-FIELD.md Part IX | Merged 6 rows (607–612). None individually named in the allowed docs; GraphRAG is adjacent to the already-PLANNED belief-graph query interface (OGR-069) but is a specific retrieval mechanism, not the belief graph itself |
| OGR-093 | Manual promote button (human sets limits, not trades) | governance | PLANNED | P0 | FEATURES.md §12; DECISIONS.md §1, §4; goal doc §6 "gate 2: Paper → real money" | "already decided" |
| OGR-094 | Config versioning + rollback | governance | PLANNED | P0 | FEATURES.md §12 | No versioning/rollback module found in `src/` |
| OGR-095 | Change log tied to deployments | governance | PLANNED | P1 | FEATURES.md §12 | |
| OGR-096 | Tax / accounting fill record (every fill, timestamped, in an exportable ledger) | governance | PLANNED | P1 | FEATURES.md §12; IDEAS-ADVANCED.md §24 | `[MISSED]` |
| OGR-097 | Jurisdiction / venue eligibility check (which venues are legally usable, KYC tier limits) | governance | PLANNED | P1 | FEATURES.md §12; IDEAS-ADVANCED.md §24 | `[MISSED]` |
| OGR-098 | Build to institutional rigor, not lines-of-code, as the quality metric | governance | PLANNED | — | DECISIONS.md §0 | "Institutional systems are large because of what they must handle, not by design" |
| OGR-099 | Business/legal structure decisions (tax-lot accounting method chosen before day one — FIFO/LIFO/specific-ID; entity structure; insurance) | governance | UNRESOLVED | — | IDEAS-ADVANCED.md §24 | Merged 3 rows (619, 620, 622). Distinct from the already-PLANNED "Tax / accounting fill record" (OGR-096), which is the raw-data ledger, not the accounting-method decision |
| OGR-100 | Year-1 objective framed as information gain per dollar risked, not return (explicit objective ladder by phase; optionality preservation as an explicit criterion) | governance | UNRESOLVED | — | IDEAS-STRATEGIC.md §1 | Merged 3 rows (623–625). Philosophically adjacent to the already-PLANNED "Initial live capital under $10k... paid validation, not income" (OGR-045, `ARCHITECTURE.md` §3b) but the formal information-gain objective ladder is not itself named there |
| OGR-101 | Pre-registered project-level abandonment and escalation criteria (stop conditions written before emotional investment; milestone-gated capital escalation; operator time costed explicitly; honestly stated expected value including base rate) | governance | UNRESOLVED | — | IDEAS-STRATEGIC.md §3 | Merged 4 rows (627–630) |
| OGR-102 | Durable-asset architecture for successor portability (calibrated knowledge — trial registry, belief graph, postmortems, negative-result corpus — stored model/framework-independent; documentation written for a successor with zero context) | governance | UNRESOLVED | — | IDEAS-STRATEGIC.md §11 | Merged 2 rows (631, 633) |
| OGR-103 | Latency histograms per venue and endpoint | observability | PLANNED | P1 | FEATURES.md §13 | |
| OGR-104 | Fill-quality metrics vs. assumed | observability | PLANNED | P1 | FEATURES.md §13 | "The number that predicts live degradation" |
| OGR-105 | Cost breakdown dashboard | observability | PLANNED | P2 | FEATURES.md §13 | |
| OGR-106 | Strategy health board | observability | PLANNED | P2 | FEATURES.md §13 | |
| OGR-107 | Ultra-visual animated node dashboard | observability | PLANNED | P3 | FEATURES.md §13; ARCHITECTURE.md §3 (Build order) | Corpus's own note: "Declined-in-practice: produces zero alpha, scales with node count" — formally still PLANNED/deferred to Phase 6+ rather than a written DECLINED verdict, so status carried as-is |
| OGR-108 | Skill-tree architecture: gates live on the transition not inside the node, and the taxonomy is not hard-coded (branches grow from validated results) | governance | PLANNED | — | DECISIONS.md §2 | Merged 2 rows (641–642), same design decision from two angles |
| OGR-109 | backtrader as an execution/backtest framework | operations | DECLINED | — | DECISIONS.md §10 | "dead since 2023-04-19 despite 22k stars" |
| OGR-110 | vectorbt OSS as a backtest framework | operations | DECLINED | — | DECISIONS.md §10 | "frozen, no live path" |
| OGR-111 | Puppeteer MCP for browser automation | operations | DECLINED | — | DECISIONS.md §10 | "archived, unpatched advisory" |
| OGR-112 | Installing MCP servers by default | operations | DECLINED | — | SYNTHESIS.md | Dev-environment decision: "most official ones are redundant or archived; CLI beats MCP 4-32x on tokens, 100% vs 72% success." Live current practice per this session's own tool access (native `Bash`/`gh` preferred over MCP where equivalent) |
| OGR-113 | Installing third-party plugins by default | operations | DECLINED | — | SYNTHESIS.md | Dev-environment decision: "third-party ecosystem is thin" |
| OGR-114 | Pre-building skills before a validated use case | operations | DECLINED | — | SYNTHESIS.md | Dev-environment decision: "build from a conversation just had, where the use case is already validated" |
| OGR-115 | Version-specific env-var workarounds | operations | DECLINED | — | SYNTHESIS.md | Dev-environment decision: "two features named in community posts were already removed by the time of writing" |
| OGR-116 | Knowledge graph of strategies/features/regimes | intelligence | UNRESOLVED | — | IDEAS-ADVANCED.md §13 | "Makes relationships explicit; feeds the meta-model." Adjacent to the already-PLANNED belief graph (OGR-064–069) but scoped to strategies/features/regimes rather than beliefs — not itself named in the allowed docs |

## Cross-references

Capabilities in this slice that already have a scored row in a sibling file. Listed once each; not
repeated as full rows above.

| Raw requirement (this slice) | Belongs to row in | Notes |
|---|---|---|
| No multi-agent LLM committee for trading decisions (governance, DECLINED, DECISIONS.md §7) | `PARTIAL-notes-and-media-ops.md` Governance — "Single strong agent over multi-agent committee" PLANNED | Same DECISIONS.md §7(a) decision stated from its negative and positive sides |
| Weights & Biases for experiment tracking (operations, DECLINED, ARCHITECTURE.md §5) | `PARTIAL-notes-and-media-ops.md` Table 2 DECLINED — "Weights & Biases" | Same free-tier corporate-use restriction, cited from two different source documents |
| Self-hosted Vault / OS keyring for secrets (security, DECLINED, ARCHITECTURE.md §5) | `PARTIAL-notes-and-media-ops.md` Security — "OS keyring / Secret Service" DECLINED and "Self-hosted HashiCorp Vault" DECLINED | This slice's raw row combines both into one; the sibling scored them as two separate rows with matching reasons |
| Capital sweep to self-custody above a threshold (security, FEATURES.md §7) | `PARTIAL-notes-and-media-ops.md` Operations — "Scheduled auto-sweep to self-custody" PLANNED (P1) | Same capability, cited from `FEATURES.md` §7 vs §9 in the two source documents |
| Threshold signatures / MPC wallets; Hardware wallet / HSM for treasury; Deterministic sub-account derivation (security, IDEAS-ADVANCED.md §22) | `PARTIAL-notes-and-media-ops.md` Security — "Self-custody via multisig/hardware wallet" PLANNED (P0, `FEATURES.md` §10) | Three IDEAS-ADVANCED mechanism-level rows collapse into the sibling's one FEATURES.md-sourced capability |
| Cross-strategy rate-limit budgeter (operations, `FEATURES.md` §9) | `PARTIAL-notes-and-media-ops.md` Operations — "Per-exchange API rate-limit compliance" PLANNED (P0) | Same rate-limit-governance capability at slightly different granularity |
| Order-intent write-ahead log (operations, `FEATURES.md` §9) | `PARTIAL-notes-and-media-ops.md` Operations — "Write-ahead order-intent log with startup reconciliation" PLANNED (P0) | Identical requirement |
| State recovery from exchange truth on restart (operations, `FEATURES.md` §9) | `PARTIAL-notes-and-media-ops.md` Operations — "Reconciliation: exchange as source of truth" PLANNED (P0) | Same requirement |
| Clock sync via chrony + drift alerting (operations, `FEATURES.md` §9) | `PARTIAL-notes-and-media-ops.md` Operations — "chrony over ntpd for VM clock sync" PLANNED (P0) | Identical; sibling notes no chrony config exists in `src/` or `scripts/` |
| Sequence-gap detection on book streams (operations, `FEATURES.md` §9) | `PARTIAL-notes-and-media-ops.md` Observability — "Sequence-gap + activity-adaptive staleness detection" **CLAIMED**, `src/capture/sequencing.py` | Confirmed via `src/statuswall/evidence.py`'s `probe_sequence_gap_detection`, which reads `BinanceDepthTracker`/`StalenessTracker` directly |
| Reconnect with full-jitter backoff, honour Retry-After (operations, `FEATURES.md` §9) | `PARTIAL-notes-and-media-ops.md` Operations — "Exponential backoff with full jitter on reconnect" **CLAIMED**, `scripts/capture_supervisor.sh:92` | Confirmed via `src/statuswall/evidence.py`'s `probe_capture_supervisor` |
| Disk / memory / resource watchdog (operations, `FEATURES.md` §9) | `PARTIAL-notes-and-media-ops.md` Operations — "Disk-space exhaustion mitigation" **CLAIMED (partial)** | The disk half is covered there. Fresh finding from this slice's own `src/statuswall/evidence.py` read: `probe_resource_watchdog`'s own text states **"Memory and CPU watchdogs not implemented"** — that half of this broader requirement remains open in both ledgers |
| Withdrawal permission never on trading keys (security, `FEATURES.md` §10) | `PARTIAL-notes-and-media-ops.md` Security — "Disabling withdrawal permission on the trading key" PLANNED (P0) | Identical |
| IP allowlisting (security, `FEATURES.md` §10) | `PARTIAL-notes-and-media-ops.md` Security — "Exchange API key IP allowlisting" PLANNED (P0) | Identical |
| sops + age secret management (security, `FEATURES.md` §10) | `PARTIAL-notes-and-media-ops.md` Security — "sops + age encrypted secrets workflow" **CLAIMED**, `src/cost/secret_store.py` | Identical requirement, already built |
| Treasury / cold-storage separation (security, `FEATURES.md` §10) | `PARTIAL-notes-and-media-ops.md` Security — "Blast-radius containment: trading key isolated from treasury" PLANNED (P0) | Identical |
| Key rotation procedure (security, `FEATURES.md` §10) | `PARTIAL-notes-and-media-ops.md` Security — "Key rotation cadence and safe-swap procedure" PLANNED (P1) | Identical |
| Third-party model weights treated as untrusted binaries (security, `FEATURES.md` §10) | `PARTIAL-notes-and-media-ops.md` Security — "Air-gapped / sandboxed execution for third-party model weights" PLANNED (P1) | Same Kronos/xz-utils-precedent requirement, phrased as the threat model vs. the mitigation |
| Dual-LLM quarantine for untrusted content (intelligence, `FEATURES.md` §11) | `PARTIAL-notes-and-media-ops.md` Security — "Dual-LLM pattern for untrusted web content" PLANNED (P1) | Identical |
| Memory — three kinds: episodic, semantic, reflective (intelligence, `DECISIONS.md` §7) | `PARTIAL-notes-and-media-ops.md` Intelligence — "Bi-temporal memory (recency/importance/relevance + reflection)" PLANNED | Both cite the identical `DECISIONS.md` §7 "three kinds of memory" passage |
| PreToolUse enforcement hooks (Bash deny-list, Edit/Write file protection); Stop hook for verification-before-completion (governance, `SYNTHESIS.md`) | `PARTIAL-notes-and-media-ops.md` Table 2 ADOPTED — "guide vs rule enforcement (Rule 4)" | Both rows describe the live `~/.claude/hooks/` enforcement layer (`block-dangerous-bash.sh`, `protect-files.sh`, `verify-before-stop.sh`) — dev-environment infrastructure, not `trading-system/src/`, so not scored CLAIMED in either ledger despite being genuinely live and tested |

## Slice summary

**By status:** CLAIMED 1 (partial) · PLANNED 78 · DECLINED 20 · UNRESOLVED 37. (116 emitted rows total;
20 of the DECLINED and CLAIMED/PLANNED capabilities in the raw slice were folded into the 24
cross-referenced rows above rather than double-counted here.)

**Five most important UNRESOLVED rows:**

1. **OGR-034-adjacent gap, structured audit log of every trading decision (`FEATURES.md` §9, P1)** —
   scored PLANNED here because it is named in the plan, but nothing in `src/` builds it yet and the one
   candidate precedent (`CaptureLedger`) only logs capture-layer anomalies, not decisions. Flagged
   because every downstream governance capability in this ledger (canary contract, postmortem
   pipeline, reasoning-change audit) assumes a decision trail exists to audit.
2. **OGR-057 — market-data-borne prompt-injection threat model.** Named nowhere in the core docs
   despite the corpus treating it as a real, structurally novel attack surface (injection arriving
   through the price feed itself, not conventional user input). The system will ingest attacker-facing
   token names and on-chain memos before this is designed.
3. **OGR-092 — LLM-inference architecture menu**, including GraphRAG over the belief graph and
   constrained decoding for the strategy DSL. The belief graph itself (OGR-064–069) is solidly PLANNED
   under §1a; how it actually gets queried and how the strategy DSL gets safely generated are not.
4. **OGR-029 — build-sequencing governance** (dependency graph by enabling power, minimum viable
   epistemic core, reversibility classification). This is meta-work about how to build everything else
   in this ledger, and it is itself unadopted — there is no committed order-of-construction beyond the
   `P0`/`P1`/`P2`/`P3` phase tags already in `FEATURES.md`.
5. **OGR-101 — pre-registered project-level abandonment criteria and honestly-stated expected value
   including base rate.** Nothing in `ARCHITECTURE.md`/`DECISIONS.md` currently states, in writing,
   what evidence by what date would mean the whole project should stop — the corpus itself calls this
   out as needing to be "written now, before emotional investment compounds."
