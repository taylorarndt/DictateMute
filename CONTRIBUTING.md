# Contributing to DictateMute

Thanks for your interest in DictateMute. This guide covers how to build the app, how to test it, and what we look for in a pull request.

## What DictateMute does

DictateMute is a macOS menu bar app. It watches whether Claude Code is using the microphone for voice dictation. While it is, DictateMute mutes Discord by pressing Mute in Discord's menu bar icon menu, using the macOS Accessibility API. When dictation stops, it unmutes Discord, but only if DictateMute was the one that muted it.

Version 1 supports Claude Code and Discord only.

## Requirements

- macOS 14.2 or later
- Xcode 16 or later
- Homebrew

## Build

The Xcode project is generated from `project.yml` by XcodeGen. Do not commit `DictateMute.xcodeproj`.

1. Install XcodeGen:

   ```
   brew install xcodegen
   ```

2. Generate the project from the repo root:

   ```
   xcodegen generate
   ```

3. Open `DictateMute.xcodeproj` in Xcode and run the DictateMute scheme, or build from the command line:

   ```
   xcodebuild -project DictateMute.xcodeproj -scheme DictateMute -configuration Debug build
   ```

Run `xcodegen generate` again any time you add or remove files or change `project.yml`.

## Source layout

- `DictateMute/MicMonitor.swift` watches which processes use the microphone through Core Audio per-process objects.
- `DictateMute/DiscordMuter.swift` presses Mute and Unmute in Discord's menu bar icon menu through the Accessibility API.
- `DictateMute/MuteEngine.swift` decides when to mute and unmute.
- `DictateMute/MenuBarView.swift` is the menu bar interface.
- `DictateMute/DictateMuteApp.swift` is the app entry point.

## Test manually

There are no automated end to end tests yet, so please test by hand before opening a pull request.

1. Build and run DictateMute.
2. Grant Accessibility permission when asked, in System Settings, Privacy and Security, Accessibility. If you rebuild and the permission stops working, remove DictateMute from the list and add it again.
3. Open Discord and join a voice channel. Make sure you are unmuted.
4. Start voice dictation in Claude Code.
5. Confirm Discord mutes.
6. Stop dictation.
7. Confirm Discord unmutes.
8. Mute Discord yourself, then dictate and stop. Confirm DictateMute leaves you muted, since it did not do the muting.

Logs are available in Console. Filter by subsystem `com.taylorarndt.DictateMute`.

## Pull requests

- Keep each pull request small and focused on one change.
- Explain what you changed, why, and how you tested it.
- Make sure the project builds with no new warnings.
- Update docs when behavior changes.

## Accessibility is required

The maintainer is blind and uses VoiceOver. Any change to the interface must:

- Give every control a clear VoiceOver label.
- Work with the keyboard alone, with a logical focus order.
- Support Dynamic Type or larger text where macOS allows it.
- Never rely on color, sound, or position alone to convey meaning.

Pull requests that break accessibility will not be merged.

## Proposing support for another app

Want DictateMute to work with another dictation app or another call app, such as Zoom, Slack, or Microsoft Teams? Please open a feature request issue first, before writing code. Describe the app, how it uses the microphone, and how it can be muted. This lets us agree on the approach before you put in the work.

## No secrets

Never commit passwords, API keys, tokens, signing certificates, or private keys. This includes Sparkle signing keys. If you commit one by mistake, tell the maintainer right away so it can be rotated.

## Code of conduct

This project follows the [Code of Conduct](CODE_OF_CONDUCT.md). By taking part, you agree to follow it.

## License

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).
