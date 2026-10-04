#!/usr/bin/env bash
set -euo pipefail

HDFS=(sudo -u hadoop env HADOOP_CONF_DIR=/etc/hadoop /opt/hadoop/bin/hdfs)
HOSTS=(namenode datanode-0 datanode-1)

check_user='sudo passwd -S hadoop | grep -q "^hadoop P " && ! id -nG hadoop | grep -qw sudo'
bash -c "$check_user"
for host in "${HOSTS[@]}"; do
    ssh "$host" "$check_user"
done
echo 'User hadoop has a password and no sudo access.'

systemctl is-active --quiet hdfs-datanode
ssh namenode 'systemctl is-active --quiet hdfs-namenode hdfs-secondarynamenode'
ssh datanode-0 'systemctl is-active --quiet hdfs-datanode'
ssh datanode-1 'systemctl is-active --quiet hdfs-datanode'
echo 'NameNode, SecondaryNameNode and three DataNodes are running.'

report=$(mktemp)
for attempt in {1..30}; do
    "${HDFS[@]}" dfsadmin -report > "$report" 2>/dev/null || true
    if grep -q '^Live datanodes (3):' "$report"; then
        break
    fi
    sleep 3
done
grep -q '^Live datanodes (3):' "$report"
! grep -Eq '^Dead datanodes \([1-9][0-9]*\):' "$report"
grep -E '^Live datanodes|^Name:' "$report"
rm -f "$report"

test_path="/hw1-test-$$"
test_text="HDFS test $(date +%s)"
printf '%s\n' "$test_text" | "${HDFS[@]}" dfs -put - "$test_path"
[[ $("${HDFS[@]}" dfs -cat "$test_path") == "$test_text" ]]
fsck=$("${HDFS[@]}" fsck "$test_path" -files -blocks -locations)
grep -q 'Status: HEALTHY' <<< "$fsck"
grep -q 'Live_repl=3' <<< "$fsck"
"${HDFS[@]}" dfs -rm -skipTrash "$test_path" >/dev/null
echo 'HDFS write, read and replication factor 3 work.'

curl -fsS http://team-08-nn:9870/ >/dev/null
echo 'NameNode web interface is available.'
echo 'All checks passed.'
