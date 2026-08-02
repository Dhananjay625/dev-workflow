#!/bin/sh
# UserPromptSubmit hook: detect a heavy task and inject the matching role menu.
# stdout is added to the model's context, so every line here costs tokens on
# every heavy prompt - keep it short and imperative.
# Always exits 0: this hook must never block a prompt.

p=$(jq -r '.prompt // empty' 2>/dev/null)
[ -z "$p" ] && { echo '[dev-workflow] team-router: no prompt (jq missing?)'; exit 0; }

HEAVY='refactor|migrat|audit|overhaul|re-?write|re-?design|re-?architect|whole (repo|codebase|project)|entire (repo|codebase|project)|across the (repo|codebase|project)|all the files|every file|end.to.end|schema|pipeline|multi.file|root cause|trace through|security review|performance|optimi[sz]e|implement|build (a|an|the) |add support for|integrat|train(ing)?|fine.?tun|classifier|neural|dataset|embedding'

if ! printf '%s' "$p" | grep -qiE "$HEAVY" && [ "${#p}" -le 400 ]; then
  echo '[dev-workflow] team-router: light task - no team dispatched'
  exit 0
fi

ML='train(ing)?|fine.?tun|classifier|neural|embedding|hyperparam|checkpoint|overfit|machine learning|[^a-z]ml[^a-z]|dataset|accuracy|f1 score|recall'
PIPE='pipeline|etl|ingest|batch job|warehouse|airflow|dbt|data quality|extract'
WEB='website|web app|frontend|front.end|backend|back.end|endpoint|react|vue|svelte|next\.?js|component|css|html|browser|[^a-z]api[^a-z]|[^a-z]ui[^a-z]'

if printf '%s' "$p" | grep -qiE "$ML"; then
  echo '[dev-workflow] HEAVY TASK - domain: ML / MODEL. Candidate roles:'
  echo '  researcher          READ-ONLY  prior art + baseline to beat      -> run FIRST'
  echo '  data-engineer       OWNS data/, loaders, splits                  -> before ml-engineer'
  echo '  ml-engineer         OWNS train/, model/, inference               -> after data-engineer'
  echo '  validation-engineer OWNS eval/, tests/  independent metric check -> after ml-engineer'
  echo '  TOPOLOGY: sequential chain - each needs the previous one output.'
elif printf '%s' "$p" | grep -qiE "$PIPE"; then
  echo '[dev-workflow] HEAVY TASK - domain: DATA PIPELINE. Candidate roles:'
  echo '  data-engineer       OWNS transform/clean logic                   -> parallel-safe'
  echo '  pipeline-engineer   OWNS orchestration, retries, scheduling      -> parallel-safe'
  echo '  auditor             READ-ONLY  row-loss + silent-truncation scan -> after both'
  echo '  TOPOLOGY: the two engineers parallelise ONLY on disjoint paths.'
elif printf '%s' "$p" | grep -qiE "$WEB"; then
  echo '[dev-workflow] HEAVY TASK - domain: WEB APP. Candidate roles:'
  echo '  backend-engineer    OWNS api/, db/  publishes the API contract   -> parallel'
  echo '  frontend-engineer   OWNS ui/, components/, styles/               -> parallel'
  echo '  test-writer         OWNS tests/                                  -> after both'
  echo '  TOPOLOGY: front/back in PARALLEL (disjoint dirs); backend publishes'
  echo '  the contract first if frontend needs a shape that does not exist yet.'
else
  echo '[dev-workflow] HEAVY TASK - domain: GENERAL. Candidate roles:'
  echo '  auditor             READ-ONLY  map the affected area   -> before planning'
  echo '  test-writer         OWNS assigned test paths           -> during execute'
fi

echo '  code-reviewer       READ-ONLY  reviews this session diff -> LAST, before delivery'
echo 'SIZE THE TEAM YOURSELF: dispatch the smallest subset covering the distinct'
echo 'concerns THIS task actually has - a one-file change may warrant one role or'
echo 'none. Never dispatch a role whose deliverable would be empty. State the'
echo 'roster and why that count in one line of the plan.'
echo 'Assign each role explicit DISJOINT owned paths. Overlapping paths = run'
echo 'sequentially, never parallel. Dispatch synchronously and WAIT for results.'
exit 0
