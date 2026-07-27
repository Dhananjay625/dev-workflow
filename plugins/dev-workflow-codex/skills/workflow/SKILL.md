---
name: workflow
description: >
  Structured development workflow for any coding, refactoring, debugging,
  data-pipeline, or feature task. Use at the start of every non-trivial
  development task (>~20 lines of change, >3 files, or any schema/pipeline
  change) and whenever deciding whether to plan first, delegate work, or
  declare a task done. Covers plan-first gating, delegation rules,
  verification, blocker protocol, changelog discipline, and delivery format.
---

# Development workflow

Follow these phases in order. Skip Phase 0 only for trivial tasks
(<~20 lines, obvious approach, no schema/pipeline impact).

## Session continuity (do this first, every session)
- FIRST ACTION: locate the project's `CHANGELOG.md`. Check the session
  root first, then search downward (e.g. `find . -maxdepth 3 -name
  CHANGELOG.md` excluding node_modules/.git). In a monorepo, the changelog
  in the directory containing the files being edited is the project's
  memory - never create a second changelog at a higher level, which would
  split it. Once located, read it: its
  `## Current state` block says exactly where the last session stopped -
  resume from it; never re-explore what it already answers.
- If `CHANGELOG.md` does not exist, create it from this skill's
  `templates/CHANGELOG.template.md` before other work.
- If it exists but has NO `## Current state` block (common on existing
  repos), PREPEND the block from the template above the existing content;
  never rewrite or truncate existing history.
- Log every change in the same turn it is made:
  `file:line - before->after - why - verified how`. Never batch entries.
- Before ANY session ends (including blocked/interrupted): rewrite
  `## Current state` so a fresh session with zero memory can continue from
  it alone: what works (with proof command), what's broken (file:line +
  symptom), exact next step, open decisions, known dead ends (DO NOT list).
  Respect the DO NOT list: recorded dead ends are never retried.

## Phase 0 - Plan
Explore read-only. The plan must contain these five items:
- Objective (one sentence)
- Deliverable (exact file paths that will exist when done)
- Approach (key decisions + one rejected alternative if non-obvious)
- Risks/blockers (surface now, not mid-build)
- Delegation (which specialist roles, if any, what each returns, and the
  estimated cost tradeoff)
If the harness has a fuller native plan format, use it - these five items
are the required core, not a cap.

Gate calibration (precedence when instructions conflict):
- Default: wait for approval before editing anything.
- If the environment's own instructions forbid pausing (autonomous/goal
  mode), do not stall and do not ignore this phase: record the plan as the
  session's first changelog entry and proceed. Pause ONLY for decisions
  with real cost (irreversible actions, significant spend, destructive
  operations), using whatever question mechanism the harness provides.
- For tasks that produce measurements or analysis rather than code, a plan
  mechanism is unnecessary: present the five items inline and gate only on
  decisions with real cost.

## Phase 1 - Execute
Default: do the work directly in the main thread. Delegation to an
isolated worker (Codex multi-agent, or any subagent mechanism) costs real
money and time - use it ONLY when the isolation value clearly exceeds
that cost:
1. A side task would flood the main context (deep multi-file audit, log
   analysis, doc research) -> AUDITOR role - returns <=40 dense lines.
2. Two workstreams with DISJOINT file sets can run in parallel ->
   TEST WRITER roles, each assigned its own test file paths.
3. The diff needs unbiased review -> CODE REVIEWER role - returns <=30
   dense lines.
Role contracts (output format, caps, verification rules) are defined in
this skill's `roles.md` - read it before delegating or performing a role.
On small tasks, or if delegation is unavailable or returns only a spawn
acknowledgement with no findings (treat as failed after one retry),
perform the role inline following the same contract. Wait for each
delegated result before entering the phase that consumes it. Never run
parallel workers whose file sets overlap. No handoff messages between
steps - the artifact on disk is the handoff.

## Phase 2 - Verify
- Run the project's linter/formatter on every file you edited, and run the
  test suite before declaring done. Do not assume any external automation
  did this: if you see no evidence of it in this session, do it yourself.
- Before declaring done on any significant change: complete a CODE
  REVIEWER pass on the diff (per roles.md). The review must complete
  BEFORE the closing report - a review that lands after delivery gates
  nothing. Fix P0/P1 findings; log P2s in the changelog.
- Verify the reviewer's claims like any other claims: negatives ("X is
  never mentioned", "no test covers Y") must be checked against the whole
  file or suite (grep/search), not accepted from a partial read.
- Run tests before claiming anything works. "Should work" is not a status.
- MEASUREMENT TASKS (run-and-report-numbers rather than write-code): the
  CODE REVIEWER pass does not apply. Instead: (1) snapshot any mutable
  state before overwriting it; (2) capture a baseline before the change;
  (3) reproduce a result once before quoting it; (4) report numbers only
  with method and sample per the evidence rule.

## Phase 3 - Deliver
- Deliverables = files at the paths named in the plan, nothing else.
- Closing report <=5 lines: what changed, test status, known gaps, next step.
- No ceremony: no team rosters, no handoff blocks, no emoji headers.

## Blocker protocol
If an approach fails twice, stop immediately. Output exactly:
`BLOCKER: <why> - proposed alternative: <one line>` and wait for the user.
Never grind a dead path to appear productive. Record the dead end in the
changelog's DO NOT list so it is never retried.

## Density rule (all capped output, including delegated returns)
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
  whole-file or whole-repo search before being stated - absence observed
  in a partial read is not evidence of absence.
- Never report a number (precision, recall, latency, coverage) without
  stating how it was measured and on what sample; label proxies as proxies.
- Prefer editing existing files over creating new ones. Creating a new
  file is justified when reusing an existing one would require a flag or
  parameter that changes its contract; when creating one, record in the
  changelog entry which existing file was rejected and why.
- Handle nulls, duplicates, and empty inputs in any data-touching code.
