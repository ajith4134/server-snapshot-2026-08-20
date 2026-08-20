# Requirements Ledger — PARTIAL — nse-crypto-bot-final, ops/security/governance/intelligence/observability

**Status: PARTIAL.** The four category-slice merge agents hit the session limit and died before writing
their files. This slice came back as a message from a sub-agent and was transcribed to disk by the
orchestrating session to prevent loss. Content unaltered.

Merged 2026-08-08. Source slice: 290 raw rows from `nse-crypto-bot-final`. ~44 rows collapsed as
duplicate citations of the same capability; 5 near-identical "watched a reference video" rows merged
to one. Net ~250 rows. SciBrain rows: 0 in this slice (`grep -in "scibrain\|signals/"` over the full
input returned no matches) — that content lives in an unmerged slice.

**Caveat that travels with every PRIOR-ART row:** `prior-attempts-postmortem.md` §3.2–3.3 records that
documentation outgrew validated results and the validation target was substituted for synthetic data.
PRIOR-ART means working code exists. It never means proven.

---

## Brain layer

| Requirement | Category | Status | Evidence | Notes |
|---|---|---|---|---|
| Ephemeral web-agent transparency feed | observability | PRIOR-ART | trading/brain/activity_feed.py:40,62 | |
| Instruction bandit selection | intelligence | PRIOR-ART | trading/brain/apply.py:38 | |
| Boss command engine (NL directive execution) | governance | PRIOR-ART | trading/brain/boss.py:185,649 | |
| Brain-OS kernel + working memory + "top" health view | operations | PRIOR-ART | trading/brain/brain_os.py:46,204; research/brain-os/DESIGN.md:9-36 | Collapsed 2 rows describing the same module from a design doc and a top-view angle |
| Daily morning briefing generator | observability | PRIOR-ART | trading/brain/briefing.py:41 | |
| Connectivity / orphan-module watchdog | operations | PRIOR-ART | trading/brain/connectivity_monitor.py:59 | Collapsed a duplicate citing it from a session-state doc |
| Neuron consult/grade bridge | intelligence | PRIOR-ART | trading/brain/consult.py:28,48 | |
| Credential chat capture | security | PRIOR-ART | trading/brain/credential_chat.py:145 | |
| Encrypted credential vault (site logins) | security | PRIOR-ART | trading/brain/credentials.py:55 | Fernet site-login vault with chat-fulfilled pending requests — different mechanism from the current `src/cost/secret_store.py` sops+age reader. Not CLAIMED |
| Decision memory (episodic case store + reflections) | intelligence | PRIOR-ART | trading/brain/decision_memory.py:65 | |
| Direction decision ledger (auditable per-trade "X-Ray" votes) | governance | PRIOR-ART | trading/brain/direction_ledger.py:20,73 | |
| Live discovery-signal feed into trading | intelligence | PRIOR-ART | trading/brain/discovery/signal.py:44 | |
| Instruction evolution loop (mutate/promote/retire, GEPA) | intelligence | PRIOR-ART | trading/brain/evolution.py:39 | |
| Strategy/lane cause-of-death graveyard | governance | PRIOR-ART | trading/brain/graveyard.py:28 | |
| Computer-use agent loop (dashboard) | intelligence | PRIOR-ART | trading/brain/gui/agent.py:32 | |
| Dashboard perception (SEE layer) | observability | PRIOR-ART | trading/brain/gui/perception.py:307,327 | |
| Reflexion-style self-critique (GUI) | intelligence | PRIOR-ART | trading/brain/gui/reflection.py:39 | |
| Growing GUI skill library (Voyager pattern) | intelligence | PRIOR-ART | trading/brain/gui/skills.py:54 | Distinct from the trading-domain skill library in the T8 composite |
| Dashboard target registry | operations | PRIOR-ART | trading/brain/gui/targets.py:74 | |
| Autonomous read-only web screener | intelligence | PRIOR-ART | trading/brain/gui/web_screener.py:41 | |
| Agent-workflow-memory induction | intelligence | PRIOR-ART | trading/brain/induction.py:53,76 | |
| Instruction lifecycle engine (follow/grade/edit/mutate/crossover/spawn/retire, Pareto archive) | intelligence | PRIOR-ART | trading/brain/instructions.py:56 | |
| Continuous autonomous learning loop | intelligence | PRIOR-ART | trading/brain/learn_loop.py:35 | |
| Self-directed learning + self-evaluation | intelligence | PRIOR-ART | trading/brain/learner.py:21 | |
| Per-symbol closed-trade lesson recall | intelligence | PRIOR-ART | trading/brain/lesson_recall.py:48,61 | |
| Cross-session full-text memory search | observability | PRIOR-ART | trading/brain/memory_search.py:115 | |
| Brain-wide mind-event bus (Stream of Mind) | observability | PRIOR-ART | trading/brain/mind_events.py:52,68 | |
| Brain reasoning tracer | observability | PRIOR-ART | trading/brain/observability.py:39 | Distinct from core/observability.py (Langfuse) |
| Brain hub meta-controller (regime probs, AdaHedge/EXP3 trust, drift sentries, champion manager) | governance | PRIOR-ART | trading/brain/regime_hub.py:264,207 | |
| Autonomous web researcher | intelligence | PRIOR-ART | trading/brain/researcher.py:52 | |
| Autonomous R&D drive | intelligence | PRIOR-ART | trading/brain/rnd.py:110 | |
| Reflexion self-critique after closed trades | intelligence | PRIOR-ART | trading/brain/selfeval.py:77,98 | |
| Semantic text memory (mem0) | intelligence | PRIOR-ART | trading/brain/semantic.py:33 | |
| Scientific-method rails for self-tuning optimizers | governance | PRIOR-ART | trading/brain/surface.py:82,152 | |
| Per-market-scoped closed-trade learning hook | intelligence | PRIOR-ART | trading/brain/trade_learn.py:15 | |
| Brain-ultra glue (associative + file memory, micro-transformer) | intelligence | PRIOR-ART | trading/brain/ultra.py:27,48 | |
| Free computer-use loop (broker browser) | intelligence | PRIOR-ART | trading/brain/vision/computer_use.py:107,45 | |
| Fast/accurate navigation planner | operations | PRIOR-ART | trading/brain/vision/fast_nav.py:59,101 | |
| Local grounded-eyes UI element detection + OCR-first perception | intelligence | PRIOR-ART | trading/brain/vision/grounded_eyes.py:51; research/free-local-eyes.md | Folded in the design note behind its fallback ladder |
| Ocular cortex (iconic/working/episodic visual memory) | intelligence | PRIOR-ART | trading/brain/vision/ocular_cortex.py:65,119,217 | |
| UI-TARS end-to-end GUI grounder | intelligence | PRIOR-ART | trading/brain/vision/uitars_grounder.py:138 | |
| Cognitive-loop flow-health monitor (file-age based) | observability | PRIOR-ART | trading/brain/flow_health.py:65 | Implements the "check file mtime, not code wiring" lesson |
| School curriculum L0-L6, exam-gated, measured L5 | intelligence | PRIOR-ART | trading/brain/school.py; research/brain-ultra-upgrade/GOAL.md:66-88 | |

