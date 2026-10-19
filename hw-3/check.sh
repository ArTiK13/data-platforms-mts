#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

systemctl is-active --quiet postgresql hive-metastore hive-server2
"${HIVE[@]}" /opt/hive/bin/schematool -dbType postgres -info

temporary=$(mktemp -d)
clients=()
cleanup() {
    for pid in "${clients[@]}"; do
        kill "$pid" 2>/dev/null || true
    done
    rm -rf "$temporary"
}
trap cleanup EXIT

"${BEELINE[@]}" -f /dev/stdin < "$SCRIPT_DIR/sql/check.sql" > "$temporary/actual"
diff -u "$SCRIPT_DIR/data/expected.tsv" "$temporary/actual"
echo 'Две партиции и все шесть событий читаются через HiveServer2.'

mkfifo "$temporary/first.in" "$temporary/second.in"
"${BEELINE[@]}" < "$temporary/first.in" > "$temporary/first.out" 2> "$temporary/first.log" &
clients+=("$!")
exec 3> "$temporary/first.in"
"${BEELINE[@]}" 3>&- < "$temporary/second.in" > "$temporary/second.out" 2> "$temporary/second.log" &
clients+=("$!")
exec 4> "$temporary/second.in"
printf "SELECT 'first_client', event_id FROM hw3.events WHERE dt='2026-10-01' AND event_id=1;\n" >&3
printf "SELECT 'second_client', event_id FROM hw3.events WHERE dt='2026-10-02' AND event_id=4;\n" >&4

ready=false
for _ in {1..60}; do
    if grep -qx $'first_client\t1' "$temporary/first.out" && \
       grep -qx $'second_client\t4' "$temporary/second.out"; then
        ready=true
        break
    fi
    if ! kill -0 "${clients[0]}" 2>/dev/null || ! kill -0 "${clients[1]}" 2>/dev/null; then
        break
    fi
    sleep 2
done
if [[ $ready != true ]]; then
    cat "$temporary/first.log" "$temporary/second.log" >&2
    echo 'Не дождались результатов от двух одновременно открытых клиентов' >&2
    exit 1
fi

printf '!quit\n' >&3
printf '!quit\n' >&4
exec 3>&- 4>&-
for pid in "${clients[@]}"; do
    wait "$pid"
done
clients=()
echo 'Два клиента одновременно держали сессии и прочитали данные.'
echo 'Все проверки Hive прошли.'
