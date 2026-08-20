# crypto-bot

Private archive of everything behind the trading system: research, design decisions,
video notes, Instagram source material, Claude Code configuration, and the Layer 0
implementation with its full git history.

## Layout

| Path | What is in it |
|---|---|
| `research/` | 54 research and design documents |
| `research/instagram-raw/` | Raw Instagram capture — 817 frames, 9 reels, per-post logs and metadata |
| `research/reference-images/` | Skill-tree and competency-domain reference images |
| `video-notes/` | 7 YouTube videos — timestamped transcripts and sampled frames |
| `claude-config/` | Global `CLAUDE.md` rules and the persistent memory files |
| `trading-system/` | Layer 0 raw capture — spec, plan, source, tests (grafted with full history) |

The Layer 0 development history also exists as its own branch,
`layer0-raw-capture`, with all 45 commits.

## Start here

**Decisions and architecture**
- [`research/DECISIONS.md`](research/DECISIONS.md) — settled choices and the reasoning
- [`research/ARCHITECTURE.md`](research/ARCHITECTURE.md) — system shape
- [`research/FEATURES.md`](research/FEATURES.md) — what it does
- [`research/SYNTHESIS.md`](research/SYNTHESIS.md) · [`research/IDEAS-SYNTHESIS.md`](research/IDEAS-SYNTHESIS.md)

**Idea banks**
- [`IDEAS-STRATEGIC`](research/IDEAS-STRATEGIC.md) · [`IDEAS-ADVANCED`](research/IDEAS-ADVANCED.md) · [`IDEAS-FRONTIER`](research/IDEAS-FRONTIER.md) · [`IDEAS-INTELLIGENCE`](research/IDEAS-INTELLIGENCE.md) · [`IDEAS-AI-FIELD`](research/IDEAS-AI-FIELD.md)

**Market structure and costs**
- [`crypto-native-market-structure.md`](research/crypto-native-market-structure.md)
- [`crypto-orderbook-signals.md`](research/crypto-orderbook-signals.md)
- [`crypto-exchange-fees-maker-economics.md`](research/crypto-exchange-fees-maker-economics.md)
- [`crypto-alpha-decay-execution-costs.md`](research/crypto-alpha-decay-execution-costs.md)
- [`crypto-latency-cloud-vs-colo.md`](research/crypto-latency-cloud-vs-colo.md)
- [`crypto-counterparty-operational-risk.md`](research/crypto-counterparty-operational-risk.md)

**Machine learning for finance**
- [`finml-gbt-vs-dl-by-frequency.md`](research/finml-gbt-vs-dl-by-frequency.md)
- [`finml-feature-engineering.md`](research/finml-feature-engineering.md)
- [`finml-architectures-live-evidence.md`](research/finml-architectures-live-evidence.md)
- [`finml-replication-problem.md`](research/finml-replication-problem.md)
- [`finml-subsecond-and-dontbuild.md`](research/finml-subsecond-and-dontbuild.md)
- [`kronos-foundation-model.md`](research/kronos-foundation-model.md)

**Validation, search, discovery**
- [`validation-beyond-deflated-sharpe.md`](research/validation-beyond-deflated-sharpe.md)
- [`multiple-comparisons-false-discovery-backtesting.md`](research/multiple-comparisons-false-discovery-backtesting.md)
- [`alpha-discovery-gp-symbolic-regression.md`](research/alpha-discovery-gp-symbolic-regression.md)
- [`llm-code-evolution-funsearch-alphaevolve-adas.md`](research/llm-code-evolution-funsearch-alphaevolve-adas.md)
- [`search-infrastructure-pbt-nas-bayesopt-bandits.md`](research/search-infrastructure-pbt-nas-bayesopt-bandits.md)
- [`promotion-pipeline.md`](research/promotion-pipeline.md) · [`allocation-and-regime.md`](research/allocation-and-regime.md)

**Operations and failure**
- [`risk-and-failure.md`](research/risk-and-failure.md) · [`failure-modes.md`](research/failure-modes.md)
- [`trading-operational-failures.md`](research/trading-operational-failures.md)
- [`trading-monitoring-deployment-discipline.md`](research/trading-monitoring-deployment-discipline.md)
- [`trading-reproducibility.md`](research/trading-reproducibility.md)
- [`trading-secrets-management.md`](research/trading-secrets-management.md)
- [`trading-market-data-storage.md`](research/trading-market-data-storage.md)
- [`trading-feature-stores-experiment-tracking.md`](research/trading-feature-stores-experiment-tracking.md)
- [`prior-attempts-postmortem.md`](research/prior-attempts-postmortem.md)
- [`continual-learning-and-failure-modes.md`](research/continual-learning-and-failure-modes.md)

**Tooling and the agent harness**
- [`enforcement-layer.md`](research/enforcement-layer.md) · [`hook-failure-modes.md`](research/hook-failure-modes.md) · [`stop-hook-mechanics.md`](research/stop-hook-mechanics.md) · [`hook-tooling-plugins.md`](research/hook-tooling-plugins.md)
- [`mcp-and-plugins.md`](research/mcp-and-plugins.md) · [`mcp-plugins-for-trading-stack.md`](research/mcp-plugins-for-trading-stack.md)
- [`skills-workspace.md`](research/skills-workspace.md) · [`session-binding-and-reload.md`](research/session-binding-and-reload.md)
- [`project-rules-and-skills-proposal.md`](research/project-rules-and-skills-proposal.md)
- [`official-guidance.md`](research/official-guidance.md) · [`cutting-edge-ai.md`](research/cutting-edge-ai.md)
- [`dual-agent-spec.md`](research/dual-agent-spec.md)

**Sources**
- [`research/instagram-sources.md`](research/instagram-sources.md) — every Instagram link, with what came from it
- [`research/instagram-findings.md`](research/instagram-findings.md) — what the posts actually said
- [`research/eliot-prince-credibility.md`](research/eliot-prince-credibility.md) — source vetting
- [`video-notes/INDEX.md`](video-notes/INDEX.md) — every YouTube link and its notes

**Layer 0 — the only code so far**
- [`trading-system/docs/superpowers/specs/2026-08-02-layer0-raw-capture-design.md`](trading-system/docs/superpowers/specs/2026-08-02-layer0-raw-capture-design.md)
- [`trading-system/docs/superpowers/plans/2026-08-02-layer0-raw-capture.md`](trading-system/docs/superpowers/plans/2026-08-02-layer0-raw-capture.md)
- Source and tests on branch `layer0-raw-capture`

## State as of 2026-08-02

Layer 0 is a working library, not a running system. 45 commits, 256 tests, capture
proven byte-exact against live Binance. It is not merged, and it has open work: a
supervisor and an HTTP poller are unbuilt, and a double-writer lock was in flight at
the time of this snapshot.