## Broker sense / execution surface

| Requirement | Category | Status | Evidence | Notes |
|---|---|---|---|---|
| Broker-app registry + execution role enforcement | security | PRIOR-ART | trading/broker_sense/brokers.py:25,154 | The structural chokepoint — vision/LLM layers physically cannot submit an order |
| Stealth browser driver selection | security | PRIOR-ART | trading/broker_sense/browser_launch.py:44 | |
| Per-broker public-vs-account data source switch | governance | PRIOR-ART | trading/broker_sense/data_sources.py:33,38 | |
| Unmapped endpoint discovery | observability | PRIOR-ART | trading/broker_sense/endpoint_discovery.py:62 | |
| Feed schema-drift self-healing watchdog | operations | PRIOR-ART | trading/broker_sense/feed_selfheal.py:75,45 | |
| Human CAPTCHA handoff | operations | PRIOR-ART | trading/broker_sense/human_handoff.py:222 | |
| Interactive remote-view browser login | operations | PRIOR-ART | trading/broker_sense/live_browser.py:222 | |
| Live video screen mirror (MJPEG) | observability | PRIOR-ART | trading/broker_sense/live_mirror.py:63 | |
| Hot watchlist with TTL | operations | PRIOR-ART | trading/broker_sense/watchlist.py:18 | |
| Eyes-brain-hand-memory self-health check, no fabricated green | observability | PRIOR-ART | trading/broker_sense/ui_health.py:74 | Same "measured, never asserted" philosophy as the current `src/statuswall/`, different target system |
| Persistent logged-in broker session manager | security | PRIOR-ART | trading/broker_sense/sessions.py:377 | |
| Browser fingerprint stealth hardening | security | PRIOR-ART | trading/broker_sense/stealth.py:74 | |
| Screen-mirror action logging | observability | PRIOR-ART | trading/broker_sense/screen_mirror.py:58,153 | |
| Event-driven funnel scheduling | operations | PRIOR-ART | trading/broker_sense/run_funnel_loop.py:25,57 | |

