#!/usr/bin/env bash
set -euo pipefail

sudo -n python3 - <<'PY'
from pathlib import Path
import shutil

hosts = {
    '10.8.0.10': 'team-08-en',
    '10.8.0.11': 'team-08-nn',
    '10.8.0.12': 'team-08-00',
    '10.8.0.13': 'team-08-01',
}
names = {alias for host in hosts.values() for alias in (host, host + '.hse.c.mws')}
path = Path('/etc/hosts')
original = path.read_text()
lines = []
for line in original.splitlines():
    body, sep, comment = line.partition('#')
    fields = body.split()
    if fields and names.intersection(fields[1:]):
        aliases = [name for name in fields[1:] if name not in names]
        if aliases:
            lines.append(fields[0] + '\t' + ' '.join(aliases) + (' #' + comment if sep else ''))
        elif sep:
            lines.append('#' + comment)
    else:
        lines.append(line)
for address, host in hosts.items():
    lines.append(f'{address}\t{host}.hse.c.mws {host}')
updated = '\n'.join(lines) + '\n'
if updated != original:
    backup = Path('/etc/hosts.before-hw3')
    if not backup.exists():
        shutil.copy2(path, backup)
    path.write_text(updated)
print('Имена узлов Hadoop привязаны к внутренним адресам.')
PY
