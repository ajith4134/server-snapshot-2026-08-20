# MCP & Plugin Decision — for the trading stack specifically

**Researched:** 2026-08-01 by Sonnet 5 subagents (Rule 1). Verified means the agent
loaded the actual marketplace JSON / repo / docs page, not a search snippet.

Supersedes the generic "install nothing" conclusion in `mcp-and-plugins.md` **for
this project only** — that file's reasoning still stands for a bare workspace.

---

## Decision

| Add | Skip |
|---|---|
| **`pyright-lsp`** (official plugin) | Every crypto/trading MCP |
| **`security-guidance`** (official plugin) | Every database MCP |
| *Context7* — defensible third, marginal | Playwright MCP **local** |
| | `hookify`, `clickhouse`, `mlflow`, `langfuse`, `data-engineering` |

**Already done instead of MCP:** `gh` CLI installed (26-tool GitHub MCP would cost
~3,100 tokens/turn).

---

## 1. Crypto / trading MCP — nothing clears the bar

- **Official marketplace: ZERO hits** for crypto / trading / ccxt / quant /
  tradingview (verified against `marketplace.json`).
- Community: a few unmaintained scaffolds (`aomi-build`, `algovault-skills`);
  `tres-finance-plugin` is blockchain *tax accounting*, not trading.
- General MCP registries: real repos exist — `doggybee/mcp-server-ccxt`,
  `AnalyticAce/binance-mcp-server`, assorted `*-ccxt-mcp` forks — but they are
  **3–14 star, essentially unmaintained toys.**

> ⚠️ **Every one that does live trading requires exchange API keys in the MCP
> server's environment.** That is exactly our forbidden case. One
> (`jackson-video-resources/claude-tradingview-mcp-trading`) explicitly wants
> **full API key + secret + passphrase for 9 exchanges.** Do not use under any
> circumstance.

TradingView MCPs are mislabelled: `atilaahmettaner/tradingview-mcp` is a **Yahoo
Finance proxy** branded TradingView-style; others drive the real desktop app via CDP
and need a logged-in session on the agent's box.

**Verdict: use `ccxt` directly from a Python script.** Strictly better — same
library, no per-turn schema cost, and **no credential surface added to the agent's
tool context.** This is the architecture decision, not a preference.

---

## 2. Database MCP — skip

The official `clickhouse` plugin talks to **ClickHouse Cloud only** (org browsing,
billing, read-only SQL). Irrelevant if self-hosting.

The general argument, which is decisive:
> A DB MCP's schema costs ~80–150 tokens **every turn** whether queried or not, and
> returns results **raw**. `clickhouse-client` / `psql` / a Python client costs
> nothing until invoked — and lets you pipe through `jq`/`grep`/`awk` to cut a
> 50k-row result down to the 20 rows that matter **before it touches context**.
> **No DB MCP does that filtering for you.**

Applies to both the market-data TSDB and the experiment ledger.

---

## 3. Context7 — marginal, defensible, zero risk

- Free tier: **1,000 calls/month**, then 20/day.
- **NautilusTrader IS indexed** — 496k tokens, 6,001 snippets, trust 8.3/10,
  "updated 1 week ago." Good coverage for a niche library.
- Install: `npx ctx7 setup --claude`, or remote MCP at `https://mcp.context7.com/mcp`.

⚠️ **The crawl is periodic, not live.** NautilusTrader is **pre-2.0 with breaking
changes between releases** — so treat Context7 as a *first pass only* there, and
verify against the actual repo/CHANGELOG when working right after a release.

Worth it mainly for the big stable doc surfaces (PyTorch, pandas, LightGBM, ccxt).
Zero credential exposure, so the only downside is token/setup cost.

---

## 4. Playwright — the local no-sudo path is CONFIRMED BROKEN

This was the decision-critical question, and the answer is definitive:

> **`npx playwright install --with-deps` shells out to `apt-get` and hard-fails on
> non-root systems.** Playwright's supported-OS list is Debian/Ubuntu only.
> GitHub issue **#11122 open since 2022**, plus **#35677 (2025)** — both confirm it
> fails exactly this way. **No documented non-apt fallback exists.**

The conda-forge `playwright` package exists, but whether it vendors the runtime
`.so` deps Chromium needs to *run* (libnss3, libgbm, libatk, mesa) — versus just the
Python bindings — **could not be confirmed. UNVERIFIED.** Testable via
`micromamba install -c conda-forge playwright nss mesa at-spi2-atk libxkbcommon`,
but do not assume it works.

**The one confirmed-clean path:** `@playwright/mcp` supports `--cdp-endpoint`
(`PLAYWRIGHT_MCP_CDP_ENDPOINT`) to attach to a **remote** browser over CDP —
zero local install, zero root, zero apt. That endpoint's token is a *browser-session*
credential, not a trading credential, so it does not trip the trifecta rule.

**Verdict:** if dashboard verification is genuinely needed later, use remote-CDP mode
against a hosted browser. Do not fight the local install.

---

## 5. Official plugins — install two