## Strategy / crypto lanes

| Requirement | Category | Status | Evidence | Notes |
|---|---|---|---|---|
| Live autoresearch driver loop | operations | PRIOR-ART | trading/strategy/autoresearch.py:1-283 | |
| Champion/challenger lineage ledger | governance | PLANNED (P2) | not built | FEATURES.md:69; ARCHITECTURE.md:222 "Shadow Before Swap". Prior repo's trading/strategy/generators/base.py:186-211 is a reference implementation |
| Evolution engine kill-switch (feature gate) | governance | PRIOR-ART | trading/strategy/control.py:1-15 | |
| Strategy catalog registry + coverage stats | governance | PRIOR-ART | trading/strategy/library/registry.py:1-16 | |
| Persisted crypto watchlist | operations | PRIOR-ART | trading/crypto/watchlist.py:1-10 | |
| Crypto T2 session orchestrator | operations | PRIOR-ART | trading/crypto/session.py:1-16 | |
| Crypto trading config (paper/live) | governance | PRIOR-ART | trading/crypto/config.py:1-9 | |
| Freqtrade config generator | operations | PRIOR-ART | trading/crypto/freqtrade/config_template.py:1-9 | |
| Freqtrade launch helper | operations | PRIOR-ART | trading/crypto/freqtrade/launch.py:1-10 | |
| Guarded paper↔live / spot↔futures switch | security | PRIOR-ART | trading/crypto/freqtrade/control.py:1-19 | |
| Freqtrade closed-trade ingestion bridge | operations | PRIOR-ART | trading/crypto/freqtrade_ingest.py:1-9 | |
| Lens-lane: orphaned-signal attribution trades | intelligence | PRIOR-ART | trading/crypto/freqtrade/brain_executor.py:699-777 | |
| CORTEX shadow/replace signal lane | intelligence | PRIOR-ART | trading/crypto/freqtrade/brain_executor.py:~1589-1620 | |
| Per-coin strategy table daemon | operations | PRIOR-ART | trading/crypto/freqtrade/strategy_table.py; run_strategy_table.py | |
| Nightly micro-distillation daemon | operations | PRIOR-ART | trading/crypto/freqtrade/run_micro_distill.py:1-13 | |
| Brain closed-learning loop (hypothesis testing, research synthesis, world-model/MuZero direction check) | intelligence | PRIOR-ART | trading/crypto/freqtrade/brain_learning.py:1-18 | |
| Entry-metadata sidecar store | observability | PRIOR-ART | trading/crypto/freqtrade/entry_meta.py:1-16 | |
| Continuous candle-updater daemon | operations | PRIOR-ART | trading/crypto/freqtrade/candle_updater.py:1-16 | |
| Same-origin dashboard overlay writer | observability | PRIOR-ART | trading/crypto/mlnb_writer.py:1-15 | |
| Brain→Freqtrade loop driver | operations | PRIOR-ART | trading/crypto/freqtrade/run_brain_loop.py:1-11 | |
| Market-symbol isolation guard | security | PRIOR-ART | trading/market_guard.py:34-78 | Plausibly built in response to the 2026-07-13 isolation audit below |
| Autonomy-earned gate checklist (paper days, trade count, baseline beat, drawdown) | governance | PLANNED | trading/evidence.py:226-253 is the prior reference | Current DECISIONS.md §5 plans a gated-live step; exact criteria unspecified |
| Mirror Gate (inverts/abstains unreliable direction sources via Wilson CI) | governance | PRIOR-ART | trading/direction/mirror_gate.py:48-190 | |
| Fill-slippage grading | observability | PRIOR-ART | trading/execution/exec_choice.py:223-283 | |
| Market calendar + LIVE/REPLAY switch | operations | PRIOR-ART | trading/online/session.py:27-107 | |
| Always-on online supervisor | operations | PRIOR-ART | trading/online/supervisor.py:32-154; run_online.py | |
| Shared persisted control surface (start/stop/pause/halt/panic) | operations | PRIOR-ART | trading/online/controls.py:32-231 | |
| On-chain source wired into direction ledger | intelligence | PRIOR-ART | trading/direction/onchain_source.py:29-92 | |
| Sandbox loop driver | operations | PRIOR-ART | trading/sandbox/run_sandbox_loop.py | |

## Journal / alerts / direction

