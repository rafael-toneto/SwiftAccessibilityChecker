#!/usr/bin/env python3
"""Obtém/cria SAC Demo no runtime iOS disponível; imprime só o UDID."""
import json
import subprocess
import sys

def sim(*args):
    return subprocess.check_output(['xcrun', 'simctl', *args], text=True)

data = json.loads(sim('list', '--json'))
for devices in data['devices'].values():
    for device in devices:
        if device['name'] == 'SAC Demo' and device.get('isAvailable'):
            print(device['udid'])
            sys.exit(0)
runtimes = [r for r in data['runtimes'] if r.get('isAvailable') and r['identifier'].startswith('com.apple.CoreSimulator.SimRuntime.iOS-')]
if not runtimes:
    sys.exit('Instale um runtime iOS em Xcode > Settings > Components.')
# Preferir 26.5 (usado no ensaio) quando presente; senão o iOS mais recente disponível.
runtime = next((r for r in runtimes if r['version'] == '26.5'), max(runtimes, key=lambda r: tuple(map(int, r['version'].split('.')))))
devices = [d for d in data['devicetypes'] if d.get('productFamily') == 'iPhone']
device_type = next((d for d in devices if d['name'] == 'iPhone 17'), devices[-1])
print(sim('create', 'SAC Demo', device_type['identifier'], runtime['identifier']).strip())
