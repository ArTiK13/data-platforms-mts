#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

ssh "$EDGE" 'mkdir -p ~/hw4-spark'
scp -r "$SCRIPT_DIR"/{common.sh,edge-deploy.sh,run.sh,check.sh,job.py,config,sql,data} "$EDGE:hw4-spark/"
ssh "$EDGE" 'bash ~/hw4-spark/edge-deploy.sh'
