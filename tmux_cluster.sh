#!/usr/bin/env bash
# tmux_cluster.sh
# Usage: ./tmux_cluster.sh [NUM_NODES]

set -exuo pipefail

NODES="${1:-3}"                 # default: 3 nodes
BASE_SQL_PORT=26257
BASE_HTTP_PORT=8080

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
  

# Make the first pane the base (node 1)
tmux new-window -n crdb-cluster cockroach start \
  --insecure \
  --store=temp_store/node1 \
  --listen-addr=localhost:$BASE_SQL_PORT \
  --http-addr=localhost:$BASE_HTTP_PORT \
  --join=$join

# Add remaining nodes below
for i in $(seq 2 "$NODES"); do
  sql_port=$((BASE_SQL_PORT + i - 1))
  http_port=$((BASE_HTTP_PORT + i - 1))
  store="node$i"
  tmux split-window -v cockroach start \
    --insecure \
    --store=temp_store/$store \
    --listen-addr=localhost:$sql_port \
    --http-addr=localhost:$http_port \
    --join=$join
  tmux select-layout -t "crdb-cluster" even-vertical
done

tmux select-layout -t "crdb-cluster" even-vertical
tmux split-window -hf -p 80 "sleep 3 && cockroach init --insecure --host=localhost:$BASE_SQL_PORT && \
   cockroach sql --insecure --host=localhost:$BASE_SQL_PORT"
tmux split-window -v -p 75

sleep 5

if command -v open &>/dev/null; then
  open "http://localhost:8080"
elif command -v xdg-open &>/dev/null; then
  xdg-open "http://localhost:8080"
fi
