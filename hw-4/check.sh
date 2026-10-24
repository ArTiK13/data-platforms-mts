#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo 'Проверяем таблицу через Hive'
"${BEELINE[@]}" -f /dev/stdin < "$SCRIPT_DIR/sql/check.sql" > "$tmp/actual"
diff -u "$SCRIPT_DIR/data/expected.tsv" "$tmp/actual" || { echo 'Данные или партиции Hive не совпали с ожидаемыми' >&2; exit 1; }
cat "$tmp/actual"

echo 'Проверяем файлы в HDFS'
"${HDFS[@]}" dfs -ls -R /user/hive/external/hw4/event_stats

echo 'Проверяем приложение Spark в YARN'
id=$(sudo -n -u hadoop cat /var/lib/spark/application-id)
"${YARN[@]}" application -status "$id" > "$tmp/yarn"
cat "$tmp/yarn"
if ! grep -Eq 'Application-Type[[:space:]]*:[[:space:]]*SPARK' "$tmp/yarn" ||
    ! grep -Eq 'State[[:space:]]*:[[:space:]]*FINISHED' "$tmp/yarn" ||
    ! grep -Eq 'Final-State[[:space:]]*:[[:space:]]*SUCCEEDED' "$tmp/yarn"; then
    echo 'Ожидались тип SPARK и статусы FINISHED / SUCCEEDED' >&2
    exit 1
fi
echo 'Проверки Spark, HDFS и Hive прошли'
