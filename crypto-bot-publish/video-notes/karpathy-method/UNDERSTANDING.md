# The Karpathy Method — 3 Layers for Working With Claude

**Source:** "Stop Prompting Claude. Use Karpathy's Method Instead." — Austin Marchese
**URL:** https://www.youtube.com/watch?v=7zZy1QTvokM
**Length:** 13:18 · Uploaded 2026-06-09
**Extracted:** 2026-08-01 · 425 caption cues (16.5 KB) + 32 sampled frames
**Basis:** Full auto-caption transcript, plus on-screen frames read directly.

---

## Core thesis

Prompting is the wrong unit of work. Replace it with three durable layers:

| Layer | Name | Question it answers |
|---|---|---|
| 1 | **The Spec** | What are we actually building, and why? |
| 2 | **The Verifier** | How do we know it's right? |
| 3 | **The Environment** | Where does this live so it compounds? |

Workshop analogy used in the video: the spec is the blueprint on the wall,
the verifier is the QC station by the door, the environment is the workshop.

---

## The framing problem: "animals vs ghosts"

Karpathy's claim: we instinctively treat AI like an *animal* (a human colleague)
— something with intrinsic motivation that responds to pressure. It isn't.
Quoted from the video: "these things are not animal intelligences. If you yell at
them, they're not going to work better or worse... it's all just statistical
simulation circuits."

The video's reframe (clearer than "ghost"): a **robot librarian**. It answers only
from the books in its library. If a book is missing it cannot help — and crucially
**it does not know the book is missing**, so it confidently invents.

Consequence: emotional levers do nothing. "Try harder," "make it better," pleading,
pressure — all no-ops. **The only real lever is verification.**

Illustrative failure the video verified across Claude, Gemini, Grok, and ChatGPT:
"I want to go to a car wash 50m away, should I drive or walk?" — all say walk.
All miss that the car must be there. AI is strong where things are measurable and
blind where context is unstated.

---

## Layer 1 — The Spec

Karpathy on plan mode: *"I actually don't even like the plan mode... there's
something more general here where you have to work with your agent to design a
spec that is very detailed."* Not that plan mode is bad — that it stops too shallow.

### 1. Uncover the goal (not the task)
"Create an end-of-month report" is a **task**. The **goal** is the conclusion it
supports or the decision it drives. AI can never decide the goal — that's yours.

Technique: **make Claude interview you.**
> "Interview me to identify the goal of this project."

### 2. Be agile, not waterfall
Waterfall = hand over the whole job, see the result at the end. Agile = small
buckets, visible checkpoints, correct course as you go. People default to waterfall
with agents because it's tempting to dump everything at once.

> "Bias towards smaller and more compartmentalized specs."

### 3. Be precise, and use your own brain
Every assumption the model makes is a chance to drift. And when Claude writes a
spec *for* you, you still have to read it critically.

> "Make me verify key decisions explicitly to ensure nothing is missed."

---

## Layer 2 — The Verifier

The load-bearing layer. **Primary source, read directly off-screen** — Boris
Cherny, creator of Claude Code:

> "Probably the most important thing to get great results out of Claude Code —
> give Claude a way to verify its work. If Claude has that feedback loop, it will
> 2-3x the quality of the final result. [...] Verification looks different for
> each domain. It might be as simple as running a bash command, or running a test
> suite, or testing the app in a browser or phone simulator. Make sure to invest
> in making this rock-solid."

### 1. Define evaluation criteria UP FRONT
Before Claude touches anything. Vague: "make this report look good." Precise:
"the report must have three sections, each ending with a recommendation."

> "Outline the evaluation criteria you will use to ensure a high-quality final
> product. Be precise."

### 2. Use a second model as critic
A second librarian with a different library may see what the first cannot.
Video's tactical suggestion: the Codex plugin inside a Claude Code session —
"if this turns into a complex build, run the final output by Codex to ensure
both systems agree."

### 3. Pull external signal
Verification beats assertion. Don't let Claude *claim* the deploy worked —
connect it to the deploy target so it can check. Non-technical version: feed in
past reports so the format is checked against reality, not imagination.

