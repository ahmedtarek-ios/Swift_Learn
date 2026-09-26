#!/bin/sh
# $1 = result bundle path relative to project (no .xcresult)
cd "/Users/darkcatxiii/iOS/AT/Swift Learn" || exit 1
xcrun xcresulttool get test-results tests --path "$1.xcresult" --format json > /tmp/dr.json 2>/dev/null
python3 - <<'PY'
import json
d=json.load(open('/tmp/dr.json'))
out=[]
def walk(n,ctx=None):
    if isinstance(n,dict):
        name=n.get('name') if n.get('nodeType')=='Test Case' else ctx
        if n.get('nodeType')=='Failure Message': out.append((ctx,n.get('name')))
        for v in n.values(): walk(v,name)
    elif isinstance(n,list):
        for v in n: walk(v,ctx)
walk(d)
seen=set()
for c,m in out:
    if c in seen: continue
    seen.add(c); print(c,'::',m[:200])
PY
