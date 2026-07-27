# dev-workflow - Claude Code plugin

A production workflow for Claude Code that installs once and applies to every
project automatically. No per-project setup, no per-session instructions.

## What it does

**1. Cross-session memory (auto-changelog).**
Claude Code has no memory between sessions. This plugin gives it one:
- A `SessionStart` hook injects your project's `CHANGELOG.md` state (what
  works, what's broken, exact next step, known dead ends) into context the
  moment every session opens - resuming never depends on the model
  remembering to read a file.
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

## Install

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

## Commands

| Command | What it does |
|---|---|
| `/dev-workflow:init` | Create the project changelog and fill in its real current state |
| `/dev-workflow:status` | Show where the project stands (Current state + last 3 entries) |
| `/dev-workflow:wrap` | End-of-session: verify entries, rewrite Current state, 5-line report |

The workflow skill and hooks trigger automatically - commands are optional
manual entry points.

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

## Using with other AI agents (Codex, Gemini CLI, Cursor, Aider, ...)

The plugin machinery (hooks, subagents, auto-triggering skills) is Claude
Code-specific, but the discipline layer is not. `AGENTS.md` in this repo is
a tool-agnostic port of the full ruleset - session-continuity changelog,
plan-first gate, verification and evidence rules, blocker protocol, and
tier-calibrated code minimalism - written for any agent that can read a
file and follow instructions.

To use it: copy `AGENTS.md` into your project root. Most agents read it
automatically (it is a common convention); if yours doesn't, point it at
the file at session start. Multiple different agents can then work the same
repo sharing one `CHANGELOG.md` as common memory - what one agent records,
the next one (of any kind) resumes from.

What you keep: the entire workflow discipline. What stays Claude
Code-exclusive: deterministic hook enforcement, real context-isolated
subagents, and automatic changelog injection at session start - other
agents follow the rules by instruction rather than by mechanism.

## Requirements

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
├── AGENTS.md                        # tool-agnostic port for other AI agents
├── README.md
└── LICENSE
```

## Token design

| Component | When it loads | Cost |
|---|---|---|
| Skill + agent descriptions | Always | A few dozen tokens |
| Skill body | Only when a dev task triggers it | On demand |
| Agent bodies | Only on dispatch | On demand |
| Hooks | Never in context - shell commands | Zero; SessionStart injects only the changelog tail |

## License

MIT
