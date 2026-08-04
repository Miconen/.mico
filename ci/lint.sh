#!/usr/bin/env bash
#
# Lint everything in this repo. Run locally with ./ci/lint.sh, or via CI.
#
# Every check runs even if an earlier one fails, then the script exits non-zero
# if any of them did. A plain sequence of CI steps stops at the first failure and
# hides the rest, which is how the original workflow managed to skip deadnix.
#
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

# Use the devShell's tools if they are already on PATH (inside `nix develop`, or
# with direnv active in this repo), otherwise enter the shell per invocation.
wrap() {
  if command -v "$1" >/dev/null; then
    "$@"
  else
    nix develop --command "$@"
  fi
}

fail=0
run_check() {
  local name="$1"
  shift
  printf '\n== %s ==\n' "$name"
  if "$@"; then
    printf '   ok\n'
  else
    printf '   FAILED\n'
    fail=1
  fi
}

# `*.sh` already matches bootstrap.sh at the root - git pathspecs are not
# anchored - so listing it separately would lint it twice.
mapfile -t nix_files < <(git ls-files '*.nix')
mapfile -t sh_files < <(git ls-files '*.sh')
mapfile -t workflow_files < <(git ls-files '.github/workflows/*.yml' '.github/workflows/*.yaml')

run_check nixfmt wrap nixfmt --check "${nix_files[@]}"
run_check statix wrap statix check
run_check deadnix wrap deadnix --fail

run_check shellcheck wrap shellcheck --external-sources "${sh_files[@]}"

# -i 2 because these scripts are 2-space indented; shfmt defaults to tabs and
# would otherwise want to reformat every line. --binary-next-line matches the
# existing style of putting `||` on the continuation line.
run_check shfmt wrap shfmt --diff --simplify --indent 2 --binary-next-line "${sh_files[@]}"

run_check zellij ./ci/zellij-check.sh

if ((${#workflow_files[@]})); then
  run_check actionlint wrap actionlint "${workflow_files[@]}"
else
  printf '\n== actionlint ==\n   skipped, no workflow files\n'
fi

if ((fail)); then
  printf '\nlint failed\n'
  exit 1
fi
printf '\nlint clean\n'
