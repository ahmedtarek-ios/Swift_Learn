#!/bin/sh
cd /tmp/sl-baseline || exit 1
rm -f /tmp/sl-base.rc
xcodebuild test \
  -project "Swift Learn.xcodeproj" \
  -scheme "Swift Learn" \
  -destination "id=058DFC0D-5732-4A75-80CA-B7A5A87EA639" \
  -derivedDataPath /tmp/sl-baseline-dd \
  -only-testing:"Swift LearnUITests/Swift_LearnUITests/testGitTabCompletesFirstCommandAndUnlocksTheNext" \
  -resultBundlePath /tmp/sl-baseline-results \
  > /tmp/sl-base.log 2>&1
echo $? > /tmp/sl-base.rc
