#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

child_pid=""

fingerprint() {
  find Package.swift Sources -type f \( -name '*.swift' -o -name 'Package.swift' \) -print0 \
    | sort -z \
    | xargs -0 cksum \
    | cksum
}

stop_child() {
  if [[ -n "$child_pid" ]] && kill -0 "$child_pid" 2>/dev/null; then
    kill "$child_pid" 2>/dev/null || true
    wait "$child_pid" 2>/dev/null || true
  fi
  child_pid=""
}

start_child() {
  stop_child
  echo "[dev-watch] starting swift run"
  swift run &
  child_pid="$!"
}

trap 'stop_child; exit 0' INT TERM EXIT

last_fingerprint="$(fingerprint)"
start_child

while true; do
  sleep 1
  next_fingerprint="$(fingerprint)"
  if [[ "$next_fingerprint" != "$last_fingerprint" ]]; then
    echo "[dev-watch] change detected; restarting"
    last_fingerprint="$next_fingerprint"
    start_child
  fi
done
