#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Merge a redistributable Manjusri model with the original CIN tables."""
import pathlib
import collections
import sqlite3
import subprocess
import sys

here = pathlib.Path(__file__).resolve().parent
tables = here.parents[2] / 'DataTables'
model, output, encoder = map(pathlib.Path, sys.argv[1:4])
if output.exists():
    raise SystemExit('Refusing to overwrite an existing database')

def cin(path):
    section = None
    for line in path.read_text(encoding='utf-8-sig').splitlines():
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        parts = line.split(maxsplit=1)
        if len(parts) != 2:
            continue
        key, value = parts
        if key in ('%chardef', '%keyname'):
            section = key if value.lower() == 'begin' else None
        elif section == '%chardef':
            yield key, value
        elif section == '%keyname':
            yield '__property_keyname-' + key, value
        elif key.startswith('%'):
            yield '__property_' + key[1:], value

with sqlite3.connect(model) as source, sqlite3.connect(output) as db:
    source.backup(db)
    db.executescript((here / 'Schema.sql').read_text())
    db.execute('CREATE TABLE cooked_information(key, value)')
    db.execute('INSERT INTO cooked_information VALUES (?, ?)', ('version', '1.1.2528'))
    phonetic = list(cin(tables / 'bpmf-ext.cin'))
    keys = list(dict.fromkeys(k for k, v in phonetic if not k.startswith('__property_')))
    coded = subprocess.run([str(encoder), 'standard'], input='\n'.join(keys) + '\n', text=True, capture_output=True, check=True).stdout.splitlines()
    if len(coded) != len(keys):
        raise ValueError('Invalid standard layout conversion')
    enc = dict(zip(keys, coded))
    db.executemany('INSERT INTO "Mandarin-bpmf-cin" VALUES(?,?)', ((enc.get(k, k), v) for k, v in phonetic))
    punct = [(k,v) for k,v in cin(tables / 'bpmf-punctuations.cin') if not k.startswith('__property_')]
    db.executemany('INSERT INTO "Mandarin-bpmf-cin" VALUES(?,?)', punct)
    counts = collections.Counter()
    for key, value in punct:
        # Preserve the upstream candidate order within each key.
        index = counts[key]
        counts[key] += 1
        db.execute('INSERT INTO unigrams VALUES(?,?,?,?)', (key, value, -1.0 - index * 0.1, 0.0))
    for filename, table in [
        ('cj-ext.cin', 'Generic-cj-cin'),
        ('simplex-ext.cin', 'Generic-simplex-cin'),
        ('cj-punctuations-halfwidth.cin', 'Punctuations-cj-halfwidth-cin'),
        ('cj-punctuations-mixedwidth.cin', 'Punctuations-cj-mixedwidth-cin'),
        ('bopomofo-correction.cin', 'BopomofoCorrection-bopomofo-correction-cin'),
    ]:
        db.executemany(f'INSERT INTO "{table}" VALUES(?,?)', cin(tables / filename))
    db.execute('CREATE TABLE associated_phrases(headchar, data)')
    db.execute('CREATE INDEX associated_phrases_index ON associated_phrases(headchar)')
    associated = collections.defaultdict(dict)
    for word, score in db.execute('SELECT current, MAX(probability) FROM unigrams GROUP BY current'):
        if 2 <= len(word) < 5 and score > -6 and '\u4e00' <= word[0] <= '\u9fff' and ',' not in word:
            associated[word[0]][word[1:]] = score
    db.executemany('INSERT INTO associated_phrases VALUES(?,?)', ((head, ','.join(sorted(items, key=items.get, reverse=True))) for head, items in associated.items()))
    db.execute('CREATE INDEX unigrams_current_index ON unigrams(current)')
    assert db.execute('PRAGMA integrity_check').fetchone()[0] == 'ok'
    print('Punctuation keys:', len(counts), 'entries:', len(punct))
    for table in ('unigrams', 'bigrams', 'Mandarin-bpmf-cin', 'Generic-cj-cin', 'Generic-simplex-cin', 'associated_phrases'):
        print(table, db.execute(f'SELECT count(*) FROM "{table}"').fetchone()[0])
