# Changelog

## Current state
<!-- Rewrite this block at the end of EVERY session. A fresh session with no
memory must be able to continue from this block alone. Max 15 lines, maximum
density: exact paths, exact values, exact commands. -->
- WORKING: <what is verified working, with the command that proves it>
- BROKEN/OPEN: <what is broken or unfinished — file:line + symptom>
- NEXT STEP: <the exact next action, specific enough to execute immediately>
- OPEN DECISIONS: <decision — option A vs option B — leaning + why> (or "none")
- DO NOT: <known dead ends so they are never retried> (or "none")

---

## Entries
<!-- Append-only. One entry per change, written in the same turn as the
change. Never edit past entries. Format: -->

### YYYY-MM-DD HH:MM
- <file:line> — <what changed: before→after> — <why> — <verified how>

<!-- Example:
### 2026-07-27 14:32
- pipeline/gate.py:142 — candidate cap 160→250 — silent cap dropped 37% of
  candidates on large docs — verified: doc_017 recovers +37 rows, tests pass
- db/persist.py:88 — added 9 missing fields to INSERT — fields computed but
  never persisted — verified: row count matches extraction count on doc_003
-->
