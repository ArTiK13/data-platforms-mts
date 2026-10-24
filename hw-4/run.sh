#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

cd /var/lib/spark
"${SPARK[@]}" /opt/spark/bin/spark-submit \
    --master yarn \
    --deploy-mode client \
    /var/lib/spark/job.py
