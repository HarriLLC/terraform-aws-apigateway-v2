#!/bin/sh
# Validate the module, once per turn.
#
# A module has no backend, so `terraform init` only installs providers and
# modules and never touches HCP. It runs only when `.terraform/` is missing, or
# when validate fails (a new provider or module may need installing), and then
# validate is retried once.
#
# Validate always runs, even if init failed: a syntax error makes init fail too,
# and skipping on that would hide the error. Only a result that just says init is
# missing (offline, no registry access) is treated as a setup problem and skipped.
#
# A module holds no state, so `plan` and `apply` never run here. Errors go to
# stderr with exit 2, so Claude sees them and fixes the file.
grep -q '"stop_hook_active": *true' && exit 0      # already ran for this stop
command -v terraform >/dev/null 2>&1 || exit 0
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0

init() { terraform init -upgrade -no-color -input=false >/dev/null 2>&1; }

[ -d .terraform ] || init
out=$(terraform validate -no-color 2>&1) && exit 0
init && out=$(terraform validate -no-color 2>&1) && exit 0

# init never completed: a setup problem, not a problem with the change
printf '%s\n' "$out" | grep -qiE 'run "terraform init"|Module not installed|Missing required provider|Required plugins are not installed' && exit 0

printf '%s\n' "$out" >&2
exit 2
