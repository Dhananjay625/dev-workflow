---
name: dev-workflow
description: >
  Structured development workflow for any coding, refactoring, debugging,
  data-pipeline, or feature task. Use at the start of every non-trivial
  development task (>~20 lines of change, >3 files, or any schema/pipeline
  change) and whenever deciding whether to plan first, dispatch subagents,
  or declare a task done. Covers plan-first gating, subagent dispatch rules,
  verification, blocker protocol, changelog discipline, and delivery format.
---

# Development workflow

Follow these phases in order. Skip Phase 0 only for trivial tasks
(<~20 lines, obvious approach, no schema/pipeline impact).

## Phase 0 — Plan
Enter plan mode. Explore read-only. Produce a plan of <=10 lines:
- Objective (one sentence)
- Deliverable (exact file paths that will exist when done)
- Approach (key decisions + one rejected alternative if non-obvious)
- Risks/blockers (surface now, not mid-build)
- Delegation (which subagents, if any, and what each returns)
Wait for approval before editing anything.

## Phase 1 — Execute
Default: do the work directly in the main thread. Dispatch a subagent ONLY
when one of these is true:
1. A side task would flood the main context (deep multi-file audit, log
   analysis, doc research) -> `auditor` — returns <=40 dense lines.
2. Two workstreams with DISJOINT file sets can run in parallel ->
   `test-writer` instances, each assigned its own test file paths.
3. The diff needs unbiased review -> `code-reviewer` — returns <=30 dense
   lines.
Never dispatch parallel subagents whose file sets overlap. No handoff
messages between steps — the artifact on disk is the handoff.

## Phase 2 — Verify
- Plugin hooks handle lint/format on edit and a test pass on stop
  (deterministic — do not duplicate their work in prose).
- Before declaring done on any significant change: dispatch `code-reviewer`
  on the diff. Fix P0/P1 findings; log P2s in the changelog.
- Run tests before claiming anything works. "Should work" is not a status.

## Phase 3 — Deliver
- Deliverables = files at the paths named in the plan, nothing else.
- Closing report <=5 lines: what changed, test status, known gaps, next step.
- No ceremony: no team rosters, no handoff blocks, no emoji headers.

## Changelog discipline (cross-session memory)
- Log every change in the project's `CHANGELOG.md` in the same turn it is
  made: `file:line — before->after — why — verified how`. Never batch
  entries at session end.
- Before ANY session ends (including blocked/interrupted): rewrite the
  `## Current state` block at the top of `CHANGELOG.md` so a fresh session
  with zero memory can continue from it alone: what works (with the command
  proving it), what's broken (file:line + symptom), exact next step, open
  decisions, known dead ends (DO NOT list).
- If `CHANGELOG.md` does not exist, create it from
  `${CLAUDE_PLUGIN_ROOT}/templates/CHANGELOG.template.md` before other work
  (the `/dev-workflow:init` command does this).

## Blocker protocol
If an approach fails twice, stop immediately. Output exactly:
`BLOCKER: <why> — proposed alternative: <one line>` and wait for the user.
Never grind a dead path to appear productive. Record the dead end in the
changelog's DO NOT list so it is never retried.

## Density rule (all capped output, including subagent returns)
Caps limit length, never precision. Every line carries exact file:line,
exact values, exact commands.
Bad:  "Fixed a bug in the validation logic"
Good: "gate.py:142 — cap 160->250 — recovers rows dropped when
candidates>160 — verified: doc_017 +37 rows"
If a cap forces omission, end with:
`OMITTED: <count> <type> — details in <file>`

## Evidence discipline
- Every claim about code cites file:line.
- Never report a number (precision, recall, latency, coverage) without
  stating how it was measured and on what sample; label proxies as proxies.
- Prefer editing existing files over creating new ones.
- Handle nulls, duplicates, and empty inputs in any data-touching code.
