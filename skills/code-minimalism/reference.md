# Code minimalism — reference examples

Read this only when the active task involves the relevant language or a
judgment call SKILL.md doesn't settle. Do not load it preemptively.

## Worked example: CSV → JSON CLI (T2 tool)

Spec: "CLI tool that reads a CSV and outputs JSON."

Bloated (~100 lines): logging setup, a `CSVReader` class wrapping stdlib,
argparse with epilog, pretty-print flag not in spec, try/except re-raising
with log noise.

Minimal at T2 (tool others run — baseline includes bad-input handling):

```python
import csv, json, sys

if len(sys.argv) != 3:
    sys.exit("usage: csv_to_json.py input.csv output.json")

try:
    with open(sys.argv[1], newline="") as f:
        data = list(csv.DictReader(f))
except OSError as e:
    sys.exit(f"cannot read {sys.argv[1]}: {e}")

with open(sys.argv[2], "w") as f:
    json.dump(data, f)
```

At T1 (personal throwaway) the usage line and try/except go too — 8 lines.
Neither version gets a class, logging, or a pretty flag: not in spec.

## Python

- Language features over helpers: `key in d`, comprehensions over
  append-loops, `{**a, **b}` over merge helpers.
- Type hints: T3 public interfaces yes; short private functions with obvious
  types no. Never annotate what inference makes obvious to a reader.
- Docstrings: only where behavior is non-obvious
  (`"""2^attempt seconds, capped at 300."""`), never "Returns the name."

## JavaScript / TypeScript

- Middleware: mount only what handles a real request concern in THIS app —
  not a helmet/cors/compression/morgan stack copied from a template.
- Structure: `index.js`, `handlers.js`, `db.js` beats a 12-folder layout for
  five endpoints. Introduce layers when a second consumer appears, not before.
- TS types: type the public surface and external data (API responses,
  parsed input). Let inference handle locals and obvious literals.

## SQL

- `SELECT` named columns, never `*` in application code (schema drift breaks
  silently).
- Normalize to the query patterns you have, not textbook 3NF: a five-column
  `products` table beats a five-table hierarchy for a small catalog.

## Frontend

- Components exist for reuse or isolated state — not for every div. One-off
  page structure stays inline.
- Don't add a state-management library for two pieces of state; don't add a
  date library to parse ISO strings; don't add a CSS framework to center one
  box. If the project ALREADY uses Tailwind/etc., follow the project —
  consistency beats local minimalism.

## Dependencies — the two questions

1. Can stdlib do it? (strings, dates, HTTP, files, JSON: usually yes)
2. Would I use >~10% of the library? If no, write the 20 lines yourself —
   unless correctness is hard (crypto, TZ math, spec-compliant parsing),
   where a maintained library IS the minimal choice.

## Review red flags → action

Commented-out code, unused imports/vars, single-use helpers or classes,
never-changed config keys, obvious-comment noise, tests on unfailable code,
impossible-error handlers → delete or inline on sight. 1000+ line file,
3+ nested loops, 4+ branch conditional → split.

## What minimalism is NOT

- Not skipping the tier baseline (validation on external input at T3 is
  required, not bloat).
- Not golf: clarity beats character count; a readable 5 lines beats a
  clever 1-liner.
- Not deleting tests that guard money-losing paths.
- Not refusing structure a growing codebase demonstrably needs — the rule is
  "no structure BEFORE need," not "no structure ever."
