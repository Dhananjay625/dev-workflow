---
name: code-minimalism
description: >
  Write the minimum code that meets the spec. Use whenever writing new code,
  reviewing code for bloat, refactoring, choosing dependencies, or deciding
  how much structure/abstraction/testing/error-handling a task needs. Also
  use when the user asks to simplify, shrink, de-bloat, or clean up code.
---

# Code minimalism

Core principle: every line is a liability. Write only what the spec demands.
When requirements change, add then — never predict.

## Step 1 — Set the context tier FIRST

Minimalism is calibrated, not absolute. Before writing, classify:

| Tier | Examples | Baseline that is NOT bloat |
|---|---|---|
| T1 Throwaway | one-off script, exploration, spike | Nothing. Tracebacks are the error handling. |
| T2 Tool | CLI/script others will run repeatedly | Handle bad input paths + malformed input; usage line on wrong args. |
| T3 Production | service, API, pipeline, library | Input validation on all external input; error handling for network/file/timeout; logging on errors and state changes; nulls/duplicates/empty handled in data-touching code; type hints on public interfaces. |

The tier baseline is part of the spec even when unwritten. Everything ABOVE
the tier baseline needs explicit spec justification. Everything below it is
negligence, not minimalism.

## Step 2 — Write only what passes these gates

Before each addition, one of these must be true, else delete:
1. The spec explicitly requires it.
2. The tier baseline (table above) requires it.
3. Its absence causes a failure that WILL occur in normal use.

Never write: features "for later", scaling beyond stated load, abstraction
layers for imagined reuse, config keys for values that never change,
comments restating the code, docstrings on obvious functions, tests for
code that cannot fail.

## Step 3 — Structure rules

- Inline until 3 uses: no helper, class, or util for a single call site.
- No class where a function works; no function where an expression works.
- Stdlib first: add a dependency only if it replaces >~30 lines of nontrivial
  code you'd otherwise maintain, or provides correctness you can't easily get
  (crypto, timezone math, parsing standards).
- Flat until it hurts: no folder with 1–2 files; no layer directories
  (controllers/services/models) for a handful of endpoints.
- Comment WHY (chosen approach, workaround, assumption), never WHAT.
- Split only on real pressure: function doing 3+ distinct things,
  file >~500 lines, 4+ branch conditionals.

## Step 4 — Test what can actually fail

Test: business logic, validation, error paths, public API behavior.
Don't test: getters, stdlib behavior, code with no branches.
(T3 code keeps the test-on-stop hook green — minimal tests, not zero tests.)

## Step 5 — Delete pass before delivery

Scan the diff and remove: commented-out code, unused imports/variables,
single-use helpers (inline), single-method classes (function), config keys
never changed (hardcode), comments explaining the obvious, impossible-error
handlers. Fewer lines generally means fewer defects and less to maintain —
but never state a made-up percentage for it.

## Interaction with dev-workflow

The dev-workflow rule "handle nulls, duplicates, and empty inputs in any
data-touching code" applies at T2/T3. At T1 (explicitly throwaway) it may be
skipped — say so in one line when skipping.

For worked examples and per-language guidance (Python, JS/TS, SQL, frontend,
dependencies), read `reference.md` in this skill's directory — only when the
task actually involves that language or a judgment call the rules above
don't settle.
