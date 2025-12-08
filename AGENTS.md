# Repository Guidelines

## Project Structure & Module Organization
This repository is intentionally small: `tmux_cluster.sh` is the single orchestrator script in the root, `README.md` is the user-facing quickstart, and `CRUSH.md` captures failure modes. Temporary cockroach stores live under `temp_store/node*`; never commit their contents, and wipe them after each run. Place any new automation under a future `scripts/` folder to keep the top-level focused on the launcher.

## Build, Test, and Development Commands
- `./tmux_cluster.sh [NUM_NODES]`: start NUM_NODES CockroachDB instances inside the current tmux session using the default ports.
- `TMUX_WINDOW=crdb-alt BASE_SQL_PORT=26357 BASE_HTTP_PORT=8090 STORE_DIRECTORY=temp_store_alt ./tmux_cluster.sh`: override window names, port ranges, and storage roots for parallel clusters.
- `shellcheck tmux_cluster.sh`: lint the Bash script; fix warnings before pushing.
- `shfmt -w -i 2 tmux_cluster.sh`: format changes consistently.

## Coding Style & Naming Conventions
Stick to POSIX-compatible Bash plus CockroachDB CLI commands. Use two-space indentation inside conditionals and loops, align long flag lists, and prefer long option names (`--listen-addr`) for clarity. Environment variables are UPPER_SNAKE_CASE and documented in `README.md`; introduce new ones adjacent to the existing export block and document defaults. Echo status lines prefixed with `INFO:` or `ERROR:` to match the current script.

## Testing Guidelines
Run the script from inside tmux: `tmux new-session -d -s crdb && tmux attach -t crdb` before executing. After startup, validate the cluster with `cockroach sql --insecure --host=localhost:26257 -e "show clusters;"`. For multi-region checks, vary `REGIONS_CSV` and confirm locality info via `cockroach node status`. Keep manual smoke-test notes in `CRUSH.md` when you discover regressions.

## Commit & Pull Request Guidelines
The git log shows short, imperative summaries (e.g., `Fix issue with preexisting cluster startup`). Follow that pattern, keep subjects under ~72 characters, and add context in the body when changing behavior. Pull requests should include: a problem statement, concise testing evidence (commands and results), and screenshots only when UI output matters (e.g., Admin UI). Link related issues and call out any operational impact such as port changes.

## Security & Configuration Tips
Clusters run with `--insecure`; restrict usage to local environments and tear down tmux sessions (`tmux kill-session -t crdb`) after demos. Clean `temp_store/` directories before reusing ports to avoid stale state, and never commit generated files like `debug.zip`.
