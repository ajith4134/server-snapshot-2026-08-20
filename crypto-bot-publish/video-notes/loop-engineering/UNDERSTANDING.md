# Loop Engineering

**Source:** "Stop Prompting Claude. Start Loop Engineering." — Austin Marchese
**URL:** https://www.youtube.com/watch?v=YAS4ojuhbW4
**Length:** 12:15 · Uploaded 2026-06-19 (most recent of the set)
**Extracted:** 2026-08-01 · 401 caption cues (15.8 KB) + 37 frames + 7 dense frames
**Basis:** Full transcript + frames read directly.

> **Extraction note (Rule 2, constraint 4).** The first frame pass returned **zero
> frames** — HTTP 403 on the video stream. Recovered by retrying with
> `player_client=android,web_safari`; `ytgrab` now auto-retries this. A second pass
> at 20s intervals showed almost only talking-head, because the prompt cards flash
> by faster than that — so I resampled seven targeted timestamps at full
> resolution. The verbatim prompts below come from that dense pass.

---

## The claim

Two toolmakers, independently:

> **Boris Cherny (creator of Claude Code):** *"What's actually leveled up, I think
> again, to the next level of abstraction, where **I don't prompt Claude anymore.
> I have loops that are running. They're the ones that are prompting Claude and
> kind of figuring out what to do. My job is to write loops.**"*

> **Peter Steinberg (creator of Open Claude):** *"You shouldn't be prompting coding
> agents anymore. You should be designing loops that prompt your agents."*

**A prompt runs once and stops. A loop runs repeatedly until a goal is verified
complete.** This is the highest-abstraction video of the five: videos 1–3 improve
*how you prompt*; this one argues you should stop being in the loop at all.

---

## Part 1 — The 4-Condition Test

Run before building any loop. All four must be yes.

| # | Condition | Fails if |
|---|---|---|
| 1 | **Does the task repeat?** | one-off → just use a prompt |
| 2 | **Is there a clear definition of done?** | you can't verify it |
| 3 | **Can you afford to be wasteful?** | loops self-prompt; they burn tokens |
| 4 | **Does it have the tools it needs?** | can't check its own work |

Condition 4 is the same point as video 3's *"give Claude a tool to see its output."*

**Verbatim prompt (dense frame, 02:25):**
> Audit my entire workspace and my conversation history. Based on what I do every
> week, what tools and files I already have set up, and what tasks I repeat. For
> each one, run the 4-Condition Test: 1) does it repeat, 2) can a rule decide if
> it's done, 3) can I afford a few wasted runs, 4) does AI have the data and tools
> it needs? Rank them as loop candidates and tell me which one to build first.

---

## Part 2 — Four building blocks

### Block 1: The trigger

| Method | Where it runs | Trade-off |
|---|---|---|
| `/loop` | **local machine** | simple; **dies when you close the laptop** |
| `/schedule` | **cloud** | runs remotely at a set time/cadence |
| **Custom loop orchestration skill** | you invoke it | *"this is actually how I run all of my loops"* |

The orchestration skill is one skill holding the goal, the steps, the done-rule and
the verification — you type `/check-weather-loop` and it runs the whole thing.

### Block 2: Execution skills — "skill-driven loop development"

**Called the most important of the four blocks.** The rule:

> **"You don't build a loop without battle-tested skills behind it."**

Why it matters, via his example: without a `/analyze-workout` skill, AI says *"it's
raining, cancel your run."* With a skill documenting that he **likes** running in
the rain, the answer inverts. The skill carries *your* preferences; the loop just
calls it.

This connects straight to video 3: skills come from work you already did manually
and validated. Loops then compose those proven skills. **Loops are built on top of
skills, never instead of them.**

### Block 3: Goal + verification (inseparable)

> "You can't have a goal unless you're able to verify the goal was complete."

**Technical example:** goal = *launch to this domain, loads under 2 seconds*;
verification = hit the domain, confirm expected content, measure load time, and
require `/engineer-review` to approve.

**Non-technical — the real insight: bridge the abstract to the verifiable.**
"Is this code good?" isn't measurable. But a `/engineer-review` skill that outputs
**approved / not approved** *makes* it measurable. Any skill can be converted into
a verifier by making its last step emit approved/not-approved or a 1-10 score.

Applied to a `/draft-emails` loop: goal = every unread email has a draft;
verification = each draft passes `/email-review`, `/writing-voice`, and
`/fact-checker`.

