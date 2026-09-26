#!/bin/sh
# $1 = derived data dir name
cd "/Users/darkcatxiii/iOS/AT/Swift Learn" || exit 1
BUNDLE=$(ls -td "DerivedData/$1/Logs/Test/"*.xcresult 2>/dev/null | head -1)
echo "bundle=$BUNDLE"
xcrun xcresulttool get test-results tests --path "$BUNDLE" --format json > /tmp/dg.json 2>/tmp/dg.err
python3 - <<'PY'
import json
try:
    d=json.load(open('/tmp/dg.json'))
except Exception as e:
    print('parse error', e); raise SystemExit
out=[]
def walk(n):
    if isinstance(n,dict):
        if n.get('nodeType')=='Failure Message': out.append(n.get('name'))
        for v in n.values(): walk(v)
    elif isinstance(n,list):
        for v in n: walk(v)
walk(d)
print(out[0] if out else 'no failure message')
PY
