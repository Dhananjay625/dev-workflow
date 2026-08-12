# Changelog

## Current state
- WORKING: v1.6.0 domain-team dispatch, now audited end-to-end and LIVE-VERIFIED.
  `${CLAUDE_PLUGIN_ROOT}` resolution is CONFIRMED: this session's own
  UserPromptSubmit fired and injected `[dev-workflow] HEAVY TASK - domain:
  GENERAL` into context. That closes the last v1.6.0 open item.
  Router regression matrix (15 prompts, all correct):
  `run(){ printf '{"prompt":%s}' "$(printf '%s' "$1" | jq -Rs .)" | sh hooks/team-router.sh; }`
  -> "train a classifier on the dataset"=ML, "Could you train a classifier on
  the dataset?"=ML, "Can you build the ETL pipeline for the warehouse?"=PIPELINE,
  "how do I fix the login form"=WEB, "refactor the auth module across the
  repo"=GENERAL, "read the code"/"is the dashboard up"/"what is my login
  email"/"fix a typo in the readme"=light.
  `sh -n hooks/team-router.sh` clean; all 5 JSON manifests pass `jq -e .`;
  exit code is 0 on every path.
- BROKEN/OPEN: nothing blocking. Two accepted-risk items, deliberately NOT
  changed (they are design calls, not defects):
  (1) Stop hook runs the project's FULL test suite on every stop with no
  timeout - in a large repo this adds minutes to every turn-end.
  (2) PostToolUse runs `ruff check --fix` / `prettier --write`, silently
  MUTATING the user's file after every edit. Both are opt-out-less today.
  Also: "why is my pipeline dropping rows" still exits light (interrogative,
  no task verb). Diagnostic questions are cheap to escalate manually.
- NEXT STEP: decide on the two accepted-risk hooks above - most likely a
  timeout on Stop and a documented opt-out env var for the lint mutation.
  Then commit; the working tree has 4 modified files + new .gitignore.
- OPEN DECISIONS: HEAVY regex breadth still fires on `implement|build a|
  performance|integrat`; unchanged pending a real false-positive rate.
- DO NOT: put team-router logic inline in hooks.json (4 domain branches +
  2 regex tiers is unmaintainable as a JSON-escaped one-liner).
  DO NOT gate domain detection behind the HEAVY regex without ML terms in it -
  that silently dropped "train a classifier on the dataset" as light.
  DO NOT re-add `\bauth\b` to the WEB vocabulary - "auth" exists in CLIs,
  daemons and libraries, and it hijacked "refactor the auth module across the
  repo" away from GENERAL.
  DO NOT gate the interrogative guard on HEAVY_GENERIC alone - polite requests
  ("could you train a classifier?") carry no HEAVY_GENERIC term and were
  silently dropped as light.

---

## Entries
<!-- Append-only. One entry per change, written in the same turn as the
change. Never edit past entries. -->

### 2026-08-12 (Codex remote install fix)
- .agents/plugins/marketplace.json:15 — `"authentication": "ON_FIRST_USE"` →
  `"ON_USE"` — `ON_FIRST_USE` is not a variant Codex's manifest deserializer
  accepts, so `codex plugin marketplace add <github url>` aborted the whole
  marketplace with `unknown variant 'ON_FIRST_USE', expected 'ON_INSTALL' or
  'ON_USE' at line 15 column 40`. Local installs had masked it (the existing
  entry was added under an older codex; 0.147.0 rejects it). — verified:
  reproduced against the pushed GitHub URL (staged clone at
  `~/.codex/.tmp/marketplaces/.staging/marketplace-add-7kBY2U`, same error),
  then after the edit `codex plugin marketplace add <repo path> --json`
  returned `{"marketplaceName":"dev-workflow-codex-marketplace",...}` and
  `codex plugin list` shows `dev-workflow@dev-workflow-codex-marketplace
  installed, enabled 1.6.0`.
