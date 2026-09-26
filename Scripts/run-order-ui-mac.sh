#!/bin/sh
cd "/Users/darkcatxiii/iOS/AT/Swift Learn" || exit 1
rm -f /tmp/sl-ui-mac.rc
rm -rf DerivedData/orderui-mac-results DerivedData/orderui-mac-results.xcresult
xcodebuild test \
  -project "Swift Learn.xcodeproj" \
  -scheme "Swift Learn" \
  -destination "platform=macOS,arch=arm64" \
  -derivedDataPath DerivedData/order-build-mac \
  -only-testing:"Swift LearnUITests" \
  -resultBundlePath DerivedData/orderui-mac-results \
  > /tmp/sl-ui-mac.log 2>&1
echo $? > /tmp/sl-ui-mac.rc
