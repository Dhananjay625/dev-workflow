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
    section 7 before any other work.
  - If it exists but has no `## Current state` block, PREPEND the block
    (section 7 format) above the existing content. Never rewrite, reorder,
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

## 3. Verify - never assume

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

## 4. Evidence discipline

- Every claim about code cites file and line (e.g. `pipeline/gate.py:142`).
- Never report a number (precision, recall, latency, coverage) without
  stating how it was measured and on what sample. Label proxies as proxies.
- Density rule: when output is limited, limit length, never precision.
  Bad:  "Fixed a bug in the validation logic"
  Good: "gate.py:142 - cap 160->250 - recovers rows dropped when
  candidates>160 - verified: doc_017 +37 rows"
  If a limit forces omission, end with:
  `OMITTED: <count> <type> - details in <file>`

## 5. Blocker protocol

If an approach fails twice, stop immediately. Output exactly:
`BLOCKER: <why> - proposed alternative: <one line>`
and wait for the user. Never grind a dead path to appear productive. Record
the dead end in the changelog's DO NOT list so no agent retries it.

## 6. Code minimalism

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

## 7. Changelog format

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

## 8. Delivery

- Deliverables = files at the paths named in the plan, nothing else.
- Closing report of at most 5 lines: what changed, test status, known gaps,
  next step. No ceremony: no team rosters, no handoff blocks, no emoji
  headers.
