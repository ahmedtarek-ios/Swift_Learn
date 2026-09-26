#!/bin/sh
cd /tmp/sl-baseline || exit 1
rm -f /tmp/sl-base-mac.rc
rm -rf /tmp/sl-baseline-mac-results /tmp/sl-baseline-mac-results.xcresult
xcodebuild test \
  -project "Swift Learn.xcodeproj" \
  -scheme "Swift Learn" \
  -destination "platform=macOS,arch=arm64" \
  -derivedDataPath /tmp/sl-baseline-dd-mac \
  -only-testing:"Swift LearnUITests/Swift_LearnUITests/testCompletesFirstLessonAndUpdatesProgress" \
  -resultBundlePath /tmp/sl-baseline-mac-results \
  > /tmp/sl-base-mac.log 2>&1
echo $? > /tmp/sl-base-mac.rc