- NOTE (not a repo change): the above `marketplace add` re-pointed the user's
  `~/.codex/config.toml` `[marketplaces.dev-workflow-codex-marketplace]`
  source from `/Users/.../Documents/Playground/.codex-marketplaces/dev-workflow`
  to this repo root. Marketplace names are the config key, so adding a
  second source under the same name overwrites rather than coexists.
- STILL OPEN: the fix is unpushed, so the GitHub URL install remains broken
  for everyone until `.agents/plugins/marketplace.json` is committed and
  pushed to origin/main. README.md:189-205 also still documents only the
  clone-then-`/plugins` flow, not the one-line
  `codex plugin marketplace add https://github.com/Dhananjay625/dev-workflow`.

### 2026-08-04 (audit continuation)
- hooks/team-router.sh:15 — WEB vocabulary `-= \bauth\b` — the documented,
  previously-verified baseline "refactor the auth module across the repo"
  had regressed from GENERAL to WEB APP, because a single incidental `auth`
  hit outscored a repo-wide generic refactor and dispatched
  backend/frontend-engineer at a task that owns neither. "auth" is not
  web-specific (CLIs, daemons, libraries all have it); the UI-specific terms
  `log.?in|sign.?up|sign.?in` already cover real web auth work — verified:
  "refactor the auth module across the repo" -> GENERAL (baseline restored),
  "add auth to the api endpoint" -> WEB APP (still correct via `\bapi\b`).
- hooks/team-router.sh:17-20,34-39 — new `TASKVERB` regex, and the
  interrogative guard's negative condition widened from `$HEAVY_GENERIC` to
  `$HEAVY_GENERIC|$TASKVERB` — the guard added last session swallowed politely
  phrased work: "Could you train a classifier on the dataset?" exited light,
  even though the bare imperative "train a classifier on the dataset" routed
  to ML. Polite interrogatives are the dominant phrasing in Claude Code, so
  this silently disabled ML/WEB/PIPELINE dispatch for a large share of real
  prompts — verified: polite form now -> ML; "how do I fix the login form" ->
  WEB APP; genuine questions ("is the dashboard up", "what is my login email",
  "who owns the payment dashboard") still exit light.
- .gitignore — new (0→11 lines) — the repo had NO .gitignore while ~3MB of
  agent-runtime state (ruvector.db 1.5M, .claude-flow/ 888K, .swarm/ 612K,
  agentdb.rvf, .claude/) sat untracked in the root of a published marketplace
  repo; one `git add -A` would have published local session state — verified:
  `git status --short` now lists only the 4 intended modified files plus
  `?? .gitignore`.
- README.md:174 — install checklist "`/agents` shows auditor, code-reviewer,
  test-writer" → all 10 agent names — the plugin has shipped 10 agents since
  v1.6.0, so the documented post-install verification step understated the
  install and would read as a partial failure — verified: listed names match
  `grep -rn '^name:' agents/` exactly.
- .claude-plugin/plugin.json:2 — marketplace description "context-isolated
  subagents (auditor, code-reviewer, test-writer)" → all 10 grouped by domain,
  plus "automatic domain-team routing" — same v1.6.0 drift on the only text a
  user sees BEFORE installing — verified: `jq -e .` passes; `name`/`version`
  untouched so marketplace.json's `source: "."` resolution is unaffected.
- AUDITED, NO CHANGE: `\b` word boundaries are supported by both BSD grep
  (macOS, tested directly) and GNU grep, so the v1.6.0 `[^a-z]`→`\b` switch is
  portable — `echo "run ml now" | /usr/bin/grep -oiE '\bml\b'` matches while
  "mlx tooling" does not. Agent frontmatter is clean: 10 files, `name:` matches
  filename in all 10, all pin `model: sonnet`, no duplicates. Role parity holds
  across ports: skills/workflow/SKILL.md names the same 10 roles as agents/,
  and plugins/dev-workflow-codex/skills/workflow/roles.md carries all 10
  contracts. All 5 JSON manifests valid.

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

