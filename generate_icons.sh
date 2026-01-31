#!/bin/bash

echo "=== Generating app icons from logo.png ==="
echo ""

# Run flutter pub get
echo "Step 1: Running flutter pub get..."
fvm flutter pub get

echo ""
echo "Step 2: Running flutter_launcher_icons..."
fvm dart run flutter_launcher_icons

echo ""
echo "=== Done! ==="
echo ""
echo "Checking generated icons..."
echo ""

# Check Android icons
if [ -d "android/app/src/main/res/mipmap-hdpi" ]; then
  echo "✅ Android icons generated:"
  ls -1 android/app/src/main/res/mipmap-hdpi/
else
  echo "❌ Android icons not found"
fi

echo ""

# Check iOS icons
if [ -d "ios/Runner/Assets.xcassets/AppIcon.appiconset" ]; then
  echo "✅ iOS icons generated:"
  ls -1 ios/Runner/Assets.xcassets/AppIcon.appiconset/ | grep -E "\.png$"
else
  echo "❌ iOS icons not found"
fi

echo ""
echo "Icon generation complete!"

