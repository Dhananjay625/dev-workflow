---
name: workflow
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

## Phase 0 - Plan
Explore read-only (use plan mode where the harness provides it for code
tasks). The plan must contain these five items:
- Objective (one sentence)
- Deliverable (exact file paths that will exist when done)
- Approach (key decisions + one rejected alternative if non-obvious)
- Risks/blockers (surface now, not mid-build)
- Delegation (which subagents, if any, what each returns, and the estimated
  cost tradeoff)
If the harness's native plan format is fuller (Context, Verification
sections), use the native format - these five items are the required core,
not a cap on the file.

Gate calibration (precedence when instructions conflict):
- Default: wait for approval before editing anything.
- If the environment's own instructions forbid pausing (autonomous/goal
  mode), do not stall and do not ignore this phase: record the plan as the
  session's first changelog entry and proceed. Pause ONLY for decisions
  with real cost (irreversible actions, significant spend, destructive
  operations), using whatever question mechanism the harness provides.
- For tasks that produce measurements or analysis rather than code, plan
  mode is the wrong mechanism: present the five items inline and gate only
  on decisions with real cost.

## Phase 1 - Execute
Default: do the work directly in the main thread. Subagents cost real money
and real time - dispatch one ONLY when the isolation value clearly exceeds
that cost:
1. A side task would flood the main context (deep multi-file audit, log
   analysis, doc research) -> `auditor` - returns <=40 dense lines.
2. Two workstreams with DISJOINT file sets can run in parallel ->
   `test-writer` instances, each assigned its own test file paths.
3. The diff needs unbiased review -> `code-reviewer` - returns <=30 dense
   lines.
On small tasks, all three jobs are done inline instead. Never dispatch
parallel subagents whose file sets overlap.

Dispatch mechanics (this matters): dispatch subagents synchronously via the
Task tool and WAIT for each result before entering the phase that consumes
it. If a dispatch returns only a spawn acknowledgement ("spawned", "will
receive instructions") with no findings, treat the subagent as failed after
one retry and do the job inline - never let a phase proceed on missing
results. No handoff messages between steps - the artifact on disk is the
handoff.

## Phase 2 - Verify
- The plugin's hooks always emit a `[dev-workflow]` heartbeat line (lint
  after edits, stop-check at session end), even when they skip. If NO
  `[dev-workflow]` lines have appeared this session, the hooks are not
  active in this environment: run the lint and the test suite yourself
  before proceeding. Never assume an unverified hook ran.
- Before declaring done on any significant change: get a `code-reviewer`
  pass on the diff (subagent if warranted by size, inline otherwise). The
  review must complete BEFORE the closing report - a review that lands after
  delivery gates nothing. Fix P0/P1 findings; log P2s in the changelog.
- Verify the reviewer's claims like any other claims: negatives ("X is never
  mentioned", "no test covers Y") must be checked against the whole file or
  suite (grep/search), not accepted from a partial read.
- Run tests before claiming anything works. "Should work" is not a status.
- MEASUREMENT TASKS (run-and-report-numbers rather than write-code): the
  code-reviewer pass does not apply. Instead: (1) snapshot any mutable
  state before overwriting it; (2) capture a baseline before the change;
  (3) reproduce a result once before quoting it; (4) report numbers only
  with method and sample per the evidence rule.

## Phase 3 - Deliver
- Deliverables = files at the paths named in the plan, nothing else.
- Closing report <=5 lines: what changed, test status, known gaps, next step.
- No ceremony: no team rosters, no handoff blocks, no emoji headers.

## Changelog discipline (cross-session memory)
- Log every change in the project's `CHANGELOG.md` in the same turn it is
  made: `file:line - before->after - why - verified how`. Never batch
  entries at session end.
- Before ANY session ends (including blocked/interrupted): rewrite the
  `## Current state` block at the top of `CHANGELOG.md` so a fresh session
  with zero memory can continue from it alone: what works (with the command
  proving it), what's broken (file:line + symptom), exact next step, open
  decisions, known dead ends (DO NOT list).
- Bootstrap cases:
  - No `CHANGELOG.md` -> create it from
    `${CLAUDE_PLUGIN_ROOT}/templates/CHANGELOG.template.md`.
  - `CHANGELOG.md` exists but has NO `## Current state` block (common on
    existing repos) -> PREPEND the block from the template above the
    existing content; never rewrite or truncate existing history.
  (`/dev-workflow:init` handles both cases.)

## Blocker protocol
If an approach fails twice, stop immediately. Output exactly:
`BLOCKER: <why> - proposed alternative: <one line>` and wait for the user.
Never grind a dead path to appear productive. Record the dead end in the
changelog's DO NOT list so it is never retried.

## Density rule (all capped output, including subagent returns)
Caps limit length, never precision. Every line carries exact file:line,
exact values, exact commands.
Bad:  "Fixed a bug in the validation logic"
Good: "gate.py:142 - cap 160->250 - recovers rows dropped when
candidates>160 - verified: doc_017 +37 rows"
If a cap forces omission, end with:
`OMITTED: <count> <type> - details in <file>`

## Evidence discipline
- Every claim about code cites file:line.
- Negative claims ("zero mentions of X", "no caller of Y") require a
  whole-file or whole-repo search before being stated - absence observed in
  a partial read is not evidence of absence.
- Never report a number (precision, recall, latency, coverage) without
  stating how it was measured and on what sample; label proxies as proxies.
- Prefer editing existing files over creating new ones. Creating a new
  file is justified when reusing an existing one would require a flag or
  parameter that changes its contract; when creating one, record in the
  changelog entry which existing file was rejected and why.
- Handle nulls, duplicates, and empty inputs in any data-touching code.
