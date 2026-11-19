#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

sudo -n systemd-run --unit=hw5-prefect --collect --wait --pipe \
    -p User=team -p WorkingDirectory="$SCRIPT_DIR" \
    -p MemoryMax=1280M -p MemorySwapMax=256M \
    -p RuntimeMaxSec=300 -p OOMPolicy=kill \
    "$SCRIPT_DIR/.venv/bin/python" "$SCRIPT_DIR/flow.py"
