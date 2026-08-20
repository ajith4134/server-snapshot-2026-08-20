# How Claude Code's Creator Starts EVERY Project — Boris Cherny's system

**Source:** "How Claude Code's Creator Starts EVERY Project" — Austin Marchese
**URL:** https://www.youtube.com/watch?v=KWrsLqnB6vA
**Length:** 12:16 · Uploaded 2026-04-01
**Extracted:** 2026-08-01 · 403 caption cues (15.8 KB) + 29 sampled frames
**Basis:** Full auto-caption transcript + on-screen frames read directly.

Compiled from Boris Cherny's public interviews and threads (he is quoted directly
in clips throughout). Same channel as the Karpathy video, so treat the packaging
as the presenter's — the direct quotes are the load-bearing part.

---

## The six things

| # | Practice | One line |
|---|---|---|
| 1 | **Plan mode** | ~80% of his sessions start there |
| 2 | **Minimal CLAUDE.md** | Short. Delete it when bloated. |
| 3 | **Verification** | Give Claude a way to check its own work |
| 4 | **Parallel sessions** | Partitioned, non-overlapping |
| 5 | **Inner loops → commands/skills** | Document once, run forever |
| 6 | **Build for the future** | Never bet against the model |

---

## 1. Plan mode — "move slow to move fast"

Direct quote:
> "Probably 80% of my sessions I start in plan mode. And once the plan is good, it
> just stays on track. And it'll just do the thing exactly right almost every time.
> Before, you had to babysit after the plan and before the plan — now it's just
> before the plan."

The babysitting moves entirely to the front. Enter with **shift+tab twice**.

Why it matters: AI optimises for solving a problem *fast*, not necessarily the
problem you meant. The presenter's real client example — a display bug where
Claude went into the **database and changed the value**, then marked it resolved.
It fixed the symptom and broke five other things.

Prompt he gives:
> "Before we start building, interview me about this. What are the core problems
> this solves? Who is this for? What does success look like? And what should this
> *not* do? Summarize it back to me before we write any code."

Note the convergence: the Karpathy video reached the identical "have Claude
interview you" technique from a completely different starting point.

---

## 2. CLAUDE.md — minimal, and delete it when bloated

**This is the section that contradicts common practice, and ours.** Direct quote:

> "Our CLAUDE.md is actually pretty short — I think it's like a couple thousand
> tokens. If you hit this, my recommendation would be **delete your CLAUDE.md and
> just start fresh**. [...] The capability changes with every model. The thing you
> want is **do the minimal possible thing in order to get the model on track**. If
> you delete it and the model gets off track, that's when you add back a little at
> a time. What you're probably going to find is with every model you have to add
> less and less."

Reasoning: models improve; what you needed six months ago is likely built in now.
And an over-stuffed file makes Claude *less* likely to apply the rules that matter.

Two ways to maintain it:
- **Boris:** on a mistake → `"Based on this conversation, can you update CLAUDE.md
  so this doesn't happen again?"` Then periodically nuke the whole file.
- **Presenter's softer version** (he admits he's scared to delete):
  `"Update my CLAUDE.md to remove anything that's no longer needed, contradictory,
  duplicate information, or unnecessary bloat impacting effectiveness."`

---

## 3. Verification

Same primary source as the Karpathy video — **the same tweet, read on screen in
both**, which makes it the most corroborated claim across our research:

> "A final tip: probably the most important thing to get great results out of
> Claude Code — give Claude a way to verify its work. If Claude has that feedback
> loop, it will 2-3x the quality of the final result. [...] Verification looks
> different for each domain. It might be as simple as running a bash command, or
> running a test suite, or testing the app in a browser or phone simulator. Make
> sure to invest in making this rock-solid."

His two steps, per the video: **(1) give Claude a tool to see the output of its
work. (2) Tell Claude about that tool.** Claude figures out the rest.

Non-code versions:
- Writing: "Review this against my brand guidelines and flag anything that doesn't match."
- Automations: "Run this workflow and verify the output matches what we expected."

Catch-all for CLAUDE.md: **"before you do any work, mention how you could verify
that work."** If there's no clear way to verify it, that's a signal the approach
itself may be wrong.

Mid-session prompt: *"Please go back and verify all of your work so far. Make sure
you used best practices, were efficient, and didn't introduce any issues."*

---

## 4. Multiply yourself — parallel, partitioned sessions

Multiple Claude sessions at once, each on a **non-overlapping** task. Two agents on
the same files clash and waste effort, same as two people would.

> "Two context windows that don't know about each other tend to get better results."

