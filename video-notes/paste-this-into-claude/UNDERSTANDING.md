# Six Power Phrases for Claude Code

**Source:** "Paste This Into Claude, It'll Make You Build 10x Faster." — Austin Marchese
**URL:** https://www.youtube.com/watch?v=TP73qyFWDcY
**Length:** 15:12 · Uploaded 2026-06-14
**Extracted:** 2026-08-01 · 506 caption cues (19.9 KB) + 46 sampled frames
**Basis:** Full auto-caption transcript + on-screen prompt cards read directly.
All prompts below are transcribed VERBATIM from frames, not paraphrased.

The most practical of the three videos — it's the operational layer under the
concepts from videos 1 and 2.

---

## The six phrases

| # | Phrase | Purpose |
|---|---|---|
| 1 | "Launch sub agents" | Parallelism |
| 2 | "Write me an implementation spec" | Collapse the option space |
| 3 | "Interview me" | Extract what's in your head |
| 4 | "Verify before you build" | Feedback loop |
| 5 | "Based on this conversation, build me a skill" | Make it repeatable |
| 6 | "Automate this" | **Cautionary — the dangerous one** |

---

## 1. "Launch sub agents"

Problem: one session at a time = a single-lane highway. You wait, review, re-ask,
wait again.

**Key claim: Claude under-uses subagents out of the box.** The main agent thinks
"this is easy, I'll do it myself" and stays in its own context when a subagent
would have served better. So you force the issue.

Three good uses:
- **Multiple perspectives.** Five subagents on the same input via different lenses.
  Crucial detail: asking the same question five times *in one chat* makes the model
  anchor on its own prior answers and converge. Separate agents don't see each
  other, so the diversity is real.
- **Newly-possible work.** He launched 10 subagents to check 10,000+ domains —
  something never attempted serially.
- **Just faster**, when tasks are genuinely independent.

Simplest form — append to any prompt:
> "Launch five sub-agents to handle this."

Caveat he stresses: subagents amplify whatever clarity you gave them. Vague
instructions × 5 agents = 5× the disappointment. This is why phrase 2 follows.

---

## 2. "Write me an implementation spec"

**The statistical argument — the sharpest explanation across all three videos.**
Three build steps × five plausible options each = **125 possible builds**. Claude
picks one. Write a spec pinning each step and it becomes **1 × 1 × 1**.

> "Without a proper spec it's statistically impossible for Claude to get it right
> on the first try. And it literally doesn't matter how good these models get —
> **it doesn't know what you don't tell it**."

That last clause is the cleanest statement of why better models don't remove the
need for specs, and it directly limits video 2's "never bet against the model."

**Verbatim prompt (read off-screen):**
> Before you build anything, write me a spec for this project.
> What does it do? Who is it for? Who is it NOT for?
> What does success look like? What's out of scope?
> Then walk me through each step of how you'd build it,
> and **for each step show me the key decisions you'd make**
> and what you'd default to. Don't build anything yet.

The highlighted line is the load-bearing one: it surfaces decisions so you can
**override them before** anything is built.

Also quotes Karpathy on plan mode being useful but not deep enough — same clip as
video 1. Plan mode *helps you create* the spec; it doesn't replace it.

---

## 3. "Interview me"

Failure mode this fixes: Claude writes a spec, and you don't actually understand
what you're looking at. You know the goal at a high level but not the details that
decide the project.

> "When Claude's outputs aren't great, it usually boils down to a **thinking
> problem**." Claude asks the questions you didn't know to ask.

**Verbatim prompt (read off-screen):**
> Before we start building, interview me about what we're trying to build.
>
> Work with me to identify the core problem we're solving, who it is and isn't for.
>
> As part of the interview, let's work through any key decisions together to help
> inform the implementation strategy.
>
> Then summarize it back to me as an implementation spec before we write any code.

Three deliberate parts: **who it's for AND isn't for** (his Anthropic example —
they grew by being clear they were building for developers *and not others*);
**work through key decisions together** (if you don't know, say "use your best
judgment" — at least you now know what was decided); **summarize as a spec**.

**The trap:** it only works if you actually think. Rushing yes/no answers is the
same as letting Claude auto-answer. Pro tip offered: dictate answers by voice so
it feels like a real interview.

---

## 4. "Verify before you build"

Same Cherny quote as videos 1 and 2 (**now corroborated three times**), plus the
sharper version:

> **Give Claude a tool to see the output of its work. Then tell Claude about that tool.**
> "The verification rule tells Claude *what* to verify; the tool tells Claude *how*."

**Three layers:**

1. **CLAUDE.md line** — "Before you do any work, mention how you could verify that work."
2. **Enable tools** — ask: *"Based on what I'm building, what are some tools that
   could help with verification?"* External/technical (a deploy-platform MCP to
   confirm a deploy went live) or internal/non-technical (a brand-voice validator skill).
