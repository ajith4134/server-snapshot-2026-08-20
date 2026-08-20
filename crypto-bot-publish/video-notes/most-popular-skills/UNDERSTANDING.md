# I Scraped 85,000 Claude Skills. These Are The Most Popular — [read]

- Channel: **Dubibubi** (not Austin Marchese — first video here from a different creator)
- 14:46 · https://www.youtube.com/watch?v=1GgyJfCK608
- Artifacts: 411 cues (16.1 KB) + 15 frames
- Processed with `ytgrab`, transcript **and** frames read. Never from title/description.

---

## What it is

A countdown of the 12 most-installed Claude Code plugins, 12 → 1, plus three honorable
mentions and one closing rule.

## The list, with install counts as stated

| # | Plugin | Claimed installs |
|---|---|---|
| 1 | **frontend-design** | 829,000 |
| 2 | **superpowers** | 752,000 |
| 3 | **context7** | 348,000 |
| 4 | **code-review** | 347,000 |
| 5 | **code-simplifier** | 284,000 |
| 6 | **skill-creator** | 283,000 |
| 7 | **GitHub MCP** | 261,000 |
| 8 | **playwright** | 248,000 |
| 9 | **claude-md-management** | 223,000 |
| 10 | **feature-dev** | 217,000 |
| 11 | **typescript-lsp** | 177,000 (Python's `pyright`/Pylance ≈ 91,000) |
| 12 | **security-guidance** | 175,000 |

Honorable mentions: **caveman** (creator claims ~75% output-token cut), **G-stack**
(Garry Tan's full Claude Code setup — CEO/engineering/design review, QA, security,
release, docs), **Karpathy skills** (Forest Cheng packaged Karpathy's complaints into
four rules in one CLAUDE.md; claimed 160,000 stars, "fastest-growing single-file repo
of 2026").

## PROVENANCE — the frames contradict the framing

The title and open claim "I scraped 85,000 skills… over 10 million data points."
**Frame f_002 (01:00) shows where the numbers actually come from**: a third-party blog
article titled *"Best Claude Code Plugins in 2026: Official, MCP, LSP, Design, and
Workflow Picks"*, with a table headed **"Public installs"** — Security Guidance
**175,630**, Semgrep 15,606 — and install commands
`/plugin install security-guidance@claude-plugins-official`. The video's "175,000"
is that row, rounded.

Verified independently: `marketplace.json` for the official marketplace has fields
`author, category, description, homepage, name, source` — **no install-count field at
all.** So the counts cannot have been scraped from the marketplace manifest. They came
from an article that was on screen for one second.

The numbers may still be accurate. The *sourcing story* is not what was claimed. This is
the video-4 lesson repeating from the other direction: last time the description panel
held content the frames missed; this time the frames expose what the audio overstates.

Also unverified: **"85,000 community skills"** and **"~11,000 contain security issues
(1 in 8)"**. Our own count of the community marketplace is **2,307 plugins** — different
unit (one plugin can ship several skills), so not a direct contradiction, but 85,000 is
nowhere confirmed. No source was shown on screen for the 1-in-8 security figure.

Visual content overall: talking head, stock b-roll, Semgrep marketing ("28M findings
detected"), one Claude *web* UI clip (Sonnet 4.6, not Claude Code). Only one frame in
fifteen carried data.

## Against our setup — we already have 10 of 12

| Video's pick | Us |
|---|---|
| frontend-design, superpowers, context7, code-review, skill-creator, playwright, claude-md-management, feature-dev, security-guidance | **installed** (9) |
| typescript-lsp | `pyright-lsp` installed — the Python slot the video names |
| **GitHub MCP** (#7) | **deliberately declined.** CLAUDE.md: ~3,100 tokens/turn for 26 tools; `gh` CLI pipes through `jq`/`grep` instead |
| **code-simplifier** (#5) | **declined 2026-08-01** after source audit — it is a code-refinement subagent, not the hook tooling our INDEX had filed it as |
| caveman (honorable mention) | installed |
| Karpathy skills (honorable mention) | we have the **source video** (INDEX #1) and built Rules 0-5 from it directly |

Two independent declines, both with recorded reasons, against a list assembled from
popularity. Popularity is not a reason.

## The one genuinely useful idea

> *"These skills are not prompts. A prompt asks Claude to think. A skill teaches Claude
> how to work."*

Same distinction as video 3's "build me a skill from this conversation," stated more
crisply. And the closing rule is the one worth acting on:

> **"Do not install all 12. Every skill you add eats context window… the sweet spot
> experts agree on is three to five skills matched to your actual workflow."**

**This directly indicts our setup: 13 plugins enabled.** No source is given for "experts
agree," so treat the specific 3-5 number as soft — but the mechanism (standing context
cost per plugin) is real and we have measured it elsewhere (~3,100 tokens/turn for the
GitHub MCP alone).

Also correct, and matching what we found independently today:

> "Anthropic flat out warns that plugins are highly trusted components that run code with
> your permissions. Security researchers have already documented malicious skills trying
> to silently hijack tool routing."

That is the same trust boundary as issue #73914 (plugin auto-updates run unreviewed) —
which is exactly why `guardrail-check` fingerprints third-party hook code.

## Weakest claims — do not treat as established

- **"I scraped 85,000 skills / 10 million data points"** — contradicted by the video's own
  frame showing a blog table as the source.
- **85,000 community skills**, **11,000 with security issues** — no source shown.
- **caveman cuts output tokens ~75%** — creator's claim, unmeasured. Note our INDEX
  recorded a **65%** claim for the same plugin from video 4. Two different numbers for one
  unverified claim.
- **Karpathy skills at 160,000 stars / "fastest-growing single-file repo of 2026"** — not
  checked.
- **"three to five skills"** — attributed to unnamed "experts."
- Contains a **paid product placement** (the creator's own app, "Ace," with a discount
  code) and an earnings claim ("$40,000 in less than 50 days"). Same commercial pattern
  flagged for video 4 — treat the surrounding recommendations accordingly.

## Verdict

Low information density against what we already knew. Its real value is threefold:
independent confirmation that our plugin set matches what the wider community converged
on, a clean articulation of skill-vs-prompt, and a challenge to our plugin count that we
should answer rather than dismiss.