### 2026-08-02 21:30
Round-1 A/B audit of v1.6.0: same brief to a plugin-dispatched auditor and a
baseline agent. Plugin run found 2 issues, baseline found 8 — the baseline
caught the gate-ordering root cause the plugin run saw only as a WEB-regex
symptom. Fixes below are C1/H1/H2 from that audit; H3 + M1-M4 deferred to
tasks #1-#5.
- hooks/team-router.sh:13-18 — ML/PIPE/WEB definitions moved ABOVE the heavy
  gate and `HEAVY` rebuilt as `HEAVY_GENERIC|ML|PIPE|WEB` (was: HEAVY defined
  alone at old :10, domains at old :17-19 below it) — the gate returned early
  at old :13, so ~2/3 of the domain vocabulary was unreachable: prompts built
  from those terms exited as "light task" and never saw a domain branch —
  verified: all 5 baseline repro prompts ("the model is overfitting, tune the
  hyperparameters", "our dbt models are broken, fix the warehouse ingest",
  "the React component re-renders on every keystroke", "the Airflow DAG
  silently drops rows in the extract stage", "data quality checks are failing
  across the batch job") now route ML/DATA/WEB/DATA/DATA; all were "light
  task" before.
- hooks/team-router.sh:13,15 — `[^a-z]ml[^a-z]`, `[^a-z]api[^a-z]`,
  `[^a-z]ui[^a-z]` → `\bml\b`, `\bapi\b`, `\bui\b` — the bracket form needs a
  character on BOTH sides, so a term ending the prompt never matched, and
  prompts commonly end on the noun — verified: "add support for the API",
  "optimize the UI", "refactor the api" now all → WEB APP; all were GENERAL.
  \b confirmed working in BSD grep -E on this macOS box, not assumed.
- hooks/team-router.sh:38-52,54-67 — if/elif first-match chain → match-count
  scoring (`n_ml`/`n_pipe`/`n_web`, highest wins) plus an `ALSO MATCHED` line
  naming any secondary domain that scored >0 — one stray ML term
  ("checkpoint", "dataset") outranked prompts that were mostly pipeline or web
  work, silently dropping the role that owned half the job — verified: "build
  an ETL pipeline for the training dataset" → ML primary + ALSO MATCHED
  DATA-PIPELINE(pipeline-engineer); "build a dashboard showing model accuracy"
  → ML + ALSO MATCHED WEB. Both lost the secondary role entirely before.
  Chose over-offering one line rather than a combined menu because
  SKILL.md already instructs the model to size the roster down.
- hooks/team-router.sh:15 — WEB regex += `checkout|shopping cart|log.?in|
  sign.?up|sign.?in|payment|\bauth\b|profile page|dashboard|form submi` — the
  pattern held only tech jargon, so the most common real web work
  (checkout/login/cart/payment/signup) fell through to GENERAL and got
  auditor+test-writer instead of backend+frontend+test-writer — verified: all
  5 of those prompts now → WEB APP; all were GENERAL.
- hooks/team-router.sh:25-33 — NEW question guard: interrogative opener with
  no HEAVY_GENERIC action verb exits light — folding domain nouns into the
  gate made questions reachable, and "what is my login email" / "is the
  dashboard up" both fired a full WEB roster — verified: both now light;
  "how do I implement checkout" still HEAVY (has `implement`), so real tasks
  phrased as questions survive. Full 30-case suite: 10 light + 20 heavy, all
  correct, `sh -n` clean, jq-missing and empty-prompt paths still exit 0.
- BEHAVIOR CHANGE from the v1.6.0 baseline suite: "refactor the auth module
  across the repo" was GENERAL, now WEB APP (via the new `\bauth\b`). Judged
  an improvement — backend-engineer owns auth — but it is a real change to a
  documented case, not a no-op.
