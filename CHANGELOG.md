# Changelog

## Current state
- WORKING: v1.6.0 domain-team dispatch. Router verified across all 4 domains:
  `for t in "train a classifier on the dataset" "build the ETL pipeline" "implement the checkout page and its API endpoint" "refactor the auth module across the repo" "read the code"; do printf '{"prompt":%s}' "$(printf '%s' "$t" | jq -Rs .)" | sh hooks/team-router.sh; done`
  -> ML / DATA PIPELINE / WEB APP / GENERAL / light-exit respectively.
  `jq -e '.hooks|keys' hooks/hooks.json` -> 4 events, valid JSON.
- BROKEN/OPEN: hooks/team-router.sh not yet exercised by a real Claude Code
  session (only piped payloads) - `${CLAUDE_PLUGIN_ROOT}` resolution untested.
  AGENTS.md deliberately NOT updated (target tools have no subagent mechanism).
- NEXT STEP: install locally (`/plugin install ./dev-workflow`), restart, send
  a heavy prompt, confirm a `[dev-workflow] HEAVY TASK` line appears in context.
- OPEN DECISIONS: HEAVY regex breadth - currently fires on `implement|build a|
  performance|integrat`; may over-fire on small tasks using those words.
  Leaning: leave until a real-session false-positive rate is observed.
- DO NOT: put team-router logic inline in hooks.json (4 domain branches +
  2 regex tiers is unmaintainable as a JSON-escaped one-liner).
  DO NOT gate domain detection behind the HEAVY regex without ML terms in it -
  that silently dropped "train a classifier on the dataset" as light.

---

## Entries
<!-- Append-only. One entry per change, written in the same turn as the
change. Never edit past entries. -->

### 2026-08-02 14:30
- agents/researcher.md, data-engineer.md, ml-engineer.md,
  validation-engineer.md, frontend-engineer.md, backend-engineer.md,
  pipeline-engineer.md — new (7 files, 0→~45 lines each) — user asked for
  industry-style domain teams (ML: researcher/data/ml/validation; web:
  frontend/backend/test) instead of 3 generic agents — verified: `grep -rn
  '^name:' agents/` shows 10 unique names, no duplicates. Reused existing
  test-writer, code-reviewer, auditor rather than creating per-domain
  duplicates; rejected a separate `test-engineer` since agents/test-writer.md:1
  already holds that contract.
- hooks/team-router.sh — new (0→57 lines) — UserPromptSubmit needs heavy-task
  + domain detection; rejected inlining into hooks.json because 4 domain
  branches JSON-escaped into one string is unmaintainable (hooks.json:19 is
  already at the readable limit at one branch) — verified: 6 piped payloads
  route to the correct domain, light prompts exit early.
- hooks/team-router.sh:10 — HEAVY regex += `train(ing)?|fine.?tun|classifier|
  neural|dataset|embedding` — "train a classifier on the support tickets
  dataset" was classified light and never reached ML domain detection, since
  the HEAVY gate runs first — verified: same prompt now returns
  `HEAVY TASK - domain: ML / MODEL`. Bare `model` deliberately excluded
  (over-fires on "data model", "model field").
- hooks/hooks.json:13-22 — added UserPromptSubmit event calling
  team-router.sh — hooks are the only always-on layer; a skill rule alone
  applies only after the skill loads — verified: `jq -e '.hooks|keys'` -> 4
  events, existing 3 hooks byte-unchanged.
- skills/workflow/SKILL.md:41-60 — Phase 1 rewritten (3 fixed dispatch
  triggers + inline-first default → domain role-menu table + self-sizing rule
  + path-ownership rule + honest cost note) — inverts the old "dispatch ONLY
  when isolation value exceeds cost" default for heavy tasks — verified: menu
  role names match the 10 agent `name:` fields exactly.
- plugins/dev-workflow-codex/skills/workflow/SKILL.md:61-79 — same Phase 1
  rewrite in instruction form (no hooks in Codex) — README.md:192 claims skill
  parity between ports, which would otherwise become false — verified: role
  sets identical to the Claude Code table.
- plugins/dev-workflow-codex/skills/workflow/roles.md:81-165 — appended 7
  domain role contracts — Codex has no agents/ dir, so roles.md is its only
  contract store; the new menu names would otherwise not resolve — verified:
  `wc -l` 80→165, existing 3 contracts untouched.
- .claude-plugin/plugin.json:4 and plugins/dev-workflow-codex/.codex-plugin/
  plugin.json:3 — version 1.5.0→1.6.0 — behavioral change to dispatch
  defaults — verified: both files parse, versions match.
- README.md:40-51 → domain-team table; structure block updated with the 7 new
  agents and hooks/team-router.sh — the 3-agent table understated what ships
  — verified: table role names match agents/ `name:` fields.
- CHANGELOG.md — created (this file) from templates/CHANGELOG.template.md —
  the repo shipped a changelog-as-memory workflow without using one itself;
  hooks/hooks.json:8 expects it — verified: `grep -c '^## Current state'` = 1.

### 2026-08-02 15:05
- AGENTS.md:56-107 — new section 3 "Assemble a team for heavy tasks"; old
  sections 3-8 renumbered 4-9; section 1's two "section 7" changelog
  cross-refs → "section 8" — the third port had NO delegation content at all,
  so Cursor/Gemini CLI/Copilot/Windsurf users got none of v1.6.0. Earlier
  reason for skipping it ("target tools have no subagent mechanism") was too
  broad — several do spawn isolated workers — verified: `grep -n '^## '`
  shows 1-9 sequential, no gaps/dupes; `grep -n 'section [0-9]'` shows both
  refs now point at 8; role sets identical across all 3 ports.
- AGENTS.md:66-75 — team section written mechanism-agnostic (spawn isolated
  workers if the tool supports it, else perform roles inline in topology
  order) — a subagent-only instruction would be unimplementable on tools
  without spawning, and the value is the separation of concerns, not the
  spawn — verified: no tool-specific API named anywhere in the section.
