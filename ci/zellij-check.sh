#!/usr/bin/env bash
# Validate the zellij config and layout by starting a real session.
# `zellij setup --check` misses semantic problems. Use --config-dir: with
# --config or XDG_CONFIG_HOME, zellij silently falls back to its built-in layout.
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

SESSION="mico-zellij-check-$$"

if ! command -v zellij >/dev/null; then
  echo "zellij not on PATH; run inside 'nix develop'" >&2
  exit 1
fi

tmp="$(mktemp -d)"
export XDG_CACHE_HOME="$tmp/cache" XDG_DATA_HOME="$tmp/data"
cleanup() {
  zellij --config-dir "$tmp/zellij" kill-session "$SESSION" >/dev/null 2>&1
  rm -rf "$tmp"
}
trap cleanup EXIT

mkdir -p "$tmp/zellij/layouts"
cp config/zellij/config.kdl "$tmp/zellij/config.kdl"
cp config/zellij/layouts/default.kdl "$tmp/zellij/layouts/default.kdl"

# An array, not a function, because `timeout` cannot run shell functions.
ZJ_ARGS=(--config-dir "$tmp/zellij")

fail=0

echo "== zellij: session starts with this config =="
if ! start_out="$(timeout 60 zellij "${ZJ_ARGS[@]}" attach --create-background "$SESSION" 2>&1)"; then
  echo "FAILED to start a session" >&2
  printf '%s\n' "$start_out" >&2
  exit 1
fi
# A parse failure prints a diagnostic but can still exit 0, so inspect the output.
if printf '%s\n' "$start_out" | grep -qiE "failed to parse|unknown layout node|failed to deserialize"; then
  echo "FAILED: config or layout did not parse" >&2
  printf '%s\n' "$start_out" >&2
  exit 1
fi
echo "   ok"

sleep 3

if ! dump="$(timeout 30 zellij "${ZJ_ARGS[@]}" -s "$SESSION" action dump-layout 2>&1)"; then
  echo "FAILED to dump the live layout" >&2
  printf '%s\n' "$dump" >&2
  exit 1
fi

# The built-in layout uses status-bar; ours doesn't.
echo "== zellij: our layout was actually used =="
if printf '%s\n' "$dump" | grep -q "zellij:status-bar"; then
  echo "FAILED: session is using the built-in layout, not ours" >&2
  fail=1
else
  echo "   ok"
fi

echo "== zellij: new tabs inherit the status bar =="
new_tab_block="$(printf '%s\n' "$dump" | sed -n '/new_tab_template {/,/^    }/p')"
if printf '%s\n' "$new_tab_block" | grep -q "compact-bar"; then
  echo "   ok"
else
  echo "FAILED: new_tab_template has no compact-bar" >&2
  printf '%s\n' "${new_tab_block:-<no new_tab_template at all>}" >&2
  fail=1
fi

echo "== zellij: swap layouts inherit the status bar =="
swap_block="$(printf '%s\n' "$dump" | sed -n '/swap_tiled_layout/,$p')"
if printf '%s\n' "$swap_block" | grep -q "compact-bar"; then
  echo "   ok"
else
  echo "FAILED: swap layouts render without the compact-bar" >&2
  fail=1
fi

if ((fail)); then
  echo
  echo "zellij check failed"
  exit 1
fi
echo
echo "zellij check clean"
