#!/bin/sh
cd "/Users/darkcatxiii/iOS/AT/Swift Learn" || exit 1
rm -f /tmp/sl-git.rc
rm -rf DerivedData/gitcheck-results DerivedData/gitcheck-results.xcresult
xcodebuild test -project "Swift Learn.xcodeproj" -scheme "Swift Learn" \
  -destination "id=058DFC0D-5732-4A75-80CA-B7A5A87EA639" \
  -derivedDataPath DerivedData/order-build \
  -only-testing:"Swift LearnUITests/Swift_LearnUITests/testGitTabCompletesFirstCommandAndUnlocksTheNext" \
  -only-testing:"Swift LearnUITests/Swift_LearnUITests/testGitFinalCommandShowsCompletionCard" \
  -only-testing:"Swift LearnUITests/Swift_LearnUITests/testGitProgressSurvivesRelaunch" \
  -only-testing:"Swift LearnUITests/Swift_LearnUITests/testGitResetClearsGitProgressAndKeepsSwiftProgress" \
  -only-testing:"Swift LearnUITests/Swift_LearnUITests/testGitResetFailureKeepsProgressAndShowsAccessibleError" \
  -only-testing:"Swift LearnUITests/Swift_LearnUITests/testGitCategoryDetailExplainsLockedCommand" \
  -only-testing:"Swift LearnUITests/Swift_LearnUITests/testGitTabSupportsKeyboardAndFocusNavigation" \
  -resultBundlePath DerivedData/gitcheck-results \
  > /tmp/sl-git.log 2>&1
echo $? > /tmp/sl-git.rc
