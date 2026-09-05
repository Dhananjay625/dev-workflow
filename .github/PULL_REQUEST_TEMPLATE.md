## What changed and why

<!-- One or two sentences. The diff shows what; explain why. -->

## Verified how

<!-- Required. Not "looks right" — what did you run, and what did it print?
     For a router change, include the prompts you tested, especially any that
     should still classify as light. -->

```
$ sh scripts/validate.sh
```

## Checklist

- [ ] `sh scripts/validate.sh` passes
- [ ] `shellcheck -s sh hooks/*.sh scripts/*.sh` is clean
- [ ] If a role was added or renamed: both `agents/` and the Codex
      `skills/workflow/roles.md` are updated
- [ ] If behaviour changed: `CHANGELOG.md` has an entry
      (`file:line — before → after — why — verified how`)
- [ ] If a new hook mutates files or costs time: it has an opt-out env var
- [ ] Version bumped in **both** `plugin.json` files, or not at all
