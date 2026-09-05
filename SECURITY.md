# Security policy

## What this plugin does on your machine

This is not a library you call — it installs **shell hooks that run
automatically** in your agent session. Before installing, know that:

- `SessionStart` reads `CHANGELOG.md` from your working directory and injects
  part of it into the model's context.
- `UserPromptSubmit` runs `hooks/team-router.sh` on **every prompt you type**.
  Your prompt text is passed to it on stdin as JSON.
- `PostToolUse` runs `ruff check --fix` or `prettier --write` on files the
  agent edits — **it rewrites your files in place**. Disable with
  `DEV_WORKFLOW_NO_LINT=1`.
- `Stop` runs your project's test suite (`npm test` / `pytest`) at the end of
  every turn. Disable with `DEV_WORKFLOW_NO_STOP_TESTS=1`.

Nothing is sent over the network by this plugin, and it collects no telemetry.
All hook output goes into your own agent session.

The prompt text handled by the router never leaves your machine, but it is
processed by shell. If you work with sensitive prompt content and want to
audit that path, `hooks/team-router.sh` is ~90 lines and is the whole of it.

## Supported versions

The latest released version only. This is a single-maintainer project; there
are no backported fixes.

## Reporting a vulnerability

Please **do not** open a public issue for a security problem.

Use GitHub's private vulnerability reporting:
<https://github.com/Dhananjay625/dev-workflow/security/advisories/new>

Include the version (`jq -r .version .claude-plugin/plugin.json`), your OS and
shell, and the smallest reproduction you can manage. I'll acknowledge within a
week; this is a side project, not a staffed one, so please set expectations
accordingly.

## Things that are in scope

- Command injection through prompt text or filenames into any hook.
- A hook that can be made to exit non-zero and block a user's session.
- Anything that causes a hook to read or write outside the working directory.

## Things that are not

- The lint and test hooks running commands from your own project
  (`package.json` scripts, your `pytest` config). That is the intended
  behaviour; the plugin runs *your* tooling, and you should trust your own
  project before you run an agent in it.
- Prompt-injection of the *model* via repository content. That's a property of
  the agent you're running, not of this plugin.
