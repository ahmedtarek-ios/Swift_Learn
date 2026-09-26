#!/bin/sh
cd "/Users/darkcatxiii/iOS/AT/Swift Learn" || exit 1
PROJ="Swift Learn.xcodeproj"
SCHEME="Swift Learn"
rm -f /tmp/sl-v-*.rc /tmp/sl-v-all.status

ORDER_TESTS='-only-testing:Swift LearnUITests/Swift_LearnUITests/testLessonAnswersAreNotShownInTheAuthoredOrder'

run_unit() {
  rm -rf "DerivedData/verify-unit-results" "DerivedData/verify-unit-results.xcresult"
  xcodebuild test -project "$PROJ" -scheme "$SCHEME" \
    -destination "id=058DFC0D-5732-4A75-80CA-B7A5A87EA639" \
    -derivedDataPath DerivedData/order-build \
    -only-testing:"Swift LearnTests" \
    -resultBundlePath DerivedData/verify-unit-results \
    > /tmp/sl-v-unit.log 2>&1
  echo $? > /tmp/sl-v-unit.rc
}

run_ui() { # name destination derivedData
  rm -rf "DerivedData/verify-$1-results" "DerivedData/verify-$1-results.xcresult"
  xcodebuild test -project "$PROJ" -scheme "$SCHEME" \
    -destination "$2" \
    -derivedDataPath "DerivedData/$3" \
    -only-testing:"Swift LearnUITests/Swift_LearnUITests/testLessonAnswersAreNotShownInTheAuthoredOrder" \
    -only-testing:"Swift LearnUITests/Swift_LearnUITests/testLessonAnswerOrderIsStableWithinAnAttemptAndAnsweredByIdentifier" \
    -resultBundlePath "DerivedData/verify-$1-results" \
    > "/tmp/sl-v-$1.log" 2>&1
  echo $? > "/tmp/sl-v-$1.rc"
}

run_unit
run_ui iphone "id=058DFC0D-5732-4A75-80CA-B7A5A87EA639" order-build
run_ui ipad   "id=AE496069-87D8-4C2D-B8E7-3E9ACCB67A72" order-build
run_ui tv     "id=55CE2A2C-E54C-44EA-9ECA-EE1BA7160B61" order-build-tv

echo done > /tmp/sl-v-all.status