| Requirement | Category | Status | Evidence | Notes |
|---|---|---|---|---|
| 85+ column closed-trade schema | observability | PRIOR-ART | trading/journal/schema.py:20-260+ | |
| Journal analytics rollup | observability | PRIOR-ART | trading/journal/analytics.py:44-241 | |
| HTML performance tearsheet | observability | PRIOR-ART | trading/journal/tearsheet.py:38-352 | |
| TradeJournal orchestrator + poison-row guard | governance | PRIOR-ART | trading/journal/journal.py:69-222 | |
| Revenge-trade / overtrading detector + Brier-calibrated Bayesian win-rate confidence | observability | PRIOR-ART | run_journal_t5.py | |
| Closed-trade reset tool | operations | PRIOR-ART | trading/journal/reset.py:38-188 | |
| Telegram alert pipeline | observability | PRIOR-ART | trading/alerts/{__init__,dispatcher,channels}.py | |
| Alert deduplication | observability | PRIOR-ART | trading/alerts/dedup.py:17-37 | |
| Telegram command router | operations | PRIOR-ART | trading/alerts/commands.py:45-247 | |
| Scheduled daily/weekly reports | operations | PRIOR-ART | trading/alerts/scheduler.py:20-75 | |
| Secrets-redacted alert config | security | PRIOR-ART | trading/alerts/config.py:22-46 | |
| Closed-trade lesson-prior lens | intelligence | PRIOR-ART | trading/direction/lesson_prior.py:73-192 | |
| Brain-lens direction sources (hypothesis ledger, experience bank, news, world-model, concept discovery) | intelligence | PRIOR-ART | trading/direction/brain_sources.py:84-436 | |
| Research-context briefs, read-only, never a vote | intelligence | PRIOR-ART | trading/direction/research_context.py:26-67 | |
| Per-candidate vote log | observability | PRIOR-ART | trading/direction/vote_log.py:33-41 | |
| Goal scoreboard | governance | PRIOR-ART | trading/goal.py:31-198 | |
| Smart-money scout swarm (scouts + consensus oracle + read-only dispatcher) | intelligence | PRIOR-ART | trading/scouts.py:52-304 | |
| Anti-overfit telemetry | governance | PRIOR-ART | trading/antioverfit.py:27-74 | |
| Feature-connectivity audit (PRESENT/STALE/DISCONNECTED, trade-artifact based) | governance | PRIOR-ART | trading/connectivity_check.py:52-129 | |
| Persisted NSE watchlist | operations | PRIOR-ART | trading/watchlist.py:32-97 | |
| NSE session orchestrator | operations | PRIOR-ART | trading/session.py:27-82 | |
| Central trading config (NSE) | security | PRIOR-ART | trading/config.py:40-104 | |

## Core / cognition / memory

