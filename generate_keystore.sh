#!/bin/bash

# Generate Android keystore for Flux app
# This script creates a keystore file for signing the Android app

KEYSTORE_PATH="$HOME/flux-upload-keystore.jks"
ALIAS="flux-upload-key"

echo "Generating Android keystore for Flux..."
echo "Keystore will be saved to: $KEYSTORE_PATH"
echo ""
echo "Please enter the following information:"
echo ""

# Generate keystore with user input
keytool -genkey -v \
  -keystore "$KEYSTORE_PATH" \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias "$ALIAS"

if [ $? -eq 0 ]; then
  echo ""
  echo "✅ Keystore created successfully!"
  echo ""
  echo "📝 Important information:"
  echo "   Keystore path: $KEYSTORE_PATH"
  echo "   Alias: $ALIAS"
  echo ""
  echo "⚠️  IMPORTANT: Save your keystore password securely!"
  echo "   You will need it to sign your app for Google Play Store."
  echo ""
  echo "Next steps:"
  echo "1. Create android/key.properties file with your keystore info"
  echo "2. Update android/app/build.gradle to use the keystore"
  echo "3. Build release APK/AAB: flutter build appbundle --release"
else
  echo ""
  echo "❌ Failed to create keystore"
  exit 1
fi

