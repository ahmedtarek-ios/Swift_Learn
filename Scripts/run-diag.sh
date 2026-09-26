#!/bin/sh
cd "/Users/darkcatxiii/iOS/AT/Swift Learn" || exit 1
rm -f /tmp/sl-diag-$1.rc
xcodebuild test -project "Swift Learn.xcodeproj" -scheme "Swift Learn" \
  -destination "$2" \
  -derivedDataPath "DerivedData/$3" \
  -only-testing:"Swift LearnUITests/TabDiagnosticsUITests/testDumpGitTab" \
  > "/tmp/sl-diag-$1.log" 2>&1
echo $? > "/tmp/sl-diag-$1.rc"
