#!/bin/sh
# One authorized run of the full UI suite per platform. No retries.
cd "/Users/darkcatxiii/iOS/AT/Swift Learn" || exit 1
PROJ="Swift Learn.xcodeproj"
SCHEME="Swift Learn"
rm -f /tmp/sl-ui-all.status /tmp/sl-ui-*.rc

run() { # name destination derivedData
  rm -rf "DerivedData/orderui-$1-results" "DerivedData/orderui-$1-results.xcresult"
  xcodebuild test -project "$PROJ" -scheme "$SCHEME" \
    -destination "$2" \
    -derivedDataPath "DerivedData/$3" \
    -only-testing:"Swift LearnUITests" \
    -resultBundlePath "DerivedData/orderui-$1-results" \
    > "/tmp/sl-ui-$1.log" 2>&1
  echo $? > "/tmp/sl-ui-$1.rc"
}

run mac    "platform=macOS,arch=arm64"                order-build-mac
run iphone "id=058DFC0D-5732-4A75-80CA-B7A5A87EA639" order-build
run ipad   "id=AE496069-87D8-4C2D-B8E7-3E9ACCB67A72" order-build
run tv     "id=55CE2A2C-E54C-44EA-9ECA-EE1BA7160B61"  order-build-tv

echo done > /tmp/sl-ui-all.status
