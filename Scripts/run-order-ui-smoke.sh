#!/bin/sh
cd "/Users/darkcatxiii/iOS/AT/Swift Learn" || exit 1
rm -f /tmp/sl-ui.status
rm -rf DerivedData/order-ui-results.xcresult
xcodebuild test \
  -project "Swift Learn.xcodeproj" \
  -scheme "Swift Learn" \
  -destination "id=058DFC0D-5732-4A75-80CA-B7A5A87EA639" \
  -derivedDataPath DerivedData/order-build \
  -only-testing:"Swift LearnUITests/Swift_LearnUITests/testLessonAnswersAreShuffledBetweenAttempts" \
  -only-testing:"Swift LearnUITests/Swift_LearnUITests/testLessonAnswerOrderIsStableWithinAnAttemptAndAnsweredByIdentifier" \
  -resultBundlePath DerivedData/order-ui-results \
  > /tmp/sl-ui.log 2>&1
echo $? > /tmp/sl-ui.status
