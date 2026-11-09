#!/bin/zsh
# Builds, signs, notarizes, and publishes a DictateMute release.
#
# Usage:
#   scripts/release.sh 1.0.0          full release
#   scripts/release.sh 1.0.0 --sign   build and sign only, nothing published
#
# Needs:
#   - The App Store Connect API key set up for the asc tool (~/.asc/config.json).
#     Xcode uses it to sign with the team's Developer ID certificate.
#   - The Sparkle signing key in the login keychain, account "DictateMute".
#   - The gh tool, signed in to GitHub.
#
# Output lines are plain text, printed as each step happens.

set -euo pipefail

VERSION="${1:?Give a version, for example scripts/release.sh 1.0.0}"
MODE="${2:-}"
ROOT="${0:A:h:h}"
cd "$ROOT"

say() { print -- "$1" }

# Versions are major.minor.bugfix, for example 1.2.3.
if [[ ! "$VERSION" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]]; then
  say "Version must be major.minor.bugfix, for example 1.2.3. Got: $VERSION"
  exit 1
fi
if git rev-parse -q --verify "refs/tags/v$VERSION" >/dev/null; then
  say "Tag v$VERSION already exists. Pick a new version."
  exit 1
fi

# App Store Connect key, read from the asc config. Values are never printed.
eval "$(python3 - <<'PY'
import json, os, shlex
c = json.load(open(os.path.expanduser("~/.asc/config.json")))
print("ASC_KEY_ID=" + shlex.quote(c["key_id"]))
print("ASC_ISSUER=" + shlex.quote(c["issuer_id"]))
print("ASC_KEY_PATH=" + shlex.quote(os.path.expanduser(c["private_key_path"])))
PY
)"
AUTH=(-allowProvisioningUpdates -authenticationKeyPath "$ASC_KEY_PATH" -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER")

BUILD_NUMBER=$(git rev-list --count HEAD)
DIST="$ROOT/dist/$VERSION"
rm -rf "$DIST"
mkdir -p "$DIST"

say "Step 1 of 6: generating the Xcode project"
xcodegen generate --quiet

say "Step 2 of 6: building and archiving version $VERSION, build $BUILD_NUMBER"
xcodebuild -project DictateMute.xcodeproj -scheme DictateMute -configuration Release \
  -archivePath "$DIST/DictateMute.xcarchive" archive \
  MARKETING_VERSION="$VERSION" CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  "${AUTH[@]}" -quiet

say "Step 3 of 6: signing with Developer ID"
cat > "$DIST/export.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>method</key><string>developer-id</string>
<key>signingStyle</key><string>automatic</string>
<key>teamID</key><string>M9SNPTXA44</string>
</dict></plist>
PLIST
xcodebuild -exportArchive -archivePath "$DIST/DictateMute.xcarchive" \
  -exportOptionsPlist "$DIST/export.plist" -exportPath "$DIST/export" "${AUTH[@]}" -quiet
APP="$DIST/export/DictateMute.app"
codesign --verify --deep --strict "$APP"
say "Signed by: $(codesign -dvv "$APP" 2>&1 | grep '^Authority' | head -1 | sed 's/Authority=//')"

if [[ "$MODE" == "--sign" ]]; then
  say "Done. Signed app is at $APP"
  exit 0
fi

say "Step 4 of 6: notarizing with Apple. This can take a few minutes."
ZIP="$DIST/DictateMute.zip"
ditto -c -k --keepParent "$APP" "$DIST/notarize.zip"
xcrun notarytool submit "$DIST/notarize.zip" --key "$ASC_KEY_PATH" --key-id "$ASC_KEY_ID" --issuer "$ASC_ISSUER" --wait
xcrun stapler staple "$APP"
spctl --assess --type execute "$APP"
say "Notarized and stapled."
ditto -c -k --keepParent "$APP" "$ZIP"

say "Step 5 of 6: signing the update for Sparkle and writing appcast.xml"
SPARKLE_BIN=$(find "$HOME/Library/Developer/Xcode/DerivedData" "$ROOT/build" -type d -path "*artifacts/sparkle/Sparkle/bin" 2>/dev/null | head -1)
[[ -n "$SPARKLE_BIN" ]] || { say "Could not find Sparkle's tools. Build the project in Xcode once first."; exit 1; }
SIGNATURE=$("$SPARKLE_BIN/sign_update" --account DictateMute "$ZIP")
URL="https://github.com/taylorarndt/DictateMute/releases/download/v$VERSION/DictateMute.zip"
DATE=$(LC_ALL=C date -u "+%a, %d %b %Y %H:%M:%S +0000")
ITEM="    <item>
      <title>Version $VERSION</title>
      <pubDate>$DATE</pubDate>
      <sparkle:version>$BUILD_NUMBER</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.2</sparkle:minimumSystemVersion>
      <sparkle:releaseNotesLink>https://github.com/taylorarndt/DictateMute/releases/tag/v$VERSION</sparkle:releaseNotesLink>
      <enclosure url=\"$URL\" $SIGNATURE type=\"application/octet-stream\"/>
    </item>"
if [[ ! -f appcast.xml ]]; then
  cat > appcast.xml <<XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>DictateMute</title>
    <link>https://github.com/taylorarndt/DictateMute</link>
    <!-- ITEMS -->
  </channel>
</rss>
XML
fi
python3 - "$ITEM" <<'PY'
import sys
s = open("appcast.xml").read()
s = s.replace("    <!-- ITEMS -->", "    <!-- ITEMS -->\n" + sys.argv[1], 1)
open("appcast.xml", "w").write(s)
PY

say "Step 6 of 6: publishing the GitHub release and the appcast"
NOTES="$DIST/notes.md"
if [[ -f "release-notes/$VERSION.md" ]]; then cp "release-notes/$VERSION.md" "$NOTES"; else print "DictateMute $VERSION" > "$NOTES"; fi
git add appcast.xml
git commit -m "Release $VERSION"
# Every release commit gets a version tag.
git tag -a "v$VERSION" -m "DictateMute $VERSION"
git push origin main
git push origin "v$VERSION"
gh release create "v$VERSION" "$ZIP" --verify-tag --title "DictateMute $VERSION" --notes-file "$NOTES"

say "Released DictateMute $VERSION: https://github.com/taylorarndt/DictateMute/releases/tag/v$VERSION"
