#!/usr/bin/env bash
set -euo pipefail

ROLE=${1:?Use: node-setup.sh namenode|datanode}
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
VERSION=3.4.2
ARCHIVE="$SCRIPT_DIR/hadoop-$VERSION.tar.gz"
HADOOP_HOME=/opt/hadoop
HADOOP_USER=hadoop
JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y openjdk-17-jre-headless

if ! id "$HADOOP_USER" >/dev/null 2>&1; then
    sudo useradd -m -s /bin/bash "$HADOOP_USER"
fi
printf '%s:%s\n' "$HADOOP_USER" "$(<"$SCRIPT_DIR/.cluster-password")" | sudo chpasswd
sudo gpasswd -d "$HADOOP_USER" sudo >/dev/null 2>&1 || true

if [[ ! -d "/opt/hadoop-$VERSION" ]]; then
    sudo tar -xzf "$ARCHIVE" -C /opt
fi
sudo ln -sfn "/opt/hadoop-$VERSION" "$HADOOP_HOME"

sudo mkdir -p /etc/hadoop
sudo cp -a --update=none "$HADOOP_HOME/etc/hadoop/." /etc/hadoop/

sudo tee /etc/hadoop/hadoop-env.sh >/dev/null <<EOF
export JAVA_HOME=$JAVA_HOME
export HADOOP_HOME=$HADOOP_HOME
export HADOOP_CONF_DIR=/etc/hadoop
export HADOOP_LOG_DIR=/var/log/hadoop
export HADOOP_PID_DIR=/run/hadoop-hdfs
export HADOOP_HEAPSIZE_MAX=512m
EOF

sudo tee /etc/hadoop/core-site.xml >/dev/null <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://team-08-nn:8020</value>
  </property>
</configuration>
EOF

sudo tee /etc/hadoop/hdfs-site.xml >/dev/null <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <property>
    <name>dfs.replication</name>
    <value>3</value>
  </property>
  <property>
    <name>dfs.namenode.name.dir</name>
    <value>file:///var/lib/hadoop-hdfs/name</value>
  </property>
  <property>
    <name>dfs.datanode.data.dir</name>
    <value>file:///var/lib/hadoop-hdfs/data</value>
  </property>
  <property>
    <name>dfs.namenode.checkpoint.dir</name>
    <value>file:///var/lib/hadoop-hdfs/secondary</value>
  </property>
  <property>
    <name>dfs.namenode.http-address</name>
    <value>team-08-nn:9870</value>
  </property>
  <property>
    <name>dfs.namenode.rpc-bind-host</name>
    <value>0.0.0.0</value>
  </property>
  <property>
    <name>dfs.namenode.http-bind-host</name>
    <value>0.0.0.0</value>
  </property>
  <property>
    <name>dfs.namenode.secondary.http-address</name>
    <value>0.0.0.0:9868</value>
  </property>
</configuration>
EOF

sudo tee /etc/hadoop/workers >/dev/null <<'EOF'
team-08-en
team-08-00
team-08-01
EOF

sudo install -d -o hadoop -g hadoop -m 0750 /var/log/hadoop /var/lib/hadoop-hdfs /run/hadoop-hdfs
if [[ "$ROLE" == namenode ]]; then
    sudo install -d -o hadoop -g hadoop -m 0700 /var/lib/hadoop-hdfs/name /var/lib/hadoop-hdfs/secondary
else
    sudo install -d -o hadoop -g hadoop -m 0700 /var/lib/hadoop-hdfs/data
fi

install_service() {
    local daemon=$1
    sudo tee "/etc/systemd/system/hdfs-$daemon.service" >/dev/null <<EOF
[Unit]
After=network.target

[Service]
User=hadoop
Environment=HADOOP_CONF_DIR=/etc/hadoop
RuntimeDirectory=hadoop-hdfs
ExecStart=/opt/hadoop/bin/hdfs $daemon
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
}

if [[ "$ROLE" == namenode ]]; then
    if ! sudo test -f /var/lib/hadoop-hdfs/name/current/VERSION; then
        sudo -u hadoop env HADOOP_CONF_DIR=/etc/hadoop /opt/hadoop/bin/hdfs namenode -format
    fi
    install_service namenode
    install_service secondarynamenode
else
    install_service datanode
fi

sudo systemctl daemon-reload
