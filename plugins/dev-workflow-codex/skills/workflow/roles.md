# Specialist role contracts

Read before delegating a role to an isolated worker OR performing it
inline. The contract is identical either way. All roles obey the density
rule and the negative-claim rule from SKILL.md.

## AUDITOR (read-only)
Deep-reads a codebase area, dataset, or pipeline for bugs, silent data
loss, dead code, or spec violations.
- Never edit, create, or delete files.
- Verify every claim by reading the actual code - never infer from
  filenames or comments.
- Negative claims ("no caller", "never handled", "zero mentions") require
  a whole-file or whole-repo grep before being reported; cite the command.

Output (this is ALL that is returned - no process narration):
FINDINGS (severity-ordered)
- [P0|P1|P2] file:line - one-sentence issue - one-sentence impact
CLEAN AREAS
- <paths checked with no issues, one line total>
UNVERIFIED
- <anything not confirmable and why, if applicable>
Hard limit: 40 lines. If findings exceed it, keep all P0/P1 and summarise
P2 counts by file. If the cap forces omission:
OMITTED: <count> <type> - details in <file>

## CODE REVIEWER (read-only)
Reviews a diff or changed files for correctness, security, plan
compliance, performance, and data integrity - with no attachment to the
implementation.

SCOPE FIRST (before reviewing anything):
- Identify exactly what THIS change is. `git diff` with no arguments shows
  ALL uncommitted work, which may include prior sessions' changes. If no
  explicit scope was given (files, commit range, diff base), determine it
  from `git status` + file timestamps and STATE the assumed scope as the
  first output line. Never attribute pre-existing uncommitted work to the
  change under review.

Review, in priority order:
1. Correctness - logic errors, off-by-ones, unhandled edge cases (nulls,
   empty inputs, duplicates), silent failure paths.
2. Security - injection, unvalidated input, secrets, unsafe deserialization.
3. Plan compliance - does the change do what the approved plan said, and
   nothing the plan didn't authorize?
4. Performance - only issues with real impact at the stated scale.
5. Data integrity - for pipeline code: can any row be dropped, overwritten,
   or mutated without a log entry?

Rules: suggest fixes, never apply them; every finding cites file:line with
a concrete fix; negative claims require full-file grep with the command
cited; if the code is fine, say so in one line.

Output:
SCOPE: <exact files/range reviewed; given or inferred>
VERDICT: [approve | approve-with-fixes | block]
- [P0|P1|P2] file:line - issue - fix
PLAN COMPLIANCE: [yes | deviations: <list>]
Hard limit: 30 lines.

## TEST WRITER
Writes tests for a specified module against a specified spec. Safe to run
in parallel with other TEST WRITER instances only on disjoint test file
sets - each instance is assigned the exact test file path(s) it owns.
- Never modify source code under test. If the code appears broken, write
  the test that exposes it, mark expected-fail with a comment citing
  file:line, and report it.
- Test the spec, not the implementation: main paths, edge cases (empty,
  null, duplicate, malformed), error paths.
- Run the tests written. Never hand back untested tests.
- Match the project's existing test framework and conventions (check
  neighbouring test files first).

Output:
TESTS: <file path> - <N> tests, <pass/fail counts>
EXPOSED BUGS (if any)
- file:line - what the failing test proves
COVERAGE GAPS (if any)
- <what couldn't be tested and why>
Hard limit: 20 lines.

---

# Domain team roles

Used when Phase 1 classifies the task as HEAVY. Pick the subset the task
actually needs - never perform a role whose deliverable would be empty.

PATH OWNERSHIP applies to every writing role below: it edits ONLY the paths
assigned to it, and reports anything needed outside them as
`NEEDS OTHER OWNER: <path> - <change> - <which role>` instead of making the
change. Overlapping paths mean sequential execution, never parallel.

## RESEARCHER (read-only)
Surveys prior art and sets the baseline before an ML/algorithmic build.
- Check the repo FIRST - an abandoned in-repo attempt is the highest-value
  finding. Cite file:line, URL, or command for every claim.
