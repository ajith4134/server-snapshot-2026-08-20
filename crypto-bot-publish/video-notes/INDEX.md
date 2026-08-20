# Video Research Index

Source material for how this project should be built. Each entry was processed
with `ytgrab` (full transcript + sampled frames read as images), never from the
title or description.

Status legend: **[read]** = transcript + frames actually reviewed.
                **[pending]** = artifacts pulled, not yet reviewed.

---

## 1. Stop Prompting Claude. Use Karpathy's Method Instead. — [read]

- Channel: Austin Marchese · 13:18 · uploaded 2026-06-09
- URL: https://www.youtube.com/watch?v=7zZy1QTvokM
- Artifacts: `karpathy-method/` — 425 cues (16.5 KB) + 32 frames
- Write-up: `karpathy-method/UNDERSTANDING.md`

**Core idea:** replace prompting with three durable layers — Spec, Verifier,
Environment.

**Key takeaways**
- AI is a *robot librarian*, not a colleague: answers only from its library, and
  doesn't know when a book is missing — so it confidently invents. Emotional
  levers (pressure, "try harder") are no-ops.
- **Verification is the only real lever.** Primary source, Boris Cherny (creator
  of Claude Code): a feedback loop "will 2-3x the quality of the final result."
- Separate the **task** from the **goal**; have Claude *interview you* to extract
  the goal. Work agile (small scoped specs + checkpoints), not waterfall.
- **A CLAUDE.md line is a GUIDE. A hook is a RULE.** "Never do" items must be
  enforced at the tool level (PreToolUse hook), not written as prose.
- Bucket every action: **always do / ask first / never do**.
- Anything done repeatedly becomes a **skill**. "Your data is your moat."

**Open action — CLOSED 2026-08-01.** Two PreToolUse hooks are live and verified
blocking (`~/.claude/hooks/`), plus 11 `permissions.deny` rules. Rule 4 documents
them. The **Stop hook** for verification now exists too
(`~/.claude/hooks/verify-before-stop.sh`, 8-case suite passing).

> **Follow-up 2026-08-01, later:** the Stop hook was registered, suite-green, and
> still inert. Its transcript read races the harness — the turn-ending assistant
> text block is flushed *after* Stop fires, so text-only turns looked empty and the
> hook failed open, blind to exactly the turns it polices. Fixed with a bounded
> re-read. Full write-ups in `~/.claude/projects/-home-anushadudekula71/memory/`:
> `stop-hook-transcript-flush-race`, `session-start-binding`,
> `hook-verification-needs-a-live-log`.
>
> This is the guide-vs-rule distinction going one level deeper: a hook is only a
> *rule* once it is observed firing. Registered, passing, and firing are three
> different states.

---

## 2. How Claude Code's Creator Starts EVERY Project — [read]

- Channel: Austin Marchese · 12:16 · uploaded 2026-04-01
- URL: https://www.youtube.com/watch?v=KWrsLqnB6vA
- Artifacts: `creator-starts-every-project/` — 403 cues (15.8 KB) + 29 frames
- Write-up: `creator-starts-every-project/UNDERSTANDING.md`

**Core idea:** Boris Cherny's (Claude Code's creator) six practices.

**Key takeaways**
1. **Plan mode for ~80% of sessions** (shift+tab twice). "Move slow to move fast" —
   all babysitting moves to before the plan.
2. **CLAUDE.md stays SHORT** (~2K tokens). "Do the minimal possible thing to get
   the model on track." Delete and start fresh when bloated.
3. **Verification** — same Cherny quote as video 1. Two steps: give Claude a tool
   to see its output, then tell Claude about the tool.
4. **Parallel partitioned sessions.** "Two context windows that don't know about
   each other tend to get better results." Fresh session beats a stuck one.
5. **Inner loops → slash commands / skills.** A prompt says "dribble"; a skill is
   the play to run.
6. **Never bet against the model** (The Bitter Lesson). Scaffolding decays; your
   information moat doesn't.

---

