#!/usr/bin/env bash
# tmux_cluster.sh
# Usage: ./tmux_cluster.sh [NUM_NODES]

set -euo pipefail

if [[ "${DEBUG:-}" == "1" ]]; then
  set -x
fi

command -v tmux >/dev/null 2>&1 || { echo "ERROR: tmux not found" >&2; exit 1; }
command -v cockroach >/dev/null 2>&1 || { echo "ERROR: cockroach not found" >&2; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "ERROR: curl not found" >&2; exit 1; }

NODES="${1:-3}"
BASE_SQL_PORT="${BASE_SQL_PORT:-26257}"
BASE_HTTP_PORT="${BASE_HTTP_PORT:-8080}"
STORE_DIRECTORY="${STORE_DIRECTORY:-temp_store}"
TMUX_WINDOW="${TMUX_WINDOW:-crdb-cluster}"

REGIONS_CSV="${REGIONS_CSV:-us-east-1,us-west-1,eu-west-1}"
OLD_IFS=$IFS; IFS=',' read -r -a REGIONS <<< "$REGIONS_CSV"; IFS=$OLD_IFS

if (( ${#REGIONS[@]} == 0 )); then
  echo "ERROR: REGIONS_CSV must contain at least one region" >&2
  exit 1
fi

if [[ -z "${TMUX:-}" ]]; then
  echo "ERROR: This script must be run inside an existing tmux session." >&2
  exit 1
fi

case "$NODES" in
  ''|*[!0-9]*) echo "ERROR: NODES must be a positive integer" >&2; exit 1;;
  *) if (( NODES < 1 )); then echo "ERROR: NODES must be >= 1" >&2; exit 1; fi;;
esac

for p in "$BASE_SQL_PORT" "$BASE_HTTP_PORT"; do
  case "$p" in ''|*[!0-9]*) echo "ERROR: Ports must be integers" >&2; exit 1;; esac
  if (( p < 1 || p > 65535 )); then echo "ERROR: Port $p out of range" >&2; exit 1; fi
done

# Retry logic to wait for HTTP endpoint to be ready
wait_for_http() {
  local url="$1"
  local max_attempts="${2:-30}"
  local delay="${3:-1}"
  local attempt=1

  while (( attempt <= max_attempts )); do
    if curl -sf "$url" >/dev/null 2>&1; then
      echo "INFO: $url is ready" >&2
      return 0
    fi
    echo "INFO: Waiting for $url to be ready (attempt $attempt/$max_attempts)..." >&2
    sleep "$delay"
    ((attempt++))
  done

  echo "ERROR: $url did not become ready after $max_attempts attempts" >&2
  return 1
}

mkdir -p "$STORE_DIRECTORY"

join=""
for i in $(seq 0 $((NODES-1))); do
  join+="localhost:$((BASE_SQL_PORT+i)),"
  mkdir -p "$STORE_DIRECTORY/node$((i+1))"
done
join=${join%,}

region="${REGIONS[0]}"

if ! tmux new-window -n "$TMUX_WINDOW" cockroach start \
  --insecure \
  --store="$STORE_DIRECTORY/node1" \
  --listen-addr="localhost:$BASE_SQL_PORT" \
  --http-addr="localhost:$BASE_HTTP_PORT" \
  --locality="region=$region" \
  --logtostderr=WARNING \
  --join="$join"; then
  echo "ERROR: failed to start node1" >&2; exit 1
fi

for i in $(seq 2 "$NODES"); do
  sql_port=$((BASE_SQL_PORT + i - 1))
  http_port=$((BASE_HTTP_PORT + i - 1))
  store="node$i"
  idx=$(( (i-1) % ${#REGIONS[@]} ))
  region="${REGIONS[$idx]}"

  if ! tmux split-window -v cockroach start \
    --insecure \
    --store="$STORE_DIRECTORY/$store" \
    --listen-addr="localhost:$sql_port" \
    --http-addr="localhost:$http_port" \
    --locality="region=$region" \
    --logtostderr=WARNING \
    --join="$join"; then
    echo "ERROR: failed to start $store" >&2; exit 1
  fi
  tmux select-layout -t "$TMUX_WINDOW" even-vertical
  echo "INFO: Started $store (sql:$sql_port http:$http_port region:$region)"
done

tmux select-layout -t "$TMUX_WINDOW" even-vertical

# Wait for cluster to be intialized before proceeding
attempts=0
until cockroach init --insecure --host=localhost:"$BASE_SQL_PORT"; do
((attempts++))
      if (( attempts > 30 )); then
        echo 'ERROR: cockroach init timed out after 30 attempts' >&2
        exit 1
      fi
      sleep 1
done

tmux split-window -hf -p 75 "cockroach sql --insecure --host=localhost:$BASE_SQL_PORT"

tmux split-window -v -p 75

# Wait for the cluster HTTP endpoint to be ready
if ! wait_for_http "http://localhost:$BASE_HTTP_PORT" 30 1; then
  echo "WARNING: Cluster HTTP endpoint not ready, skipping UI open" >&2
fi

if [[ "${OPEN_UI:-1}" == "1" ]]; then
  if command -v open &>/dev/null; then
    open "http://localhost:$BASE_HTTP_PORT"
  elif command -v xdg-open &>/dev/null; then
    xdg-open "http://localhost:$BASE_HTTP_PORT"
  fi
fi
