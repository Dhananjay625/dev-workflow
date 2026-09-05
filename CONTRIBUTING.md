# Contributing

Thanks for looking at this. It's a small, opinionated plugin — contributions
are welcome, especially ones that come from having actually used it on real
work.

## What this repo is

There is no build step, no package manager, and no runtime dependency. The
plugin is Markdown (skills, agents, commands), JSON manifests, and two shell
scripts. That shapes everything below: "the tests" are structural checks, and
the interesting bugs are in the hooks.

It ships to **two targets** that must stay in sync:

| | Claude Code | Codex |
|---|---|---|
| manifest | `.claude-plugin/plugin.json` | `plugins/dev-workflow-codex/.codex-plugin/plugin.json` |
| skills | `skills/` | `plugins/dev-workflow-codex/skills/` |
| role contracts | `agents/*.md` (one file per agent) | `skills/workflow/roles.md` (one heading per role) |
| hooks | `hooks/hooks.json` | none — Codex has no hook layer |

If you add or rename a role, you must touch both sides. `scripts/validate.sh`
enforces this.

## Before you open a PR

```sh
sh scripts/validate.sh          # required — CI runs exactly this
shellcheck -s sh hooks/*.sh scripts/*.sh   # required — CI runs this too
```

`validate.sh` needs `jq` and nothing else. It checks that every manifest
parses, that every hook command embedded in `hooks.json` is non-empty and
syntactically valid shell, that agent names are unique and match their
filenames, that every role the router offers exists as an agent, that both
ports agree on the version, and that the changelog still exposes exactly one
`## Current state` block.

## Changing a hook

Hooks are the sharp edge. They run shell on every user's machine, on every
prompt, edit, or turn-end. Two rules:

1. **A hook must never block the user.** Every hook command ends in `exit 0`
   and degrades to a printed message when a tool it wants is missing. A hook
   that exits non-zero, or hangs, breaks the session.
2. **A hook that mutates or costs time needs an opt-out.** `PostToolUse`
   rewrites the user's file, so it honours `DEV_WORKFLOW_NO_LINT`. `Stop`
   runs the test suite, so it honours `DEV_WORKFLOW_NO_STOP_TESTS` and carries
   a `timeout`. Anything new in that category needs the same.

To test a hook command in isolation, extract it from the JSON first — do not
eyeball it through the escaping:

```sh
jq -r '.hooks.Stop[0].hooks[0].command' hooks/hooks.json > /tmp/h.sh
wc -c /tmp/h.sh     # non-zero! an empty file passes `sh -n` silently
sh -n /tmp/h.sh
printf '{"tool_input":{"file_path":"/tmp/x.py"}}' | sh /tmp/h.sh   # PostToolUse
```

## Changing the router

`hooks/team-router.sh` classifies each prompt as light or heavy and picks a
domain. It is regex-based and deliberately so. It has a history of subtle
regressions — read the `DO NOT` list at the top of `CHANGELOG.md` before
editing it; each line there is a bug that already happened once.

Test with real prompts, including polite and interrogative phrasings:

```sh
run() { printf '{"prompt":%s}' "$(printf '%s' "$1" | jq -Rs .)" | sh hooks/team-router.sh; }
run "train a classifier on the dataset"        # expect ML
run "Could you train a classifier on it?"      # expect ML  (polite ≠ light)
run "is the dashboard up"                      # expect light (question, no task verb)
```

A router change is not done until you've checked that it did not silently
reclassify an existing case as light. Dropping work is worse than
over-offering a role.

## The changelog is the memory

`CHANGELOG.md` is not a release note file — the `SessionStart` hook reads it
back into the agent's context at the start of every session. That's why
entries record `file:line — before → after — why — verified how`, and why the
`## Current state` block is rewritten rather than appended to.

If your change alters behaviour, add an entry. Keep the `DO NOT` list
accurate: it exists so the same bug isn't reintroduced by the next person (or
the next model).

## Commit messages

Short. `<type>: <what changed>`, ~70 chars, subject line only unless the *why*
is genuinely non-obvious. Types: `feat, fix, refactor, docs, test, chore, perf, ci`.

## Scope

Good contributions: router false positives you hit in practice, a hook that
misbehaves on your platform, a role contract that's too vague to act on,
documentation that misled you.

Please open an issue before large additions. This plugin's whole thesis is
that less is better — a new agent, hook, or skill needs to justify its cost in
tokens and complexity, not just be useful in principle.
