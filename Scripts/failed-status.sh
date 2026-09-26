#!/bin/sh
cd "/Users/darkcatxiii/iOS/AT/Swift Learn" || exit 1
for p in mac iphone ipad tv; do
  rc=$(cat "/tmp/sl-f-$p.rc" 2>/dev/null || echo running)
  line="$p rc=$rc"
  if [ -d "DerivedData/failed-$p-results.xcresult" ]; then
    s=$(xcrun xcresulttool get test-results summary --path "DerivedData/failed-$p-results.xcresult" --format json 2>/dev/null | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d.get("passedTests"),d.get("failedTests"))' 2>/dev/null)
    line="$line passed/failed=$s"
  fi
  echo "$line"
done
echo "overall=$(cat /tmp/sl-f-all.status 2>/dev/null || echo running) free=$(df -h / | awk 'NR==2{print $4}')"
