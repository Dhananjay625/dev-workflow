---
description: End-of-session wrap — update changelog Current state for clean resume
---
Wrap up this session now:
1. Verify every change made this session has an entry in `CHANGELOG.md`
   (`file:line — before→after — why — verified how`). Append any missing ones.
2. Rewrite the `## Current state` block (max 15 lines, maximum density) so a
   fresh session with zero memory can continue from it alone: WORKING (with
   proof command), BROKEN/OPEN (file:line + symptom), NEXT STEP (immediately
   executable), OPEN DECISIONS (options + leaning), DO NOT (dead ends).
3. Output a closing report of <=5 lines: what changed, test status, known
   gaps, next step. Nothing else.