### ✅ `pyright-lsp`
Genuine **LSP client integration** — persistent language server, go-to-definition,
find-references, hover. This is a real fix for the documented Claude Code gap where
refactors degrade to `mv` + `grep`.

⚠️ **Caveat: rename-symbol is NOT among the documented capabilities.** Renames may
still need manual care. Requires `pip install pyright` separately.

### ✅ `security-guidance`
Adds a **Stop-time LLM-powered diff review** (injection, SSRF, secrets, 25+ classes)
plus PreToolUse pattern warnings.

**Additive, not redundant** with our hand-rolled hooks — ours are regex; this is a
*semantic* review pass. Also partially addresses our missing Stop hook, though it
reviews the diff rather than re-running tests.

### ❌ Skip, with reasons
| Plugin | Why not |
|---|---|
| `hookify` | Conditions are **regex/equals/contains only** — our hand-rolled hooks in real shell logic already exceed it. Adds natural-language authoring UX, not power |
| `clickhouse` | ClickHouse **Cloud** only |
| **`mlflow`** | ⚠️ **Misleading name** — it is agent *tracing/eval*, NOT classic ML experiment tracking. Does **not** cover our experiment ledger. Use the real `mlflow` Python package for that |
| `langfuse` | LLM observability — irrelevant to a quant pipeline |
| `data-engineering` | Airflow-specific |
| `code-review`, `pr-review-toolkit`, `code-simplifier`, `commit-commands`, `claude-md-management`, `superpowers` | All real, all fine, **none critical**. Optional |

---

## Commands (user must run — these are slash commands, not shell)

```
/plugin marketplace add anthropics/claude-plugins-official
/plugin install pyright-lsp@claude-plugins-official
/plugin install security-guidance@claude-plugins-official
```
Then in the project venv: `pip install pyright`

Optional third:
```
npx ctx7 setup --claude
```

**No command given for Playwright or any crypto/trading MCP** — both recommended
against for this environment and stack.

---

## 6. The video's 9 plugins — re-judged for THIS project

Earlier I fact-checked whether they *exist*. Different question: are they worth it
for an ML/research-heavy trading system?

**The discriminator the video never mentions: does the plugin bundle an MCP server?**
MCP-backed plugins cost ~80-150 tokens **per tool, per turn, forever**. Pure
skill/agent plugins cost **nothing until invoked**. Verified from marketplace JSON:

| Video # | Plugin | Exists | MCP cost | Verdict for us |
|---|---|---|---|---|
| 5 | **`skill-creator`** | OFFICIAL | **none** | ✅ **Best pick in the video** — eval-driven skill dev |
| 5 | **`security-guidance`** | OFFICIAL | **none** | ✅ Already recommended |
| 2 | **`exa`** | OFFICIAL | **MCP** | ⚠️ Real value, real cost — see below |
| 2 | **`firecrawl`** | OFFICIAL | low | ⚠️ Only with Exa |
| 5 | **`frontend-design`** | OFFICIAL | **none** | 🕐 Later — only if we build a dashboard |
| 9 | **`burn`** | community | — | 🕐 Optional — token-spend visibility |
| 1 | **`caveman`** | community | — | ❌ Terser output at the cost of clarity |
| 6 | Codex plugin | not by that name | — | ❌ Our research: budget-matched multi-model underperforms |
| 3 | Compound Engineering | **not installable** | — | ❌ Philosophy already adopted |
| 4 | Higgsfield | **not in any marketplace** | — | ❌ Paid sponsor; irrelevant |
| 7 | buildpartner.ai | **not in any marketplace** | — | ❌ Presenter's own product |
| 8 | Morph | **not in any marketplace** | — | ❌ Paid; numbers self-described "theoretical" |

### `skill-creator` — the video undersold it

Mentioned in passing under "Anthropic official," but for us it is the most valuable
item on the list. It stores test cases in `evals/evals.json`, runs isolated subagent
tests, benchmarks **with-skill vs without-skill**, and does **blind A/B between skill
versions**.

That is a *hard, non-LLM evaluator for skills* — exactly the pattern that separates
FunSearch and the Stanford Virtual Lab from the systems whose claims outran their
evidence. We are building skills (2 so far) and currently validate them by eyeball.
**Zero MCP cost.**

### Exa + Firecrawl — genuine value, but pay for it knowingly

The video's technical point is correct and matters for us: **keyword search returns
SEO pages containing your words; semantic search returns pages about your meaning.**
This project reads papers, exchange docs and market analysis continuously, and our
`parallel-research` skill has already run 11 times.

But `exa` is **MCP-backed** — permanent per-turn context cost — and needs an API key.
That key cannot move money, so it does not trip the trifacta rule, but it is still a
standing cost.

**Recommendation: defer.** Add only if native WebSearch demonstrably fails us on
research quality. Measure first, then buy.

### The pattern worth noting

**The plugins the video hyped hardest are the ones to skip** (Higgsfield = paid
sponsor, buildpartner = his own product, Morph = unverifiable numbers), while the one
it mentioned in passing — `skill-creator` — is the most useful thing on the list for
our actual work.
