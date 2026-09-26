#!/bin/sh
for p in iphone ipad mac tv; do
  rc=$(cat "/tmp/sl-ui-$p.rc" 2>/dev/null || echo running)
  passed=$(grep -c "' passed (" "/tmp/sl-ui-$p.log" 2>/dev/null || echo 0)
  failed=$(grep -c "' failed (" "/tmp/sl-ui-$p.log" 2>/dev/null || echo 0)
  printf '%s rc=%s passed=%s failed=%s\n' "$p" "$rc" "$passed" "$failed"
done
printf 'overall=%s free=%s\n' "$(cat /tmp/sl-ui-all.status 2>/dev/null || echo running)" "$(df -h / | awk 'NR==2{print $4}')"