## 3. Paste This Into Claude, It'll Make You Build 10x Faster — [read]

- Channel: Austin Marchese · 15:12 · uploaded 2026-06-14
- URL: https://www.youtube.com/watch?v=TP73qyFWDcY
- Artifacts: `paste-this-into-claude/` — 506 cues (19.9 KB) + 46 frames
- Write-up: `paste-this-into-claude/UNDERSTANDING.md` (prompts VERBATIM from frames)

**Core idea:** six operational "power phrases" — the practical layer under
videos 1 and 2.

**Key takeaways**
1. **"Launch sub agents"** — Claude under-uses them by default; force it.
   Separate agents don't anchor on each other, so parallel perspectives stay diverse.
2. **"Write me an implementation spec"** — 3 steps × 5 options = 125 possible
   builds; a spec makes it 1. *"It doesn't know what you don't tell it."*
3. **"Interview me"** — bad output is usually a *thinking* problem. Only works if
   you actually think about your answers.
4. **"Verify before you build"** — give Claude a tool to see its output, then tell
   it about the tool. Plus **human validation zones** by cost of error, and
   *"explain the blast radius"* before touching hot zones.
5. **"Based on this conversation, build me a skill"** — never build skills
   abstractly; build from work you just did. Add a **gotchas** section over time.
6. **"Automate this"** — the dangerous one. Taste test + 80/20 filter first;
   prefer augmentation. Every automation is operational debt.

---

## 4. 9 Claude Code Plugins to Build 10x Faster — [read + fact-checked]

- Channel: Austin Marchese · 14:25 · uploaded 2026-05-13
- URL: https://www.youtube.com/watch?v=sBF3UumkL4Y
- Artifacts: `9-claude-code-plugins/` — 466 cues (18.3 KB) + 43 frames
- Write-up: `9-claude-code-plugins/UNDERSTANDING.md`

