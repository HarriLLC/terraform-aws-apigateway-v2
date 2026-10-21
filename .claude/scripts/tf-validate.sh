#!/bin/sh
# Validate the module, once per turn.
#
# The repo root is validated when it holds .tf files; validating it also checks
# every submodule it calls. A mono-repo with no .tf at the root (each module lives
# under modules/<name>/ and is published on its own) is validated one submodule
# at a time instead.
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

has_tf() { ls "$1"/*.tf >/dev/null 2>&1; }

check() {
  init() { (cd "$1" && terraform init -upgrade -no-color -input=false >/dev/null 2>&1); }
  [ -d "$1/.terraform" ] || init "$1"
  out=$(cd "$1" && terraform validate -no-color 2>&1) && return 0
  init "$1" && out=$(cd "$1" && terraform validate -no-color 2>&1) && return 0
  # init never completed: a setup problem, not a problem with the change
  printf '%s\n' "$out" | grep -qiE 'run "terraform init"|Module not installed|Missing required provider|Required plugins are not installed' && return 0
  printf -- '--- %s\n%s\n' "$1" "$out" >&2
  return 2
}

if has_tf .; then
  dirs=.
else
  dirs=$(for d in modules/*/; do has_tf "${d%/}" && echo "${d%/}"; done)
fi

rc=0
for d in $dirs; do check "$d" || rc=2; done
exit "$rc"
