#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
VERSION=3.4.2
ARCHIVE="hadoop-$VERSION.tar.gz"
URL="https://dlcdn.apache.org/hadoop/common/hadoop-$VERSION/$ARCHIVE"
HOSTS=(namenode datanode-0 datanode-1)

cd "$SCRIPT_DIR"

if [[ ! -f "$ARCHIVE" ]]; then
    echo "Downloading Hadoop $VERSION"
    curl -fL "$URL" -o "$ARCHIVE"
fi

for host in "${HOSTS[@]}"; do
    ssh "$host" 'mkdir -p ~/hw-1-hdfs'
    scp -q node-setup.sh .cluster-password "$ARCHIVE" "$host:hw-1-hdfs/"
done

echo 'Configuring edge'
bash node-setup.sh datanode
echo 'Configuring namenode'
ssh namenode 'bash ~/hw-1-hdfs/node-setup.sh namenode'
echo 'Configuring datanode-0'
ssh datanode-0 'bash ~/hw-1-hdfs/node-setup.sh datanode'
echo 'Configuring datanode-1'
ssh datanode-1 'bash ~/hw-1-hdfs/node-setup.sh datanode'

ssh namenode 'sudo systemctl enable hdfs-namenode hdfs-secondarynamenode && sudo systemctl restart hdfs-namenode hdfs-secondarynamenode'
sudo systemctl enable hdfs-datanode
sudo systemctl restart hdfs-datanode
ssh datanode-0 'sudo systemctl enable hdfs-datanode && sudo systemctl restart hdfs-datanode'
ssh datanode-1 'sudo systemctl enable hdfs-datanode && sudo systemctl restart hdfs-datanode'

bash check.sh

rm -f "$ARCHIVE" .cluster-password
for host in "${HOSTS[@]}"; do
    ssh "$host" "rm -f ~/hw-1-hdfs/$ARCHIVE ~/hw-1-hdfs/.cluster-password"
done
