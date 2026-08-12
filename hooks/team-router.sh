#!/bin/sh
# UserPromptSubmit hook: detect a heavy task and inject the matching role menu.
# stdout is added to the model's context, so every line here costs tokens on
# every heavy prompt - keep it short and imperative.
# Always exits 0: this hook must never block a prompt.

p=$(jq -r '.prompt // empty' 2>/dev/null)
[ -z "$p" ] && { echo '[dev-workflow] team-router: no prompt (jq missing?)'; exit 0; }

# Domain vocabularies are defined BEFORE the gate and folded into it: a prompt
# built entirely from domain terms ("the model is overfitting") must survive the
# gate to reach its own branch. \b (not [^a-z]) so a term can end the prompt.
ML='train(ing)?|fine.?tun|classifier|neural|embedding|hyperparam|checkpoint|overfit|machine learning|\bml\b|dataset|accuracy|f1 score|recall'
PIPE='pipeline|etl|ingest|batch job|warehouse|airflow|dbt|data quality|extract'
WEB='website|web app|frontend|front.end|backend|back.end|endpoint|react|vue|svelte|next\.?js|component|css|html|browser|\bapi\b|\bui\b|checkout|shopping cart|log.?in|sign.?up|sign.?in|payment|profile page|dashboard|form submi'

# Verbs that turn an interrogative into a work request. Claude Code users
# phrase most tasks politely ("could you train a classifier?"), so the
# question guard below must not fire on them.
TASKVERB='build|implement|add|fix|write|create|train|refactor|update|make|set ?up|wire|migrat|debug|remove|delete|rename|port|optimi[sz]e|clean ?up|split|extract|handle'

HEAVY_GENERIC='refactor|migrat|audit|overhaul|re-?write|re-?design|re-?architect|whole (repo|codebase|project)|entire (repo|codebase|project)|across the (repo|codebase|project)|all the files|every file|end.to.end|schema|multi.file|root cause|trace through|security review|performance|optimi[sz]e|implement|build (a|an|the) |add support for|integrat'
HEAVY="$HEAVY_GENERIC|$ML|$PIPE|$WEB"

if ! printf '%s' "$p" | grep -qiE "$HEAVY" && [ "${#p}" -le 400 ]; then
  echo '[dev-workflow] team-router: light task - no team dispatched'
  exit 0
fi

# A question that names a domain noun is not a task: "is the dashboard up" and
# "what is my login email" are asks, not work. Folding domain vocab into the
# gate above made these reachable, so an interrogative opener with no action
# verb anywhere exits light. TASKVERB is checked alongside HEAVY_GENERIC
# because a polite request ("could you train a classifier?") is an
# interrogative that carries no HEAVY_GENERIC term but is still real work.
if printf '%s' "$p" | grep -qiE '^ *(what|who|when|where|why|which|is|are|was|were|does|do|did|can|could|should|would|how)\b' \
   && ! printf '%s' "$p" | grep -qiE "$HEAVY_GENERIC|$TASKVERB"; then
  echo '[dev-workflow] team-router: light task - no team dispatched'
  exit 0
fi

# Score every domain rather than first-match: in an if/elif chain a single
# stray ML term ("checkpoint", "dataset") outranked a prompt that was mostly
# pipeline or web work, silently dropping the role that owned it.
n_ml=$(printf '%s' "$p" | grep -oiE "$ML" | wc -l | tr -d ' ')
n_pipe=$(printf '%s' "$p" | grep -oiE "$PIPE" | wc -l | tr -d ' ')
n_web=$(printf '%s' "$p" | grep -oiE "$WEB" | wc -l | tr -d ' ')

best=general; top=0
[ "$n_ml"   -gt "$top" ] && { top=$n_ml;   best=ml; }
[ "$n_pipe" -gt "$top" ] && { top=$n_pipe; best=pipe; }
[ "$n_web"  -gt "$top" ] && { top=$n_web;  best=web; }

# A close second domain is reported, never dropped: over-offering one line is
# cheaper than losing the role that owns half the work.
also=''
[ "$best" != ml   ] && [ "$n_ml"   -gt 0 ] && also="$also ML(researcher/data-engineer/ml-engineer)"
[ "$best" != pipe ] && [ "$n_pipe" -gt 0 ] && also="$also DATA-PIPELINE(pipeline-engineer)"
[ "$best" != web  ] && [ "$n_web"  -gt 0 ] && also="$also WEB(backend-engineer/frontend-engineer)"

if [ "$best" = ml ]; then
  echo '[dev-workflow] HEAVY TASK - domain: ML / MODEL. Candidate roles:'
  echo '  researcher          READ-ONLY  prior art + baseline to beat      -> run FIRST'
  echo '  data-engineer       OWNS data/, loaders, splits                  -> before ml-engineer'
  echo '  ml-engineer         OWNS train/, model/, inference               -> after data-engineer'
  echo '  validation-engineer OWNS eval/, tests/  independent metric check -> after ml-engineer'
  echo '  TOPOLOGY: sequential chain - each needs the previous one output.'
elif [ "$best" = pipe ]; then
  echo '[dev-workflow] HEAVY TASK - domain: DATA PIPELINE. Candidate roles:'
  echo '  data-engineer       OWNS transform/clean logic                   -> parallel-safe'
  echo '  pipeline-engineer   OWNS orchestration, retries, scheduling      -> parallel-safe'
  echo '  auditor             READ-ONLY  row-loss + silent-truncation scan -> after both'
  echo '  TOPOLOGY: the two engineers parallelise ONLY on disjoint paths.'
elif [ "$best" = web ]; then
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

[ -n "$also" ] && echo "  ALSO MATCHED:$also - pull in if it owns real work here."
echo '  code-reviewer       READ-ONLY  reviews this session diff -> LAST, before delivery'
echo 'SIZE THE TEAM YOURSELF: dispatch the smallest subset covering the distinct'
echo 'concerns THIS task actually has - a one-file change may warrant one role or'
echo 'none. Never dispatch a role whose deliverable would be empty. State the'
echo 'roster and why that count in one line of the plan.'
echo 'Assign each role explicit DISJOINT owned paths. Overlapping paths = run'
echo 'sequentially, never parallel. Dispatch synchronously and WAIT for results.'
exit 0
