# SDD ledger — plan: docs/superpowers/plans/2026-08-02-layer0-raw-capture.md

Worktree: .claude/worktrees/layer0-raw-capture
Branch: worktree-layer0-raw-capture
Base: master @ f4363ce (plus .gitignore fix on master)

Pre-flight scan:
- Epoch constants verified: 1785648600_000_000_000 -> 2026-08-02T05 UTC, +1h -> T06. Test dates correct.
- Finding A (plan-mandated, needs ruling): Task 8 stats key `dropped` is unreachable until the
  deferred queue task; its test asserts dropped == 0 vacuously.
- Finding B (controller ruling: proceed): Task 11 live test gated on CAPTURE_LIVE=1. Deliberate -
  network dependency; unit tests prove logic, only a live run proves capture.
- Finding C (controller ruling: proceed): BinanceVenue.subscribe_messages returns [] by design -
  required by the venue interface that Hyperliquid implements.

- Finding A ruling (human): KEEP `dropped` stat + assertion, document Task 14 as what makes it live.

Task 1: complete (commits 7860ef6..133fec0, review clean)
Task 2: complete (commits 133fec0..0afe5ae, review clean)
Task 2: minor (deferred): adversarial escape cases (literal backslash-n; trailing backslash) hand-traced correct but not asserted in tests
Task 2: minor (deferred): IndexEntry is frozen with seq: dict -> unhashable; do not use instances as set members or dict keys (carry to Tasks 3/4/8)
Task 2: minor (deferred): _ESCAPES ordering is load-bearing (backslash first) but documented only in module docstring
Task 2: minor (deferred): encode_index_entry "no trailing newline" not directly asserted
Task 2: warning resolved by controller: capture/__init__.py is committed from Task 1; import verified
Task 3: review found 4 Important (all plan-mandated) + 1 minor. Human ruling: REVIEW GOVERNS, fix all.
  1. read_pair unescapes unconditionally -> corrupts payloads containing backslashes (breaks byte-exactness)
  2. .splitlines() over-splits on U+2028/\v/\f/\x85 -> raw/idx desync cascades through rest of file
  3. no exception safety in _open/close -> fd leak on partial open failure
  4. append can desync raw/idx counts if idx write fails after raw write
  5. (minor) hour_key float division loses ns precision at hour boundary
Task 3: fix round 1/5 (4 addressed, 1 open - finding 4 raw/idx desync on mid-write failure still silently mispairs in read_pair; commits 4ac10b5..28ac6cd)
Task 3: fix round 2/5 (finding 4 ADDRESSED both parts; 1 NEW Important - fix diff reverted round-1 n-increment ordering, stale n on idx failure; commits 28ac6cd..5a7caf2)
Task 3: fix round 3/5 (1 addressed, 0 open; commits 5a7caf2..9848073)
Task 3: complete (commits 0afe5ae..9848073, review clean after 3 fix rounds)
Task 4: review found 2 Important + 2 minor.
  I1. reconcile_pair sets esc=False on all recovered entries -> read_pair returns still-escaped text if the lost line was escaped
  I2. _write_lines opens idx with "wb" -> truncates valid index before rewrite; second crash leaves it unreadable
  m3. (deferred) idx longer than raw returns 0, conflating "aligned" with "broken differently"; fails safe via PairLengthMismatch
  m4. _read_lines duplicates read_pair's inline split logic - folding into fix round since that logic caused a severe Task 3 bug
Task 4: fix round 1/5 (3 addressed, 0 open; commits 60cdc69..44b459c)
Task 4: minor (deferred): tempfile.mkstemp gives idx 0600 after first reconcile, diverging from raw file's umask-derived mode
Task 4: complete (commits 9848073..44b459c, review clean after 1 fix round)
Task 5: review Approved, 1 Important (plan-mandated by omission, not by mandate -> controller ruled fix, no human interrupt):
  I1. json.dumps(detail) raises TypeError on bytes/Decimal/set, silently defeating "never drop an anomaly"
  m. (deferred) no fsync - events survive process crash but not OS/power crash
  m. (deferred) event.venue never validated against the ledger's own venue
