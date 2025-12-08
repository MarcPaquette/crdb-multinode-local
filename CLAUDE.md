# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A small shell-based helper to run a local multi-node CockroachDB cluster via tmux. There is no language toolchain or test framework—just a single orchestrator script.

## Commands

```bash
# Start cluster (requires running inside tmux session)
./tmux_cluster.sh [NUM_NODES]    # default: 3 nodes

# Override configuration via environment variables
TMUX_WINDOW=crdb-alt BASE_SQL_PORT=26357 BASE_HTTP_PORT=8090 STORE_DIRECTORY=temp_store_alt ./tmux_cluster.sh

# Lint and format
shellcheck tmux_cluster.sh
shfmt -w -i 2 tmux_cluster.sh

# Stop and cleanup
tmux kill-session -t crdb
rm -rf temp_store temp_store_2
```

## Environment Variables

- `DEBUG`: set to 1 for debug output
- `TMUX_WINDOW`: tmux window name (default: crdb-cluster)
- `BASE_SQL_PORT`: first SQL port (default: 26257)
- `BASE_HTTP_PORT`: first HTTP port (default: 8080)
- `STORE_DIRECTORY`: base directory for node stores (default: temp_store)
- `REGIONS_CSV`: comma-separated regions cycled across nodes (default: us-east-1,us-west-1,eu-west-1)
- `OPEN_UI`: set to 0 to skip auto-opening Admin UI (default: 1)

## Code Style

- Bash-compatible, POSIX where practical
- Two-space indentation; align continued lines; lines under ~100 chars
- Environment variables: UPPER_SNAKE_CASE; local variables: lower_snake_case
- Quote all variable expansions (`"$var"`)
- Log with prefixed levels (`INFO:`, `WARN:`, `ERROR:`) to stderr for errors
- Functions: small, single-purpose, named as verb_noun, return nonzero on error
- Provide defaults via `${VAR:-default}` and validate inputs before use

## Testing

No automated tests. Validate manually:
1. Run inside tmux: `tmux new-session -d -s crdb && tmux attach -t crdb`
2. Execute script, verify nodes start and Admin UI is reachable
3. Validate cluster: `cockroach sql --insecure --host=localhost:26257 -e "show clusters;"`

## Important Notes

- Clusters run with `--insecure`; restrict to local environments
- Temporary stores live under `temp_store/node*`; never commit their contents
- Clean store directories before reusing ports to avoid stale state
- Place new automation under a future `scripts/` folder to keep root focused