| Requirement | Category | Status | Evidence | Notes |
|---|---|---|---|---|
| Live node registry / dashboard sync | observability | PRIOR-ART | core/registry.py | |
| LangGraph brain agent (recall→respond, memory-grounded fallback) | intelligence | PRIOR-ART | core/brain_agent.py:20-95; memory/brain.py; run_brain_agent.py | |
| Durable LLM/agent observability (Langfuse) | observability | PRIOR-ART | core/observability.py | |
| Per-provider LLM call telemetry + cooldown | observability | PRIOR-ART | core/llm_telemetry.py | |
| RAG chat grounded in the brain's own state | intelligence | PRIOR-ART | core/chat_brain.py | |
| Honest live system map, never-asserted node status | observability | PRIOR-ART | core/system_map.py | Kindred to current statuswall, different target |
| Multi-provider cloud-LLM failover | intelligence | PRIOR-ART | core/llm.py | |
| Per-provider LLM rate-limit budget + local fallback | operations | PRIOR-ART | research/ai-scientist/ideas-ledger.md:181 | Ideas-ledger evidence only, lower confidence |
| Vision-LLM failover | intelligence | PRIOR-ART | core/llm.py:100-118 | |
| Active-inference surprise + curiosity (pymdp) | intelligence | PRIOR-ART | cognition/active_inference.py | |
| ReAct + Tree-of-Thoughts reasoning | intelligence | PRIOR-ART | cognition/reasoning.py | |
| Traceable symbolic reasoning over the knowledge graph | intelligence | PRIOR-ART | cognition/neuro_symbolic.py:35-152 | |
| Causal effect estimation + refutation (DoWhy/causal-learn) | intelligence | PRIOR-ART | cognition/neuro_symbolic.py:180-224 | |
| Conformal calibration & answer/abstain gate | governance | PRIOR-ART | cognition/calibration.py | |
| Constitution self-audit guardrails (NeMo-Guardrails) | governance | PRIOR-ART | cognition/guardrails.py | |
| Deliberate cognition orchestrator (Thinker chain) | intelligence | PRIOR-ART | cognition/thinker.py | |
| Process-reward step verifier + best-of-N | governance | PRIOR-ART | cognition/verifier.py | |
| Society-of-mind internal debate (bull/bear/risk-officer) | intelligence | PRIOR-ART | cognition/society.py | Direct ancestor of the BULL/BEAR/arbiter design |
| Persistent identity / persona self-model (Letta) | intelligence | PRIOR-ART | cognition/identity.py | |
| Affect / mood channel | intelligence | PRIOR-ART | cognition/affect.py | |
| Multimodal senses (hear/speak/see) | intelligence | PRIOR-ART | cognition/multimodal.py | |
| Embodiment personality orchestrator | intelligence | PRIOR-ART | cognition/embodiment.py | |
| Stream-of-mind + global workspace | intelligence | PRIOR-ART | cognition/stream_of_mind.py | |
| Autonomous self-coding node invention (ADAS pattern) | intelligence | PRIOR-ART | cognition/self_coding.py | |
| Sandboxed subprocess execution for self-coded candidates | security | PRIOR-ART | cognition/self_coding.py:150-192; cognition/_sandbox_worker.py | |
| Deep Knowledge Tracing mastery model | intelligence | PRIOR-ART | memory/knowledge_tracing.py | |
| Claude-Code-style file memory | intelligence | PRIOR-ART | memory/file_memory.py | |
| NetworkX knowledge graph + personalized-PageRank recall | intelligence | PRIOR-ART | memory/graph.py | |
| Autonomous internet-reading loop (Librarian) | intelligence | PRIOR-ART | memory/librarian.py | |
| Neural vector memory (embedded ChromaDB) | intelligence | PRIOR-ART | memory/store.py | |
| Hybrid multi-project memory fusion | intelligence | PRIOR-ART | memory/hybrid_memory.py | |
| KnowledgeBrain RAG ingestion + fused recall | intelligence | PRIOR-ART | memory/brain.py; run_knowledge.py | |
| Human-like memory decay, tiers, and dreaming | intelligence | PRIOR-ART | memory/human_memory.py | |
| Associative connect-the-dots note memory (HippoRAG + A-MEM) | intelligence | PRIOR-ART | memory/associative.py | |
| Unified instruction-shaped neuron store (6,741 neurons measured) | intelligence | PRIOR-ART | memory/neurons.py; research/brain-ultra-upgrade/GOAL.md:15-45 | |
| Cross-store neuron-web migration + weaving | operations | PRIOR-ART | memory/neuron_web.py | |

## Infrastructure / tooling / dashboard

| Requirement | Category | Status | Evidence | Notes |
|---|---|---|---|---|
| Auto-discovery of every node factory | operations | PRIOR-ART | nodes/autoload.py | |
| Native compiled hot-kernel library (C hot paths) | operations | PRIOR-ART | native/fastops.c; native/fastops.py; native/build.sh; native/rolling_vp/ | |
| Secrets-safe centralized config loader (~25 keys, never printed) | security | PRIOR-ART | config.py; CONVENTIONS.md:72-75 | Different mechanism from current secret_store.py. Not CLAIMED |
| AST-based self-generating code index (INDEX.md) | operations | PRIOR-ART | tools/gen_index.py; Makefile:4-5 | |
| Discovered-broker-capability census generator | operations | PRIOR-ART | tools/gen_upstox_census.py | |
| Cron self-healing process keeper | operations | PRIOR-ART | tools/loop_keeper.py | |
| Headful remote-VNC broker login solver | security | PRIOR-ART | tools/remote_login_browser.py | |
| Workflow-agent research rescue tool | operations | PRIOR-ART | tools/save_workflow_research.py | |
| Self-improving skill learnings loop (LEARNINGS.md, Hermes pattern) | intelligence | PRIOR-ART | tools/skill_learnings.py | |
| Zero-dependency stdlib HTTP dashboard server | observability | PRIOR-ART | dashboard/server.py | |
| Modular route-body extraction | operations | PRIOR-ART | dashboard/routes/{brain,trading,network,post}_ext.py | |
| Live brain snapshot builder, honest real-vs-demo | observability | PRIOR-ART | dashboard/brain_live.py | Falls back to a labeled synthetic demo, never silently fabricates |
| React/Three.js/D3/Sigma trading + brain frontend | observability | PRIOR-ART | dashboard/web/src/{App,BrainPage,TradingDashboard,MissionControl,SigmaNetwork,Graph3D}.jsx | |
| Reuse-first / search-copy-adapt-stitch coding policy | governance | PRIOR-ART | CONVENTIONS.md:38-49; vendor/ dirs | Backed by real vendored code |
| Enforced NodeProtocol interface + self-registering registry | governance | PRIOR-ART | core/node_protocol.py; core/registry.py | |
| Dashboard-sync (auto-visible nodes/features) | observability | PRIOR-ART | dashboard/; state.json from ~20 run_*.py | |
| Honest-wiring rule, no fabricated dashboard edges | governance | PRIOR-ART | run_oss.py:53-57,66-70; run_columns.py:88-89; run_network.py:14-16 | Same spirit as Rule 8 |
| CORTEX B7 unified network-state generator | observability | PRIOR-ART | run_network.py; nodes/active_subnet.py; nodes/reflex.py; core/columns.py; core/segments.py | |
| Trainable-network dashboard renderer (gate/cascade/bus) | observability | PRIOR-ART | run_trainable.py | |
| Trading Dark-Pro dashboard (T6) | observability | PRIOR-ART | trading-execution-blueprint.md T6 status block | No src file cited — lower confidence |
| Multi-service orchestrated boot | operations | PRIOR-ART | start_all.sh | |
| Dashboard/tunnel relaunch + public Cloudflare tunnel | operations | PRIOR-ART | start_tunnel.sh | |
| Config diagnostic CLI | security | PRIOR-ART | config.py:69-73 | |
| Trading brain experience→intelligence loop (CBR, River drift, AutoQuiz, MAML warm-start, STUMPY/hmmlearn regime, gplearn factor mining, sentiment, safety-gated pipeline) | intelligence | PRIOR-ART | run_brain_t8.py (partial read); trading-execution-blueprint.md T8.4-T8.9 | Kept composite deliberately — one partial code read plus a status doc, not per-capability citations |

