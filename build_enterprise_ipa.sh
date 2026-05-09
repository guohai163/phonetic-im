#!/usr/bin/env bash
set -euo pipefail

# ===== Config (edit if needed) =====
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_PATH="$PROJECT_DIR/PhoneticIM.xcodeproj"
SCHEME="PhoneticIM"
CONFIGURATION="Release"
ARCHIVE_PATH="$PROJECT_DIR/Release/PhoneticIM.xcarchive"
EXPORT_DIR="$PROJECT_DIR/Release"
EXPORT_OPTIONS_PLIST="$PROJECT_DIR/Release/exportOptions.plist"
MANIFEST_PLIST="$PROJECT_DIR/Release/manifest.plist"

# App metadata
BUNDLE_ID="org.guohai.pim"
BUNDLE_VERSION="0.1.0"
APP_TITLE="PhoneticIM"

# Public HTTPS download URL for the IPA (MUST be reachable by iPhone)
# Example: https://intra.example.com/apps/PhoneticIM.ipa
IPA_URL="${IPA_URL:-https://your-internal-domain.example.com/PhoneticIM.ipa}"
# Optional display image URLs
DISPLAY_IMAGE_URL="${DISPLAY_IMAGE_URL:-https://your-internal-domain.example.com/icon57.png}"
FULL_SIZE_IMAGE_URL="${FULL_SIZE_IMAGE_URL:-https://your-internal-domain.example.com/icon512.png}"

mkdir -p "$EXPORT_DIR"

echo "[1/4] Generating exportOptions.plist ..."
cat > "$EXPORT_OPTIONS_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>enterprise</string>
  <key>signingStyle</key>
  <string>manual</string>
  <key>stripSwiftSymbols</key>
  <true/>
  <key>teamID</key>
  <string>RRC34WMGHN</string>
  <key>provisioningProfiles</key>
  <dict>
    <key>org.guohai.pim</key>
    <string>pim-ios</string>
    <key>org.guohai.pim.keyboard</key>
    <string>pim-key-ios</string>
  </dict>
</dict>
</plist>
PLIST

echo "[2/4] Archiving ..."
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  clean archive

echo "[3/4] Exporting IPA ..."
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"

IPA_FILE="$(find "$EXPORT_DIR" -maxdepth 1 -name '*.ipa' | head -n 1)"
if [[ -z "$IPA_FILE" ]]; then
  echo "ERROR: IPA not found in $EXPORT_DIR"
  exit 1
fi

IPA_NAME="$(basename "$IPA_FILE")"

echo "[4/4] Generating manifest.plist ..."
cat > "$MANIFEST_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>items</key>
  <array>
    <dict>
      <key>assets</key>
      <array>
        <dict>
          <key>kind</key>
          <string>software-package</string>
          <key>url</key>
          <string>${IPA_URL}</string>
        </dict>
        <dict>
          <key>kind</key>
          <string>display-image</string>
          <key>url</key>
          <string>${DISPLAY_IMAGE_URL}</string>
        </dict>
        <dict>
          <key>kind</key>
          <string>full-size-image</string>
          <key>url</key>
          <string>${FULL_SIZE_IMAGE_URL}</string>
        </dict>
      </array>
      <key>metadata</key>
      <dict>
        <key>bundle-identifier</key>
        <string>${BUNDLE_ID}</string>
        <key>bundle-version</key>
        <string>${BUNDLE_VERSION}</string>
        <key>kind</key>
        <string>software</string>
        <key>title</key>
        <string>${APP_TITLE}</string>
      </dict>
    </dict>
  </array>
</dict>
</plist>
PLIST

echo

echo "Done. Files in $EXPORT_DIR:"
ls -la "$EXPORT_DIR"
echo

echo "Important: set a real HTTPS IPA_URL before internal distribution."
echo "Current IPA filename: $IPA_NAME"
echo "Install link example:"
echo "itms-services://?action=download-manifest&url=https://your-internal-domain.example.com/manifest.plist"
