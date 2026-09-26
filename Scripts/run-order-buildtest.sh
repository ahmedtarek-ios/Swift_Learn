#!/bin/sh
cd "/Users/darkcatxiii/iOS/AT/Swift Learn" || exit 1
rm -f /tmp/sl-bt.status
xcodebuild build-for-testing \
  -project "Swift Learn.xcodeproj" \
  -scheme "Swift Learn" \
  -destination "id=058DFC0D-5732-4A75-80CA-B7A5A87EA639" \
  -derivedDataPath DerivedData/order-build \
  > /tmp/sl-bt.log 2>&1
echo $? > /tmp/sl-bt.status
