#!/usr/bin/env bash
# tmux_cluster.sh
# Usage: ./tmux_cluster.sh [NUM_NODES]

set -exuo pipefail

NODES="${1:-3}"                 # default: 3 nodes
BASE_SQL_PORT="${BASE_SQL_PORT:-26257}"
BASE_HTTP_PORT="${BASE_HTTP_PORT:-8080}"
STORE_DIRECTORY="${STORE_DIRECTORY:-temp_store}"
TMUX_WINDOW="${TMUX_WINDOW:-crdb-cluster}"


# define a comma-separated list of regions (no spaces!) and split into an array
REGIONS_CSV="${REGIONS:-us-east,us-west,us-central}"
IFS=',' read -r -a REGIONS <<< "$REGIONS_CSV"

# Ensure we're inside a tmux session
if [[ -z "${TMUX:-}" ]]; then
  echo "This script must be run inside an existing tmux session."
  exit 1
fi

# Build the --join list
join=""
for i in $(seq 0 $((NODES-1))); do
  join+="localhost:$((BASE_SQL_PORT+i)),"
done
join=${join%,}  # remove trailing comma
  
region="${REGIONS[0]}"
# Make the first pane the base (node 1)
tmux new-window -n $TMUX_WINDOW cockroach start \
  --insecure \
  --store=$STORE_DIRECTORY/node1 \
  --listen-addr=localhost:$BASE_SQL_PORT \
  --http-addr=localhost:$BASE_HTTP_PORT \
  --locality=region=$region \
  --join=$join

# Add remaining nodes below
for i in $(seq 2 "$NODES"); do
  sql_port=$((BASE_SQL_PORT + i - 1))
  http_port=$((BASE_HTTP_PORT + i - 1))
  store="node$i"

  # pick region by rotating through the array
  idx=$(( (i-1) % ${#REGIONS[@]} ))
  region="${REGIONS[$idx]}"

  tmux split-window -v cockroach start \
    --insecure \
    --store=$STORE_DIRECTORY/$store \
    --listen-addr=localhost:$sql_port \
    --http-addr=localhost:$http_port \
    --locality=region=$region \
    --join=$join
  tmux select-layout -t "$TMUX_WINDOW" even-vertical
done

tmux select-layout -t "$TMUX_WINDOW" even-vertical
tmux split-window -hf -p 80 "sleep 3 && cockroach init --insecure --host=localhost:$BASE_SQL_PORT && \
   cockroach sql --insecure --host=localhost:$BASE_SQL_PORT"
tmux split-window -v -p 75

sleep 5

if command -v open &>/dev/null; then
  open "http://localhost:$BASE_HTTP_PORT"
elif command -v xdg-open &>/dev/null; then
  xdg-open "http://localhost:$BASE_HTTP_PORT"
fi
