CRUSH.md — Quickstart for agents working in this repo

Build / Run / Test
- This repo is a small shell-based helper to run a local multi-node CockroachDB cluster via tmux. There is no language toolchain or test framework here.
- Primary entrypoint: ./tmux_cluster.sh
- Run with defaults: ./tmux_cluster.sh
- Override ports/window/store: TMUX_WINDOW=crdb-cluster BASE_SQL_PORT=26257 BASE_HTTP_PORT=8080 STORE_DIRECTORY=temp_store ./tmux_cluster.sh
- Example alt cluster: TMUX_WINDOW=crdb-cluster-two BASE_SQL_PORT=26357 BASE_HTTP_PORT=8090 STORE_DIRECTORY=temp_store_2 ./tmux_cluster.sh
- Start detached (tmux server persists panes): tmux new-session -d -s crdb && TMUX_WINDOW=crdb BASE_SQL_PORT=26257 BASE_HTTP_PORT=8080 STORE_DIRECTORY=temp_store ./tmux_cluster.sh
- Stop/cleanup: kill tmux session (tmux kill-session -t crdb) and remove store dirs (rm -rf temp_store temp_store_2)
- Lint/format: Shell script only. Use shellcheck and shfmt if available:
  - shellcheck tmux_cluster.sh
  - shfmt -w tmux_cluster.sh
- Tests: No automated tests exist. To validate, run the script and ensure Cockroach nodes start and UIs are reachable on specified ports. To “run a single test,” run a targeted shellcheck rule: shellcheck -s bash -o all -e SC1090 tmux_cluster.sh (adjust -e to focus rules).

Code Style Guidelines (Shell)
- Shell: Bash-compatible. Keep POSIX where practical; rely on common tmux and cockroach CLI.
- Imports/execs: Prefer absolute or repo-relative paths; check tools exist before use (command -v cockroach >/dev/null 2>&1).
- Formatting: Use shfmt defaults; 2-space indent; align continued lines; keep lines under ~100 chars.
- Variables: UPPER_SNAKE for env/config (TMUX_WINDOW, BASE_SQL_PORT); local variables lower_snake; quote all expansions ("$var").
- Defaults: Provide safe defaults via : or ${VAR:-default}. Validate numeric ports and directories before use.
- Functions: small, single-purpose; name as verb_noun; return nonzero on error.
- Error handling: set -euo pipefail where safe; check commands (if ! tmux new-window ...; then ... fi); propagate exit codes.
- Traps/cleanup: use trap 'cleanup' EXIT to close panes or temporary dirs when appropriate.
- Naming: Scripts and files in lower_snake; temporary data under temp_store*/.
- Logging: echo prefixed levels (INFO:, WARN:, ERROR:) to stderr for errors (>&2).

Cursor/Copilot Rules
- No Cursor or Copilot rules found in this repo at the time of writing. If added later (e.g., .cursor/rules/, .cursorrules, or .github/copilot-instructions.md), mirror key conventions here.
