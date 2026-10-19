#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

if [[ ${1:-} == --tunnel ]]; then
    exec ssh -N -o ExitOnForwardFailure=yes -L 127.0.0.1:10000:127.0.0.1:10000 "$EDGE"
fi
if [[ $# != 0 ]]; then
    echo 'Use: deploy.sh [--tunnel]' >&2
    exit 1
fi

ssh "$EDGE" 'mkdir -p ~/hw3-hive'
scp -r "$SCRIPT_DIR"/{common.sh,edge-deploy.sh,node-setup.sh,load-data.sh,check.sh,config,sql,data} "$EDGE:hw3-hive/"
ssh "$EDGE" 'bash ~/hw3-hive/edge-deploy.sh'
