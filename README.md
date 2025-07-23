# crdb-multinode-local
Cockroach Database Local Cluster using Tmux panes

You can override the defaults:
```
TMUX_WINDOW=crdb-cluster-two BASE_SQL_PORT=26357 BASE_HTTP_PORT=8090 STORE_DIRECTORY=temp_store_2 ./tmux_cluster.sh
```
