# Reference Images — the tree architecture

Supplied by the user 2026-08-01 as visual reference for the "tree of brains,
branches to branches" architecture. Saved out of the session-scoped upload
directory, which gets cleaned up.

Five files were uploaded; **two were byte-identical duplicates**
(md5 `f94a2174…`), so four unique images are stored here.

---

## 01 — Tree of Skills (competency domains)
`01-tree-of-skills-competency-domains.png`

A literal tree: trunk splits into six coloured domain circles, each surrounded by
leaf sub-skills.
- **Cognitive** — critical thinking, problem solving, system thinking, lateral thinking
- **Leadership** — organizing, entrepreneurship, excellence, influence without authority
- **Collaboration** — negotiation, conflict mgmt, cross-cultural, communication
- **Creativity** — curiosity, ideation, innovation, visualization
- **Emotional** — empathy, adaptability, self-awareness, resilience
- **Social & Civic** — citizenship, environment, health, equality

**Maps to:** the top two layers of our tree — **brain → strategy family**. One trunk,
several major domains, each fanning out into concrete capabilities.

---

## 02 — Game skill tree (unlock paths)
`02-game-skill-tree-unlock-paths.jpeg`

A Jedi-style progression tree with three labelled trunks — **FORCE**, **LIGHTSABER**,
**SURVIVAL** — nodes connected by paths, a highlighted selected node ("Overhead
Slash — 1 skill point"), and a **skill-point budget** at the bottom.

**Maps to:** two ideas we need —
1. **Nodes unlock only when their prerequisites are taken** — a strategy can't
   activate until its dependencies pass.
2. **A finite point budget** — capital allocation. You cannot light up the whole
   tree; you spend a limited resource on the branches that earn it.

---

## 03 — Radial passive tree (massive scale)
`03-radial-passive-tree-massive-scale.png`

A Path-of-Exile-style network: concentric rings and wedge sectors, hundreds of minor
nodes, a smaller number of large "keystone" nodes, and orange highlighted paths
showing the routes actually taken through an otherwise unlit graph.

**Maps to:** what the system looks like at maturity. The full graph is the *space of
possible strategies*; the lit orange path is what has actually been **validated and
funded**. Most of the tree stays dark — that's correct, not a failure. Also the right
mental model for scale: thousands of nodes, few of them active at once.

---

## 04 — Skill tree methodology (THE important one)
`04-skill-tree-methodology-preskills.jpeg`

Hand-drawn methodology sheet. This is the one with actual mechanics rather than
aesthetics, and it maps almost one-to-one onto our promotion pipeline.

**Its rules:**
- *"Every skill builds off previous skills aka **PRE-SKILLS**"*
- *"Use skill trees to break down more complex ideas"*
- **Competency scale 0–5:** 0 not learned/required · 1 beginner · 2 intermediate ·
  3 novice · 4 expert · 5 master
- **Every node carries a competency bar** on its left edge (current level)
- **Every connecting line carries a number** = *the competency level required to
  move on* to the next node
- Steps: (1) find a skill to improve, (2) break into pre-skills as needed,
  (3) assign required competency, (4) **honestly** assess where you are,
  (5) find where the gaps are
- *"What you put here implies importance — **BE REALISTIC!**"*
- *"If you're struggling, maybe you're missing a pre-skill? Try to find it"*
- *"Non-judgemental process to assess, plan & improve"*
- *"**Every skill tree is different!**"*

### Direct mapping to our design

| Sheet | Our system |
|---|---|
| Node | A strategy or capability |
| **Pre-skill** | Dependency — *"you don't build a loop without battle-tested skills behind it"* |
| Competency bar on the node | Which validation stage it has passed (0 = untested … 5 = live and scaled) |
| **Number on the connecting line** | **The promotion gate** — the threshold required to advance |
| "Honestly assess where you are" | Deflated Sharpe on out-of-sample data, not in-sample hope |
| "Find where the gaps are" | What the meta-model over the experiment ledger computes |
| "Missing a pre-skill?" | A strategy failing because its dependency was never validated |
| "Be realistic" | The reason the ledger must record failures |

**The single best idea here is the number on the edge.** A gate lives on the
*transition*, not inside the node — exactly the pre-trade risk architecture
(`Strategy → RiskEngine → Execution`) and exactly the promotion pipeline
(experiment → CV → held-out → DSR → paper → live). The tree structure and the
validation structure are the same structure.