## Governance practices actually run

| Requirement | Category | Status | Evidence | Notes |
|---|---|---|---|---|
| watch_live_trades_since_epoch | observability | PRIOR-ART | research/direction-brain-mission/live_watch.py:1-19 | |
| Pre-registered verdict check (V1-V5 rules, Wilson CIs, auto-revert) | governance | PRIOR-ART | research/direction-brain-mission/verdict_check.py:1-25 | |
| Strategy coverage crosscheck (157/157 required concepts) | governance | PRIOR-ART | research/strategies/COVERAGE_CROSSCHECK.md:1-6 | |
| Recurring static-import connectivity audit, 8 dated runs, with false-positive verification | governance | PRIOR-ART | research/audits/independent-audit-20260717-184107.md +7 siblings; verdict-2026-07-07.md:6-13 | The recurring practice, distinct from the watchdog code |
| Direction-source colosseum (55% CI bar to earn live weight) | governance | PRIOR-ART | research/direction-accuracy-program/PLAN.md:69-73 | |
| Permanent control lane (~20% deterministic pre-mission control) | governance | PRIOR-ART | research/direction-brain-mission/LOG.md Session 1 | |
| Retire long-only fallback decider | governance | PRIOR-ART | research/direction-brain-mission/LOG.md Session 9 X14 | |
| Lane parole and kill governance (faster-accruing probation for killed lanes) | governance | PRIOR-ART | research/direction-brain-mission/LOG.md Session 9 X21 | |
| Dashboard visual regression QA | observability | PRIOR-ART | research/visual-qa/report-20260712-142735.md:1-13 | |
| Dashboard interaction QA | observability | PRIOR-ART | research/visual-qa/interaction-report-20260705-074428.md:1-11 | |
| App driving-school coverage audit | observability | PRIOR-ART | research/app-feature-audit-2026-07-06.md | |
| RAM symbol-data coverage audit | observability | PRIOR-ART | research/ram-symbol-data-coverage-audit-20260713.md | |
| Fix brain stagnation root causes (dead trading loops, LLM pool 95% exhausted) | operations | PRIOR-ART | research/brain-audit-2026-07-10.md | Real fixes shipped same day |
| Fix torch/torchvision ABI mismatch | operations | PRIOR-ART | research/torch-torchvision-abi-mismatch.md | |
| Video-understand skill (ffmpeg + faster-whisper + yt-dlp) | operations | PRIOR-ART | research/video-understand-skill.md | Same shape as the current `youtube-video` skill |
| Descaffold fable session overhead | operations | PRIOR-ART | research/fable5/descaffold-proposal-20260716.md:1-8 | Human-driven session fix |
| Local vision VLM, no throttle (Granite-3.2-Vision via Ollama) | intelligence | PRIOR-ART | research/local-vision-vlm.md | Doc-only citation |
| Brain cockpit FreqUI view | observability | PRIOR-ART | research/ai-scientist/ideas-ledger.md:200 | Ideas-ledger only, lower confidence |
| Session state snapshot capture | operations | PRIOR-ART | research/ai-scientist/state-*.md (10 files) | **READS-AS-BUILT RISK** — ai-scientist/fable5 are human-driven session logs and prompt packs, not an autonomous loop. Also: committing timestamped state snapshots is what the current Rule 9 now forbids |

