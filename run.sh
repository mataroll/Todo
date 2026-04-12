#!/bin/bash

SCHEME="Todo"
PROJECT="Todo.xcodeproj"
SIMULATOR="iPhone 17 Pro Max"
SIM_UDID="F555665A-9F8D-436E-86B3-A80E5A38C32A"
DEVICE_ID="00008140-000445623C09801C"

# --- Clean & build for simulator ---
echo "Clean building for simulator..."
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,name=$SIMULATOR" \
  -configuration Debug \
  clean build 2>&1 | tail -5

if [ ${PIPESTATUS[0]} -ne 0 ]; then echo "Simulator build failed."; exit 1; fi

APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -path "*/Build/Products/Debug-iphonesimulator/Todo.app" 2>/dev/null | head -1)
BUNDLE_ID=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showBuildSettings 2>/dev/null | grep "^\s*PRODUCT_BUNDLE_IDENTIFIER " | awk '{print $3}')

echo "Launching on simulator..."
xcrun simctl boot "$SIM_UDID" 2>/dev/null
open -a Simulator
sleep 2
xcrun simctl install "$SIM_UDID" "$APP_PATH"
xcrun simctl launch "$SIM_UDID" "$BUNDLE_ID"
echo "✓ Simulator done"

# --- Real iPhone build (uncomment if device is connected & provisioned) ---
# echo "Building for iPhone..."
# xcodebuild \
#   -project "$PROJECT" \
#   -scheme "$SCHEME" \
#   -destination "platform=iOS,id=$DEVICE_ID" \
#   -configuration Debug \
#   -allowProvisioningUpdates \
#   CODE_SIGN_STYLE=Automatic \
#   DEVELOPMENT_TEAM=LAUYA46MGB \
#   build 2>&1 | tail -8
#
# if [ ${PIPESTATUS[0]} -ne 0 ]; then
#   echo "iPhone build failed. Make sure the device is trusted and unlocked."
# else
#   echo "✓ iPhone done — app installed on Matar's iPhone"
# fi
