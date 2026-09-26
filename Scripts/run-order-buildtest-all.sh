#!/bin/sh
cd "/Users/darkcatxiii/iOS/AT/Swift Learn" || exit 1
rm -f /tmp/sl-bt-all.status
{
  echo "=== macOS"
  xcodebuild build-for-testing -project "Swift Learn.xcodeproj" -scheme "Swift Learn" \
    -destination "platform=macOS,arch=arm64" -derivedDataPath DerivedData/order-build-mac
  echo "mac=$?"
  echo "=== tvOS"
  xcodebuild build-for-testing -project "Swift Learn.xcodeproj" -scheme "Swift Learn" \
    -destination "id=55CE2A2C-E54C-44EA-9ECA-EE1BA7160B61" -derivedDataPath DerivedData/order-build-tv
  echo "tv=$?"
  echo "=== watchOS app"
  xcodebuild build -project "Swift Learn.xcodeproj" -scheme "Swift Learn Watch App" \
    -destination "generic/platform=watchOS Simulator" -derivedDataPath DerivedData/order-build-watch
  echo "watch=$?"
} > /tmp/sl-bt-all.log 2>&1
echo done > /tmp/sl-bt-all.status
