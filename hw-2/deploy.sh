#!/usr/bin/env bash
set -euo pipefail

if [[ ${1:-} != --web ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

    ssh "team@2.59.83.169" 'mkdir -p ~/hw2-yarn'
    scp -r \
        "$SCRIPT_DIR"/{common.sh,edge-deploy.sh,node-setup.sh,check.sh,config} \
        "team@2.59.83.169:hw2-yarn/"
    ssh "team@2.59.83.169" 'bash ~/hw2-yarn/edge-deploy.sh'

    PAGES=(
        8444/cluster 8445/jobhistory 8446/dfshealth.html 8447/status.html
        8448/datanode.html 8449/datanode.html 8450/datanode.html
        8451/node 8452/node 8453/node
    )
    ssh "team@2.59.83.169" bash -s -- "${PAGES[@]}" <<'SH'
set -euo pipefail
for page in "$@"; do
    url="http://127.0.0.1:$page"
    status=$(curl --noproxy '*' -fsS --connect-timeout 5 --max-time 15 -o /dev/null -w '%{http_code}' "$url") && \
        [[ $status == 200 ]] || { echo "Ошибка проверки: $url (HTTP $status)" >&2; exit 1; }
    printf 'OK: %s\n' "$url"
done
SH
fi

printf 'ResourceManager: http://127.0.0.1:8444/cluster\n'
exec ssh -N -o ExitOnForwardFailure=yes \
    -L 127.0.0.1:8444:127.0.0.1:8444 \
    -L 127.0.0.1:8445:127.0.0.1:8445 \
    -L 127.0.0.1:8446:127.0.0.1:8446 \
    -L 127.0.0.1:8447:127.0.0.1:8447 \
    -L 127.0.0.1:8448:127.0.0.1:8448 \
    -L 127.0.0.1:8449:127.0.0.1:8449 \
    -L 127.0.0.1:8450:127.0.0.1:8450 \
    -L 127.0.0.1:8451:127.0.0.1:8451 \
    -L 127.0.0.1:8452:127.0.0.1:8452 \
    -L 127.0.0.1:8453:127.0.0.1:8453 \
    team@2.59.83.169
