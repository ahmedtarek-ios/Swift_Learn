#!/bin/zsh
# Paired-simulator proof for Apple Watch <-> iPhone synchronization.
# Verifies that a review answer queued on the Watch reaches the paired iPhone
# and comes back as an acknowledgement in the next snapshot.
#
# Usage: Scripts/verify_watch_pair_sync.sh <phone-udid> <watch-udid>
set -u
PHONE=${1:?phone simulator udid}
WATCH=${2:?watch simulator udid}
BUNDLE=com.ata.Swift-Learn
WATCH_BUNDLE=com.ata.Swift-Learn.watchkitapp

defaults_path() {
  local container
  container=$(xcrun simctl get_app_container "$WATCH" "$WATCH_BUNDLE" data 2>/dev/null) || return 1
  echo "$container/Library/Preferences/$WATCH_BUNDLE.plist"
}

pending_count() {
  local plist
  plist=$(defaults_path) || { echo "unknown"; return; }
  /usr/bin/python3 - "$plist" <<'PY'
import json, plistlib, sys
try:
    with open(sys.argv[1], 'rb') as handle:
        data = plistlib.load(handle)
except Exception:
    print('unknown')
    raise SystemExit
raw = data.get('swiftLearn.watch.sync.pending.v1')
if raw is None:
    print(0)
else:
    print(len(json.loads(bytes(raw))))
PY
}

echo "Pending Watch events before foregrounding iPhone: $(pending_count)"
xcrun simctl launch "$PHONE" "$BUNDLE" --ui-testing-persistent --skip-intro > /dev/null
sleep 20
xcrun simctl launch "$WATCH" "$WATCH_BUNDLE" > /dev/null
sleep 20
echo "Pending Watch events after the round trip: $(pending_count)"