Pro tip: have a **different** model or a subagent judge the output for a less
biased opinion — same "second librarian" idea as video 1.

### Block 4: Output + memory

The output is obvious. **The memory is what people miss.**

> "Every loop starts from scratch unless you record what happened. **No memory means
> no improvement**, and you'll waste tokens hitting the same issues over and over."

Two quotes he leans on:
> **"The agent forgets, the repo doesn't."**
> Anthropic docs: *"Provide a place to write notes, as simple as a markdown file."*

Don't overthink it — a markdown file of lessons learned and run history is enough.

---

## Part 3 — Building your first loop

**Start from what already works.** *"What is the smallest thing you've already done
and proved works that you can create a loop for?"*

### Loop Training Mode — the guardrail (verbatim, dense frame 10:20)

**The single most reusable idea in this video.** Both prompts bake it in:

> **Build a Loop**
>
> The Task: [your weekly task].
> The Goal: [one sentence — what done looks like].
> The Verification: [the rule that confirms done].
>
> Build me ONE Orchestration Skill with the goal, steps, and done-rule pre-baked.
> Static. **Small enough to read in one sitting.**
>
> Bake in a feature called **Loop Training Mode** with these exact rules:
>
> - **When ON:** pause at every step and wait for my approval before continuing.
>   Skip any step that already passes the done-rule. Only re-run steps that fail.
>   **Cap retries so it can't loop forever.**
> - **When OFF:** run autonomously, no pauses, but keep the done-rule checks and
>   the retry cap.
>
> **Set Loop Training Mode to ON by default.** Document the toggle at the top of
> the skill file so I can flip it later.

And the discovery variant:

> **Identify Loop Options**
>
> Look at my past session history and find tasks I've done multiple times where I'd
> benefit from a loop. For each candidate, run the 4-Condition Test (repeats, clear
> done-rule, can afford waste, has the tools it needs). **Only suggest tasks where I
> already have a saved skill file for the work.** Tell me which one to build first,
> then build the Orchestration Skill with Loop Training Mode baked in.

Three safety properties worth naming explicitly, because they're the difference
between a loop and a runaway:
1. **Human approval per step while training** — *"quick check before I burn the tokens."*
2. **Skip steps already passing the done-rule** — don't redo satisfied work.
3. **Retry cap** — a hard stop so it cannot loop forever.

### Checkpoints for fuzzy goals

> "If a goal is less quantifiable, break the loop into much smaller goals with
> output at key checkpoints."

His analogy: telling an intern *"plan a corporate party"* could go anywhere — you'd
want checkpoints at date, venue, theme, because those decisions shape everything
downstream. **Your human verification checkpoints are the moments where a wrong
turn invalidates the rest of the run.**

---

## How this fits the other four videos

**This is the capstone.** It composes everything prior:
- Video 1's spec/verifier/environment → the loop's goal, done-rule, and skills.
- Video 2's *"give Claude a tool to see its output"* → 4-Condition Test #4.
- Video 3's *"build skills from work you just did"* → the prerequisite for loops.
- Video 4's compound engineering (*"a good compound note means the next agent
  doesn't have to learn the same lesson from scratch"*) → Block 4's memory file.

**New here:**
- Loops as the unit of work rather than prompts.
- **Skill-driven loop development** — never loop without battle-tested skills.
- **Bridging abstract → verifiable** by making a skill emit approved/not-approved.
- **Loop Training Mode**, with retry caps and step approval.
- "The agent forgets, the repo doesn't."

**Tension worth noting:** loops maximise autonomy; video 3 warned that every
automation is operational debt and to apply the taste test first. Loop Training
Mode is effectively the reconciliation — earn autonomy incrementally rather than
granting it up front.

---

## Assessment

**Strong:**
- The 4-Condition Test is a real gate, not a vibe — it will correctly reject most
  candidates.
- **Loop Training Mode with a retry cap** is the most directly reusable safety
  pattern in all five videos, and applies to any agent work, not just loops.
- "Bridge the abstract to the verifiable" solves the hardest part of non-technical
  verification.
- Two independent primary sources (Cherny, Steinberg) for the core claim.

**Weaker:**
- `/loop` and `/schedule` are described only briefly; no live demo of a loop
  actually running end-to-end.
- ~35s email-list promo (03:35) and ~30s subscribe/giveaway (08:17).
- The Steinberg quote is shown but not sourced on screen — I could not verify it
  independently.