Task 5: fix round 1/5 (2 addressed, 0 open; commits 9cbe78c..0ef6c1d)
Task 5: minor (deferred): out-of-order arrival (earlier ts_ns after a later one, reopening a rotated-past date) untested; append-mode handles it structurally
Task 5: minor (deferred): test comment claims "first moment of 2026-08-03" but timestamp is T05:30Z
Task 5: note - fix commit incidentally swept in controller's uncommitted plan edits + newly-tracked uv.lock; both belong in repo
Task 5: complete (commits 44b459c..0ef6c1d, review clean after 1 fix round)
Task 6: review Needs fixes, 3 Important (all verified by execution) + 2 minor:
  I1. malformed Binance msg (missing u) absorbed into state as None -> next message treated as "first frame", real break MISSED
  I2. median poisoning: burst of genuine stalls raises threshold (verified 6x50s stalls -> threshold 255s) masking later 40s stall
  I3. warm-up blind spot: no report possible before 12th call; a long gap there is missed AND folded into the baseline
  m. (deferred) warm-up count 10 is a magic number unrelated to window
  m. (deferred) duplicate/replayed Binance message flagged corrupting though it is a replay not a break
Task 6: fix round 1/5 (3 addressed, 0 open; commits f779ad4..a511551)
Task 6: minor (deferred, FOR FINAL REVIEW): excluding flagged stalls from the learning window means a PERMANENT cadence
  slowdown is never re-learned -> alarms on every frame forever. Consequence of the controller-mandated fix, not implementer
  error. Candidate mitigation: accept the new cadence after N consecutive stalls. Alert fatigue is a named system-health
  failure (IDEAS-FRONTIER 11), so triage this before merge.
Task 6: minor (deferred): test comment says six 1s intervals but first is a 60s gap; window gets 5 clean samples not 6
Task 6: complete (commits 0ef6c1d..a511551, review clean after 1 fix round)
Task 7: review Approved (0 Critical/Important). Controller CONFIRMED the reviewer's warning as a real gap -> enters fix loop:
  I1. instruments_url() cannot express the request shape. VERIFIED LIVE: Hyperliquid /info GET -> 405; POST {"type":"meta"}
      -> 232 universe entries with isDelisted present. Binance exchangeInfo GET -> 200. Venues need different method+body.
  m. (deferred, carry to Task 9): parse_instruments returns [] for BOTH malformed payload and genuinely-empty universe;
      downstream an empty result reads as "everything delisted"
  m. (deferred): no test for non-string symbol/coin; isinstance guards handle it correctly by inspection
Task 7: fix round 1/5 (1 addressed, 0 open; commits 7d325c7..a69e940)
Task 7: complete (commits a511551..a69e940, review clean after 1 fix round)
POLICY CHANGE (human, standing): code creation/implementation agents must be sonnet 5 / opus 5 / fable 5. No lesser models.
  Tasks 1-6 implementers were haiku (pre-instruction). Tasks 7-8 sonnet. Tasks 9-13 sonnet+.
Task 8: review Needs fixes, 1 Important + 2 minor. Judgment call (propagate not swallow on write failure) CONFIRMED correct.
  I1. close() aborts on first failing writer -> remaining writers AND the ledger never closed, buffered zstd data lost.
      Verified by repro, not inferred. Same disk-full scenario that triggers the propagate path. Docstring claims the
      opposite guarantee.
  m. (deferred) _tracker_for compares stream without casefold though its cache key is casefolded
  m. (deferred) stats()["control"] never asserted by any test
Task 8: fix round 1/5 (1 addressed, 0 open; commits 3c24324..989bf40)
Task 8: complete (commits a69e940..989bf40, review clean after 1 fix round)

