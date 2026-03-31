#!/bin/bash

SCHEME="Todo"
PROJECT="Todo.xcodeproj"
SIMULATOR="iPhone 17"
DEVICE_ID="00008140-000445623C09801C"

# --- Simulator build ---
echo "Building for simulator..."
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,name=$SIMULATOR" \
  -configuration Debug \
  build 2>&1 | tail -5

if [ ${PIPESTATUS[0]} -ne 0 ]; then echo "Simulator build failed."; exit 1; fi

APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "Todo.app" 2>/dev/null | grep iphonesimulator | head -1)
BUNDLE_ID=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showBuildSettings 2>/dev/null | grep "^\s*PRODUCT_BUNDLE_IDENTIFIER " | awk '{print $3}')

echo "Launching on simulator..."
open -a Simulator
sleep 1
xcrun simctl install booted "$APP_PATH"
xcrun simctl launch booted "$BUNDLE_ID"
echo "✓ Simulator done"

# --- Real iPhone build ---
echo "Building for iPhone..."
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "platform=iOS,id=$DEVICE_ID" \
  -configuration Debug \
  -allowProvisioningUpdates \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=LAUYA46MGB \
  build 2>&1 | tail -8

if [ ${PIPESTATUS[0]} -ne 0 ]; then
  echo "iPhone build failed. Make sure the device is trusted and unlocked."
else
  echo "✓ iPhone done — app installed on Matar's iPhone"
fi
