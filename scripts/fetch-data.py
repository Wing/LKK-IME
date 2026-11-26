#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
import hashlib,json,pathlib,urllib.request
ROOT=pathlib.Path(__file__).resolve().parents[1]
lock=json.loads((ROOT/'Resources/data-sources.json').read_text())
for name,item in lock['files'].items():
    target=ROOT/'build/data'/name
    if target.exists() and hashlib.sha256(target.read_bytes()).hexdigest()==item['sha256']:continue
    url=f"https://raw.githubusercontent.com/openvanilla/McBopomofo/{lock['commit']}/{item['path']}"
    data=urllib.request.urlopen(url,timeout=60).read()
    if hashlib.sha256(data).hexdigest()!=item['sha256']:raise SystemExit(f'Checksum mismatch: {name}')
    target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
print('Public data checksums verified')
