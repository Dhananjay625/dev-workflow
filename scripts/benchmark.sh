#!/bin/sh
# Measures what can be measured honestly about this plugin:
#   1. prompt-router classification accuracy against a labeled corpus
#   2. context cost (characters the hooks inject into the model's context)
#   3. hook latency
#
# It does NOT measure whether the plugin makes an agent "better" at coding.
# That needs a controlled eval with blind grading and many samples per arm;
# no number in this file should ever be presented as that claim.
#
# Reproducible: anyone can clone and run `sh scripts/benchmark.sh`.

CASES=tests/router-cases.tsv
ROUTER=hooks/team-router.sh

route() {
  printf '{"prompt":%s}' "$(printf '%s' "$1" | jq -Rs .)" | sh "$ROUTER"
}

# Map router stdout to a single label.
classify() {
  out=$(route "$1")
  case "$out" in
    *"light task"*)          echo light ;;
    *"domain: ML"*)          echo ml ;;
    *"domain: DATA PIPELINE"*) echo pipe ;;
    *"domain: WEB APP"*)     echo web ;;
    *"domain: GENERAL"*)     echo general ;;
    *)                       echo UNPARSEABLE ;;
  esac
}

echo "=============================================="
echo " 1. ROUTER ACCURACY"
echo "=============================================="
total=0; correct=0
misses=$(mktemp)
# Redirected, not piped: a piped `while` runs in a subshell and the counters
# would be discarded (this exact bug shipped in validate.sh once).
grep -v '^#' "$CASES" | grep -v '^[[:space:]]*$' > /tmp/bm_cases.$$
while IFS="$(printf '\t')" read -r expected prompt; do
  [ -z "$prompt" ] && continue
  got=$(classify "$prompt")
  total=$((total + 1))
  hit=0
  # expected may be "web|ml" - any listed label counts as correct
  OLDIFS=$IFS; IFS='|'
  for e in $expected; do [ "$e" = "$got" ] && hit=1; done
  IFS=$OLDIFS
  if [ "$hit" -eq 1 ]; then
    correct=$((correct + 1))
  else
    printf '  expected %-12s got %-10s %s\n' "$expected" "$got" "$prompt" >> "$misses"
  fi
done < /tmp/bm_cases.$$
rm -f /tmp/bm_cases.$$

pct=$(awk -v c="$correct" -v t="$total" 'BEGIN{printf "%.1f", (c/t)*100}')
echo "  $correct / $total correct  =  ${pct}%"
echo
if [ -s "$misses" ]; then
  echo "  MISCLASSIFIED (every one, so the number is auditable):"
  cat "$misses"
else
  echo "  no misclassifications"
fi
rm -f "$misses"

echo
echo "=============================================="
echo " 2. CONTEXT COST (characters injected)"
echo "=============================================="
echo "  Characters are exact. Tokens are an ESTIMATE at ~4 chars/token"
echo "  (English prose+code heuristic); no tokenizer is used."
echo

light_c=$(route "what does this function do" | wc -c | tr -d ' ')
heavy_c=$(route "build the ETL pipeline for the warehouse" | wc -c | tr -d ' ')
sess=$(jq -r '.hooks.SessionStart[0].hooks[0].command' hooks/hooks.json > /tmp/bm_ss.$$; sh /tmp/bm_ss.$$ 2>/dev/null | wc -c | tr -d ' '; rm -f /tmp/bm_ss.$$)

for pair in "router, light prompt:$light_c" "router, heavy prompt:$heavy_c" "SessionStart (this repo):$sess"; do
  label=${pair%%:*}; chars=${pair##*:}
  tok=$(awk -v c="$chars" 'BEGIN{printf "%.0f", c/4}')
  printf '  %-28s %6s chars  ~%5s tokens\n' "$label" "$chars" "$tok"
done
echo
echo "  Note: SessionStart cost scales with the project's own CHANGELOG.md"
echo "  (it injects the Current state block + last 3 entries), so this number"
echo "  is specific to THIS repo and is near the high end - the changelog here"
echo "  is unusually long."

echo
echo "=============================================="
echo " 3. HOOK LATENCY"
echo "=============================================="
N=50
for label in light heavy; do
  [ "$label" = light ] && p="what does this function do" || p="build the ETL pipeline for the warehouse"
  start=$(perl -MTime::HiRes=time -e 'printf "%.6f", time')
  i=0; while [ "$i" -lt "$N" ]; do route "$p" >/dev/null; i=$((i+1)); done
  end=$(perl -MTime::HiRes=time -e 'printf "%.6f", time')
  awk -v s="$start" -v e="$end" -v n="$N" -v l="$label" \
    'BEGIN{printf "  %-6s prompt: %.1f ms/call  (mean of %d runs)\n", l, ((e-s)/n)*1000, n}'
done
echo
echo "  Measured on this machine, cold cache, including the jq subprocess."
echo "  This is wall-clock added per prompt before the model is called."
