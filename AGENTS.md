# Agent Workflow Rules

Rules for any AI coding agent working in this repository (Codex, Gemini CLI,
Cursor, Aider, Claude Code without the plugin, or any other). Follow them
without being asked. They are tool-agnostic: no specific agent features are
required, only the ability to read files, run commands, and follow
instructions.

(If you are Claude Code with the dev-workflow plugin installed, the plugin
already enforces these rules with hooks and subagents - this file is the
fallback and the shared contract; the two never conflict.)

## 1. Session continuity (do this first, every session)

- FIRST ACTION: locate and read the project's `CHANGELOG.md`. Check the
  current directory, then search downward (excluding node_modules/.git).
  In a monorepo, the changelog next to the files being edited is the
  project's memory - never create a second one at a higher level, which
  would split it.
  - The `## Current state` block at the top says exactly where the last
    session stopped: what works, what's broken, the next step, open
    decisions, and known dead ends. Resume from it. Never re-explore or
    re-plan what it already answers.
  - If `CHANGELOG.md` does not exist, create it using the format in
    section 8 before any other work.
  - If it exists but has no `## Current state` block, PREPEND the block
    (section 8 format) above the existing content. Never rewrite, reorder,
    or truncate existing history.
- DURING WORK: append one entry per change, in the same turn the change is
  made. Never batch entries at session end. Entry format:
  `file:line - before->after - why - verified how`
- BEFORE THE SESSION ENDS (including when blocked or interrupted): rewrite
  the `## Current state` block so a fresh session with zero memory - yours
  or a different agent's - can continue from it alone.
- Respect the DO NOT list: it records measured dead ends. Do not retry them.

## 2. Plan before code

For any non-trivial task (>~20 lines of change, >3 files, or any schema/
pipeline change): explore read-only first, then present a short plan and
wait for approval before editing anything. The plan must contain:
- Objective (one sentence)
- Deliverable (exact file paths that will exist when done)
- Approach (key decisions + one rejected alternative if non-obvious)
- Risks/blockers (surface now, not mid-build)

Trivial tasks (<~20 lines, obvious approach): just do them.

Gate calibration: by default wait for approval before editing. If the
environment's own instructions forbid pausing, record the plan as the
first changelog entry and proceed, pausing only for decisions with real
cost (irreversible, significant spend, destructive). For measurement or
analysis tasks that produce numbers rather than code, present the plan
items inline - no plan mechanism needed.

## 3. Assemble a team for heavy tasks

LIGHT tasks: do the work yourself, start to finish. A delegated worker that
returns what you already know is pure cost.

HEAVY tasks: staff a team of specialist roles. HEAVY = any of: >3 files,
>~100 lines, a schema/pipeline/migration change, an unfamiliar area needing
>5 file reads, or two or more genuinely distinct skill sets (data +
modelling, UI + server).

MECHANISM (this section works with or without subagents):
- If your tool CAN spawn isolated workers (subagents, background agents,
  multi-agent delegation), dispatch one per role. Dispatch synchronously and
  WAIT for each result before starting the phase that consumes it. A spawn
  acknowledgement with no findings = failed after one retry; then do that
  role's job yourself.
- If it CANNOT, perform the roles yourself, one at a time, in the topology
  order below, holding each role's contract while you do it. The value is in
  the separation of concerns and the explicit handoffs, not the spawning.

Pick roles from the domain menu - it is a MENU, not a fixed roster:

| Domain | Roles | Topology |
|---|---|---|
| ML / model | RESEARCHER (prior art + baseline), DATA ENGINEER (data, splits), ML ENGINEER (train, model), VALIDATION ENGINEER (eval) | Sequential - each consumes the previous one's output |
| Data pipeline | DATA ENGINEER (transform/clean), PIPELINE ENGINEER (orchestration, retries), AUDITOR (row-loss scan) | Engineers parallel if paths disjoint; auditor after |
| Web app | BACKEND ENGINEER (api, db), FRONTEND ENGINEER (ui, components), TEST WRITER (tests) | Front/back parallel; backend publishes the API contract first |
| General | AUDITOR (map the area), TEST WRITER (assigned test paths) | Auditor before planning |

CODE REVIEWER closes every heavy task, last, before the closing report.

SIZE THE TEAM YOURSELF: use the smallest subset covering the distinct
concerns THIS task actually has. A one-file CSS fix in a web task needs one
role or none; a full training run may need all four. Never staff a role whose
deliverable would be empty. If two roles would edit the same paths, merge
them into one. State the roster and why that count in ONE line of the plan.

