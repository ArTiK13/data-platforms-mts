#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

sudo -n test -x /opt/hadoop/bin/hdfs
"${HDFS[@]}" dfsadmin -report

sudo -n env DEBIAN_FRONTEND=noninteractive apt-get update
sudo -n env DEBIAN_FRONTEND=noninteractive apt-get install -y openjdk-17-jre-headless postgresql libpostgresql-jdbc-java curl

if [[ ! -d /opt/apache-hive-$VERSION-bin ]]; then
    archive="apache-hive-$VERSION-bin.tar.gz"
    base="https://archive.apache.org/dist/hive/hive-$VERSION"
    cd "$SCRIPT_DIR"
    curl -fL --retry 3 "$base/$archive" -o "$archive"
    curl -fL --retry 3 "$base/$archive.sha256" -o "$archive.sha256"
    expected=$(awk '{for (i=1; i<=NF; i++) if (length($i)==64 && $i ~ /^[0-9a-fA-F]+$/) print $i}' "$archive.sha256")
    [[ -n $expected ]]
    printf '%s  %s\n' "$expected" "$archive" | sha256sum -c -
    sudo -n tar -xzf "$archive" -C /opt
    rm -f "$archive" "$archive.sha256"
fi
sudo -n ln -sfn "/opt/apache-hive-$VERSION-bin" /opt/hive
sudo -n install -m 0644 /usr/share/java/postgresql.jar /opt/hive/lib/postgresql.jar

bash "$SCRIPT_DIR/node-setup.sh"
sudo -n systemctl enable hive-metastore hive-server2
sudo -n systemctl restart hive-metastore hive-server2

ready=false
for _ in {1..30}; do
    if timeout 20 "${BEELINE[@]}" -e 'SELECT 1;' >/dev/null 2>&1; then
        ready=true
        break
    fi
    sleep 3
done
if [[ $ready != true ]]; then
    sudo -n journalctl -u hive-metastore -u hive-server2 -n 80 --no-pager >&2
    echo 'HiveServer2 не готов к запросам' >&2
    exit 1
fi

bash "$SCRIPT_DIR/load-data.sh"
bash "$SCRIPT_DIR/check.sh"
