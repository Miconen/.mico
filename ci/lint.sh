#!/usr/bin/env bash
# Lint everything. Every check runs even if an earlier one fails.
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

# Use tools already on PATH, otherwise run them via the devShell.
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

# selene exits 0 even with warnings, so check its summary lines.
selene_clean() {
  local out
  out="$(wrap selene .config/nvim 2>&1)" || true
  printf '%s\n' "$out"
  printf '%s\n' "$out" | grep -qx '0 errors' && printf '%s\n' "$out" | grep -qx '0 warnings'
}

mapfile -t nix_files < <(git ls-files '*.nix')
mapfile -t sh_files < <(git ls-files '*.sh')
mapfile -t workflow_files < <(git ls-files '.github/workflows/*.yml' '.github/workflows/*.yaml')
mapfile -t lua_files < <(git ls-files '*.lua')

run_check nixfmt wrap nixfmt --check "${nix_files[@]}"
run_check statix wrap statix check
run_check deadnix wrap deadnix --fail

run_check shellcheck wrap shellcheck --external-sources "${sh_files[@]}"

run_check shfmt wrap shfmt --diff --simplify --indent 2 --binary-next-line "${sh_files[@]}"

if ((${#lua_files[@]})); then
  run_check stylua wrap stylua --check .config/nvim
  run_check selene selene_clean
fi

# Not via wrap(): `command -v` succeeds for a script path, skipping the devShell.
if command -v zellij >/dev/null; then
  run_check zellij ./ci/zellij-check.sh
else
  run_check zellij nix develop --command ./ci/zellij-check.sh
fi

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
