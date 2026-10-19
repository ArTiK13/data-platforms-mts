#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
EDGE=team@2.59.83.169
VERSION=4.1.0
HIVE=(sudo -n -u hadoop env HIVE_HOME=/opt/hive HIVE_CONF_DIR=/etc/hive HADOOP_HOME=/opt/hadoop HADOOP_CONF_DIR=/etc/hadoop)
HDFS=(sudo -n -u hadoop env HADOOP_CONF_DIR=/etc/hadoop /opt/hadoop/bin/hdfs)
BEELINE=("${HIVE[@]}" /opt/hive/bin/beeline -u jdbc:hive2://127.0.0.1:10000/default -n hadoop --silent=true --showHeader=false --outputformat=tsv2 --force=false)
