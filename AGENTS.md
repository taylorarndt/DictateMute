# DictateMute agent notes

## Build

    xcodegen generate
    xcodebuild -project DictateMute.xcodeproj -scheme DictateMute -configuration Debug build

## Releases

- Versions are major.minor.bugfix, for example 1.2.3. Major for big or breaking changes, minor for new features, bugfix for fixes only.
- Every release commit is tagged with its version, for example v1.2.3, and the tag is pushed.
- `scripts/release.sh 1.2.3` builds, signs with Developer ID, notarizes, signs the update for Sparkle, updates appcast.xml, tags, and publishes the GitHub release.
- `scripts/release.sh 1.2.3 --sign` only builds and signs, for checking signing.
- Optional release notes go in release-notes/1.2.3.md.
- Never commit signing keys, the Sparkle private key, or App Store Connect keys.

## Rules

- Accessibility is required: every control needs a clear VoiceOver label, and everything must work from the keyboard.
- Read Discord's menu bar Mute item fresh every time. Discord rebuilds that menu on every mute change, so a saved copy shows a stale checkmark.