=== OPUS ADVERSARIAL REVIEW OF TASKS 1-6 (human-requested, out-of-band) ===
VERDICT: NOT TRUSTWORTHY. 4 Critical + 4 Important, all verified by execution.
 C1 raw_writer _open uses "wb" -> EVERY open TRUNCATES the hour file. Reachable on the NORMAL restart path
    (venue_recorder closes on every run exit), on close-then-append in same hour, on one out-of-order timestamp,
    and even a FAILED open truncates first then raises. Breaks invariants 1 and 3.
 C2 reconcile_pair assumes missing idx entries are a SUFFIX. A mid-file idx failure yields count-matching but
    MISALIGNED pairs - frame N's bytes labelled with frame N+1's real timestamp/seq. `n` is written but never read.
 C3 torn zstd tail accepted silently: -1 byte lost 397 frames and returned a half-payload as complete. When raw and
    idx lose the same group, counts match and read_pair reports success with frames silently gone.
 C4 _read_lines rstrip("\n") strips ALL trailing newlines -> one trailing empty payload permanently bricks the hour,
    and reconcile_pair refuses to repair it by design.
 I1 close() closes raw first; ENOSPC there leaves idx>raw, the one direction reconcile_pair cannot repair.
 I2 reconcile_pair on a LIVE hour os.replace's the idx while RawWriter holds the old fd -> repair creates a mismatch.
 I3 ledger read_all: one torn line raises and loses ALL intact events for that day.
 I4 sequencing: a stream whose natural cadence exceeds floor_seconds never fills its window - 199/200 false alarms,
    and a real 30-min outage is indistinguishable from the noise.
MUTATION TESTING: 5 mutations ALL pass the 32-test suite, incl. hour_key dropping UTC (passes only because box TZ is
 UTC) and "wb"->"ab" (truncate-vs-append entirely unconstrained - which is why C1 survived 3 fix rounds).
 test_append_increments_n_after_raw_write_not_idx_write asserts as CORRECT the exact state that produces C2.
 Correction: encode_index_entry's no-trailing-newline IS constrained - drop that from the known-minors list.
OPUS CORE FIX WAVE: all 4 Critical + 4 Important fixed. 60 -> 89 tests. All 8 mutations killed incl. "ab"->"wb" and
  hour_key-drops-UTC. Commits 989bf40..03ea320.
  HUMAN RULING: damaged hour stays REFUSED (HourFileNotAppendable) - detection over continuity.
  FOLLOW-UP (for a later task, not now): auto-run reconcile_pair at startup, which converts the refusal into a non-issue.
  DEFERRED for final review: staleness statistic changed median -> p25. 10*p25 is TIGHTER than 10*median on bursty
    streams, so expect more alarms on legitimately variable venues. Both are constructor params. Watch in live smoke.
  NOTE: controller's suggested C3 fix was WRONG - ZstdDecompressor.decompress() raises on valid stream-written frames.
    Fixer used decompressobj().eof instead and verified before relying on it.
OPUS RE-REVIEW OF FIX WAVE: all 8 original findings ADDRESSED (I8 incompletely). 17/18 mutations killed.
  NEW CRITICAL: torn hour bricks the ENTIRE venue recorder permanently. HourFileNotAppendable advertises
    reconcile_pair as the remedy, but reconcile_pair raises TruncatedFrameFile on the same file. No path back.
    VenueRecorder.consume does not guard append -> unwinds the loop, so even undamaged streams never get files.
    The human's ratified "refuse over continue" ruling rested on a FALSE PREMISE (that repair worked).
  NEW IMPORTANT: p25 reintroduces the I8 class on BURSTY streams - 57% of frames flagged, permanent not warmup.
    Measured alarm inflation p25 vs median on healthy streams: 61v3, 43v9, and 339v5. Fixer's "could alarm sooner"
    understated a 20-60x increase.
  M16 SURVIVED: escape_payload skipping backslash escaping passes all 89 tests. Pre-existing gap in test_frame_codec.
  Remaining risk noted: a 1-byte chop on the idx loses ALL 200 timestamps (kind=recovered, t_recv_ns=0) while
    "reconcile repaired 200/200" reads reassuringly. Marker race in _open. pytest-randomly not installed so
    -p no:randomly in the report is a no-op and order has never been shuffled.