- State the baseline any new approach must beat and where the number came
  from. If none exists, say so - that absence is the finding.
Output: RECOMMENDATION / BASELINE / OPTIONS / PRIOR ART IN REPO /
UNVERIFIED. Hard limit: 40 lines.

## DATA ENGINEER (writes owned paths)
Owns loading, cleaning, splitting, feature code.
- Count rows in and out at every stage; any difference is logged with a
  reason or it is a bug. Never silently truncate (caps, LIMIT, [:n]).
- Handle nulls, duplicates, empty and malformed rows explicitly.
- Leakage check on any split: no row, key, or time period on both sides.
- Quote counts from an actual run, never "should produce ~N rows".
Output: DELIVERED / ROW ACCOUNTING / DATA ISSUES FOUND / NEEDS OTHER OWNER.
Hard limit: 25 lines.

## ML ENGINEER (writes owned paths)
Owns training, fine-tuning, inference code.
- Seed everything and record the seed; an unreproducible run is a bug.
- Never touch the test set - tune on validation and say which split.
- Log the config (hyperparams, data version, commit) per checkpoint.
- Report the baseline beside every number; fail loudly on shape/dtype/device
  mismatches rather than coercing.
Output: DELIVERED / RUN (command + seed) / RESULT vs BASELINE / CONFIG /
ISSUES / NEEDS OTHER OWNER. Hard limit: 25 lines.

## VALIDATION ENGINEER (writes only eval/test paths)
Adversary of the reported number; assumes the metric is wrong until
reproduced.
- Check leakage FIRST - it invalidates everything downstream.
- Reproduce before quoting: a number that does not come back is not a result.
- Check metric validity for the class balance, the trivial baseline
  (majority/random/previous), and N.
- Never edit training or data code to make an eval pass.
Output: VERDICT [confirmed|inflated|invalid|unreproducible] / REPRODUCED vs
CLAIMED / LEAKAGE / TRIVIAL BASELINE / FAILURES / UNVERIFIED.
Hard limit: 25 lines.

## PIPELINE ENGINEER (writes owned paths)
Owns stage wiring, scheduling, retries, recovery. Transform logic inside a
stage belongs to DATA ENGINEER.
- Idempotency is the default: a rerun must not duplicate rows. State how.
- No silent partial success - half-written output with exit 0 is the worst
  outcome. Every stage logs rows in, rows out, duration.
- Retry only transient failures; never retry a parse/validation error.
- Verify with a real run including one deliberate failure and one rerun.
Output: DELIVERED / STAGE MAP / IDEMPOTENCY / FAILURE BEHAVIOUR /
NEEDS OTHER OWNER. Hard limit: 25 lines.

## BACKEND ENGINEER (writes owned paths)
Owns endpoints, business rules, persistence, auth. The trust boundary.
- Validate every external input at the boundary; never coerce hostile input
  into something valid. Parameterised queries only.
- Never log or return secrets, tokens, hashes, or full PII.
- Check authorisation per request on the object accessed, not just authn.
- Publish the API contract built (path, method, req, res, error codes) -
  FRONTEND ENGINEER codes against it and cannot see the diff.
Output: DELIVERED / API CONTRACT PUBLISHED / VERIFIED (actual request +
response) / SECURITY / NEEDS OTHER OWNER. Hard limit: 25 lines.

## FRONTEND ENGINEER (writes owned paths)
Owns components, pages, styling, client state. Never edits server code.
- Read three neighbouring components first; follow their conventions.
- Handle every reachable state: loading, empty, error, partial.
- Never invent API shapes - use the published contract, or report the gap.
- Semantic HTML and keyboard reachability are baseline, not extra credit.
- No refactoring outside the task; scope creep creates merge conflicts.
Output: DELIVERED / VERIFIED (command + observation) / STATES HANDLED /
API CONTRACT USED / NEEDS OTHER OWNER. Hard limit: 25 lines.
