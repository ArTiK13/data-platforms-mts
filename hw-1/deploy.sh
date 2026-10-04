#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
EDGE=data-platforms-course
PASSWORD_FILE="$SCRIPT_DIR/.cluster-password"

if [[ ! -f "$PASSWORD_FILE" ]]; then
    umask 077
    openssl rand -base64 32 > "$PASSWORD_FILE"
fi

ssh "$EDGE" 'mkdir -p ~/hw-1-hdfs'
scp -q \
    "$SCRIPT_DIR/edge-deploy.sh" \
    "$SCRIPT_DIR/node-setup.sh" \
    "$SCRIPT_DIR/check.sh" \
    "$PASSWORD_FILE" \
    "$EDGE:hw-1-hdfs/"
ssh "$EDGE" 'chmod 600 ~/hw-1-hdfs/.cluster-password; bash ~/hw-1-hdfs/edge-deploy.sh'

echo "Password for hadoop: $PASSWORD_FILE"

