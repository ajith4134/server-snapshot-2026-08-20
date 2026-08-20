# What Makes Code Deep — A Sourced Definition and a Reviewer's Checklist

Research date: 2026-08-08. Compiled by direct retrieval of primary sources (book excerpts,
the original papers, and empirical studies) — not paraphrased from secondary blog summaries
except where explicitly marked.

## Verdict

"Depth" has a rigorous, decades-old definition in the software-design literature, and it is
**not** the same thing as "well-organized" or "clean." Depth is a ratio: how much
functionality a module provides *divided by* how much a caller must learn to use it. John
Ousterhout's *A Philosophy of Software Design* names this explicitly — "the best modules are
those whose interfaces are much simpler than their implementations" — and traces it to David
Parnas's 1972 concept of information hiding: a good module hides a design decision, not a
line count. Fred Brooks separates the complexity a designer is stuck with (essential) from the
complexity tooling and notation impose (accidental) — depth is specifically the discipline of
absorbing essential complexity *into* a module instead of leaking it into every caller.

Empirically, LLM-generated code degrades in exactly the ways this theory predicts: less
"moved" (refactored/reused) code, more copy-pasted and duplicated blocks, higher code-smell
counts than human baselines, and in security-relevant contexts, a well-replicated tendency to
produce vulnerable code with high user confidence. The evidence is real but uneven in rigor —
industry telemetry studies (GitClear, Uplevel) are large-N but observational and not
peer-reviewed; the academic security studies (Pearce et al., Perry et al.) are peer-reviewed
but modest-N; the 2025 METR RCT on experienced developers is small-N but genuinely causal.

Depth is checkable. Section 4 below gives eight mechanical tests — none requires taste,
all can be applied to a diff by counting things.

---

## 1. Deep vs. shallow modules (Ousterhout, *A Philosophy of Software Design*)

**Source**: John Ousterhout, *A Philosophy of Software Design* (2018, 2nd ed. 2021),
Chapter 4 "Modules Should Be Deep." Verified against a scanned copy of the book (chapter/page
references below), Ousterhout's own Stanford CS 190 lecture notes, and his GitHub essay
responding to *Clean Code* (`johnousterhout/aposd-vs-clean-code`), which restates the
definitions in his own words outside the book.

### The core definition

> "In order to identify and manage dependencies, we think of each module in two parts: an
> interface and an implementation. The interface consists of everything that a developer
> working in a different module must know in order to use the given module... For the
> purposes of this book, a module is any unit of code that has an interface and an
> implementation... The best modules are those whose interfaces are much simpler than their
> implementations. Such modules have two advantages. First, a simple interface minimizes the
> complexity that a module imposes on the rest of the system. Second, if a module is modified
> in a way that does not change its interface, then no other module will be affected by the
> modification."
> — *A Philosophy of Software Design*, Ch. 4 (via scanned edition, djvu.online)

> "The best modules are deep: they have a lot of functionality hidden behind a simple
> interface... a shallow module is one whose interface is relatively complex in comparison to
> the functionality that it provides."
> — Ch. 4, quoted with Kindle locations 623 and 660 (gienverschatse.com book notes,
> cross-checked against the scanned text)

His own restatement, written for a general audience outside the book:

> "The best methods are those that provide a lot of functionality but have a very simple
> interface: they replace a large cognitive load (reading the detailed implementation) with a
> much smaller cognitive load (learning the interface). I call these methods 'deep.'"
> — Ousterhout, `johnousterhout/aposd-vs-clean-code` (GitHub), his critique of *Clean Code*'s
> `PrimeGenerator` example

His canonical example of a deep interface — worth quoting because it is concrete, not
metaphorical (from his 2018 Talks at Google presentation, delivered as part of the book
promotion, cross-checked wording against multiple transcript sources):

> Unix file I/O: five functions (`open`, `close`, `read`, `write`, `lseek`), each individually
> simple, and behind them "hundreds of thousands of lines of code" doing disk-space
> management, file caching, device drivers. "Just this amazingly beautiful five functions."

### The failure mode: shallow modules and "classitis"

