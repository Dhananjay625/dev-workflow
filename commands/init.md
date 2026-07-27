---
description: Initialize or repair the dev-workflow changelog in the current project
---
Handle the project changelog, covering all three states:

1. No `CHANGELOG.md`: create it from
   `${CLAUDE_PLUGIN_ROOT}/templates/CHANGELOG.template.md`.
2. `CHANGELOG.md` exists but has no `## Current state` block (common on
   existing repos): PREPEND the Current state block from the template above
   the existing content. Never rewrite, reorder, or truncate the existing
   history - it stays byte-identical below the new block.
3. `CHANGELOG.md` exists with a `## Current state` block: do not modify it;
   report its content instead.

For cases 1 and 2, fill the block with the project's ACTUAL current state:
inspect the repo briefly (README, entry points, one test run) and write
WORKING / BROKEN-OPEN / NEXT STEP / OPEN DECISIONS / DO NOT with maximum
density (exact paths, exact commands). Max 15 lines.
