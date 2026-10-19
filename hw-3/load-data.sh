#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

sudo -n install -o hadoop -g hadoop -m 0640 "$SCRIPT_DIR"/data/*.csv /var/lib/hive/import/
"${BEELINE[@]}" -f /dev/stdin < "$SCRIPT_DIR/sql/load.sql"
