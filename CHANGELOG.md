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
- ALSO WORKING: v1.6.1 closes both accepted-risk hooks. Stop now carries a
  harness-enforced `"timeout": 120` and an opt-out; PostToolUse lint has an
  opt-out. Both verified by piping the extracted command into `sh` with and
  without the env var set - see the 1.6.1 entry for the exact transcript.
- BROKEN/OPEN: nothing blocking. One accepted-risk item remains:
  "why is my pipeline dropping rows" still exits light (interrogative, no
  task verb). Diagnostic questions are cheap to escalate manually.
- ALSO WORKING: Codex remote install, LIVE-VERIFIED against the real GitHub
  URL after 046b384. `codex plugin marketplace add
  https://github.com/Dhananjay625/dev-workflow` now resolves
  (`source_type = "git"`) and `codex plugin list` shows the plugin
  installed+enabled at 1.6.0. Root cause was
  `.agents/plugins/marketplace.json` declaring `authentication:
  "ON_FIRST_USE"`, which Codex 0.147.0's deserializer rejects (valid:
  `ON_INSTALL` | `ON_USE`); the bad value aborted the entire marketplace
  parse before any plugin was listed, so the error never named the plugin.
- ALSO WORKING: open-source infrastructure is in place — CONTRIBUTING.md,
  SECURITY.md, CODE_OF_CONDUCT.md, issue/PR templates, a CI workflow, and
  scripts/validate.sh holding the 9 repo invariants that were previously
  re-checked by hand each session. validate.sh is negative-tested: four
  injected faults each produced exit 1.
- ALSO WORKING: v1.6.1 is RELEASED — annotated tag v1.6.1 at 56716a0, GitHub
  release marked latest, tarball verified to carry 1.6.1 in both manifests and
  to pass validate.sh in a clean checkout. The version is now pinnable; before
  this the repo had no tags at all.
- NEXT STEP: v1.6.1 is COMMITTED BUT NOT YET LIVE-VERIFIED end-to-end. The
  hook commands were verified in isolation (extracted from the JSON, piped
  into `sh`); what is NOT yet proven is that Claude Code itself honours the
  `"timeout": 120` field on a Stop hook - that needs one real session in a
  repo with a slow suite. Also NOT verified: the new one-line Codex install
  block in README.md:194-203 was written from `codex plugin --help`
  (subcommand is `add`, NOT `install`), not from an actual clean install.
  Re-verify with `codex plugin marketplace remove` then add from the URL.
  CI IS NOW LIVE-VERIFIED: run 33993259528 on the real ubuntu-latest runner
  completed `success` in 13s (`gh run watch --exit-status` → 0), so both the
  validate.sh and shellcheck steps pass off this machine, not just on macOS.
  Repo description and 9 topics are set; repo is PUBLIC with issues enabled.
  RESOLVED (privacy): repo-local `git config user.email` is now the GitHub
  noreply address and the personal student address is redacted from this file.
  HISTORY IS DELIBERATELY UNCHANGED — user chose not to rewrite, since new
  SHAs would break every existing clone and fork for a value GitHub may have
  cached anyway. Past commits still carry the old address; that is accepted.
