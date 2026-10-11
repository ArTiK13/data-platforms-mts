#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
on_node "$MASTER" 'systemctl is-active --quiet hdfs-namenode hdfs-secondarynamenode yarn-resourcemanager mapred-historyserver'
for node in "${WORKERS[@]}"; do
    on_node "$node" 'systemctl is-active --quiet hdfs-datanode yarn-nodemanager'
done

temporary=$(mktemp -d)
trap 'rm -rf "$temporary"' EXIT
"${HDFS[@]}" dfsadmin -report > "$temporary/hdfs.txt"
grep -q '^Live datanodes (3):' "$temporary/hdfs.txt" && \
    ! grep -Eq '^Dead datanodes \([1-9]' "$temporary/hdfs.txt" || { echo 'Ожидались 3 живых DataNode без мёртвых узлов' >&2; exit 1; }


echo 'YARN и JobHistory в процессе'
for i in {1..30}; do
    if curl -fsS --max-time 10 http://team-08-nn:8088/ws/v1/cluster/metrics > "$temporary/metrics.json" && \
       curl -fsS --connect-timeout 2 --max-time 5 http://team-08-nn:19888/ws/v1/history/info >/dev/null && \
       python3 - "$temporary/metrics.json" <<'PY'
import json, sys
m = json.load(open(sys.argv[1]))["clusterMetrics"]
assert m["activeNodes"] == 3, m
PY
    then
        break
    fi
    if [[ $i == 30 ]]; then
        echo 'Не дождались 3 NodeManager и интерфейса JobHistory' >&2
        exit 1
    fi
    sleep 3
done


grep -E '^Live datanodes|^Name:' "$temporary/hdfs.txt"
sudo -n -u hadoop env HADOOP_CONF_DIR=/etc/hadoop /opt/hadoop/bin/yarn node -list -all
echo 'Все проверки служб, HDFS и YARN прошли'
