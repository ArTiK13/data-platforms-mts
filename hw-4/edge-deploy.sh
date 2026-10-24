#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

if [[ ! -d /opt/spark-$VERSION-bin-hadoop3 ]]; then
    archive="spark-$VERSION-bin-hadoop3.tgz"
    base="https://archive.apache.org/dist/spark/spark-$VERSION"
    cd "$SCRIPT_DIR"
    curl -fL --retry 3 "$base/$archive" -o "$archive"
    curl -fL --retry 3 "$base/$archive.sha512" -o "$archive.sha512"
    sha512sum -c "$archive.sha512"
    sudo -n tar -xzf "$archive" -C /opt
    rm -f "$archive" "$archive.sha512"
fi
sudo -n ln -sfn "/opt/spark-$VERSION-bin-hadoop3" /opt/spark
sudo -n install -d -m 0755 /etc/spark
sudo -n install -m 0644 "$SCRIPT_DIR"/config/* /etc/spark/
sudo -n install -d -o hadoop -g hadoop -m 0755 /var/lib/spark
sudo -n install -o hadoop -g hadoop -m 0644 "$SCRIPT_DIR/job.py" /var/lib/spark/job.py
"${HDFS[@]}" dfs -mkdir -p /user/hive/external/hw4

bash "$SCRIPT_DIR/run.sh"
bash "$SCRIPT_DIR/check.sh"
