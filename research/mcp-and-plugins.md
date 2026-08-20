# MCP, Plugins & Security — a skeptical assessment

**Researched:** 2026-08-01 by a Sonnet 5 subagent (Rule 1).

**Headline finding: install nothing by default.** Most of the original official MCP
server set is either redundant with Claude Code's built-in tools or archived.

---

## The verdict table

| Server | Status | Verdict |
|---|---|---|
| filesystem (official) | maintained | **Skip** — ~1:1 duplicate of Read/Write/Edit/Glob/Grep |
| git (official) | "early development" | **Skip** — one-line wrappers around `git`, which Bash already runs |
| GitHub (GitHub's own) | very active | **Situational** — cheaper first move: install `gh` CLI and shell out |
| fetch (official) | active | **Skip** — WebFetch already does HTML→markdown+summarise |
| Postgres (official) | **ARCHIVED** (stale since Dec 2024) | **Skip** |
| SQLite (official) | **ARCHIVED** (Apr 2025) | **Skip** |
| Puppeteer (official) | **ARCHIVED + unpatched security advisory** (SSRF / prompt-injection / sandbox bypass) | **Skip** |
| **Playwright (Microsoft)** | active | ✅ **The one clear win** — accessibility-tree snapshots + persistent browser state across turns |
| Context7 (Upstash) | very active, 60k★ | Situational — version-pinned docs; worth it only for heavy multi-library work |
| Brave / Tavily search | active | Situational — Tavily's multi-page `crawl`/`map` is a real gap WebFetch can't fill |
| memory/knowledge-graph (official) | active but **its own README says "reference/educational, not production-ready"** | **Skip** — a git-diffable markdown file is simpler |
| postgres-mcp Pro (community) | active, 3.1k★ | Situational — real index-tuning simulation beyond `psql` |

⚠️ Playwright caveat: headless-browser system deps **on a no-sudo box are
UNVERIFIED**. Test before relying on it.

---

## Is MCP even needed? The CLI-redundancy finding

Documented practitioner benchmark (75 runs): **CLI used 4–32× fewer tokens than
MCP, with 100% vs 72% success rate**, and roughly **$3.20 vs $55.20 per 10K
ops/month**. The gap is driven by CLI piping through `jq`/`grep` instead of dumping
raw output into context.

GitHub's own MCP server is the canonical example people route around in favour of
the `gh` CLI.

**MCP earns its keep only when:**
- The session is genuinely **stateful** (browser automation, DB pooling, multi-step
  OAuth) — a CLI reconnects fresh every call.
- The target has **no usable CLI/API** (GUI-only SaaS, proprietary internal tools).
- You need **centralised audit/governance** across many users.
- The consumer isn't a developer with a terminal.

For a solo setup like ours, only browser automation qualifies — which is exactly
why Playwright is the single yes.

---

## Token cost — the number that decides it

Confirmed via Anthropic's own engineering blog (Nov 2025): MCP tool schemas cost
**~80–150 tokens per tool, EVERY TURN** — not once.

| Config | Cost per turn |
|---|---|
| 3-tool custom server | ~180 tokens |
| filesystem server (7 tools) | ~640 tokens |
| **GitHub server (26 tools)** | **~3,100 tokens** |
| GitHub full surface (91 tools) | **~46,000 tokens** before mitigation |

**Schemas load for every registered tool up front, whether or not it's ever called.**
Multiple servers stack.

**Mitigation — Tool Search Tool:** tools marked `defer_loading: true` aren't loaded
until Claude searches for them. Benchmark: 50+ tools from ~72,000 → ~8,700 tokens
(85–95% reduction) **with improved accuracy**. Reported to have landed natively in
Claude Code ~2.1.7 — **exact trigger UNVERIFIED**; the mechanism is solid, the
numbers are practitioner-reported.

Controls we have today: `/mcp enable` / `/mcp disable`, `claude mcp add --scope
local|project|user`, `/doctor` (reportedly shows per-server token usage).
Known gap (issue #44845): **no way to disable a server globally across all
projects** — per-project only.

---

## Security — keeping the distinction between PoC and in-the-wild

**Prompt injection via tool output is real and vendor-confirmed, not theoretical:**
- Invariant Labs (May 2025) — a public GitHub issue titled "About The Author"
  instructed an agent to exfiltrate private-repo data via a PR.
- Azure DevOps MCP (July 2026) — **hidden HTML comments in PR descriptions,
  invisible in the UI but visible in raw tool output**, hijacked reviewer agents.
  No patch at time of research.

**The lethal trifecta** (Simon Willison, June 2025): private data + untrusted
content + external communication. Both the GitHub case and a Supabase MCP incident
(July 2025) hit all three legs. **Stated fix: make the server read-only to remove
one leg.**

**Tool poisoning** — a poisoned `description` field carries instructions invisible
in the approval UI but fed to the model. An arXiv census of 1,360 deployed servers
found this structurally widespread — evidence the attack *surface* is common, not
that campaigns are live.

**Rug-pulls have a real CVE:** CVE-2025-54136 "MCPoison" in Cursor (CVSS 8.8) — a
server changing behaviour post-approval without re-prompting. Relevant mechanic:
Claude Code auto-refreshes tool lists via MCP's `list_changed` notification without
re-prompting, and permission rules key on `mcp__server__tool` **name**, not a hash
of the schema. *(Researcher's own inference from documented mechanics, not an
audited finding.)*

**Actually exploited in the wild** (vs. responsible disclosure): a malicious
**Postmark MCP npm package** (~Sept 2025) exfiltrating email, and a cloned "Oura
MCP" distributing malware (~Feb 2026, weakly sourced). Both are **supply-chain**
compromises — a different risk category from protocol flaws.

Disclosed-but-not-exploited CVEs: `mcp-remote` CVE-2025-6514 (9.6), Anthropic's own
MCP Inspector CVE-2025-49596 (9.4), Figma MCP CVE-2025-53967, Anthropic's own
Filesystem MCP CVE-2025-53109/53110.

**Concrete mitigations:**
- Allowlist servers in **source-controlled settings** for review, not ad-hoc approval.
- **Least-privilege credentials** — the GitHub incident traced to one over-broad PAT.
- **Pin exact versions/hashes.** Not `npx @latest` / floating `uvx`.
- **Read the full raw tool JSON before approving**, not the name in the UI.
- **Never run a content-fetching tool and an externally-communicating tool in the
  same session** — that's the trifecta, broken at the source.

---

## The decision framework (confirmed against official docs)

| Tool | What it is | Reach for it when |
|---|---|---|
| **Skill** | Reusable instructions in the **main** context | Default. Cheapest. |
| **Subagent** | Own **isolated** context + tool permissions | Output is verbose/disposable, or tool access must be enforced |
| **MCP** | External, **stateful**, or async-push | Persistent DB connection; a webhook arriving while you're away. Nothing in-turn can replicate this. |
| **Plugin** | Pure **packaging** — adds no capability | You're distributing the above to others |

**Escalation order: Skill → Subagent → MCP → Plugin.** Each step costs more context
and more attack surface.

---

## Plugins

`/plugin marketplace add <source>` then `/plugin install <plugin>@<marketplace>`.
Two official marketplaces: `claude-plugins-official` (auto-registered, curated) and
`claude-plugins-community` (screened).

A plugin manifest can bundle skills/commands, subagents, hooks, `.mcp.json` server
configs, LSP configs, and background monitors. `themes` and `monitors` are flagged
**experimental / schema-unstable**; skills/agents/hooks/MCP carry no such caveat.

**Honest finding: the third-party plugin ecosystem is thin.** Beyond Anthropic's own
(`commit-commands`, `pr-review-toolkit`, `security-guidance`, LSP integrations,
`github`/`sentry`/`slack`/`figma`), the researcher **declined to recommend any
specific third-party plugin** — sources naming them were self-reported blog reviews,
and one list calls the ecosystem "early-stage" with compatibility that "may break
across versions."

---

## Recommendation for us

**Install nothing by default.**
- Add **Playwright MCP** only when browser automation is actually needed — and test
  headless-Chromium deps work without sudo first.
- Install **`gh` CLI** over the GitHub MCP server (we have no `gh` yet).
- Context7 / Brave / Tavily / Postgres-Pro only when a specific workload demands it.
- Treat every addition as **a context-budget cost AND a security-surface cost**,
  never a free win.
