"""Kontrola serialu SOA z uwzglednieniem rodzaju zdarzenia GitHub."""
import json
import os
import pathlib
import re
import subprocess
import sys

path = sys.argv[1]
event = json.loads(pathlib.Path(os.environ['GITHUB_EVENT_PATH']).read_text())
kind = os.environ['GITHUB_EVENT_NAME']
if kind in ('schedule', 'workflow_dispatch') or os.environ['GITHUB_REF'].startswith('refs/tags/'):
    print('SOA: kontrola porownawcza nie dotyczy tego zdarzenia.')
    sys.exit(0)
base = event['pull_request']['base']['sha'] if kind == 'pull_request' else event.get('before', '')
if not base or set(base) == {'0'}:
    print('SOA: pierwszy push nowej galezi — brak wersji porownawczej.')
    sys.exit(0)
previous = subprocess.run(['git', 'show', f'{base}:{path}'], capture_output=True)
if previous.returncode:
    print('SOA: nowa strefa — brak poprzedniej wersji.')
    sys.exit(0)
current = pathlib.Path(path).read_bytes()
if current == previous.stdout:
    print('SOA: plik strefy nie zostal zmieniony.')
    sys.exit(0)

def serial(data):
    text = '\n'.join(line.split(';', 1)[0] for line in data.decode().splitlines())
    match = re.search(r'\bSOA\s+\S+\s+\S+\s*\(?\s*(\d+)', text, re.I)
    if not match:
        raise SystemExit('Nie znaleziono numeru SOA.')
    return int(match.group(1))

old, new = serial(previous.stdout), serial(current)
print(f'SOA {path}: poprzedni={old}, nowy={new}')
if new <= old:
    raise SystemExit('Zmieniono strefe bez zwiekszenia numeru SOA.')