## UNRESOLVED — no home in any plan, no implementation

| Requirement | Category | Evidence |
|---|---|---|
| NO SHADOW ON PAPER rule | governance | CONVENTIONS.md §15 — policy, no enforcing code |
| Prompt-quality / verify-first / error-research workflow rules | governance | CONVENTIONS.md §8,11,12 |
| Honest sentience stance, functional-vs-phenomenal distinction | governance | ml-network-brain-ultra-blueprint.md:158-173 |
| Multi-agent debate trading roles (TradingAgents pattern) | intelligence | t8-stitch-blueprint.md §2 — explicitly deferred in source |
| POET open-ended curriculum + topology self-evolution | intelligence | t8-stitch-blueprint.md §7 Layer E — gated behind paper + backtest acceptance |
| Adjacent-fields research survey (ensembles, reservoir computing, MoE) | intelligence | ml-network-research.md; ml-network-related-topics.md |
| Source requirements taxonomy tracking | governance | research/strategies/SOURCE_REQUIREMENTS.md:1-30 |
| Poisoned-era inverter bug postmortem (31 shorts vs 1 long, −112 P&L, era excluded) | governance | research/audits/poisoned-era-inverter-20260716.md:1-14 |
| Market isolation audit — isolation was convention-only, not structural | security | research/audits/market-isolation-audit-20260713.md:1-16 |
| Eyes-brain-hand conformance verification | governance | research/audits/eyes-brain-hand-conformance-2026-07-09.md:1-20 |
| Deep-connect signal wiring audit — indicator_fusion output computed but never read | governance | research/audits/deep-connect-findings-20260712.md:1-18 |
| Stagnated unused features audit — real trades vs blocked T8 advisory pipeline | governance | research/audits/brain-stagnated-features-20260714.md:1-20 |
| Whole-brain closed-loop review | governance | research/audits/brain-closed-loop-review-20260717.md:1-16 |
| Strategy tournament registry remeasure (552 vs stale cap bug) | governance | research/perf/tournament-cap-remeasure-20260716.md:1-30 |
| Hardware saturation audit — 5+ serial-loop sites, GIL-bound | operations | research/perf/hardware-saturation-audit-20260712.md:1-25 |
| Preserve verbatim owner goal | governance | research/founder-intent/goal-2026-07-07-human-trading-system.md:1-20 |
| Freqtrade deep-fork 4-segment design | operations | research/plans/freqtrade-deep-fork-4segments.md:1-25 |
| Self-improving LLM agent trading system (Hermes-Agent notes) | intelligence | research/video/self-improving-agent/understanding.md:1-18 |
| Reference-video / competitor literature scan | intelligence | research/video/{krafer-patterns,ai-quant-trader-vid,vp0,vidup1,vidup2,joshua-trades,yt-wQ0duoTeAAU} |
| Login walkthrough video review (AngelOne/Coinbase/Binance nav specs) | operations | research/video/{angelone-login,coinbase-login,binance-app-improve} |
| Brain screen-mirror stall diagnosis | observability | research/video/brain-slow-nav/understanding.md:1-13 |
| Resume QA after outage | operations | research/visual-qa/RESUME-QA-20260705.md:1-15 |
| Benchmark against SEB AI hedge-fund committee | governance | research/uploads-20260717/UNDERSTANDING.md:1-33 |
| Practice-notebook confirmation gate design | intelligence | research/practice-notebook/DESIGN.md:1-45 |
| Paste prompts into manual Fable sessions | intelligence | research/fable5/{BRIEF,PROMPTS,PROMPTS-BRAIN,PROMPT-DIRECTION-BRAIN}.md — source's own confirmation that fable5 packs are human-pasted, not programmatic |
| Entry research sweep, 106 claims | intelligence | research/direction-brain-mission/research-entries.md |
| Restart starves labeling | operations | research/fable5/lessons/2026-07-17-restart-starves-labeling.md |
| Owner-authorized restarts required | operations | research/fable5/lessons/production-restarts-are-owner-actions.md |
| Direction ceiling research — edge lives in momentum/carry, not microstructure | intelligence | research/ai-scientist/direction-ceiling-research-20260717.md:10-20 |
| Gate-rebuild literature synthesis, 217 unique claims, adversarial fact-check | intelligence | research/gate-rebuild/ALL-CLAIMS.md; SYNTHESIS-AND-FIELD-LIST.md |
| Binance/Upstox nav expert | intelligence | research/brain-ultra-upgrade/GOAL.md:136; AUDIT-20260713.md:21-23 — source labels it **STUB, evidence-starved** |
| Associative long-term memory recommendation | intelligence | research/agentic-longterm-memory-2026.md |
| Boss-command brain donor map | governance | research/boss-command-brain-stitch-map.md |
| Boss chat stream-of-mind design | governance | research/boss-command-brain.md |
| Brain feature activation audit (~239 subsystems, 4-batch plan) | observability | research/brain-activation-map.md |
| Computer-use GUI agent survey | intelligence | research/brain-advanced-features-chat.md |
| Observe-reflect-hypothesize loop proposal | intelligence | research/brain-features-chat.md |
| RAM vs demo data-path audit (~200 modules ranked) | observability | research/brain-features-ram-audit-20260713.md |
| Brain upgrade four-axes survey (HippoRAG2+A-MEM, nanoGPT, Docling, Avalanche) | intelligence | research/brain-ultra-upgrade-2026.md |
| Brain upgrade stitch-target map | intelligence | research/brain-ultra-upgrade-stitch-map.md |
| Per-trade SHAP attribution logging | observability | research/decision-lineage-feature-attribution-logging.md — **directly relevant to goal doc §10.8** |
| Decision-memory provenance stitch | intelligence | research/decision-memory-stitch-map.md |
| Episodic memory for trading agents survey | intelligence | research/episodic-memory-trading-agents.md |
| Hermes-Agent runtime assessment | intelligence | research/hermes-agent.md |
| GUI agent SOTA deep research (106-agent sweep, cross-app ~0% success) | intelligence | research/gui-ai-agents-deep-research.md |
| Planner-actor-validator navigation proposal | intelligence | research/intelligent-web-navigation.md |
| Concept-space manifold visualisation | observability | research/manifold-concept-space-viz-oss.md |
| Always-on loop architecture design | operations | research/online-alwayson-loop-and-features.md |
| Robot-learning self-evolution map | intelligence | research/robot-learning-evolution-2026.md |
| Independent code-connectivity audit (grimp/import-linter/vulture/pyan3) | governance | research/skill-independent-audit.md |
| T8 brain-ultra OSS capability survey | intelligence | research/t8-brain-ultra-features-oss.md |
| Experience-to-intelligence loop design | intelligence | research/t8-experience-intelligence-oss.md |
| Trade-journal decision-provenance OSS survey | observability | research/trade-journal-decision-provenance-oss.md |
| Ultra-advanced brain ideas shortlist | intelligence | research/ultra-advanced-brain-ideas-2026.md |
| Research directory provenance index | governance | research/README.md |
| AngelOne login pivot to SmartAPI | security | research/angelone-login-blocked.md |
| Broker-native ocular cortex spec | intelligence | research/broker-native-trader-spec.md — spec state, paralleled by the built ocular_cortex.py |
| Paper/real market toggle design | operations | research/online-market-toggles-paper-real-switch.md |
| NSE off-hours replay trading design | operations | research/online-nse-offhours-paper-trading.md |
| Broker UI automation OSS scan (OmniParser V2, UI-TARS 1.5-7B) | intelligence | research/oss-web-ui-trading-scan-20260713.md |
| GUI web-reader research session review (106-agent, 2.3M-token session) | governance | research/session-review-20260705-gui-web-reader.md |
| Broker web-reader scraper architecture | intelligence | research/web-reader-broker-scraper.md |
| Web-reader OSS deep research | intelligence | research/web-reader-oss-deep.md |
| **Coarse-to-fine universe scan architecture** | operations | research/universe-scan-architecture.md — **directly relevant to goal doc §5a** |

## Slice notes

- **1 row flagged READS-AS-BUILT RISK**: `capture_session_state_snapshot`. All other ai-scientist/fable5
  rows checked out as genuine fixes or genuine findings from human-driven sessions.
- **No rows in this slice matched** the always-returns-healthy or `np.random` self-reward patterns.
  The health-check rows here (`ui_health.py`, `system_map.py`, `brain_live.py`, `flow_health.py`)
  describe honest, evidence-based, never-fabricated status reporting — the opposite case.
- **2 rows PLANNED**, everything else PRIOR-ART or UNRESOLVED. Zero CLAIMED — nothing in this slice is
  satisfied by the current project.
- All 290 input rows processed; nothing truncated.
