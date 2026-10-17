#!/usr/bin/env bash
# Builds a universal, ad-hoc signed Soniq.app into ./build (and a zip into ./dist).
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${VERSION:-$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || true)}"
VERSION="${VERSION:-0.1.0}"
APP="build/Soniq.app"

swift build -c release --arch arm64 --arch x86_64
BIN="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/Soniq"

[ -f Resources/AppIcon.icns ] || swift scripts/make-icon.swift

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Soniq"
cp Resources/AppIcon.icns Resources/MenuBarIcon.png Resources/BrandMark.png Resources/Wordmark.png "$APP/Contents/Resources/"
sed "s/__VERSION__/$VERSION/g" Resources/Info.plist > "$APP/Contents/Info.plist"
cp -R Resources/*.lproj "$APP/Contents/Resources/"

# Prefer a stable identity so macOS keeps the audio permission across builds
# (see scripts/setup-signing.sh); fall back to ad-hoc signing.
if [ -z "${SIGN_IDENTITY:-}" ]; then
  SIGN_IDENTITY="$(security find-identity -p codesigning 2>/dev/null | awk -F'"' '/Soniq Local Signing/ {print $2; exit}')"
fi
codesign --force --options runtime --timestamp=none --sign "${SIGN_IDENTITY:--}" "$APP"

mkdir -p dist
# Asset names carry no version so releases/latest/download/<name> is a permanent link.
rm -f dist/Soniq.zip
ditto -c -k --keepParent "$APP" dist/Soniq.zip
# Disk image with the usual "drag to Applications" layout.
STAGE="$(mktemp -d)"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
rm -f dist/Soniq.dmg
hdiutil create -quiet -volname "Soniq" -srcfolder "$STAGE" -fs HFS+ -format UDZO dist/Soniq.dmg
rm -rf "$STAGE"
codesign --force --timestamp=none --sign "${SIGN_IDENTITY:--}" dist/Soniq.dmg

# Checksums for the release; install.sh verifies Soniq.zip against them.
(cd dist && shasum -a 256 Soniq.zip Soniq.dmg > SHA256SUMS.txt)

echo "Built $APP (v$VERSION), dist/Soniq.zip, dist/Soniq.dmg and dist/SHA256SUMS.txt"
