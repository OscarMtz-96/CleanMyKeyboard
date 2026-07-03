#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Clean My Keyboard"
PRODUCT_NAME="CleanMyKeyboard"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"
APP="$DIST/$APP_NAME.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
DMG="$DIST/$APP_NAME.dmg"
DMG_ROOT="$DIST/dmg-root"
ICONSET="$DIST/AppIcon.iconset"
RW_DMG="$DIST/$APP_NAME-rw.dmg"
BACKGROUND="$DMG_ROOT/.background/dmg-background.png"

cd "$ROOT"
swift build -c release --product "$PRODUCT_NAME"

while MOUNTED="$(hdiutil info | awk -v volume="/Volumes/$APP_NAME" '$0 ~ volume "($| [0-9]+$)" {print substr($0, index($0, volume)); exit}')" && [[ -n "$MOUNTED" ]]; do
  hdiutil detach "$MOUNTED" >/dev/null 2>&1 || hdiutil detach "$MOUNTED" -force >/dev/null
done

rm -rf "$APP" "$DMG" "$RW_DMG" "$DMG_ROOT" "$ICONSET"
mkdir -p "$MACOS" "$RESOURCES"
cp ".build/release/$PRODUCT_NAME" "$MACOS/$PRODUCT_NAME"
swift scripts/make-icon.swift "$ICONSET"
iconutil -c icns "$ICONSET" -o "$RESOURCES/AppIcon.icns"

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$PRODUCT_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>com.cleanmykeyboard.app</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSHumanReadableCopyright</key>
  <string>Open source macOS utility</string>
</dict>
</plist>
PLIST

xattr -cr "$APP"
codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP"

mkdir -p "$DMG_ROOT/.background"
cp -R "$APP" "$DMG_ROOT/"
xattr -cr "$DMG_ROOT/$APP_NAME.app"
codesign --verify --deep --strict "$DMG_ROOT/$APP_NAME.app"
ln -s /Applications "$DMG_ROOT/Applications"
swift scripts/make-dmg-background.swift "$BACKGROUND"
chflags hidden "$DMG_ROOT/.background"

hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_ROOT" -ov -format UDRW "$RW_DMG"
MOUNT_POINT="$(hdiutil attach "$RW_DMG" -readwrite -noverify -noautoopen | awk '/\/Volumes\// {print substr($0, index($0, "/Volumes/")); exit}')"
trap 'hdiutil detach "$MOUNT_POINT" >/dev/null 2>&1 || true' EXIT

osascript <<APPLESCRIPT
tell application "Finder"
  tell disk "$APP_NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set bounds of container window to {160, 120, 680, 420}

    set opts to icon view options of container window
    set arrangement of opts to not arranged
    set icon size of opts to 96
    set background picture of opts to file ".background:dmg-background.png"

    set position of item "$APP_NAME.app" to {150, 150}
    set position of item "Applications" to {370, 150}
    update without registering applications
    delay 1
    close
  end tell
end tell
APPLESCRIPT

xattr -cr "$MOUNT_POINT/$APP_NAME.app"
codesign --verify --deep --strict "$MOUNT_POINT/$APP_NAME.app"

sync
hdiutil detach "$MOUNT_POINT"
trap - EXIT
hdiutil convert "$RW_DMG" -format UDZO -o "$DMG"
rm -f "$RW_DMG"
xattr -cr "$APP" "$DMG_ROOT/$APP_NAME.app"
echo "$DMG"
