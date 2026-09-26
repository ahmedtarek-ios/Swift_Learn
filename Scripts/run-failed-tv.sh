#!/bin/sh
cd "/Users/darkcatxiii/iOS/AT/Swift Learn" || exit 1
P="Swift LearnUITests/Swift_LearnUITests"
rm -f /tmp/sl-f-tv.rc
rm -rf DerivedData/failed-tv-results DerivedData/failed-tv-results.xcresult
xcodebuild test -project "Swift Learn.xcodeproj" -scheme "Swift Learn" \
  -destination "id=55CE2A2C-E54C-44EA-9ECA-EE1BA7160B61" \
  -derivedDataPath DerivedData/order-build-tv \
  -only-testing:"$P/testGitTabCompletesFirstCommandAndUnlocksTheNext" \
  -only-testing:"$P/testGitTabSupportsKeyboardAndFocusNavigation" \
  -only-testing:"$P/testGitCategoryDetailExplainsLockedCommand" \
  -only-testing:"$P/testGitFinalCommandShowsCompletionCard" \
  -only-testing:"$P/testGitProgressSurvivesRelaunch" \
  -only-testing:"$P/testGitResetClearsGitProgressAndKeepsSwiftProgress" \
  -only-testing:"$P/testGitResetFailureKeepsProgressAndShowsAccessibleError" \
  -only-testing:"$P/testProfileAvatarSavesLocally" \
  -only-testing:"$P/testProfileBadgeUnlocksAfterCompletingFirstLesson" \
  -only-testing:"$P/testProfileResetStartsLearningFromBeginning" \
  -resultBundlePath DerivedData/failed-tv-results \
  > /tmp/sl-f-tv.log 2>&1
echo $? > /tmp/sl-f-tv.rc
