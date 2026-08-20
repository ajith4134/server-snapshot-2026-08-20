---
name: interview-instead-of-assuming
description: "Standing instruction — interview the user for clarifications when unsure; never ask a question, drop it, and proceed on an assumption."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: a7ca9e36-9139-4f35-8254-4bad5e42b7ec
  modified: 2026-08-09T07:34:36.773Z
---

When something is unclear, **interview the user** — ask the specific question and
wait for the answer. Do not raise a question and then answer it yourself, and do
not let an open question quietly become an assumption a few steps later.

Given 2026-08-09, after a Phase 4 spec surfaced five open decisions: the failure
mode being guarded against is asking well and then proceeding as if the answer
had been given.

**Why:** an assumption made after a question was already recognised is worse than
one made without noticing — the uncertainty was visible and got buried anyway,
so the user has no signal that a choice was made on their behalf.

**How to apply:** use `AskUserQuestion` for decisions that change what gets built,
at the moment the decision is reached rather than batched to the end. When work
must continue while an answer is pending, do only the parts that are correct
under every branch, and say which parts are waiting. Related:
[[trading-bot-intelligence-standard]].