OPUS FIX ROUND 2: Critical crash-loop + p25 bursty regression + M16 + 2 minors all fixed. 89 -> 105 tests,
  verified under shuffle seeds. Commits 03ea320..326f284.
  - refuse -> repair -> resume now TERMINATES; repair quarantines originals byte-for-byte, returns RepairOutcome
    (not an int) so losses are reported not implied.
  - blast radius contained: a damaged hour quarantines only its own (stream,symbol); sibling stream went 0 files -> recording.
  - sequencing needed a MECHANISM change not a constant: stall-contaminated and bursty windows are structurally
    identical bimodal distributions, so no single quantile satisfies both. Added p99 routine-ceiling term + learn from
    every gap unless > 3x threshold. Bursty 66/69/59/58 -> 13/2/1/2 alarms per 100. All four requirements hold.
  - fixer self-caught a dead end in its own round-2 change (raw-first ordering reintroduced an unrepairable state);
    also flagged that the two orderings are byte-identical in size, defeating .pyc mtime+size caching -> stale result once.
HUMAN RULING: zstd flush cadence = every ~30s. MEASURED trade-off on one hour of one depth stream (19.7 MB raw):
  none=4.35MB/loses whole hour; ~100s=4.35MB(-0.1%)/0.55MB; ~30s=4.43MB(+1.8%)/0.16MB; ~10s=4.45MB(+2.4%)/0.05MB.
  Chose 30s: bounds crash loss to ~300 frames for +1.8% (~7 GB over the full 400 GB runway).
FLUSH ROUND 3: 30s cadence implemented, 105 -> 118 tests, verified under shuffle seeds. Commit c09c92b.
  CONTROLLER MEASUREMENT ERROR, corrected by the fixer: my table modelled random truncation; kill -9 only loses bytes
  not yet handed to the OS, and zstd's ~128KB block already bounds loss to ~134 frames. Real effect of 30s cadence:
  fast depth stream UNCHANGED (134 frames ~13s, +0.37% size); slow 8s l2Book 134 frames (~18 MIN) -> 3 frames (+18.7%,
  22 KB/hr). Ruling stands but for the opposite reason presented.
  ALSO: fixer corrected its own round-2 "one byte costs the whole hour" - true only for single-block files; at realistic
  hour sizes a torn tail costs only the last block.
  FLAGGED NOT DECIDED: bounding fast streams needs ~10s or a byte-count term in the trigger.
Task 9: implemented (6faee4e, ab59c83). 118 -> 157 tests, 21/21 mutations killed.
  Hazard handled by REFUSING not guessing: empty universe always refused (no venue observed empty); delisting of
  >max_delisted_fraction(0.5) of a universe >=10 refused too, since partial parse failure looks identical.
  On refusal nothing is written, so the next healthy poll diffs against the last good universe.
  Event record fsynced BEFORE state advances (reverse order would lose transitions permanently).
  LOOSE END (must be closed by the integration task): a refusal is only an exception. Whoever calls record_snapshot
    MUST record it to the capture ledger, or universe capture stops advancing SILENTLY - which is the exact failure
    R2 exists to prevent.
  DEFERRED: directory entries not fsynced (power-loss only, degrades to a missing transition not a wrong one).
    raw_writer does not fsync at all -> decide for the whole capture layer, not here.
  DEFERRED: no concurrency control; single capture process per venue assumed, violation undetected.
  Self-review post-GREEN caught 2 real defects (bare string diffed char-by-char; non-int ts_ns wrote unreadable state).
  Fixer disclosed its first mutation harness run falsely reported 19/19 by running pytest in the wrong directory.
Task 9: complete (commits c09c92b..ab59c83, review APPROVED first pass, 0 Critical/Important).
  Reviewer independently authored 9 mutations (overlapping but not identical), all killed; reproduced the crash-window
  replay by forcing os.replace to fail mid-record_snapshot -> duplicate-not-wrong events, as claimed.
  Minor (deferred): state file 0600 via mkstemp; _MIN_UNIVERSE_FOR_MASS_DELISTING_GUARD=10 is a module constant not a param.
