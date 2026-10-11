#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
INTERNAL=(team-08-nn team-08-00 team-08-01)
for node in "${INTERNAL[@]}"; do
    ssh "${INNER_SSH[@]}" "team@$node" 'mkdir -p ~/hw2-yarn'
    scp -r "${INNER_SSH[@]}" "$SCRIPT_DIR"/{common.sh,node-setup.sh,config} "team@$node:hw2-yarn/"
done
for node in team-08-en "${INTERNAL[@]}"; do
    on_node "$node" "bash ~/hw2-yarn/node-setup.sh $node"
done

"${HDFS[@]}" dfs -mkdir -p /tmp/hadoop-yarn/staging /mr-history/done /mr-history/done_intermediate /app-logs
"${HDFS[@]}" dfs -chmod 1777 /tmp /tmp/hadoop-yarn/staging /mr-history/done_intermediate /app-logs
"${HDFS[@]}" dfs -chmod 0755 /tmp/hadoop-yarn /mr-history
"${HDFS[@]}" dfs -chmod 0750 /mr-history/done

on_node "$MASTER" 'sudo -n systemctl enable yarn-resourcemanager mapred-historyserver && sudo -n systemctl restart yarn-resourcemanager mapred-historyserver'
for node in "${WORKERS[@]}"; do
    on_node "$node" 'sudo -n systemctl enable yarn-nodemanager && sudo -n systemctl restart yarn-nodemanager'
done
sudo -n env DEBIAN_FRONTEND=noninteractive apt-get update
sudo -n env DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
site=/etc/nginx/sites-available/hadoop-ui.conf
sudo -n install -m 0644 "$SCRIPT_DIR/config/nginx/hadoop-ui.conf" "$site"
sudo -n ln -sfn "$site" /etc/nginx/sites-enabled/hadoop-ui.conf
sudo -n nginx -t
sudo -n systemctl enable --now nginx
sudo -n systemctl reload nginx
if sudo -n ufw status | grep -q '^Status: active'; then
    sudo -n ufw allow 8443:8453/tcp
fi
bash "$SCRIPT_DIR/check.sh"
