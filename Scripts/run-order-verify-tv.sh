#!/bin/sh
cd "/Users/darkcatxiii/iOS/AT/Swift Learn" || exit 1
rm -f /tmp/sl-v-tv.rc
rm -rf DerivedData/verify-tv-results DerivedData/verify-tv-results.xcresult
xcodebuild test -project "Swift Learn.xcodeproj" -scheme "Swift Learn" \
  -destination "id=55CE2A2C-E54C-44EA-9ECA-EE1BA7160B61" \
  -derivedDataPath DerivedData/order-build-tv \
  -only-testing:"Swift LearnUITests/Swift_LearnUITests/testLessonAnswersAreNotShownInTheAuthoredOrder" \
  -only-testing:"Swift LearnUITests/Swift_LearnUITests/testLessonAnswerOrderIsStableWithinAnAttemptAndAnsweredByIdentifier" \
  -resultBundlePath DerivedData/verify-tv-results \
  > /tmp/sl-v-tv.log 2>&1
echo $? > /tmp/sl-v-tv.rc