> ⚠️ Contains a **paid sponsor** (#4 Higgsfield) and the **presenter's own
> product** (#7 buildpartner.ai). Neither is in any marketplace.

**Verified against both real marketplaces** (276 official / 2,307 community):
5 of 9 confirmed official (`firecrawl`, `exa`, `skill-creator`, `frontend-design`,
`security-guidance`), 2 more in community (`caveman`, `burn`), 4 unverifiable
(`compound-engineering`, `higgsfield`, `buildpartner`, `morph`).

> **Corrected 2026-08-01** after reading the video's own description panel, which
> lists **13** install links — one more than this file had tracked. Two errors:
>
> 1. **`codex-plugin-cc` (OpenAI) was missed entirely.** Not in the official
>    marketplace. Notable in its own right: a competitor's plugin promoted inside
>    a Claude Code video.
> 2. **The "Anthropic legal plugin" claim was overstated.** This file said it
>    "does not appear to exist." A legal plugin *does* exist and *is* official —
>    **`legalzoom`** (source: `github.com/legalzoom/claude-plugins`, git-subdir).
>    What is wrong is the *attribution*: it is published by LegalZoom, not by
>    Anthropic. Branding error in the video, turned into a non-existence claim here.
>
> Lesson: the description panel is source material too. Transcript + frames missed
> a list that was one tap away, and the frames never showed the description.

**Key takeaways (the ideas, not the shopping list)**
- **Compound engineering** — the best content here. *"Each unit of engineering work
  should make subsequent units easier — not harder."* **80% planning and review,
  20% execution.** Loop: plan → work → review → compound → repeat.
  *"A good compound note means the next agent doesn't have to learn the same lesson
  from scratch."*
- **Research stack:** keyword search (native) → **semantic** search (Exa) →
  extraction (Firecrawl). Keyword returns SEO pages containing your words; semantic
  returns pages about your meaning.
- **Mechanical vs. reasoning tokens** — if code can do it deterministically, write
  the script instead of spending model tokens.
- **Maintainer matters** — prefer tools someone is paid to maintain. Our broken
  `mcp-youtube-transcript` independently confirms this.
- **Subsidy reality:** $200/mo Max against ~$1,800 of token value — the strongest
  external justification for our Rule 1.

**Official plugins found while verifying, relevant to our open items**:
`hookify` (hooks!), `code-simplifier`, `plugin-dev`, `hostinger` — still not
installed. `claude-md-management`, `code-review`, `superpowers` — now installed.

**Install status of this video's 5 official plugins (2026-08-01):** all 5 in —
`skill-creator`, `frontend-design`, `security-guidance`, plus `exa` and
`firecrawl` added today, which completes the research stack (semantic search →
extraction) that the takeaway above argues for.

---

## 5. Stop Prompting Claude. Start Loop Engineering. — [read]

- Channel: Austin Marchese · 12:15 · uploaded 2026-06-19 (most recent)
- URL: https://www.youtube.com/watch?v=YAS4ojuhbW4
- Artifacts: `loop-engineering/` — 401 cues (15.8 KB) + 37 frames + 7 dense frames
- Write-up: `loop-engineering/UNDERSTANDING.md`

> Extraction note: first pass returned **0 frames** (HTTP 403). Recovered via
> alternate player client; `ytgrab` now auto-retries. Prompt cards were faster than
> 20s sampling, so 7 timestamps were resampled at full resolution.

**Core idea:** stop prompting; write loops that prompt the agent.
Cherny: *"I don't prompt Claude anymore. I have loops that are running... My job is
to write loops."* Steinberg says the same independently.

**Key takeaways**
- **4-Condition Test** before any loop: does it repeat / is there a clear done-rule
  / can you afford waste / does it have the tools to verify.
- **Four blocks:** trigger (`/loop` local, `/schedule` cloud, or a custom
  orchestration skill) · execution skills · goal+verification · output+memory.
- **Skill-driven loop development:** *"You don't build a loop without battle-tested
  skills behind it."* Loops compose proven skills; never replace them.
- **Bridge abstract → verifiable:** make a skill emit approved/not-approved or a
  1-10 score. That's how non-quantifiable goals become loopable.
- **Memory:** *"The agent forgets, the repo doesn't."* A markdown file of lessons
  and run history is enough. No memory = no improvement.
- **Loop Training Mode** (the reusable safety pattern): ON by default — pause at
  every step for approval, skip steps already passing the done-rule, **cap retries
  so it can't loop forever**. Flip OFF only once proven.
- **Checkpoints for fuzzy goals** — human verification at the decisions that
  invalidate everything downstream if wrong.

---

## 6. I Scraped 85,000 Claude Skills. These Are The Most Popular — [read + fact-checked]

- Channel: **Dubibubi** · 14:46 · added 2026-08-01
- URL: https://www.youtube.com/watch?v=1GgyJfCK608
- Artifacts: `most-popular-skills/` — 411 cues (16.1 KB) + 15 frames
- Write-up: `most-popular-skills/UNDERSTANDING.md`

> ⚠️ First video here from a different creator, and the **weakest sourced**. Contains a
> paid placement for the creator's own product plus a "$40,000 in 50 days" earnings claim.

**Core content:** countdown of the 12 most-installed Claude Code plugins, plus caveman,
G-stack, and Karpathy skills as honorable mentions.

**The finding is in the frames, not the audio.** The video claims "I scraped 85,000
skills, 10 million data points." Frame f_002 shows the actual source: a third-party blog
table headed *"Public installs"* (Security Guidance **175,630** — the video's "175,000").
Verified independently: the official `marketplace.json` carries no install-count field at
all, so those numbers cannot have been scraped from it.

**Mirror image of video 4's lesson.** There, the description panel held content the
transcript and frames missed. Here, the frames expose what the audio overstates. Both
directions of the same rule: read every channel, trust none of them alone.

**Against our setup: we already have 10 of the 12.** The two we lack were both declined
deliberately, with recorded reasons — **GitHub MCP** (#7; ~3,100 tokens/turn vs the `gh`
CLI) and **code-simplifier** (#5; audited 2026-08-01, it is a refinement subagent, not the
hook tooling this INDEX had mis-filed it as). Popularity is not a reason.

**The one claim that indicts us:** *"Do not install all 12… the sweet spot experts agree
on is three to five skills matched to your actual workflow."* **We have 13 plugins
enabled.** The "experts agree" attribution is unsourced and the specific number is soft,
but the mechanism — standing context cost per plugin — is real and measured. This is an
open question against our setup, not a settled one.

**Best line:** *"A prompt asks Claude to think. A skill teaches Claude how to work."*

---

## Implementation audit — 2026-08-01

Every principle across all 6 videos, checked against what is on disk. **17 implemented.**

Verification → Rule 0 + 3 hooks + `guardrail-check` (enforced, not prose) · cost-of-error
buckets → Rule 0 · guides-vs-rules → Rule 4 · model selection → Rule 1 (now measured at
40%) · memory compounds → 6 memory files + this INDEX + `~/research` · minimal standing
context → the CLAUDE.md split · skills from real work → all 4 skills · abstract→verifiable
→ APPROVED/NOT APPROVED · 4-condition test → `guardrail-check` · Loop Training Mode → same
· scripts over model tokens → bash history logging · research before decisions → Rule 5 ·
YouTube → Rule 2 · install-don't-skip → Rule 3 · **interview → Rule 6** · **spec → Rule 6**
· **plan mode → Rule 6** · **never bet against the model + 80/20 automation filter → the
counterweight section.**

### Deliberately NOT implemented — decisions, not oversights

| Principle | Source | Why skipped |
|---|---|---|
| **Parallel partitioned sessions**; "two context windows that don't know about each other tend to get better results" | v2 #4 | Claude cannot open sessions. The portable half — *a fresh session beats a stuck one* — is advice to give in the moment, not a rule that changes behaviour. Too weak to earn standing tokens. |
| **"Launch sub agents"** — force their use, since Claude under-uses them by default | v3 #1 | **Directly conflicts with a standing session instruction**: "Do not call the AgentTool unless the user requested it." A rule telling Claude to spawn agents unprompted would contradict it. Rule 1 already governs *which* model once agents are requested. |

### The cost of completeness

Implementing the audit grew CLAUDE.md from ~2,590 to ~3,320 tokens in one step — after a
deliberate 37% cut earlier the same day. The user explicitly authorised overriding video
2's keep-it-short warning where a rule was useful enough. That trade is recorded here so
it stays a decision rather than drift, and it is exactly what the new **counterweight**
section exists to police: *when a rule stops changing what gets done, delete it.*

Still unaddressed: **standing plugin cost (~5,400 tokens/turn, 2.1x CLAUDE.md)** and
video 6's 3-5 plugin guidance. Cutting `firecrawl` alone returns ~1,900 tokens/turn —
proposed, not yet decided.

---

## Cross-video synthesis — all 6 videos read

> **Updated 2026-08-01** for video 6. Videos 1-5 are one creator (Austin Marchese) and
> form the ladder below. Video 6 is a different creator, is the weakest sourced, and adds
> exactly one thing to the synthesis: **standing context cost is a real budget, and
> plugins are the largest line item in it.** Measured the same day — 66 plugin-supplied
> skills/commands/agents inject **~5,400 tokens per turn**, more than twice the whole of
> CLAUDE.md (~2,590). Two plugins account for 72% of it. Video 2's "keep CLAUDE.md short"
> discipline was being applied to the smaller half of the problem.

> All five are from one channel (Austin Marchese). Treat the *packaging* as one
> person's synthesis; the load-bearing parts are the direct quotes from Boris
> Cherny (creator of Claude Code), Andrej Karpathy, and Peter Steinberg, plus the
> Compound Engineering README. Where a claim appears in only one video and comes
> from the presenter rather than a primary source, it is weaker evidence.

### The one thing every video agrees on

**Verification is the highest-leverage practice.** The same Cherny quote appears in
three of the five, read on screen each time:

> *"Give Claude a way to verify its work. If Claude has that feedback loop, it will
> 2-3x the quality of the final result."*

Sharpest operational form (video 2, restated in 3):
**(1) give Claude a tool to see the output of its work. (2) Tell Claude about that
tool.** The rule says *what* to verify; the tool says *how*.

### The through-line: a ladder of abstraction

The five videos are rungs, not alternatives:

| Rung | Unit of work | Video |
|---|---|---|
| 0 | Prompts | (what everyone starts with) |
| 1 | **Specs** — decide before building | 1, 3 |
| 2 | **Verification** — a feedback loop | 1, 2, 3 |
| 3 | **Skills** — repeatable, battle-tested units | 2, 3, 4 |
| 4 | **Loops** — the loop prompts the agent, not you | 5 |

Each rung requires the one below. Loops without skills fail; skills without
verification produce confident garbage; verification without a spec has no
definition of "correct".

### Principles that survived all five

1. **Separate the goal from the task.** The goal is the decision the work drives —
   AI can never supply it. Extract it by having Claude *interview you* (all 5).
2. **Specs collapse the option space.** 3 steps × 5 options = 125 possible builds;
   a spec makes it 1. *"It doesn't know what you don't tell it."*
3. **Front-load the effort.** Compound Engineering: **80% planning and review, 20%
   execution.** Cherny: ~80% of sessions start in plan mode. "Move slow to move fast."
4. **Build skills from work you already did**, never from abstraction. Ask "should
   this become a skill?", not "what skill should I build?"
5. **Bridge abstract → verifiable.** Make a skill emit approved/not-approved or a
   1-10 score. This is what makes non-quantifiable work checkable.
6. **Memory is what makes it compound.** *"The agent forgets, the repo doesn't."*
   A markdown file of lessons is enough. No memory = repeating the same mistakes.
7. **Guides vs rules.** Prose in CLAUDE.md is a *request*; a hook is a *rule*.
   Bucket everything: **always do / ask first / never do** — and "never do" must be
   enforced at the tool level.
8. **Earn autonomy incrementally.** Loop Training Mode ON by default: approve each
   step, skip already-passing steps, **cap retries**. Turn it off only once proven.
9. **Prefer scripts to model calls for mechanical work.** "A lot of your token spend
   is on mechanical work, not reasoning."
10. **Cost of error decides the guardrail.** Low-cost zones move fast; high-cost
    zones (payments, deletion, deploys) need human sign-off and "explain the blast
    radius."

### Genuine disagreements

| Question | Position A | Position B | Resolution |
|---|---|---|---|
| CLAUDE.md size | Rich environment (v1) | Minimal, delete when bloated (v2) | **Not size — TYPE.** Lines that *change what Claude does* earn their place; text that merely *describes* is bloat. |
| Prompt tuning | Be precise (v1, v3) | Largely wasted; models improve (v2) | Scaffolding decays, **context does not**. "It doesn't know what you don't tell it." |
| Automation | Loops everywhere (v5) | Every automation is operational debt (v3) | Taste test + 80/20 filter *first*; then Loop Training Mode to earn autonomy. |

### Weakest claims (flagged, do not treat as established)

- **"10x faster"** — unmeasured in all five titles.
- **Video 4 is ~2/9 commercial** (a paid sponsor and the presenter's own product,
  neither in any marketplace).
- Morph's performance numbers are self-described as "theoretical"; the presenter
  says he could not test them.
- The Steinberg quote (v5) is shown but unsourced on screen; not independently
  verified.
- Compound Engineering is not in either official or community marketplace, despite
  being presented as installable.

### What this implies for our setup

1. **Build the enforcement layer first.** Every rule we have is currently prose.
   This is the single clearest gap across all five videos.
2. **Split CLAUDE.md by type**, not by size — durable environment facts vs.
   behavioural rules.
3. **Skills come later**, from work we've actually done. Do not pre-build them.
4. **Verification must be structural** — a CLAUDE.md line requiring a verification
   plan before multi-step work, plus real tools to check output.
5. **Loops come last**, and only on top of battle-tested skills.

---