---

## Layer 3 — The Environment

Where layers 1 and 2 live. The point: most people rebuild the workshop from
scratch every session. A single long chat is explicitly NOT what this means.

### 1. A real CLAUDE.md
Auto-injected every prompt — the first thing Claude reads. Example given:
"before building anything multi-step, include a verification plan" — which makes
verification structural instead of something you must remember to ask for.

**His actual CLAUDE.md, read off-screen** (titled `CLAUDE.md - Internal-OS`,
"Knowledge management and agent orchestration for personal brand content creation"):

    How This Repo Works
      .claude/skills/   — Slash-command workflows (scripts, newsletters, thumbnails)
      .claude/agents/   — Consultant personas loaded by skills and agent tool
      knowledge/        — Three-layer knowledge base
      projects/         — Active and completed work (youtube, shorts, newsletters, linkedin)
      scripts/          — Python utilities for transcript processing

    "Skills are the primary interface. When in doubt, invoke the skill."

    Skill Routing
      Video idea/title brainstorm  -> /youtube-1-idea-research
      Thumbnail text               -> /youtube-thumbnail-text
      Thumbnail concepts           -> /youtube-2-thumbnail
      Deep research for a video    -> /youtube-3-script-research
      Write or revise a script     -> /youtube-4-script-writer
      Full script review           -> /youtube-4b-script-reviewer
      Line-by-line simplification  -> /youtube-4c-script-simplifier

    Pipeline order (do not skip): 4-script-writer -> 4b-script-reviewer
      -> user iteration -> 4c-script-simplifier -> youtube-sync
    The Notion push REFUSES to run until script-final.md has
      status: polish_complete in its YAML frontmatter (set by 4c on completion).

Note the shape: sections for **how the repo works**, **skill routing**,
**knowledge architecture**, and **hard working rules**. And note the last line —
a machine-enforced gate, not a polite request.

### 2. Build an LLM knowledge base
Karpathy's viral concept: a folder system holding your own material, organised so
Claude can find things. The video's framing: **"your data is your moat."**

### 3. Build a skill set
Rule of thumb: **anything you'll do repeatedly becomes a custom skill.** A skill is
a handbook for one task, and it improves with use.

> "The best way to find a leak in a hose is to run water through it."

### 4. Guardrails — the guide/rule distinction
**The sharpest practical idea in the video.** A CLAUDE.md line like "don't touch
/important-dont-edit" is a **request**. Claude can still ignore it. To make it a
**rule**, enforce it at the tool level — a **PreToolUse hook** that intercepts
Write/Edit and blocks the path. Then Claude *cannot* do it.

Bucket every action into three:

| Bucket | Meaning | Mechanism |
|---|---|---|
| **Always do** | autopilot | permissions allowlist |
| **Ask first** | needs a human look | confirmation prompt |
| **Never do** | cannot be crossed | **hook — not prose** |

---

## The closing point

> "You can outsource your thinking, but you can't outsource your understanding."

All three layers depend on *your* understanding of the goal. That's the part that
doesn't transfer to the model.

---

## Assessment — what's genuinely useful vs. filler

**Strong, act on it:**
- Guide vs. rule (prose vs. hook). Concrete, testable, and we can implement it today.
- Verification as the only real lever — backed by a primary source (Cherny), not
  just the presenter's opinion.
- Goal ≠ task, extracted by having Claude interview you.
- "Repeated thing → skill."

**Weaker / caveats:**
- "Karpathy's method" is the presenter's synthesis. Karpathy is quoted on the spec
  and on animals-vs-ghosts; the clean 3-layer structure is Marchese's packaging.
- The Codex-as-critic tip is vendor-specific and may not fit this setup.
- ~30 seconds is a subscribe/giveaway break (08:18-08:50) — no content.

**Gap relative to what we've built:** our CLAUDE.md currently has good *hard rules*
(Rules 1-3) but no "how this repo works" or skill-routing section, because there is
no project yet. No hooks are configured, so we currently have zero "never do"
enforcement — everything is a guide.