- MEASURED: router accuracy is 83.8% (57/68) on tests/router-cases.tsv;
  `sh scripts/benchmark.sh` reproduces it and prints every miss. 8 of 11
  misses are heavy-work-classified-as-light for lack of a vocabulary term.
  This is the top open quality issue and the number to move.
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
  DO NOT invent enum values in `.agents/plugins/marketplace.json` - Codex
  fails the WHOLE marketplace on one unknown variant and the error names
  the line, never the plugin. Check against `codex plugin marketplace add
  --help` and the accepted variants before editing policy fields.
  DO NOT trust a working local Codex install as evidence the remote install
  works - a stale registration from an older codex build kept `ON_FIRST_USE`
  working locally for weeks while every GitHub-URL install failed. Verify
  remote installs by `marketplace remove` then re-add from the URL.
  DO NOT document `codex plugin install <name>` - there is no such
  subcommand. `codex plugin --help` on 0.147.0 lists exactly: add, list,
  marketplace, remove. Installing a plugin is `codex plugin add`.
  DO NOT verify a hook by running `sh -n` on a file built from a failed
  `jq` - an empty file passes `sh -n` and reports a false OK. Check the
  byte count of the extracted command before trusting the syntax result.
  DO NOT pipe into a `while read` loop in a check script — the loop body runs
  in a SUBSHELL and any failure flag it sets is discarded, so the script
  reports FAIL and exits 0. Redirect from a file instead.
  DO NOT list files for validation with plain `git ls-files` — it shows only
  TRACKED files, so newly added files are skipped and the check passes
  vacuously. Use `--cached --others --exclude-standard`.
  DO NOT add a CI lint step without running that linter locally first —
  shellcheck found 3 hard errors in the first draft of validate.sh, which
  would have made the very first CI run red.
  DO NOT tune the router against tests/router-cases.tsv and then quote the
  resulting accuracy - that is training on the test set. Fix against the
  failure MODE, then re-measure on prompts written after the fix.
  DO NOT relabel a corpus case after seeing what the router did to it. One
  label ("implement retry logic everywhere we call the payment provider" =
  general, router said web) is genuinely debatable and was LEFT ALONE for
  exactly this reason.
  DO NOT bump the version in plugin.json without cutting a matching tag — a
  manifest version with no tag is a claim with no artifact behind it, and
  users end up installing from a moving `main`. Verify a release by
  downloading the published TARBALL and checking the version inside it, not
  by checking the working tree you just tagged from.

---

## Entries
<!-- Append-only. One entry per change, written in the same turn as the
change. Never edit past entries. -->

### 2026-09-05 (measurement: router benchmark)
- tests/router-cases.tsv — new (68 labeled prompts) — the router had never been
  measured against anything but ad-hoc spot checks, so no accuracy claim about
  it could be made honestly. Labels were written as "what a reasonable
  maintainer would want" BEFORE running the router, and cases expected to fail
  were included deliberately; a corpus with no failures measures nothing.
  Ambiguous prompts carry multiple acceptable labels ("web|ml").
- scripts/benchmark.sh — new — measures router accuracy, context cost in
  characters, and hook latency. Explicitly does NOT measure "does this make an
  agent better at coding": that needs a controlled eval with blind grading,
  and the script says so in its header so no number in it can be quoted as
  that claim.
- MEASURED (first run, this machine): router accuracy 57/68 = 83.8%.
  Context cost: light prompt 60 chars (~15 tok), heavy prompt 888 chars
  (~222 tok), SessionStart 9,820 chars (~2,455 tok) in THIS repo. Latency
  9.4 ms light / 20.9 ms heavy, mean of 50 runs.
