#!/bin/sh
# Re-runs only the tests that failed in the last full pass, per platform.
cd "/Users/darkcatxiii/iOS/AT/Swift Learn" || exit 1
PROJ="Swift Learn.xcodeproj"
SCHEME="Swift Learn"
P="Swift LearnUITests/Swift_LearnUITests"
rm -f /tmp/sl-f-*.rc /tmp/sl-f-all.status

GIT7="-only-testing:$P/testGitTabCompletesFirstCommandAndUnlocksTheNext
-only-testing:$P/testGitTabSupportsKeyboardAndFocusNavigation
-only-testing:$P/testGitCategoryDetailExplainsLockedCommand
-only-testing:$P/testGitFinalCommandShowsCompletionCard
-only-testing:$P/testGitProgressSurvivesRelaunch
-only-testing:$P/testGitResetClearsGitProgressAndKeepsSwiftProgress
-only-testing:$P/testGitResetFailureKeepsProgressAndShowsAccessibleError"

run() { # 1=name 2=destination 3=derivedData 4=extra only-testing args
  rm -rf "DerivedData/failed-$1-results" "DerivedData/failed-$1-results.xcresult"
  # shellcheck disable=SC2086
  IFS='
'
  set -f
  xcodebuild test -project "$PROJ" -scheme "$SCHEME" \
    -destination "$2" -derivedDataPath "DerivedData/$3" \
    $GIT7 $4 \
    -resultBundlePath "DerivedData/failed-$1-results" \
    > "/tmp/sl-f-$1.log" 2>&1
  echo $? > "/tmp/sl-f-$1.rc"
  set +f
  unset IFS
}

MAC_EXTRA="-only-testing:$P/testProfileBadgeUnlocksAfterCompletingFirstLesson
-only-testing:$P/testProfileResetStartsLearningFromBeginning
-only-testing:$P/testResumeAndLockedReasonUseTheCurrentJourney"

TV_EXTRA="-only-testing:$P/testProfileAvatarSavesLocally
-only-testing:$P/testProfileBadgeUnlocksAfterCompletingFirstLesson
-only-testing:$P/testProfileResetStartsLearningFromBeginning"

xcrun simctl shutdown all >/dev/null 2>&1
killall Simulator >/dev/null 2>&1
sleep 5
run mac    "platform=macOS,arch=arm64"                order-build-mac "$MAC_EXTRA"
run iphone "id=058DFC0D-5732-4A75-80CA-B7A5A87EA639"  order-build     ""
run ipad   "id=AE496069-87D8-4C2D-B8E7-3E9ACCB67A72"  order-build     ""
run tv     "id=55CE2A2C-E54C-44EA-9ECA-EE1BA7160B61"  order-build-tv  "$TV_EXTRA"

echo done > /tmp/sl-f-all.status
