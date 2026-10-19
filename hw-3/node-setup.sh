#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

sudo -n install -d -o root -g hadoop -m 0750 /etc/hive
sudo -n install -d -o hadoop -g hadoop -m 0750 /var/lib/hive /var/lib/hive/import
sudo -n install -m 0644 "$SCRIPT_DIR/config/hive-site.xml" /etc/hive/hive-site.xml
sudo -n install -m 0644 "$SCRIPT_DIR/config/hive-env.sh" /etc/hive/hive-env.sh
sudo -n install -m 0644 "$SCRIPT_DIR"/config/*.properties /etc/hive/
sudo -n install -m 0644 "$SCRIPT_DIR"/config/systemd/*.service /etc/systemd/system/

password_file=/etc/hive/metastore-password
if ! sudo -n test -f "$password_file"; then
    openssl rand -hex 32 | sudo -n tee "$password_file" >/dev/null
fi
sudo -n chown root:hadoop "$password_file"
sudo -n chmod 0640 "$password_file"
password=$(sudo -n cat "$password_file")
[[ $password =~ ^[0-9a-f]{64}$ ]]

sudo -n systemctl enable --now postgresql
if [[ $(sudo -n -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='hive'") != 1 ]]; then
    sudo -n -u postgres psql -v ON_ERROR_STOP=1 -c 'CREATE ROLE hive LOGIN'
fi
sudo -n -u postgres psql -v ON_ERROR_STOP=1 >/dev/null <<SQL
ALTER ROLE hive PASSWORD '$password';
SQL
if [[ $(sudo -n -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='hive_metastore'") != 1 ]]; then
    sudo -n -u postgres createdb -O hive hive_metastore
fi

sudo -n tee /etc/hive/hivemetastore-site.xml >/dev/null <<XML
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>jdbc:postgresql://127.0.0.1:5432/hive_metastore</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionDriverName</name>
    <value>org.postgresql.Driver</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionUserName</name>
    <value>hive</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionPassword</name>
    <value>$password</value>
  </property>
  <property>
    <name>metastore.thrift.bind.host</name>
    <value>127.0.0.1</value>
  </property>
  <property>
    <name>metastore.event.db.notification.api.auth</name>
    <value>false</value>
  </property>
  <property>
    <name>metastore.schema.verification</name>
    <value>true</value>
  </property>
  <property>
    <name>datanucleus.schema.autoCreateAll</name>
    <value>false</value>
  </property>
</configuration>
XML
sudo -n chown root:hadoop /etc/hive/hivemetastore-site.xml
sudo -n chmod 0640 /etc/hive/hivemetastore-site.xml

tables=$(sudo -n -u postgres psql -d hive_metastore -tAc "SELECT count(*) FROM information_schema.tables WHERE table_schema='public'")
if [[ $tables == 0 ]]; then
    "${HIVE[@]}" /opt/hive/bin/schematool -dbType postgres -initSchema
fi
"${HIVE[@]}" /opt/hive/bin/schematool -dbType postgres -info

"${HDFS[@]}" dfs -mkdir -p /tmp /user/hadoop /user/hive/warehouse /user/hive/external
"${HDFS[@]}" dfs -chmod 1777 /tmp
"${HDFS[@]}" dfs -chmod 0750 /user/hadoop /user/hive /user/hive/warehouse /user/hive/external
sudo -n systemctl daemon-reload
