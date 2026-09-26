#!/bin/sh
cd "/Users/darkcatxiii/iOS/AT/Swift Learn" || exit 1
rm -f /tmp/sl-unit.status
rm -rf DerivedData/order-unit-results DerivedData/order-unit-results.xcresult
xcodebuild test \
  -project "Swift Learn.xcodeproj" \
  -scheme "Swift Learn" \
  -destination "id=058DFC0D-5732-4A75-80CA-B7A5A87EA639" \
  -derivedDataPath DerivedData/order-build \
  -only-testing:"Swift LearnTests" \
  -resultBundlePath DerivedData/order-unit-results \
  > /tmp/sl-unit.log 2>&1
echo $? > /tmp/sl-unit.status