PATH OWNERSHIP - this is what makes parallel work safe: give every role an
explicit, DISJOINT set of owned paths. It edits nothing outside them and
reports needed outside changes back instead of making them. Overlapping paths
mean sequential execution, never parallel; violating this means two workers
silently overwrite each other. No handoff messages between steps - the
artifact on disk is the handoff.

Each role obeys the density rule and the negative-claim rule from sections 4
and 5, and reports in a capped, structured format (findings with file:line,
what it delivered, what it could not verify).

COST, HONESTLY: a four-role team costs roughly four times the tokens of doing
it inline, plus wall-clock for the sequential legs. Worth it on heavy work,
wasteful on light work.

## 4. Verify - never assume

- Run tests before claiming anything works. "Should work" is not a status.
- Run the project's linter/formatter on files you edit if one is configured.
- Before declaring a significant change done, review your own diff for:
  correctness (nulls, empty inputs, duplicates, silent failure paths),
  security (injection, unvalidated input, secrets), and plan compliance
  (did you build what was approved, and nothing more).
- Scope reviews precisely: a bare `git diff` shows ALL uncommitted work,
  which may include earlier changes that are not yours. State what you are
  reviewing. Never attribute pre-existing work to your change.
- Negative claims ("X is never mentioned", "no test covers Y", "Z has no
  callers") require a whole-file or whole-repo search before being stated.
  Absence observed in a partial read is a guess, not a finding.
- Measurement tasks (run-and-report-numbers): snapshot mutable state
  before overwriting it, capture a baseline before the change, reproduce a
  result once before quoting it, and report numbers only with method and
  sample.

## 5. Evidence discipline

- Every claim about code cites file and line (e.g. `pipeline/gate.py:142`).
- Never report a number (precision, recall, latency, coverage) without
  stating how it was measured and on what sample. Label proxies as proxies.
- Density rule: when output is limited, limit length, never precision.
  Bad:  "Fixed a bug in the validation logic"
  Good: "gate.py:142 - cap 160->250 - recovers rows dropped when
  candidates>160 - verified: doc_017 +37 rows"
  If a limit forces omission, end with:
  `OMITTED: <count> <type> - details in <file>`

## 6. Blocker protocol

If an approach fails twice, stop immediately. Output exactly:
`BLOCKER: <why> - proposed alternative: <one line>`
and wait for the user. Never grind a dead path to appear productive. Record
the dead end in the changelog's DO NOT list so no agent retries it.

## 7. Code minimalism

Every line is a liability. Write only what the spec demands; when
requirements change, add then - never predict.

First classify the tier, then apply its baseline:

| Tier | What it is | Baseline (NOT bloat) |
|---|---|---|
| T1 Throwaway | one-off script, spike | Nothing. Tracebacks are the error handling. |
| T2 Tool | CLI/script others run | Handle bad input paths + malformed input; usage line on wrong args. |
| T3 Production | service, API, pipeline, library | Validate all external input; handle network/file/timeout errors; log errors and state changes; handle nulls/duplicates/empty in data-touching code; type the public interface. |

Everything above the tier baseline needs explicit spec justification.
Everything below it is negligence, not minimalism.

Structure rules:
- Inline until 3 uses: no helper, class, or util for a single call site.
- No class where a function works; no function where an expression works.
- Stdlib first: add a dependency only if it replaces >~30 lines of
  nontrivial code or provides correctness you can't easily get (crypto,
  timezone math, spec-compliant parsing).
- Flat until it hurts: no folder with 1-2 files; no layer directories for a
  handful of endpoints.
- Comment WHY (approach, workaround, assumption), never WHAT.
- Test what can fail: business logic, validation, error paths, public API.
  Don't test getters, stdlib behavior, or code with no branches.
- Delete pass before delivery: remove commented-out code, unused imports/
  variables, single-use helpers (inline them), never-changed config keys
  (hardcode), obvious comments, impossible-error handlers.

## 8. Changelog format

```markdown
# Changelog

## Current state
- WORKING: <what is verified working, with the command that proves it>
- BROKEN/OPEN: <file:line + symptom>
- NEXT STEP: <exact next action, specific enough to execute immediately>
- OPEN DECISIONS: <decision - option A vs B - leaning + why> (or "none")
- DO NOT: <known dead ends so they are never retried> (or "none")

---

## Entries

### YYYY-MM-DD HH:MM
- <file:line> - <before->after> - <why> - <verified how>
```

Max 15 lines in Current state, maximum density. Entries are append-only:
never edit past entries.

## 9. Delivery

- Deliverables = files at the paths named in the plan, nothing else.
- Closing report of at most 5 lines: what changed, test status, known gaps,
  next step. No ceremony: no team rosters, no handoff blocks, no emoji
  headers.