- FINDING (not yet fixed): 8 of the 11 misses are the SAME failure mode —
  plainly heavy work classified as LIGHT because it contains no HEAVY
  vocabulary term ("add dark mode to the settings page", "port this bash
  script to python", "remove all the dead code in the repo", "set up
  pre-commit hooks"). Verified: that prompt matches 0 heavy-vocab terms, so
  the gate drops it before domain detection runs. This is the DANGEROUS
  direction of error - the router silently declines to staff work rather
  than over-offering a role.
- NOT CHANGED DELIBERATELY: the router was not tuned against this corpus in
  the same session it was measured. Fixing the regex until the number goes up
  would make the 83.8% an in-sample score and therefore meaningless. Any fix
  needs a fresh held-out set written after the change.

### 2026-09-05 (v1.6.1 released)
- git tag v1.6.1 (annotated) at 56716a0 + GitHub release — the repo had ZERO
  tags despite both manifests declaring 1.6.1, so the declared version had no
  immutable reference: every install was really tracking `main` and nobody
  could pin. Twelve-Factor V (build/release/run separation) — verified: tag
  object b16dcb4 dereferences to 56716a0 == origin/main; `gh api
  .../releases/latest` returns `v1.6.1`; release is not draft, not
  prerelease. END-TO-END: downloaded the published tarball from the tag URL
  (59,285 bytes), and in that clean extracted copy BOTH plugin.json files
  read 1.6.1 and `sh scripts/validate.sh` exits 0 — so the artifact a user
  actually installs is self-consistent, not just the working tree.
- Release notes lead with the two opt-out env vars and the Stop timeout,
  since those are what a cautious installer needs before trusting a plugin
  that runs shell on every turn.

### 2026-09-05 (open-source infrastructure)
- scripts/validate.sh — new (0→~100 lines) — the repo's invariants were being
  re-checked by hand every session (manifests parse, hooks are valid shell,
  agent names unique, port parity, one `## Current state`); that is exactly
  what a script should hold, and CI can then run the same file — verified:
  passes clean, and NEGATIVE-tested by injecting four faults (version drift,
  agent name/filename mismatch, a deleted agent the router offers, a malformed
  YAML file) — each produced a FAIL line and exit 1, and reverting restored
  exit 0.
- scripts/validate.sh check 5 — `grep ... | while read` → `while read < tmpfile`
  — the pipeline ran the loop in a SUBSHELL, so `fail=1` was discarded: the
  script printed `FAIL: router offers 'researcher'...` and still exited 0. CI
  would have gone GREEN on a broken repo, which is worse than having no CI —
  verified: deleting agents/researcher.md now yields exit 1, restoring yields 0.
- scripts/validate.sh checks 1 and 9 — `git ls-files` → `git ls-files --cached
  --others --exclude-standard` — plain ls-files lists only TRACKED files, so
  the four brand-new .github YAML files were invisible and check 9 passed by
  finding nothing — verified: check 9 now lists all 4 files; `find` rejected in
  the other direction because it descends into gitignored .claude-flow/.
- .github/workflows/ci.yml — new — runs validate.sh + shellcheck on push/PR.
  shellcheck is a separate step, not folded into validate.sh, so contributors
  without it installed can still run the invariants — verified: installed
  shellcheck locally first and fixed 3 SC1087 ERRORS (`$k[$i]` parses as an
  array expansion) plus 4 infos; `shellcheck -s sh hooks/*.sh scripts/*.sh` is
  now clean, so CI will not go red on its first run. hooks/team-router.sh was
  already clean.
- CONTRIBUTING.md — new (107 lines) — documents the two-port parity rule, the
  two hook rules (never block the user; anything mutating or slow needs an
  opt-out), and how to extract a hook command from the JSON before testing it,
  including the byte-count check that catches an empty extraction.
- SECURITY.md — new — this plugin runs shell on every prompt, edit and
  turn-end and rewrites the user's files, which is a real disclosure
  obligation for an open-source install; states what runs, that nothing leaves
  the machine, both opt-out vars, and routes reports to GitHub private
  advisories rather than a public issue.
- CODE_OF_CONDUCT.md — new — shortened Contributor Covenant 2.1. Enforcement
  contact is the private security advisory URL, deliberately NOT an email
  address, to avoid publishing a personal address in a public repo.
- .github/ISSUE_TEMPLATE/{bug_report,feature_request,config}.yml,
  .github/PULL_REQUEST_TEMPLATE.md — new — bug template requires version, host
  and platform (the fields that actually make a hook/router bug reproducible);
  feature template requires an explicit cost answer, since the project's thesis
  is that additions must justify their token cost — verified: all 4 YAML files
  parse under `ruby -ryaml`, and validate.sh check 9 now enforces that.
- README.md:3-4, 345-360 — CI + license badges, and a Contributing section
  linking the three new docs — verified: `grep -n` finds all five references.

### 2026-09-05 (v1.6.1 - hook opt-outs, Stop timeout, Codex install lead)
- hooks/hooks.json:29 — PostToolUse lint command prefixed with
  `[ -n "$DEV_WORKFLOW_NO_LINT" ] && { echo ...; exit 0; };` — the hook ran
  `ruff check --fix` / `prettier --write` on every edit, silently rewriting
  the user's file with no way to decline; an opt-out is the minimum a
  mutating hook owes its user — verified: extracted the command with
  `jq -r --arg k PostToolUse '.hooks[$k][0].hooks[0].command'` (759 bytes,
  `sh -n` clean) and piped a synthetic `{"tool_input":{"file_path":
  "/tmp/x.py"}}` payload into it — with `DEV_WORKFLOW_NO_LINT=1` it prints
  `lint: skipped (DEV_WORKFLOW_NO_LINT set)` and exits 0; unset, it still
  reaches the normal `no linter mapped` path.
- hooks/hooks.json:38-39 — Stop hook gained `"timeout": 120` and the same
  opt-out guard (`DEV_WORKFLOW_NO_STOP_TESTS`) — it ran the project's FULL
  suite at every turn-end with no bound, adding minutes per turn in a large
  repo. Used the harness's own `timeout` field rather than a `timeout(1)`
  wrapper because macOS ships no `timeout` binary (it is `gtimeout` from
  coreutils, not present by default), so a shell wrapper would silently
  no-op on the author's own platform — verified: `jq -r
  '.hooks.Stop[0].hooks[0].timeout'` = 120; command extracted (639 bytes,
  `sh -n` clean); with the env var set it prints `stop-check: skipped` and
  exits 0, unset it prints `no test suite detected`.
- README.md:71-77 — hooks bullet rewritten to state that lint REWRITES the
  file in place and to name both env vars + the 120s cap — an opt-out no one
  can discover is not an opt-out — verified: `grep -n DEV_WORKFLOW_NO`
  README.md returns both names in the behaviour section and again under
  Requirements.
- README.md:280-286 — Requirements section gained an explicit opt-out list.
- README.md:191-203 — Codex install now leads with `codex plugin marketplace
  add <url>` + `codex plugin add dev-workflow`, with the clone flow demoted
  to a secondary option — the one-line remote install started working at
  046b384 but the README still documented only the clone-then-`/plugins`
  path — verified: `codex plugin --help` on the installed 0.147.0 lists
  exactly `add, list, marketplace, remove`. NOTE: I first wrote `codex
  plugin install dev-workflow`; there is no `install` subcommand and the
  help output caught it before commit.
- .claude-plugin/plugin.json:4 and plugins/dev-workflow-codex/.codex-plugin/
  plugin.json:3 — version 1.6.0→1.6.1 — hook behaviour changed in a
  user-visible way (a new field and two new env vars) — verified: all 5 JSON
  manifests pass `jq -e .`, both report 1.6.1.

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

- PUSHED as 046b384 (aa0fa61..046b384, origin/main) — supersedes the
  "STILL OPEN" bullet above; the remote install path is now live. Single
  commit, sole author `Dhananjay` (single author), no
  `Co-Authored-By` trailer (user asked explicitly; also CLAUDE.md rule).
  Carried the v1.6.0 audit follow-ups (team-router regressions, 10-agent
  description, README agent list, new .gitignore) in the same commit
  rather than splitting, since the CHANGELOG hunk spans both. — verified
  END-TO-END against the real remote, not a local path:
  `codex plugin marketplace remove dev-workflow-codex-marketplace` then
  `codex plugin marketplace add https://github.com/Dhananjay625/dev-workflow`
  → `{"marketplaceName":"dev-workflow-codex-marketplace","installedRoot":
  "~/.codex/.tmp/marketplaces/dev-workflow-codex-marketplace"}`;
  `codex plugin list` → `dev-workflow@dev-workflow-codex-marketplace
  installed, enabled 1.6.0`; config.toml now records
  `source_type = "git"`, `source = "https://github.com/Dhananjay625/dev-workflow.git"`.
- SIDE EFFECT (user's machine, not the repo): the `remove` + git `add`
  above replaced the earlier local-path marketplace registration. The
  Playground path `/Users/.../Documents/Playground/.codex-marketplaces/dev-workflow`
  is no longer registered at all — the plugin now resolves from the git
  snapshot. Restore with `codex plugin marketplace add <that path>` if the
  local working copy is wanted back.

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
