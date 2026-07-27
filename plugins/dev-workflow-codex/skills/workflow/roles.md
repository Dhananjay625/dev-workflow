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
