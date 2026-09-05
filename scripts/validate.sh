#!/bin/sh
# Repo invariants. Run locally before a PR; CI runs the same file.
# No build step and no dependencies beyond jq - this plugin is data + shell,
# so "the tests" are structural checks on manifests, hooks and agent names.
# Exits non-zero on the first category that fails, after reporting all of them.

fail=0
err() { echo "FAIL: $*"; fail=1; }
ok()  { echo "  ok: $*"; }

echo "== 1. every JSON manifest parses =="
# `--cached --others --exclude-standard` = tracked PLUS new-but-not-ignored.
# Plain `git ls-files` lists only TRACKED files, so a file you just created
# and have not staged is invisible - the check passes by finding nothing.
# `find` is wrong in the other direction: it would descend into gitignored
# runtime dirs like .claude-flow/ and fail on a contributor's local state.
for f in $(git ls-files --cached --others --exclude-standard '*.json'); do
  if jq -e . "$f" >/dev/null 2>&1; then ok "$f"; else err "$f is not valid JSON"; fi
done

echo "== 2. shell scripts are syntactically valid =="
for f in hooks/*.sh scripts/*.sh; do
  [ -f "$f" ] || continue
  if sh -n "$f" 2>/dev/null; then ok "$f"; else err "$f has a shell syntax error"; fi
done

echo "== 3. every hook command embedded in hooks.json is non-empty and valid =="
# An empty file passes `sh -n` silently, so the byte count is checked FIRST.
# Skipping that check once produced four false "syntax OK" lines in a row.
for k in $(jq -r '.hooks | keys[]' hooks/hooks.json); do
  n=$(jq -r --arg k "$k" '.hooks[$k][0].hooks | length' hooks/hooks.json)
  i=0
  while [ "$i" -lt "$n" ]; do
    tmp=$(mktemp)
    jq -r --arg k "$k" --argjson i "$i" '.hooks[$k][0].hooks[$i].command' hooks/hooks.json > "$tmp"
    bytes=$(wc -c < "$tmp" | tr -d ' ')
    if [ "$bytes" -lt 20 ]; then
      err "${k}[${i}] command is only ${bytes} bytes - extraction probably failed"
    elif sh -n "$tmp" 2>/dev/null; then
      ok "${k}[${i}] (${bytes} bytes)"
    else
      err "${k}[${i}] has a shell syntax error"
    fi
    rm -f "$tmp"
    i=$((i + 1))
  done
done

echo "== 4. agent names are unique and match their filenames =="
for f in agents/*.md; do
  name=$(awk -F': *' '/^name:/{print $2; exit}' "$f")
  base=$(basename "$f" .md)
  [ -n "$name" ] || { err "$f has no 'name:' frontmatter field"; continue; }
  [ "$name" = "$base" ] || err "$f declares name '$name' but the file is '$base.md'"
  awk '/^description:/{found=1} END{exit !found}' "$f" || err "$f has no 'description:' field"
done
dupes=$(awk -F': *' '/^name:/{print $2}' agents/*.md | sort | uniq -d)
if [ -z "$dupes" ]; then ok "no duplicate agent names"; else err "duplicate agent names: $dupes"; fi

echo "== 5. every role the router offers actually exists as an agent =="
# The router prints a menu of role names. A renamed agent file would leave the
# menu pointing at a role that cannot be dispatched, and nothing else catches it.
# Redirect from a temp file rather than piping into `while`: a pipeline runs
# its loop in a SUBSHELL, so `fail=1` set inside would be discarded and the
# script would print FAIL yet still exit 0. Verified by deleting an agent file.
rolelist=$(mktemp)
grep -oE '\b(researcher|auditor|[a-z]+-(engineer|writer|reviewer))\b' hooks/team-router.sh | sort -u > "$rolelist"
while read -r role; do
  if [ -f "agents/$role.md" ]; then ok "$role"; else err "router offers '$role' but agents/$role.md does not exist"; fi
done < "$rolelist"
rm -f "$rolelist"

echo "== 6. the Codex port documents every role the Claude port ships =="
# roles.md titles its contracts as headings ("## DATA ENGINEER"), so the
# hyphenated agent name is normalised to that form before searching.
roles=plugins/dev-workflow-codex/skills/workflow/roles.md
for f in agents/*.md; do
  name=$(basename "$f" .md)
  heading=$(printf '%s' "$name" | tr 'a-z-' 'A-Z ')
  if grep -qi "^## $heading" "$roles"; then ok "$name"
  else err "agent '$name' has no '## $heading' contract in $roles (port parity)"; fi
done

echo "== 7. plugin versions agree across both ports =="
a=$(jq -r .version .claude-plugin/plugin.json)
b=$(jq -r .version plugins/dev-workflow-codex/.codex-plugin/plugin.json)
if [ "$a" = "$b" ]; then ok "both ports at $a"; else err "version drift: Claude=$a Codex=$b"; fi

echo "== 8. the changelog still exposes exactly one resume block =="
# hooks.json's SessionStart greps for this heading. Zero or two breaks resume.
c=$(grep -c '^## Current state' CHANGELOG.md)
if [ "$c" -eq 1 ]; then ok "one '## Current state' block"; else err "expected 1 '## Current state', found $c"; fi

echo "== 9. GitHub YAML (workflows, issue templates) parses =="
# Optional: skipped where no YAML parser is present, so a contributor without
# ruby can still run the rest. CI always has it.
if command -v ruby >/dev/null 2>&1; then
  for f in $(git ls-files --cached --others --exclude-standard '.github/*.yml' '.github/**/*.yml'); do
    if ruby -ryaml -e 'YAML.load_file(ARGV[0])' "$f" 2>/dev/null; then ok "$f"
    else err "$f is not valid YAML"; fi
  done
else
  echo "  skipped: no ruby available to parse YAML"
fi

echo
if [ "$fail" -eq 0 ]; then echo "All checks passed."; else echo "Some checks FAILED."; fi
exit "$fail"
