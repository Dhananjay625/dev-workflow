# dev-workflow

A production workflow for AI coding agents: plan-first execution,
cross-session memory via a project changelog, evidence discipline, and
tier-calibrated code minimalism.

Works three ways:
- **Claude Code plugin** - install once, everything is enforced
  automatically (hooks, subagents, auto-triggering skills). No per-project
  setup, no per-session instructions.
- **Codex plugin** - the same skills as a native OpenAI Codex plugin,
  installable from this repo's built-in Codex marketplace. See
  [Install (Codex)](#install-codex).
- **Any other agent** (Gemini CLI, Cursor, Aider, ...) - drop `AGENTS.md`
  into your project root and the same ruleset applies by instruction. See
  [Using with any AI agent](#using-with-any-ai-agent).

Both modes share one `CHANGELOG.md` as common memory, so different agents
can work the same repo and resume each other's sessions.

## What it does

**1. Cross-session memory (auto-changelog).**
AI coding agents have no memory between sessions. This workflow gives them
one, stored in the repo itself:
- The project's `CHANGELOG.md` carries a `## Current state` block: what
  works, what's broken, exact next step, known dead ends. Any agent resumes
  from it. (In Claude Code, a `SessionStart` hook injects it automatically;
  other agents are instructed to read it first.)
- Every change is logged in the same turn it's made, with file:line,
  before→after, why, and how it was verified.
- Before any session ends, the `## Current state` block is rewritten so a
  fresh session with zero memory can continue from it alone.

**2. Plan-first gating.**
Non-trivial tasks (>~20 lines, >3 files, or any schema/pipeline change) go
through plan mode first: a ≤10-line plan naming the exact deliverable paths,
approach, and risks - approved before a single edit.

**3. Context-isolated subagents (real token savings).**
Three read-mostly specialists absorb exploration noise so it never enters
your main context:

| Agent | Job | Returns |
|---|---|---|
| `auditor` | Deep-reads many files for bugs, silent data loss, dead code | ≤40 dense lines, severity-ordered, file:line cited |
| `code-reviewer` | Reviews the final diff: correctness, security, plan compliance | ≤30 lines, verdict + fixes |
| `test-writer` | Writes and runs tests; parallel-safe on disjoint file sets | ≤20 lines, pass/fail + exposed bugs |

Density rule everywhere: caps limit length, never precision. If a cap forces
omission, output ends with `OMITTED: <count> <type> - details in <file>`.

**4. Deterministic quality hooks.**
- On every file edit: auto-lint/format (ruff for Python, prettier for JS/TS -
  skipped gracefully if not installed).
- On session stop: run the project's test suite if one exists.

**5. Blocker protocol.**
An approach that fails twice halts with
`BLOCKER: <why> - proposed alternative: <one line>` - and the dead end is
recorded so it's never retried. No grinding dead paths.


**6. Code minimalism (tier-calibrated).**
A second skill enforces "every line is a liability" - but calibrated to
context, not absolute: a throwaway script gets zero ceremony, a production
service gets validation/error-handling/logging as a non-negotiable baseline,
and everything above that baseline needs explicit spec justification.
Includes inline-until-3-uses, stdlib-first dependency rules, comment-why-
not-what, and a mandatory delete pass before delivery. Long examples live in
a reference file loaded only when relevant, so the skill stays cheap.

## Using with any AI agent

No Claude Code required. `AGENTS.md` in this repo is a tool-agnostic port
of the full ruleset - session-continuity changelog, plan-first gate,
verification and evidence rules, blocker protocol, and tier-calibrated code
minimalism - written for any agent that can read a file and follow
instructions (Codex, Gemini CLI, Cursor, Aider, Windsurf, or anything
comparable).

Setup is one file. From your project root:
```
curl -O https://raw.githubusercontent.com/Dhananjay625/dev-workflow/main/AGENTS.md
```
`AGENTS.md` is an open standard read natively by 20+ tools. Per-tool notes:

### OpenAI Codex (CLI and IDE extension)
Nothing else to do. Codex reads `AGENTS.md` from the repo root
automatically at session start - it is the tool that originated the
standard. Notes:
- Nested files win: in a monorepo, an `AGENTS.md` closer to the edited
  files takes precedence, so you can drop this file in a subproject too.
- For personal defaults across all repos, place a copy at
  `~/.codex/AGENTS.md` (project files still override it).
- Verify pickup: start a session and ask "what workflow rules apply?" -
  Codex should describe the changelog and plan-first rules.

### Cursor
Reads `AGENTS.md` from the repo root natively - no extra setup. If your
team already uses `.cursor/rules/`, keep those for Cursor-specific style
rules; this file coexists with them.

### Gemini CLI
Reads `GEMINI.md` by default. Two options:
- Point it at this file - in `.gemini/settings.json`:
  `{ "contextFileName": "AGENTS.md" }`
- Or just copy: `cp AGENTS.md GEMINI.md`

### GitHub Copilot
The coding agent reads `AGENTS.md` natively. For chat/inline Copilot,
also copy it to `.github/copilot-instructions.md`:
`mkdir -p .github && cp AGENTS.md .github/copilot-instructions.md`

### Windsurf
Reads `AGENTS.md` natively in current versions. On older versions:
`cp AGENTS.md .windsurfrules`

### Aider
Listed as an `AGENTS.md` supporter; on versions without auto-discovery,
load it explicitly: `aider --read AGENTS.md`
(or set `read: AGENTS.md` in `.aider.conf.yml` so it applies every run).

### Claude Code (without this plugin)
The plugin is the better path (hooks + subagents), but the file alone
works too: create a `CLAUDE.md` containing the single line `@AGENTS.md`,
or run `/init` in a repo that already has `AGENTS.md`.

### Anything else
If a tool has its own instruction file, copy `AGENTS.md` to that filename.
If it has none, paste "Read and follow AGENTS.md in the repo root" as your
first message.

Multiple different agents can then work the same repo sharing one
`CHANGELOG.md` as common memory - what one agent records, the next one (of
any kind) resumes from.

What you keep: the entire workflow discipline. What is Claude
Code-exclusive: deterministic hook enforcement, real context-isolated
subagents, and automatic changelog injection at session start - other
agents follow the rules by instruction rather than by mechanism, which is
somewhat looser over very long sessions. Honest tradeoff, stated plainly.

## Install (Claude Code)

Two steps - add this repo as a marketplace, then install the plugin from it:

```
/plugin marketplace add Dhananjay625/dev-workflow
/plugin install dev-workflow@dev-workflow-marketplace
```

Then run `/reload-plugins` (or restart Claude Code).

Verify it loaded:
- `/plugin list` shows `dev-workflow`
- `/agents` shows `auditor`, `code-reviewer`, `test-writer`
- Typing `/dev-workflow:` autocompletes `init`, `status`, `wrap`

Local install (for development or offline use):
```
git clone https://github.com/Dhananjay625/dev-workflow
/plugin install ./dev-workflow
```

Troubleshooting: a "Marketplace not found" error usually means the two-step
flow above wasn't used, or Claude Code is outdated - run `claude update`
and retry.

## Install (Codex)

This repo doubles as a repo-scoped Codex marketplace
(`.agents/plugins/marketplace.json`), so installation is:

```
git clone https://github.com/Dhananjay625/dev-workflow
cd dev-workflow
codex          # open Codex in the repo
/plugins       # the "Dev Workflow" marketplace appears - select Install
```

Then start a NEW Codex thread (plugins load at session start; there is no
hot-reload). To make the plugin available in your own projects rather than
this repo, copy the marketplace entry into your personal marketplace at
`~/.agents/plugins/marketplace.json` (point `source.path` at your clone),
or vendor `plugins/dev-workflow-codex/` into your project repo.

Invoke explicitly with `$workflow` / `$code-minimalism` (or `@dev-workflow`
to browse), or just describe a dev task - Codex matches it against the
skill descriptions automatically.

What the Codex port contains vs the Claude Code plugin:
- Identical: both skills (workflow, code-minimalism), the three specialist
  role contracts (as `roles.md`, applied inline or via Codex multi-agent
  delegation), the changelog template, and every rule from v1.2.0's
  field-tested fixes.
- Different: no lifecycle hooks - the Codex skill makes lint, tests, and
  the read-changelog-first step explicit instructions instead, and pairing
  it with `AGENTS.md` in your project root (which Codex reads natively at
  every session start) restores the always-on layer.

## Commands

| Command | What it does |
|---|---|
| `/dev-workflow:init` | Create the project changelog and fill in its real current state |
| `/dev-workflow:status` | Show where the project stands (Current state + last 3 entries) |
| `/dev-workflow:wrap` | End-of-session: verify entries, rewrite Current state, 5-line report |

The workflow skill and hooks trigger automatically - commands are optional
manual entry points. (Claude Code only; other agents achieve the same via
the instructions in `AGENTS.md`.)

## Field-tested notes (v1.5.0)

Second real-session feedback round, fixed:
- SessionStart hook no longer issues a false "no changelog" imperative
  when the changelog lives in a subdirectory (monorepo case): it now
  searches 3 levels down before declaring absence, reports what it found,
  and explicitly warns against creating a second changelog that would
  split the project's memory.
- Gate calibration: when an environment's own instructions forbid pausing
  (autonomous/goal modes), the plan is recorded as the first changelog
  entry and work proceeds, pausing only for real-cost decisions. Resolves
  the contradiction between "wait for approval" and no-pause harnesses.
- Measurement mode: for run-and-report-numbers tasks, the reviewer pass is
  replaced by snapshot-before-overwrite, baseline-first, and
  reproduce-before-quoting. Plan mode is not required for non-code tasks;
  the five plan items are presented inline.
- File-creation test: creating a new file is justified when reuse would
  require a flag that changes an existing file's contract - with the
  rejected file recorded in the changelog entry.
- Hook heartbeats: every hook now emits a [dev-workflow] line even when it
  skips, so "did the hooks fire?" is decidable instead of ambiguous
  silence.

## Field-tested notes (v1.2.0)

Changes driven by real-session feedback:
- Subagent dispatch is now explicitly synchronous: wait for results before
  the phase that consumes them; a spawn acknowledgement with no findings =
  failed after one retry, do the job inline. Reviews must land BEFORE the
  closing report or they gate nothing.
- Hook verification fallback: if there is no evidence hooks fired in a
  session (no lint output on edit, no test run at stop), the skill now
  requires running those checks manually instead of assuming.
- Reviewer hardening: explicit diff scoping (plain `git diff` shows ALL
  uncommitted work, not just this session's change) and mandatory
  whole-file grep before reporting any negative claim ("zero mentions of
  X"), with the search command cited.
- Changelog bootstrap now handles existing changelogs that lack a
  `## Current state` block: the block is PREPENDED, history untouched.
- Cost honesty: subagents cost real money and time. The default remains
  work-in-main-thread; delegate only when isolation value clearly exceeds
  the cost.

## Requirements (Claude Code hooks)

None hard. Optional, auto-detected:
- `jq` - enables per-file lint-on-edit (`brew install jq` / `apt install jq`)
- `ruff` (Python) or `prettier` (JS/TS) - enables auto-lint/format
- `pytest` or an npm `test` script - enables test-on-stop

Everything degrades gracefully if absent.

## Structure

```
dev-workflow/
├── .claude-plugin/
│   ├── plugin.json          # manifest (required)
│   └── marketplace.json     # lets this repo act as a marketplace
├── skills/
│   ├── workflow/SKILL.md            # workflow procedure (loads on demand)
│   └── code-minimalism/
│       ├── SKILL.md                 # minimalism rules (loads on demand)
│       └── reference.md             # examples (loaded only when relevant)
├── agents/                  # auditor, code-reviewer, test-writer
├── hooks/hooks.json         # SessionStart resume + lint-on-edit + test-on-stop
├── commands/                # /init, /status, /wrap
├── templates/CHANGELOG.template.md
├── .agents/plugins/marketplace.json # repo-scoped CODEX marketplace
├── plugins/dev-workflow-codex/      # native Codex plugin port
│   ├── .codex-plugin/plugin.json
│   └── skills/                      # workflow (+ roles.md, template), code-minimalism
├── AGENTS.md                        # tool-agnostic port for other AI agents
├── README.md
└── LICENSE
```

## Token design (Claude Code)

| Component | When it loads | Cost |
|---|---|---|
| Skill + agent descriptions | Always | A few dozen tokens |
| Skill body | Only when a dev task triggers it | On demand |
| Agent bodies | Only on dispatch | On demand |
| Hooks | Never in context - shell commands | Zero; SessionStart injects only the changelog tail |

## License

MIT
