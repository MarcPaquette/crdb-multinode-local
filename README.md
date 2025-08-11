# crdb-multinode-local
Cockroach Database Local Cluster using tmux panes

Quickstart
- Ensure tmux and the cockroach CLI are installed and on your PATH
- Start within an existing tmux session (the script requires being run inside tmux)
- Run with defaults (3 nodes, ports starting at 26257/8080, window name crdb-cluster, data in temp_store/):
  ./tmux_cluster.sh

What it does
- Creates a new tmux window (default name: crdb-cluster)
- Starts N cockroach nodes (default 3), each in its own pane
- Stores data under STORE_DIRECTORY/nodeX (default temp_store/nodeX)
- Uses sequential ports per node, starting at BASE_SQL_PORT and BASE_HTTP_PORT
- Initializes the cluster and opens a SQL shell in a side pane
- Optionally opens the Admin UI in your browser for node1 (http://localhost:BASE_HTTP_PORT)

Usage
- Inside an existing tmux session, run:
  ./tmux_cluster.sh [NUM_NODES]
  - NUM_NODES defaults to 3 and must be a positive integer

Configuration via environment variables
- TMUX_WINDOW: tmux window name (default: crdb-cluster)
- BASE_SQL_PORT: first SQL port (default: 26257). Subsequent nodes use +1, +2, ...
- BASE_HTTP_PORT: first HTTP port (default: 8080). Subsequent nodes use +1, +2, ...
- STORE_DIRECTORY: base directory for node stores (default: temp_store)
- REGIONS_CSV: comma-separated regions cycled across nodes (default: us-east,us-west,us-central)
- OPEN_UI: set to 0 to skip auto-opening the Admin UI (default: 1)

Examples
- Override ports/window/store directory:
  TMUX_WINDOW=crdb-cluster BASE_SQL_PORT=26257 BASE_HTTP_PORT=8080 STORE_DIRECTORY=temp_store ./tmux_cluster.sh
- Start an alternate cluster on different ports and store dir:
  TMUX_WINDOW=crdb-cluster-two BASE_SQL_PORT=26357 BASE_HTTP_PORT=8090 STORE_DIRECTORY=temp_store_2 ./tmux_cluster.sh
- Start tmux server detached, then run the script inside that session/window:
  tmux new-session -d -s crdb && TMUX_WINDOW=crdb BASE_SQL_PORT=26257 BASE_HTTP_PORT=8080 STORE_DIRECTORY=temp_store ./tmux_cluster.sh

Notes
- The script validates numeric ports and node count and will exit on errors
- The join list for nodes is built as localhost:BASE_SQL_PORT .. localhost:BASE_SQL_PORT+N-1
- Data directories are created under STORE_DIRECTORY/node1..nodeN
- To stop and clean up, kill the tmux session and remove the store directories, for example:
  tmux kill-session -t crdb
  rm -rf temp_store temp_store_2
