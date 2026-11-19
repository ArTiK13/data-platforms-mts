#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

ssh data-platforms-course 'mkdir -p ~/hw5-prefect'
scp "$SCRIPT_DIR"/{flow.py,run.sh} data-platforms-course:hw5-prefect/
ssh data-platforms-course bash -s <<'SH'
set -euo pipefail
sudo -n apt-get install -y python3-venv
cd ~/hw5-prefect
python3 -m venv .venv
.venv/bin/pip install prefect==3.9.3
bash run.sh
bash ~/hw4-spark/check.sh
SH
