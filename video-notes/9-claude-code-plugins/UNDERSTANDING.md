# 9 Claude Code Plugins — with independent verification

**Source:** "9 Claude Code Plugins to Build 10x Faster" — Austin Marchese
**URL:** https://www.youtube.com/watch?v=sBF3UumkL4Y
**Length:** 14:25 · Uploaded 2026-05-13
**Extracted:** 2026-08-01 · 466 caption cues (18.3 KB) + 43 sampled frames
**Basis:** Full transcript + frames, **plus a live check of both Anthropic plugin
marketplaces** (276 official / 2,307 community entries pulled 2026-08-01).

> ⚠️ **Commercial content.** Plugin #4 (Higgsfield) is a **paid sponsor** — stated
> in the video. Plugin #7 (buildpartner.ai) is **the presenter's own product**.
> Treat those two as advertising, not recommendation.

---

## Verification — what actually exists

I checked every named plugin against the real marketplaces rather than taking the
video's word for it.

| # | Plugin | Claim | **Verified** |
|---|---|---|---|
| 1 | caveman | condense output | **community** ✓ |
| 2 | firecrawl | scraping | **OFFICIAL** ✓ |
| 2 | exa | semantic search | **OFFICIAL** ✓ |
| 3 | compound-engineering | plan/work/review/compound | **not in either marketplace** |
| 4 | higgsfield | media generation | **not found — SPONSOR**, own MCP connector |
| 5 | skill-creator | build skills | **OFFICIAL** ✓ |
| 5 | frontend-design | UI variants | **OFFICIAL** ✓ |
| 5 | security-guidance | audit | **OFFICIAL** ✓ |
| 5 | "their legal plugin" | legal | **mischaracterised** — only `legalzoom` exists (LegalZoom the company, not Anthropic) |
| 6 | codex | OpenAI in Claude Code | not by that name; community has `codex-bridge`, `codex-review`, `codex-dispatch`, `codex-hud`, `claude-codex-loop` |
| 7 | buildpartner | expert advice | **not found — PRESENTER'S OWN** |
| 8 | morph | faster edit/search | **not in either marketplace** (paid, third-party) |
| 9 | code burn | token spend dashboard | community as **`burn`** ✓ |

**Net:** 5 of 9 verified in the official marketplace, 2 more in community. **The
sponsor's plugin and the presenter's own plugin are in neither** — both install
from their own sources. That's the clearest signal about which parts of this video
are editorial and which are commercial.

---

## The one genuinely valuable idea: Compound Engineering

Even though the plugin isn't in the marketplaces, **its philosophy is the best
content in the video.** Read directly from its README on screen:

> "AI skills and agents that make each unit of engineering work easier than the last."
>
> **Each unit of engineering work should make subsequent units easier — not harder.**
>
> Traditional development accumulates technical debt. Every feature adds
> complexity. Every bug fix leaves behind a little more local knowledge that
> someone has to rediscover later. The codebase gets larger, the context gets
> harder to hold, and the next change becomes slower.
>
> Compound engineering inverts this. **80% is in planning and review, 20% is in
> execution:**
> - Plan thoroughly before writing code with `/ce-brainstorm` and `/ce-plan`
> - Review to catch issues and calibrate judgment with `/ce-code-review` and `/ce-doc-review`
> - Codify knowledge so it is reusable with `/ce-compound`
> - Keep quality high so future changes are easy
>
> "The point is not ceremony. The point is **leverage**. A good brainstorm makes
> the plan sharper. A good plan makes execution smaller. A good review catches the
> pattern, not just the bug. **A good compound note means the next agent does not
> have to learn the same lesson from scratch.**"

**The 80/20 planning-to-execution ratio is the single most concrete number across
all four videos**, and the last line is exactly what our `video-notes/` +
`CLAUDE.md` practice is already doing.

The presenter's five-step loop: **plan → work → review → compound → repeat.**

---

## Two plugin-selection principles (on screen)

1. **The maintainer matters.** Bias toward tools where someone is *paid* to keep
   them working. (Our own experience backs this: `mcp-youtube-transcript` — 463
   stars, community-maintained — is broken upstream right now.)
2. **"Don't be one plugin from extinction."** If an Anthropic release would kill
   what you're building, reconsider what you're building.

---

## The research stack (#2) — the genuinely useful technical point

Three layers, each doing a different job:

| Layer | Mechanism | Good for |
|---|---|---|
| Claude native search | **keyword** match | fetching a URL you already know |
| **Exa** | **semantic** search | *finding* the right sources |
| **Firecrawl** | extraction | pulling clean content (handles JS, strips nav/footer) |

The distinction is real: keyword search returns SEO-optimised pages containing your
words; semantic search returns pages *about* your meaning. His analogy — a good
intern doesn't paste your phrase into Google and take the top five.

> "Your AI output is only as good as the information you provide."

---

## Multi-model (#6) — the argument, minus the plugin

The plugin name doesn't check out, but the reasoning is sound:
- **Different models are good at different things** — a second opinion can unstick
  a problem, same logic as video 1's "second librarian" critic.
- **Model independence is a muscle worth flexing.** Current pricing is VC-subsidised.
  His own number: **$200/month Claude Max against ~$1,800 of token value** — so if
  subsidies end, you want to already know how to switch.

That $1,800-vs-$200 figure is also the clearest justification I've seen for our
**Rule 1** (use the lightest adequate model) — the allowance is worth far more than
its sticker price.

---

## Mechanical vs. reasoning token spend (#8)

Morph isn't verifiable, but the underlying idea is portable and good:

> "A lot of your token spend is on **mechanical work, not actually reasoning**."

Portable prompt, no plugin needed:
> "Based on everything that I use in my Claude Code project, is there anything that
> I can convert to a script that will allow me to use code instead of using AI to
> complete a task?"

**If code can do it deterministically, write the script.** Don't spend model tokens
re-deriving mechanical work. (This is exactly why `ytgrab` is a script and not a
prompt.)

---

## Relevant plugins the video did NOT mention

While verifying, I found these in the **official** marketplace — several bear
directly on our open items:

- **`hookify`** — hooks. Our #1 open item is that nothing is currently unbypassable.
- **`claude-md-management`** — CLAUDE.md maintenance. Directly relevant to the
  size/split conflict from video 2.
- **`code-review`**, **`code-simplifier`**, **`pr-review-toolkit`**
- **`plugin-dev`**, **`mcp-server-dev`**, **`claude-code-setup`**
- **`superpowers`**, **`ralph-loop`**, **`remember`**, **`session-report`**
- **`hostinger`** — the exact deploy-verification example from video 3.

Not installed; recorded for the build step.

---

## Assessment

**Strong:**
- Compound engineering philosophy + the 80/20 planning ratio.
- Keyword vs. semantic search distinction — concrete and correct.
- "Mechanical vs. reasoning token spend" → convert repeated work to scripts.
- Maintainer-matters heuristic, which our broken-MCP experience independently confirms.
- The subsidy point ($200 paid / $1,800 consumed).

**Weak / caveats:**
- **Two of nine are commercial placements** (one paid sponsor, one own product) and
  neither is in any marketplace.
- The "Anthropic legal plugin" doesn't appear to exist as described.
- Morph's performance numbers are explicitly "theoretical" and the presenter admits
  he could not test them directly.
- "10x faster" is unmeasured, as in every video from this channel.
- Least methodologically useful of the four — it's a product list. Videos 1-3 give
  you technique; this one mostly gives you a shopping list, ~40% of which I could
  not verify.
