#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Generate ordinary SQLite for Manjusri; no legacy databases are read."""
import json,math,pathlib,sqlite3,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[1]
def build(rows,output):
    readings=list(dict.fromkeys(' '.join(r[1]) for r in rows))
    encoded=subprocess.run([str(ROOT/'build/encode-readings'),'encode'],input='\n'.join(readings)+'\n',text=True,capture_output=True,check=True).stdout.splitlines()
    if len(encoded)!=len(readings):raise ValueError('Reading conversion count mismatch')
    mapping=dict(zip(readings,encoded))
    if output.exists():output.unlink()
    with sqlite3.connect(output) as db:
        db.executescript('CREATE TABLE unigrams(qstring TEXT,current TEXT,probability REAL,backoff REAL); CREATE TABLE bigrams(qstring TEXT,previous TEXT,current TEXT,probability REAL); CREATE INDEX unigram_q ON unigrams(qstring); CREATE INDEX bigram_q ON bigrams(qstring);')
        unique=set()
        for word,reading,score in rows:
            q=mapping[' '.join(reading)]
            if not word or len(q)!=len(word)*2 or not math.isfinite(score):raise ValueError('Invalid dictionary row')
            if (q,word) in unique:continue
            unique.add((q,word));db.execute('INSERT INTO unigrams VALUES(?,?,?,0)',(q,word,score))
        db.executemany('INSERT INTO unigrams VALUES(?,?,?,?)',[('*','',-99,0),('!','',0,0),('$','',0,0)])
        if db.execute('PRAGMA integrity_check').fetchone()[0]!='ok':raise ValueError('Integrity check failed')
        count=db.execute('SELECT count(*) FROM unigrams').fetchone()[0]
    print(f'{output.name}: {count} entries; static bigrams: 0')
if __name__=='__main__':
    fixture='--fixture' in sys.argv
    if fixture:
        rows=[('你',['ㄋㄧˇ'],-2),('好',['ㄏㄠˇ'],-2),('郝',['ㄏㄠˇ'],-3),('你好',['ㄋㄧˇ','ㄏㄠˇ'],-1),('他',['ㄊㄚ'],-1),('她',['ㄊㄚ'],-2)]
        build(rows,ROOT/'build/fixture.db')
    else:
        folder=ROOT/'build/data'
        counts={p[0]:int(p[1]) for l in (folder/'phrase.occ').read_text().splitlines() if (p:=l.split()) and not l.startswith('#')}
        for line in (folder/'exclusion.txt').read_text().splitlines():
            p=line.split()
            if len(p)>=2 and not line.startswith('#') and p[0] in p[1] and p[0] in counts and p[1] in counts:counts[p[0]]-=counts[p[1]]
        norm=sum(2.7**(len(w)-1)*max(0,c) for w,c in counts.items())
        if norm<=0:raise ValueError('Invalid frequency normalization')
        preferred=[]
        for name in ['heterophony1.list','heterophony2.list','heterophony3.list']:
            preferred.append({p[0]:p[1] for l in (folder/name).read_text().splitlines() if (p:=l.split()) and not l.startswith('#')})
        rows=[]
        for filename,single in [('BPMFBase.txt',True),('BPMFMappings.txt',False)]:
            for line in (folder/filename).read_text().splitlines():
                p=line.split()
                if not p or line.startswith('#') or len(p)<2:continue
                word=p[0];reading=p[1:2] if single else p[1:]
                if len(word)!=len(reading) or len(word)>7:continue
                score=math.log10(2.7**(len(word)-1)*max(.5,counts.get(word,.5))/norm)
                if len(word)==1 and word in preferred[0] and reading[0]!=preferred[0][word]:
                    if preferred[1].get(word)==reading[0]:score+=math.log10(.75)
                    elif preferred[2].get(word)==reading[0]:score+=math.log10(.5)
                    else:score=-6.8
                rows.append((word,reading,score))
        build(rows,ROOT/'build/model.db')
        (ROOT/'build/model-metadata.json').write_text(json.dumps({'format':1,'source':json.loads((ROOT/'Resources/data-sources.json').read_text()),'normalization':'log10, length scale 2.7, minimum count 0.5','static_bigrams':0},indent=2)+'\n')
