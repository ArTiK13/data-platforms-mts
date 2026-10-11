#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
NODE=${1:?Use: node-setup.sh team-08-en|team-08-nn|team-08-00|team-08-01}
sudo -n install -m 0644 "$SCRIPT_DIR"/config/hadoop/{yarn-site.xml,mapred-site.xml} /etc/hadoop/
sudo -n install -d -o hadoop -g hadoop -m 0750 \
    /var/lib/hadoop-yarn /var/lib/hadoop-yarn/local /var/log/hadoop-yarn /var/log/hadoop-yarn/containers

if [[ $NODE == "$MASTER" ]]; then
    sudo -n install -m 0644 "$SCRIPT_DIR/config/systemd/yarn-resourcemanager.service" /etc/systemd/system/yarn-resourcemanager.service
    sudo -n install -m 0644 "$SCRIPT_DIR/config/systemd/mapred-historyserver.service" /etc/systemd/system/mapred-historyserver.service
else
    sudo -n install -m 0644 "$SCRIPT_DIR/config/systemd/yarn-nodemanager.service" /etc/systemd/system/yarn-nodemanager.service
fi
sudo -n systemctl daemon-reload