> "A shallow module is one whose interface is complicated relative to the functionality it
> provides... Classitis: the extreme of the 'classes should be small' approach... stems from
> the mistaken view that 'classes are good, so more classes are better.' Classitis may result
> in classes that are individually simple, but it increases the complexity of the overall
> system. 1. Small classes don't contribute much functionality, so there have to be a lot of
> them, each with its own interface. These interfaces accumulate to create tremendous
> complexity at the system level. 2. Small classes also result in a verbose programming style,
> due to the boilerplate required for each class."
> — Ch. 4.6 "Classitis" (yiming.dev clippings, cross-checked against Kindle-location quote
> "classitis, which stems from the mistaken view that 'classes are good, so more classes are
> better'" at location 685, gienverschatse.com)

### Complexity, formally defined

Ousterhout does not use "complexity" loosely — he gives it a definition and a (informal)
formula:

> "Complexity is anything related to the structure of a software system that makes it hard to
> understand and modify the system."
> Complexity is caused by two things: **dependencies** and **obscurity**.
> "A dependency exists when a given piece of code cannot be understood and modified in
> isolation; the code relates in some way to other code, and the other code must be considered
> and/or modified if the given code is changed... Obscurity occurs when important information
> is not obvious... Complexity comes from an accumulation of dependencies and obscurities."
> — Ch. 2 (yiming.dev clippings; wording cross-checked against gienverschatse.com Kindle
> quotes at locations 339–446)

The overall complexity of a system is presented as a weighted sum over its parts: "the overall
complexity of a system (C) is determined by the complexity of each part (c_p) weighted by the
fraction of time developers spend working on that part (t_p)" — i.e., C = Σ c_p·t_p. This is
Ousterhout's own informal notation, reported consistently across two independent secondary
sources (yiming.dev, oehler.dev); it does not appear to be a citation to a formal empirical
model, and should be read as a mnemonic rather than a measured law. Marked for caution below.

Two named consequences of complexity that recur constantly in his checklist language:
**change amplification** (a simple conceptual change requires touching code in many places)
and **unknown unknowns** ("it is not obvious which pieces of code must be modified to
complete a task, or what information a developer must have to carry out the task
successfully" — gienverschatse.com, location 384).

### Information hiding as the mechanism, and information leakage as its failure

> "The most important technique for achieving deep modules is information hiding. This
> technique was first described by David Parnas. The basic idea is that each module should
> encapsulate a few pieces of knowledge, which represent design decisions."
> — Ch. 4 (gienverschatse.com, location 729)

> "The opposite of information hiding is information leakage. Information leakage occurs when
> a design decision is reflected in multiple modules. This creates a dependency between the
> modules: any change to that design decision will require changes to all of the involved
> modules."
> — Ch. 5.2, p. 31 (quoted via books.danielhofstetter.com summary, cross-checked against
> Stanford CS190 lecture notes: "Information leakage: opposite of information hiding —
> Implementation details exposed, other classes depend on them. Anything in the interface is
> leaked. Back-door leakage: not visible in the interface. Temporal decomposition: one of the
> most common causes of information leakage.")

**Pass-through methods** — a named, checkable red flag for shallow decomposition:

> "A pass-through method is one that does little except invoke another method, whose signature
> is similar or identical to that of the calling method... Pass-through methods indicate that
> there is confusion over the division of responsibility between classes... Pass-through
> methods are bad because they contribute no new functionality."
> — Ch. 7.1, p. 52 (books.danielhofstetter.com; corroborated by the book's own end-of-chapter
> "Red Flags" list at yingang.github.io/aposd2e-zh, an openly hosted copy of the book's
> official summary page: "Pass-Through Method: a method does almost nothing except pass its
> arguments to another method with a similar signature (see p. 52).")

### Tactical vs. strategic programming

> "Almost every software development organization has at least one developer who takes
> tactical programming to the extreme: a tactical tornado. The tactical tornado is a prolific
> programmer who pumps out code far faster than others but works in a totally tactical
> fashion... tactical tornadoes leave behind a wake of destruction. They are rarely considered
> heroes by the engineers who must work with their code in the future."
> — Ch. 3 (Goodreads quote page, cross-checked verbatim against two independent Goodreads
> listings and consistent with Ousterhout's own Stanford lecture-note outline of the same
> chapter: "Tactical programming — Goal is to get the next feature or bug fix working... Results
> in bad design, high complexity... Strategic programming — Primary goal is to produce a great
> design.")

> "The problem with test-driven development is that it focuses attention on getting specific
> features working, rather than finding the best design. This is tactical programming pure and
> simple, with all of its disadvantages."
> — Ch. 3 (Goodreads quote page)

Ousterhout's own summary framing of the book's overall claim, from his teaching materials
("Can Great Programmers Be Taught?", Stanford), lists the whole doctrine as one list:
"Working code isn't enough: must minimize complexity / Complexity comes from dependencies and
obscurity / Strategic vs. tactical programming / Classes should be deep / General-purpose
classes are deeper / New layer, new abstraction / Comments should describe things that are not
obvious from the code / Define errors out of existence / Pull complexity downwards."

---

## 2. Complementary sources: Parnas, Brooks, and abstraction quality

### Parnas (1972) — information hiding as a decomposition *criterion*, not a size rule

**Source**: D.L. Parnas, "On the Criteria To Be Used in Decomposing Systems into Modules,"
*Communications of the ACM* 15(12), December 1972. Full text retrieved directly (PDF, ACM
reprint hosted at jezuk.co.uk and cse.sc.edu — text cross-checked identical across both
mirrors).

Parnas's paper is not abstract theorizing — it is a worked comparison of two decompositions of
the same real system (a KWIC index generator), one using a conventional flowchart-driven
decomposition, one using information hiding. His conclusion is the origin of the entire "deep
module" idea forty-six years before Ousterhout's book:

> "The second decomposition was made using 'information hiding' as a criterion. The modules no
> longer correspond to steps in the processing... Every module in the second decomposition is
> characterized by its knowledge of a design decision which it hides from all others. Its
> interface or definition was chosen to reveal as little as possible about its inner workings."

> "We propose instead that one begins with a list of difficult design decisions or design
> decisions which are likely to change. Each module is then designed to hide such a decision
> from the others."

He also states the two axes on which he judges the decompositions — **changeability**
(independent development) and **comprehensibility** — and reports his own subjective
verdict directly:

> "The system [modularization 1] will only be comprehensible as a whole. It is my subjective
> judgment that this is not true in the second modularization."

He gives five concrete examples of information worth hiding — these are the direct ancestor of
Ousterhout's "design decisions" language:

1. A data structure and its accessing/modifying procedures belong in one module, not shared.
2. The routine and its calling sequence are one module.
3. Control-block formats belong in one module, not exposed as an interface.
4. Character codes and alphabetic orderings are hidden in one module.
5. The processing order of items should, as far as practical, be hidden in one module.

Parnas also demonstrates self-correction on his own example — showing depth is a discipline
you can still get wrong:

> "Hindsight now suggests that this definition [of the circular shift module] reveals more
> information than necessary... By prescribing the order for the shifts we have given more
> information than necessary and so unnecessarily restricted the class of systems that we can
> build... Our failure to do this... must clearly be classified as a design error."

### Brooks (1986) — essential vs. accidental complexity, and why depth is the strategy that attacks essence

**Source**: Frederick P. Brooks Jr., "No Silver Bullet — Essence and Accidents of Software
Engineering," *Computer* 20(4), April 1987 (widely dated 1986 for the original conference/tech
report version; full text retrieved from the UNC technical report PDF, cross-checked against
Duke and Dartmouth course-hosted PDF mirrors — text is identical).

> "All software construction involves essential tasks, the fashioning of the complex
> conceptual structures that compose the abstract software entity, and accidental tasks, the
> representation of these abstract entities in programming languages and the mapping of these
> onto machine languages within space and speed constraints."

> "Following Aristotle, I divide them into essence — the difficulties inherent in the nature of
> the software — and accidents — those difficulties that today attend its production but that
> are not inherent."

> "The complexity of software is an essential property, not an accidental one. Hence
> descriptions of a software entity that abstract away its complexity often abstract away its
> essence."

Why this matters for "depth": a deep module's whole value proposition is that it absorbs
essential complexity so callers don't have to re-derive it. Brooks is explicit that tooling
and language improvements (his target in the essay: Ada, OOP, high-level languages) can only
ever remove **accidental** complexity — "such advances can do no more than to remove all the
accidental difficulties from the expression of the design. The complexity of the design itself
is essential; and such attacks make no change whatever in that." This is the direct
justification for why "depth" cannot be manufactured by tooling, boilerplate reduction, or
code generation alone — a shallow module wrapped in a nicer syntax is still shallow, because
the essential complexity it fails to absorb is still there, still unhidden. Brooks also names
the four inherent properties of essence: **complexity, conformity, changeability, and
invisibility**.

### Abstraction quality: two more rigorous framings

1. **Ousterhout's own definition of abstraction**, cited directly (not paraphrased) because it
   is the connective tissue between "deep module" and "good abstraction":
   > "an abstraction is a simplified view of an entity, which omits unimportant details" — and
   > his direct claim that "deep classes are good abstractions" because the simplification is
   > large relative to what's hidden (Talks at Google transcript, cross-checked against the
   > `aposd-vs-clean-code` GitHub essay's restatement: "abstraction as 'a simplified way of
   > thinking about something [that] omits unimportant details.'").

2. **Joel Spolsky, "The Law of Leaky Abstractions"** (2002) — the necessary caution on
   abstraction quality, retrieved verbatim from joelonsoftware.com:
   > "All non-trivial abstractions, to some degree, are leaky."
   This is not a rebuttal of the deep-module thesis but a bound on it: depth reduces how often
   the leak matters (fewer callers touch the underlying complexity), but does not eliminate the
   leak. A checklist for "is this abstraction good" has to ask not just "is the interface
   simple" but "when it leaks, how far does the leak travel" — which is exactly Ousterhout's
   change-amplification framing applied to failure paths.

---

## 3. Empirical evidence on LLM-generated code quality

Honesty check up front: the strongest, most-repeated finding — LLM code has more duplication
and more code smells than human baselines — comes from a mix of large-N industry telemetry
(not peer reviewed, methodology partly proprietary) and smaller academic studies (peer
reviewed, rigorous, but modest sample sizes). Treat magnitude estimates as directional, not
precise.

### 3.1 Duplication and churn — GitClear, 2024 and 2025 reports

**Source**: GitClear, "Coding on Copilot: 2023 Data Suggests Downward Pressure on Code
Quality" (Jan 2024) and its 2025 follow-up "AI Copilot Code Quality: Evaluating 2024's
Increased Defect Rate" (Feb 2025). Both retrieved as full PDFs directly from GitClear's own
hosting (gitclear.com, gitclear-public.s3.amazonaws.com). **Not peer-reviewed** — this is a
vendor research report, though GitClear is a code-analytics company with a large proprietary
dataset and the methodology is documented in detail (operation taxonomy: Added / Deleted /
Moved / Updated / Find-Replaced / Copy-Pasted / No-op).

Methodology: 153 million changed lines of code (Jan 2020–Dec 2023) in the 2024 report,
extended to 211 million changed lines (through Dec 2024) in the 2025 report, drawn from a mix
of commercial customers (e.g., NextGen Health, Bank of Georgia) and popular open-source repos
(Facebook React, Google Chrome).

Key findings, quoted directly:

> "Code churn — the percentage of lines that are reverted or updated less than two weeks after
> being authored — is projected to double in 2024 compared to its 2021, pre-AI baseline... the
> percentage of 'added code' and 'copy/pasted code' is increasing in proportion to 'updated,'
> 'deleted,' and 'moved' code. In this regard, code generated during 2023 more resembles an
> itinerant contributor, prone to violate the DRY-ness of the repos visited."

Year-over-year operation changes reported for 2022→2023: Added +3.1%, Deleted +4.8%, Updated
+5.2%, **Moved −17.3%**, **Copy/Pasted +11.3%**, Churn **+39.2%**.

The 2025 follow-up, using a newly built "duplicate block detection" method (5+ contiguous
duplicated lines), found:

> "2024 was without precedent in the likelihood that a commit would contain a duplicated code
> block. The prevalence of duplicate blocks in 2024 was observed to be approximately 10x higher
> than it had been two years prior."

Raw table (commits containing a duplicate block, by year authored): 2020: 0.70%; 2021: 0.48%;
2022: 0.45%; 2023: 1.80%; 2024: **6.66%**.

Interpretation directly relevant to "depth": less "Moved" code is GitClear's proxy for less
refactoring/reuse — i.e., fewer instances of someone recognizing shared functionality and
pulling it into one place (exactly the deep-module move). More copy/paste is the opposite
motion: repeating the shallow, unabstracted version instead.

### 3.2 Independent replication of the duplication finding — academic code-smell study

**Source**: "Investigating the Smells of LLM Generated Code" (extended version of "Does LLM
Generated Code Smell?", accepted IEEE ICCBDCS 2025), arXiv:2510.03029, retrieved as full text.

Methodology: automated code-smell detection (implementation smells + design smells) on Java
programs generated by four LLMs — Gemini Pro, ChatGPT, Codex, Falcon — compared against a
baseline of professionally written reference solutions, across coding tasks segmented by topic
and complexity.

> "We find that LLM-generated code has a higher incidence of code smells compared to reference
> solutions. Falcon performed the least badly, with a smell increase of 42.28%, followed by
> Gemini Pro (62.07%), ChatGPT (65.05%) and finally Codex (84.97%). The average smell increase
> across all LLMs was 63.34%, comprising 73.35% for implementation smells and 21.42% for design
> smells. We also found that the increase in code smells is greater for more complex coding
> tasks and for more advanced topics, such as those involving object-orientated concepts."

This is directly relevant to "depth is decided under difficulty": the paper explicitly links
its own finding to GitClear's — "based on a quantitative study of 211 million lines of code
changes... Harding et al. identified multiple 'signs of eroding code quality'... this raises an
important question: what specific quality defects are present in LLM generated code?" — and
finds the depth-relevant defect (design smells, i.e., structural/abstraction problems, not just
style) is worse specifically where object-oriented decomposition is required — the exact
territory Ousterhout is describing.

### 3.3 Security defects — Pearce et al. 2021/2022, "Asleep at the Keyboard?"

**Source**: Hammond Pearce, Baleegh Ahmad, Benjamin Tan, Brendan Dolan-Gavitt, Ramesh Karri,
"Asleep at the Keyboard? Assessing the Security of GitHub Copilot's Code Contributions," IEEE
S&P 2022 (arXiv:2108.09293, peer-reviewed venue). Full text retrieved directly.

Methodology: 89 hand-crafted scenarios spanning MITRE's "2021 CWE Top 25" list, across Python,
C, and Verilog; Copilot asked for up to 25 completions per scenario; 1,689 total programs
generated; vulnerability determined via CodeQL static analysis plus manual inspection.

> "In total, we produce 89 different scenarios for Copilot to complete, producing 1,689
> programs. Of these, we found approximately 40% to be vulnerable."

Breaking down the largest sub-experiment (54 scenarios, 18 CWEs): 1,084 valid programs
generated, 477 (44.00%) contained a CWE; by language, C was worse (258/513, 50.29% vulnerable)
than Python (219/571, 38.35% vulnerable).

### 3.4 User-study evidence — Perry, Srivastava, Kumar, Boneh (Stanford), ACM CCS 2023

**Source**: "Do Users Write More Insecure Code with AI Assistants?" arXiv:2211.03622, published
ACM CCS '23 (peer-reviewed). Full text and NSF-hosted mirror retrieved directly.

Methodology: 47-participant user study (33 experiment / 14 control, after exclusions from an
initial pool of 54), five security-related programming tasks across Python/JavaScript/C, using
an AI assistant built on OpenAI's `codex-davinci-002`. Statistical tests: Welch's t-test and
chi-squared test for unequal-variance categorical comparisons; the paper explicitly documents
significance testing given the small-N constraint.

> "Participants who had access to an AI assistant wrote significantly less secure code than
> those without access to an assistant. Participants with access to an AI assistant were also
> more likely to believe they wrote secure code than those without access to the AI assistant,
> suggesting that such tools may lead users to be overconfident about security flaws in their
> code."

The paper's own stated limitation, quoted directly: "our participant group consisted mainly of
university students which likely do not represent the population that is most likely to use AI
assistants (e.g. software developers) regularly." This is a real limitation on generalizability
and should be carried forward whenever this study is cited.

### 3.5 Field telemetry on bug rate and productivity — Uplevel (2024) and METR (2025)

**Uplevel** ("Can Generative AI Improve Developer Productivity?", Sept 2024) — observational,
not peer-reviewed, ~800 developers across enterprise customers, pre/post Copilot rollout
(Jan–Apr 2023 vs. Jan–Apr 2024), 351 test-group / 434 control-group developers, t-tests/z-tests
on cycle time, PR throughput, and bug rate. Explicitly self-labeled: "All results are
observational, limited to the developers included, and not causal."

> "Developers with Copilot access saw a significantly higher bug rate while their issue
> throughput remained consistent." Reported figure: **41% increase in bug rate**, with no
> significant change in PR cycle time or throughput.

**METR** ("Measuring the Impact of Early-2025 AI on Experienced Open-Source Developer
Productivity," arXiv:2507.09089, July 2025) — this is the strongest-design study in this
section: a genuine **randomized controlled trial**, 16 experienced developers (avg. 5 years on
their own repos, ~1,500 prior commits each), 246 real tasks on large repos (avg. 23,000 stars,
1.1M LOC), each task randomly assigned AI-allowed or AI-disallowed, primary tool Cursor Pro
with Claude 3.5/3.7 Sonnet, 143 hours of screen recording hand-labeled for causal-mechanism
analysis. Small N (16 developers) but randomized at the task level (246 tasks), which is a
materially different — stronger — design than the observational studies above.

> "Before starting tasks, developers forecast that allowing AI will reduce completion time by
> 24%. After completing the study, developers estimate that allowing AI reduced completion time
> by 20%. Surprisingly, we find that allowing AI actually increases completion time by 19%—AI
> tooling slowed developers down."

This is not a code-quality finding per se, but it is directly relevant to the "depth" argument:
depth work (understanding what already exists, finding the right abstraction boundary,
integrating cleanly into a large mature codebase) is exactly the kind of task where METR's
subjects — who were skilled and working in codebases they knew intimately — were slowed down
by AI, not sped up. The paper's own framing supports this: their repos "broadly have very high
quality bars for code contributions," i.e., depth-sensitive environments.

### Honest caveat on the whole section

None of the industry telemetry studies (GitClear, Uplevel) are peer reviewed, and neither
publishes a fully open, independently-replicable dataset comparable to an academic corpus.
GitClear's methodology, while detailed, is proprietary, and the company sells developer
analytics tooling that benefits from an "AI hurts code quality" narrative — a real conflict of
interest to weigh, even though the underlying operation-classification methodology is
documented and the raw percentages are consistent across two independent report years. The
academic studies (Pearce, Perry, the code-smell paper) are peer-reviewed and methodologically
transparent but have modest N and, in Perry et al.'s case, a non-representative (heavily
student) sample by the authors' own admission. The METR RCT is the most rigorous design here
but the smallest (16 developers) and specific to one tool generation (early-2025 Cursor +
Claude 3.5/3.7 Sonnet) — it should not be read as a permanent verdict on all future AI coding
tools.

---

## 4. Checkable criteria — mechanical tests a reviewer can apply to a diff

These are constructed by turning each definition above into a countable or binary check. None
requires subjective taste; all can be applied by a reviewer reading a diff plus the module's
call sites.

**Test 1 — Interface-to-implementation ratio.**
Count public symbols exposed by the module (public functions/methods, exported types, public
fields) against the lines of implementation behind them. A shallow module has a ratio near 1:1
(the interface is *almost the whole thing*, e.g. a class with mostly getters/setters and thin
wrappers). A deep module has an interface an order of magnitude smaller than its
implementation. Directly operationalizes Ousterhout: "the best modules are those whose
interfaces are much simpler than their implementations."

**Test 2 — Concept count at the call site.**
At each call site, count the number of distinct concepts (parameters, required call-ordering,
preconditions the caller must track, sibling methods that must be called together) a caller
must hold in working memory to use the module correctly. Depth is inversely proportional to
this count. A concrete proxy: parameter count plus number of other methods on the same object
that must be called in a specific sequence around this one. Rising concept count with no rise
in functionality delivered is the signature of "classitis."

**Test 3 — Pass-through count.**
Grep the diff for methods/functions whose body is (almost) only a call to another
function/method with a similar or identical signature, with no independent logic. Ousterhout
names this explicitly as a red flag ("a pass-through method is one that does little except
invoke another method, whose signature is similar or identical to that of the calling
method"). Any pass-through found is evidence the module boundary is drawn in the wrong place,
not that the code is well-layered.

**Test 4 — Information-leakage test.**
Pick any non-trivial design decision inside the module (a file format, an ordering assumption,
a retry policy, a schema). Ask: is this decision encoded, in whole or in part, in more than one
module? If two classes both need to know the same fact to work correctly, information hiding
has failed regardless of how the code is organized on disk. Concretely: grep for the same magic
constant, format string, or business rule appearing in two unrelated files/modules.

**Test 5 — Error paths vs. happy paths.**
Count the number of distinct failure modes the module's *implementation* has to handle
internally versus the number the module's *interface* exposes to the caller (as distinct
exception types, error codes, or documented failure states). A deep module absorbs failure
handling — Ousterhout's "define errors out of existence" — so this ratio should be high
(many internal failure modes handled, few new ones surfaced). A shallow wrapper typically
just re-throws or passes every underlying error straight through, meaning the ratio is close
to 1:1 and the caller inherits the full failure surface of the thing being wrapped.

**Test 6 — Leak-blast-radius test (from the leaky-abstraction caveat).**
Since "all non-trivial abstractions are leaky" (Spolsky), the relevant question for a reviewer
is not "does this ever leak" but "when it leaks, how many callers are affected, and how far
does the fix propagate." Trace one plausible failure of the abstraction (e.g., what happens on
the module's internal implementation change) and count how many call sites need to change. If
it's one (the module itself), the abstraction is doing its job. If it's every caller, the
interface didn't actually hide anything — it just relocated the complexity's *appearance*, not
its *consequence*.

**Test 7 — General-purpose-vs-special-purpose interface question.**
Ousterhout's own diagnostic question, quotable directly: "What is the simplest interface that
will cover all my current needs?" — applied as a reviewer test: does the interface expose
parameters/options that exist only because of one specific caller's needs (special-purpose,
narrow, shallow) or does it express the underlying capability in general terms that happen to
satisfy the current caller (general-purpose, more likely deep)? A named smell: any parameter
whose only purpose is to let one specific caller bypass the module's own logic.

**Test 8 — Temporal-decomposition test.**
Check whether the module boundaries mirror *execution order* (step 1 class, step 2 class, step
3 class) rather than *knowledge boundaries* (this class owns this fact). Parnas's own worked
example (flowchart decomposition vs. information-hiding decomposition of the KWIC index) is the
literal source of this test: decomposition-by-flowchart was his explicit example of the wrong
approach. If you can describe the module boundaries in your diff purely by narrating "first this
happens, then this happens, then this happens," that's a strong signal of temporal
decomposition, which Ousterhout separately names as "one of the most common causes of
information leakage."

**Single best mechanical test, if forced to pick one**: Test 1 (interface-to-implementation
ratio), because it is the one Ousterhout states as the defining criterion rather than a
symptom — "It is more important for a module to have a simple interface than a simple
implementation" — and it is the only test on this list that can be applied without reading the
call sites at all, purely from the module's own public surface vs. its body.

---

## 5. The trap — where "depth" advice is wrong or over-applied

**Depth is not size, and the confusion is common enough that Ousterhout addresses it directly.**
A god object — "an object that references a large number of distinct types, has too many
unrelated or uncategorized methods, or some combination of both" (Wikipedia, summarizing the
antipattern's standard definition, itself sourced to Arthur Riel's 1996 *Object-Oriented Design
Heuristics*) — can look "deep" by Test 1 above (huge implementation, small-looking surface) if
the surface is measured naively. The distinguishing test is **coherence of the design
decision(s) hidden**, not size. Riel's own heuristic names the smell directly: "Be very
suspicious of an abstraction whose name contains Driver, Manager, System, or Subsystem." A
module is deep only if the large implementation behind its interface is hiding *one design
decision or a tightly related family of them* — a god object is large because it hides *many
unrelated* decisions behind a interface that only looks simple because most of its surface is
rarely used by any single caller. Practically: ask whether every part of the implementation is
in service of the same interface promise. If the module's implementation splits cleanly into
sections that never call each other and serve unrelated callers, it is not deep — it is
several shallow-or-fine modules stapled together, and Test 4 (information leakage) will
usually not fire because there's no shared knowledge being hidden, just shared file location.

**Premature abstraction is the mirror-image trap.** Depth is a property discovered by
generalizing from real, current needs — Ousterhout's own qualifier is "somewhat
general-purpose": "the module's functionality should reflect your current needs, but its
interface should not [be limited to them]." Building a deep-looking interface for
functionality that doesn't exist yet (speculative generality, extensibility hooks for
requirements that haven't arrived) produces an interface that is *simple relative to
imagined future implementation* but has no implementation behind it yet to justify the
abstraction cost paid today. This is depth borrowed against a future that may not arrive — the
interface adds cognitive load now (Test 2 fires: more concepts to hold) for a payoff that is
speculative.

**Over-decomposition in the name of "small methods" is a real, sourced controversy, not a
strawman.** Ousterhout's own public critique of Robert C. Martin's *Clean Code* is a
documented, named disagreement between two practitioners, not a generic warning — worth citing
because it shows the depth idea is contested, not universally agreed:

> On *Clean Code*'s `PrimeGenerator` example, decomposed into 8 small methods: "code is chopped
> up so much (8 teeny-tiny methods) that it's difficult to read... These methods are shallow and
> entangled: in order to understand [one] you have to read the other two methods and load all
> of that code into your mind at once."
> — Ousterhout, `johnousterhout/aposd-vs-clean-code`

Martin's side of that same document, quoted directly for balance: "I think you and I are just
going to disagree on this. In general I believe in the principle of small well-named methods
and the separation of concerns." This is a live, unresolved disagreement among serious
practitioners — cited here as evidence that "smaller is deeper" is a real, popular position
that the deep-module framework directly contradicts, not evidence that either side is simply
correct.

**Depth can also be used as post-hoc justification for a design nobody actually validated.**
None of the sources above supply a *test that certifies* depth in the abstract — every test in
Section 4 requires an actual call site, an actual failure mode, or an actual second module to
compare against. A module can be *asserted* deep by its author ("look how simple the interface
is") while still being untested against Test 5 (does it actually absorb the errors) or Test 6
(does a leak actually stay contained). Treat any claim of depth that hasn't been checked
against at least one of Tests 1–8 as unverified, in the same spirit as this report's own
Rule-0-style discipline: a design claim that hasn't been checked is not a result.

**The productivity data (Section 3.5) is itself a trap if over-read.** The METR result (AI
slows down experienced developers on codebases they know well) is sometimes cited as "AI can't
write deep code" — that's an overreach the paper itself doesn't make. The RCT measured task
completion time, not code depth; the mechanism the authors themselves emphasize most is
developer over-trust and time spent reviewing/correcting AI suggestions, not a demonstrated
inability of the AI to produce good abstractions. Cite METR for "AI-assisted work is slower in
depth-sensitive environments," not for "AI code is shallow" — that second claim needs Section
3.1–3.3's evidence instead.

---

## UNVERIFIED

- Ousterhout's complexity formula, C = Σ c_p · t_p, is reported consistently by two independent
  secondary sources summarizing the book (yiming.dev, oehler.dev) but was not independently
  located in the primary scanned-book excerpt retrieved for this report. Treat the *existence*
  of a weighted-sum framing as reliable (both sources agree closely on wording) but the exact
  notation as UNVERIFIED against the original typeset page.
- The "No Silver Bullet" essay's original publication date is given both as 1986 (invited paper
  at IFIP, and as printed in the widely-cited PDF headers) and 1987 (the *Computer* journal
  print date, April 1987, Vol. 20 No. 4). Both are used in the literature; this report follows
  the question's own framing ("Brooks... 1986") but the *Computer* journal citation is dated
  1987 in at least one retrieved source. Not a substantive discrepancy, but noted for citation
  precision.
- GitClear's report methodology (what exactly counts as a "duplicate block," exact regression
  method for 2024 projections using a GPT-4 assistant) is described in the PDF but not
  independently auditable — no raw dataset was published alongside the report. The percentages
  quoted above are taken directly from GitClear's own PDF and should be understood as
  vendor-reported, not independently replicated.
- No study located in this research directly measures "module depth" (in Ousterhout's specific
  technical sense — interface-to-implementation ratio) for LLM-generated code as a labeled
  metric. The empirical section's connection between "code smells / duplication / churn" and
  "shallowness" is this report's own synthesis of the theory (Section 1-2) applied to the
  measured defects (Section 3) — it is a reasonable inference, not a claim any cited study
  makes explicitly. Flagged here so it isn't mistaken for a direct empirical finding.
- The claim that GitClear has a "real conflict of interest" is this report's own editorial
  judgment (GitClear sells code-quality analytics tooling), not a sourced admission by GitClear
  itself. Included because Rule 0/Rule 5-style diligence requires surfacing it, but it is
  inference about incentive, not a verified fact about intent.
