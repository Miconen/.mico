#!/usr/bin/env bash
#
# Lint the Nix in this repo. Run locally with ./ci/lint.sh, or via CI.
#
# Runs every check even if an earlier one fails, then exits non-zero if any of
# them did. A plain sequence of steps would stop at the first failure and hide
# the rest, which is how the original CI managed to skip deadnix entirely.
#
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

# Use the devShell's tools unless they are already on PATH (they are inside
# `nix develop` or with direnv active).
wrap() {
  if command -v "$1" >/dev/null; then
    "$@"
  else
    nix develop --command "$@"
  fi
}

fail=0
run_check() {
  local name="$1"; shift
  printf '\n== %s ==\n' "$name"
  if "$@"; then
    printf '   ok\n'
  else
    printf '   FAILED\n'
    fail=1
  fi
}

# shellcheck disable=SC2046
run_check nixfmt wrap nixfmt --check $(git ls-files '*.nix')
run_check statix wrap statix check
run_check deadnix wrap deadnix --fail

if (( fail )); then
  printf '\nlint failed\n'
  exit 1
fi
printf '\nlint clean\n'
