#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Generate the existing phrase converter's CIN format from OpenCC 1.1.9.

The generated mappings are derived from Apache-2.0 licensed OpenCC data.
The source dictionaries and their license are retained separately.
"""
import pathlib
import sys

source, output, character_output = map(pathlib.Path, sys.argv[1:4])

def read(name):
    for line in (source / name).read_text(encoding='utf-8').splitlines():
        if not line or line.startswith('#'):
            continue
        key, values = line.split('\t', 1)
        yield key, values.split()

characters = {key: values[0] for key, values in read('TSCharacters.txt')}
phrases = {key: values[0] for key, values in read('TSPhrases.txt')}
def simplify(word):
    return phrases.get(word, ''.join(characters.get(char, char) for char in word))

result = dict(phrases)
for filename in ('TWPhrasesIT.txt', 'TWPhrasesName.txt', 'TWPhrasesOther.txt'):
    for mainland, taiwanese in read(filename):
        for word in taiwanese:
            result.setdefault(word, simplify(mainland))

with output.open('w', encoding='utf-8') as out:
    out.write('# Derived from OpenCC ver.1.1.9 (Apache-2.0); converted to CIN by LKK-IME.\n')
    out.write('%gen_inp\n%ename Phrase Conversion\n%cname 全詞轉換\n%tcname 全詞轉換\n%scname 全词转换\n%keyname begin\n%keyname end\n%chardef begin\n')
    for key, value in sorted(result.items()):
        if key != value and len(key) > 1 and not any(c.isspace() for c in key + value):
            out.write(f'{key} {value}\n')
    out.write('%chardef end\n')

for filename, symbol in [('SC' + 'T', 'vxSC2TCTable'), ('TC' + 'S', 'vxTC2SCTable')]:
    dictionary = 'STCharacters.txt' if filename == 'SCT' else 'TSCharacters.txt'
    table = sorted((ord(key), ord(values[0])) for key, values in read(dictionary)
                   if len(key) == len(values[0]) == 1 and ord(key) <= 0xffff and ord(values[0]) <= 0xffff)
    output_path = character_output / ('VXHCSC2TCTable.c' if filename == 'SCT' else 'VXHCTC2SCTable.c')
    with output_path.open('w', encoding='utf-8') as out:
        out.write('/* Derived from OpenCC ver.1.1.9 (Apache-2.0); converted to C pairs by LKK-IME. */\n#include <stddef.h>\n')
        out.write(f'const size_t {symbol}Size = {len(table)};\nunsigned short {symbol}[] = {{\n')
        for key, value in table:
            out.write(f'    0x{key:04x}, 0x{value:04x},\n')
        out.write('};\n')