Task 10: implemented (2a6a724, 63a4333, 17fde80). 157 -> 194 tests, 33/33 mutations killed.
  3 mutations survived the first pass and found real bugs: count included suppressed alerts; all gap severities could
  collapse into `corrupting` unnoticed (the alert-fatigue mutation); nothing checked the alert was fsynced before
  being counted as written.
  CONTROLLER RATIFIES concern 3: first day of capture cannot raise an absence alert (an `uninitialised` band exists so
    a fresh install does not alert). Accepted - day 1 is operator-attended anyway while B2 is unresolved, and inverting
    it would make every fresh install cry wolf. Revisit once capture is unattended.
  DEFERRED: nothing calls this yet and free_bytes has no producer -> component is INERT until wired to a schedule.
    This is the MEMORY.md lesson (green suite != firing in production) and must be closed by the wiring task.
  DEFERRED: measure_daily_bytes walks the whole raw/ tree (~1e5 stats at 90d retention).
Task 10: complete (commits ab59c83..17fde80, review APPROVED first pass, 0 Critical/Important).
  Reviewer independently ran 6 mutations, all killed; independently confirmed by grep that nothing calls
  capture_health and no free_bytes producer exists -> honest disclosure, not hidden defect.
  Minor (deferred): 381-line module blends 4 concerns; alert-writing block (~85 lines) is a candidate split later.

*** WIRING GAPS FOR THE FINAL REVIEW - three components are built but not connected ***
  W1 (Task 9): a universe refusal is only an exception. Nothing records it to the capture ledger, so universe capture
     can stop advancing SILENTLY - the exact failure R2 exists to prevent.
  W2 (Task 10): nothing calls capture_health and free_bytes has no producer anywhere. The health component is INERT.
     This is precisely the MEMORY.md lesson: a green suite proves logic, not that the thing is firing.
  W3 (plan self-review, Task 14): the bounded queue that makes stats()["dropped"] reachable was never written, so the
     7-day unattended acceptance criterion in spec 7.3 cannot currently be met.
Task 11: implemented (370d200). 194 -> 211 tests (+1 skipped offline), 13/13 mutations killed.
  LIVE RUN SUCCEEDED: 853 frames in 30s over BTC/ETH/SOL, 1.16 MB wire text -> 240 KB in 6 files, contiguous index,
  intact U/u/pu chains, every stored line byte-identical to text teed off the socket. Byte-exactness proven on REAL data.

*** CRITICAL LIVE FINDING (controller independently reproduced, no capture code involved) ***
  Three of four core Binance channels deliver ZERO frames from this host. Measured, 12s each:
    depth@100ms 117 | bookTicker 266 | trade 501   <- WORK
    aggTrade 0 | markPrice@1s 0 | forceOrder 0 | kline_1m 0 | miniTicker 0 | !forceOrder@arr 0   <- SILENT
  REST /fapi/v1/aggTrades returns data fine, so the venue has it; a subset of WEBSOCKET streams is silent here.
  FIX AVAILABLE AND BETTER: @trade works (501 frames) and is INDIVIDUAL trades, strictly more raw than @aggTrade.
  UNRESOLVED: funding (markPrice) and liquidations (forceOrder) have no working websocket path from this host.
  Had this shipped, the archive would have silently contained depth only - no trades, no funding, no liquidations -
  and none of it recoverable later. This is exactly why the live smoke test exists.

*** RESEARCH RESULT — all gaps resolved empirically, no documentation trusted ***
  FUNDING/MARK/OI: websocket path is dead from this host for Binance (every markPrice variant tested = 0 frames).
    SOLUTION, and it is BETTER than the spec's websocket approach:
      Binance REST /fapi/v1/premiumIndex with NO symbol -> 854 symbols in ONE call (markPrice, indexPrice,
        lastFundingRate, nextFundingTime). Binance REST /fapi/v1/openInterest per symbol.
      Hyperliquid ws activeAssetCtx WORKS (funding, openInterest, premium, oraclePx, markPx, midPx) AND
        REST metaAndAssetCtxs -> 232 assets + 232 contexts in ONE call.
    Per-symbol ws streams would need hundreds of subscriptions to match one poll -> materially improves R1 broad tail.
  LIQUIDATIONS: Binance has NO public path (allForceOrders 404, forceOrders 401 = auth + own-orders-only).
    Bybit allLiquidation/liquidation: subscribe acked, 0 data in 25s - inconclusive (episodic).
    OKX liquidation-orders instType=SWAP WORKS: real market-wide liquidation received within 25s from this host.
  HUMAN RULING: add OKX as a REFERENCE-ONLY feed. Market data only, never an execution venue, read-only forever.
    Rationale: liquidation cascades are cross-venue correlated and forced non-discretionary flow is the most durable
    edge class in the research corpus; the data is unrecoverable if not captured now.
  SPEC CHANGE REQUIRED: core tier is no longer "websocket streams" only. It is ws for depth+trades, REST poll for
    funding/OI, plus an OKX reference feed for liquidations.