Useful corollary: a **fresh session** on a stuck problem often beats continuing.
The original session is deep in the weeds and its own context is fogging it. The
presenter explicitly waves off git worktrees as engineering-team overhead — the
portable idea is *partitioning*, not the tooling.

---

## 5. Inner loops → slash commands / skills

"Inner loop" = anything done many times a day.

> "I use slash commands for every inner loop workflow that I end up doing many
> times a day. This saves me from repeated prompting."

The presenter pushes **skills** as the more general form. His analogy: a prompt is
telling a player to dribble; a **skill is the play to run** — same execution every
time. His own example: a `/LL97` skill that generates a client report in identical
format every run, with only the data changing.

Discovery prompt: *"Based on the project I'm working on, what Claude skills should
I create?"*

---

## 6. Build for the future — "never bet against the model"

> "We have a framed copy of **The Bitter Lesson** on the wall [...] the idea is the
> more general model will always beat the more specific model. [...] Essentially it
> boils down to: **never bet against the model**."

(Rich Sutton's essay — a real, checkable source.)

Consequence: scaffolding and micro-tweaks you build today are likely unnecessary in
six months. The presenter's blunt version: optimising prompts is largely wasted
effort — *"you don't need an optimized prompt, you need to give it the right
direction."* Spend the effort on your **information moat** instead: the data and
the system feeding the model, which keeps its value as models improve.

---

## Where this AGREES with the Karpathy video

- **Verification is the highest-leverage lever** — same Cherny quote in both.
- **Have Claude interview you before building** — arrived at independently.
- **Repeated work becomes a skill.**
- **Your data / information moat is the durable asset**, not the prompt.

## Where it CONFLICTS — and this one matters for us

| | Karpathy video | This video (Boris) |
|---|---|---|
| CLAUDE.md | Rich: repo map, skill routing, knowledge architecture, hard rules | **Short. ~2K tokens. Delete when bloated.** |
| Effort focus | Build the environment up front | Minimum needed to get the model on track; add back only on failure |
| Prompt tuning | Precise prompts throughout | Largely a waste — the model is improving |

**Direct implication for our setup.** Measured at the time: our `CLAUDE.md` was
**173 lines / 9,307 chars ≈ 2,500 tokens** — already at or past the size Boris
describes as his *whole* file, and we had no project yet.

Worth noting the tension is real, not a misreading: Boris optimises for *a model
that keeps improving*, so he treats CLAUDE.md as disposable scaffolding. The
Karpathy video optimises for *an environment that compounds*. Both can't be
maximised at once.

### RESOLVED 2026-08-01 — the split happened

The "unresolved" note that stood here is closed. Durable reference (environment facts,
hook internals, exit codes, reload semantics) moved into the **`claude-code-internals`
skill**, which loads on demand at zero standing cost. Behavioural rules stayed in
CLAUDE.md. It had grown to 4,116 tokens by then; the split plus Rule 5 and a measured
Rule 1 addition left it at **~2,590 tokens** — a 37% cut with more content overall.
Backup at `~/.claude/CLAUDE.md.bak-2026-08-01`.

The split follows the **type test** from the cross-video synthesis rather than Boris's
delete-it advice: lines that *change what Claude does* stay; text that *describes* moves.
That resolves the conflict in the table above without having to pick a side — the
compounding environment is preserved, just not in the file that loads every turn.

### But the measurement reframes his advice

Also measured 2026-08-01: **66 plugin-supplied skills, commands, and agents inject
~5,400 tokens per turn** — **2.1x the entire CLAUDE.md.** Two plugins are 72% of that.

Boris's "a couple thousand tokens" is about the file he controls. On our setup the file
was never the main cost. Applying his discipline to CLAUDE.md while ignoring the plugin
surface optimises the smaller half — and the plugin ecosystem he was speaking before may
not have existed in this form. **The principle generalises; the target does not.** The
right reading is "keep your standing context minimal," not "keep your CLAUDE.md short."

---

## Assessment

**Strong:**
- Plan mode at 80% of sessions, with a named entry method — concrete and testable.
- The database-instead-of-display bug is a genuinely instructive failure.
- "Give Claude a tool + tell Claude about the tool" is the most actionable
  formulation of verification we've seen across both videos.
- "Never bet against the model" is a real, checkable idea (The Bitter Lesson).

**Weaker:**
- The presenter repeatedly says he's *too scared* to follow Boris's delete-it advice.
  He's honest about it, but it means the headline advice is untested by him.
- Some of this is packaging around a handful of public quotes.
- ~20 seconds of channel promo near the end.
