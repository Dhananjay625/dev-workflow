---
description: Initialize the dev-workflow changelog in the current project
---
Create `CHANGELOG.md` in the project root by copying
`${CLAUDE_PLUGIN_ROOT}/templates/CHANGELOG.template.md`, then fill the
`## Current state` block with the project's actual current state: inspect the
repo briefly (README, entry points, test status via one test run) and write
WORKING / BROKEN-OPEN / NEXT STEP / OPEN DECISIONS / DO NOT with maximum
density (exact paths, exact commands). Do not exceed 15 lines in the block.
If `CHANGELOG.md` already exists, do not overwrite it — report its Current
state instead.