3. **Human validation zones** — identify where **cost of error is high**. His
   example: the marketing site is low-cost (move fast, break things); the **payment
   system is high-cost** → requires human sign-off. Murphy's law framing: with
   humans out of the execution loop, things *will* go wrong, so decide in advance
   where that's unacceptable.

**Verbatim CLAUDE.md prompt (read off-screen):**
> Enhance my Claude.md to include:
>
> Before you start any work, state how you would verify it.
> After you finish, run the verification and report results.
>
> Before changing any code in [HOT ZONE, i.e. payment/]
> ask me first and explain the blast radius.

"Explain the blast radius" is a genuinely good phrase — it forces scope-of-damage
reasoning rather than a yes/no permission check.

---

## 5. "Based on this conversation, build me a skill"

A skill = a folder of instructions Claude can call automatically. Same "play to
run" idea as video 2.

**The insight — never build skills abstractly.** Asking "what skill should I build?"
produces either nothing or a skill you never use. Build from a conversation you
**just had**, so the use case is already validated — you literally just did the work
manually; Claude only packages it.

> Reframe: not *"What skill should I create?"* but **"Should I turn this process
> into a skill?"** Concrete beats abstract.

**Gotchas section** (attributed to an Anthropic article on internal skill use):
edge cases, stylistic quirks, anything you had to correct. Append them over time.
> "Based on this conversation, enhance any skill I use to include a gotchas section
> so we don't make this mistake again."

---

## 6. "Automate this" — the cautionary one

The presenter is openly **skeptical** of this phrase and spends the section arguing
against over-use.

> "Unlike a lot of the YouTube AI productivity hype boys, almost nothing is the
> ideal scenario. You'll end up with a lot of non-ideal automations. **Each one adds
> operational debt you have to manage.**"

Prefer **augmentation** (streamline a process) over **automation** (remove yourself).

**Two filters, both read off-screen:**

**Filter 1 — the Taste Test.** *Does this task require taste to judge good vs bad
output, or is it entirely quantifiable?* Requires taste → **augment**. Quantifiable
→ automation candidate.

**Filter 2 — the 80/20 output analysis.** *If the output were 80% as good, would I
be okay with it?* Yes → automate. No → augment.

His own "Don't Require Taste" list (verbatim from screen):
- Research files
- Brainstorms / idea-research
- Website copy "below the fold"
- Technical implementation architecture on non-core features
- Internal OS and internal app builds
- Story maps & outlines
- A/B test logging & analytics
- Lived-experience logs
- Asset generation / mockups

> "What happens instead is people create a ton of automations that do nothing
> besides waste tokens and **produce AI slop at scale**."

Names **hooks, schedules, and loops** as the three most powerful Claude Code
features for automation/augmentation.

---

## How this fits with videos 1 and 2

**Corroborations:**
- Cherny's verification quote appears in all three → the single most-supported claim.
- "Interview me" appears in all three, reached independently each time.
- Skills-from-repeated-work in all three.
- Parallel/partitioned sessions here and in video 2.

**This video's unique contributions:**
- The **125 → 1** option-space argument for specs.
- **"It doesn't know what you don't tell it"** — the strongest counter to video 2's
  "never bet against the model." Better models don't fix missing context.
- **Skills must come from conversations you just had**, never from abstraction.
- **Taste test + 80/20 filter** before automating anything.
- **Human validation zones** keyed to cost of error.
- "Explain the blast radius."
- Claude **under-uses subagents by default** — you must ask explicitly.

**Tension with video 2 (CLAUDE.md size):** this video adds *more* to CLAUDE.md
(verification line, hot-zone rule). Video 2 says keep it minimal. Reconcilable:
both additions are **behavioural rules that change what Claude does**, which is
exactly what Boris says earns its place — as opposed to documentation that merely
describes things.

---

## Assessment

**Strong:**
- Every prompt is concrete and pasteable; I captured them verbatim from frames.
- The 125→1 argument is the best justification for specs in any of the three videos.
- The automation skepticism is genuinely counter-hype — he argues *against* the
  thing his title sells, which is a good sign.
- Human validation zones + blast radius map directly onto video 1's
  "always do / ask first / never do" buckets.

**Weaker:**
- "10x faster" is a title claim with no measurement behind it.
- ~40s of email-list promo (05:12) and ~30s of subscribe/giveaway (10:22).
- The claim that Claude under-uses subagents for "business reasons" is speculation,
  flagged as such by the presenter himself.