Task 11: fix round 1 (97d1a8b) verified live. 90s run: 10,625 frames; trade 1,697/5,614/721 FLOWING; markPrice 0,
  forceOrder 0; six silent_stream events written to the ledger MID-RUN at 60.016s. 218 tests +1 skipped.
  Implementer disclosed 1 surviving mutation as a true equivalent mutant - reviewer independently CONFIRMED it is
  genuinely equivalent (.get(event, event) already returns "trade"), not self-grading cover.
Task 11 review: APPROVED, 2 Important -> fix round 2:
  I1. Silence detection only covers streams that NEVER speak. A stream that speaks once then dies is permanently
      invisible: _record_silent_streams excludes any key already in _writers, and only depth/l2Book have staleness
      trackers. trade/markPrice/forceOrder have NO owner - and trade is the channel currently flowing live.
      The docstring at venue_recorder.py:162-163 claims this is "already owned by the staleness and gap trackers".
      That claim is FALSE. Reviewer proved it empirically.
  I2. silent_stream events never reach capture_health's report - build_report only buckets kind=="gap" or CORRUPTING.
      "The silence is no longer silent" holds only for someone reading ledger/*/events.ndjson directly.
Task 11: fix round 2 (a4ced5a). 218 -> 231 tests, 12/12 mutations killed. Live 90s: 6,241 frames, 6 silent_stream
  events at 60.055s, NO new gap events, health surfaced silent_streams=6 + 1 alert.
  KEY INSIGHT from the implementer: attaching a tracker per stream is NOT sufficient - every tracker is FRAME-DRIVEN,
  so a dead stream sends nothing for its own tracker to run on. Silence must be judged on when a stream LAST spoke.
  It also tried relaxing the learning rule, the EXISTING stall-poisoning test caught it, and it reverted and recorded
  the failed attempt in the code.
Task 11 re-review round 2: I1 + I2 CONFIRMED FIXED for the reproduced cases (reviewer reproduced both independently
  with its own scripts and a different seed/distribution: 1.0% alarm rate vs the earlier 57% storm).
  NEW IMPORTANT - same bug class as Task 6, new location:
    _widest_gap_ns folds EVERY gap in via monotonic max() with no cap, no decay, and NO exclusion of gaps that were
    themselves reported as stalls. threshold = max(grace, 3 x widest). Reproduced: settled stream + one genuine 600s
    stall -> threshold 1800s; after 300s of TRUE silence (5x the grace) no silent_stream event fires. A health check
    on a few-minute interval never sees the dead stream. StalenessTracker excludes stalls from its window for exactly
    this reason; the recorder's bookkeeping does not.
  Out-of-scope: bursty test is vacuous in ISOLATION (mutating _tracker_for to None still passes it) though a sibling
    test catches the regression; --silence-grace-seconds lacks the negative guard that --seconds has.
*** B1 RESOLVED 2026-08-02 *** bucket gs://capture-raw-data4134 + roles/storage.objectAdmin granted to
  1095194309870-compute@developer.gserviceaccount.com. scripts/verify_gcs_write.sh passes end-to-end:
  upload / read back / list / BYTE-EXACT compare / delete. archive_offloader is UNBLOCKED and can now be built.
  Note: the script compares the round trip byte-for-byte rather than trusting exit 0 - a silently corrupting
  upload is the exact failure mode this project exists to avoid.
Task 12: complete (script written, executed, spec B1 marked resolved).
Task 13 / B2: the proposed @reboot CRON MITIGATION IS DEAD - cron is NOT INSTALLED on this box (no crontab binary,
  no daemon), and installing it needs apt-get -> sudo -> denied. linger also denied. Both stated mitigations gone.
  REPLACEMENT FOUND, and it is better: GCE startup-script metadata runs AS ROOT at every boot via
  google-guest-agent.service, which is already ENABLED here. No install, no linger, no sudo on the VM.
  BLOCKED ON OPERATOR: this SA lacks compute.instances.get, so metadata must be set from the console.
  Instance: instance-20260801-081737, zone asia-south1-c. No startup-script currently set (metadata has only ssh-keys).
  scripts/reboot_probe_startup_script.sh written for pasting; the recorder launch is left COMMENTED so that proving
  the boot hook fires stays separate from proving the recorder survives - conflating them makes a failure ambiguous.
Task 11: fix round 3 (bcc0676). 231 -> 236 tests, 10/10 mutations killed.
  CONTROLLER INSTRUCTION WAS WRONG AND THE IMPLEMENTER CORRECTLY REJECTED IT. I said "exclude stalls from the
  estimator". That breaks slow streams: on first sight a 200s gap on a 200s-cadence stream is indistinguishable from
  a 200s stall on a 1s stream, so exclusion discards exactly the evidence a slow stream needs and reports it dead
  every session. Repetition, not one-off magnitude, is what separates a stall from a slow cadence -> stalls are
  OUTVOTED (0.90 quantile over a bounded 200-gap window, floored at grace, capped at 1h), not excluded.
  The re-reviewer INDEPENDENTLY IMPLEMENTED my suggested exclusion fix and reproduced the failure: a healthy 200s
  stream reported dead after 100s. Rejection verified, not merely argued.
  Also: implementer disclosed one of its OWN tests was not testing what it claimed (first aging test passed even with
  an unbounded window) and replaced it with a regime-change test.
Task 11: complete (commits 17fde80..bcc0676, review clean after 3 fix rounds).

*** ALL IMPLEMENTATION TASKS COMPLETE (1-11) + Task 12 (B1 resolved). Task 13 (B2) blocked on operator console. ***

=== FINAL WHOLE-BRANCH REVIEW (opus) — 41 commits, 2566 lines, 236 tests, 46 mutations run ===
VERDICT: merge as a LIBRARY yes; run UNATTENDED no.
 C1 venue_recorder.py:160 quarantine is per-STREAM for process life, but HourFileNotAppendable names one HOUR.
    Verified: damage T05 -> T06 and T07 never written though undamaged. One torn hour costs the stream every
    remaining hour, and the loss total only reports at close(), which an unattended run never reaches.
 C2 silent-stream detection is SESSION-scoped; capture_health is DAY-scoped. Verified over 4 days with 3/4 streams
    dead from day 1: days 3-4 report status=present silent_streams=0. Clean bill of health on a dead capture.
 C3 UniverseTracker has ZERO callers outside tests. No HTTP client, no poller, no scheduler. Guarantee 6 is NOT
    delivered by the running system. My W1 understated it - the issue is record_snapshot is never called at all.
 I4 main() catches only KeyboardInterrupt; no gap_on_restart event exists anywhere though spec 6 mandates one.
 I5 flush() ordering docstring claims load-bearing; mutation N3 (swap to index-first) PASSED ALL 236 TESTS and
    produces the one direction reconcile_pair refuses. close()'s identical claim IS constrained; flush()'s twin is not.
 I6 fsync posture is accidental: raw_writer 0, capture_ledger 0, universe_tracker 2, capture_health 1.
 I7 _open does not consult is_hour_being_written, so two capture processes interleave zstd frames in one file.
 Minor: hour_key float-division fix applied in raw_writer but NOT in capture_ledger/universe_tracker (verified
    midnight-1ns lands on the wrong date); quantile_ns index formula unconstrained (N14 survived); \r escaping
    unconstrained (N6 survived); double-close clear unconstrained (N20 survived).
 REVIEWER CORRECTED THE PLAN'S OWN SELF-REVIEW: W3 (bounded queue) is NOT the 7.3 blocker. consume reads the socket
    directly so a slow writer applies TCP backpressure rather than dropping - that PRESERVES guarantee 3. Building a
    dropping queue would trade a guarantee-preserving failure for a guarantee-violating one. Do not build it.
 Triage: 8 must-fix before unattended, 21 can wait. Several deferred items already closed by later work.
