#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
MASTER=team-08-nn
WORKERS=(team-08-en team-08-00 team-08-01)
INNER_SSH=(-i "$HOME/.ssh/team_internal" -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=15 -o StrictHostKeyChecking=accept-new)
HDFS=(sudo -n -u hadoop env HADOOP_CONF_DIR=/etc/hadoop /opt/hadoop/bin/hdfs)
on_node() {
    local node=$1
    shift
    if [[ $node == team-08-en ]]; then
        bash -c "$1"
    else
        ssh "${INNER_SSH[@]}" "team@$node" "$1"
    fi
}
