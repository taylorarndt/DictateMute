# DictateMute

DictateMute is a small Mac menu bar app. It mutes you in Discord while you dictate to Claude Code, then unmutes you when you stop.

[![Build](https://github.com/taylorarndt/DictateMute/actions/workflows/build.yml/badge.svg)](https://github.com/taylorarndt/DictateMute/actions/workflows/build.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Why I made this

I'm Taylor Arndt. I'm on Discord all day with my team, and I do a lot of dictating in Claude Code. Every time I dictated, the people in my voice channel heard everything I said to Claude. So I would mute myself, dictate, and then forget to unmute. People would talk to me and I would answer, and nobody could hear me.

It kept happening, and it was becoming a real problem. I wanted it to just happen on its own, with nothing to remember. So I worked with Claude to build a solution, and this is it.

## What it does

- When Claude Code starts listening to your microphone, DictateMute mutes you in Discord.
- When Claude Code stops listening, DictateMute unmutes you.
- If you had already muted yourself, DictateMute leaves you muted. It only undoes a mute it made.
- If you quit DictateMute in the middle of dictating, it unmutes you first.

You keep dictating the way you already do. There is nothing new to press.

## How it works

I want to be open about exactly what this app does on your Mac.

1. **Watching for dictation.** About five times a second, DictateMute asks macOS which apps are recording from a microphone. macOS has a list of this for every app (Core Audio process objects, macOS 14.2 and later). If Claude Code is on that list, you are dictating. DictateMute never records, hears, or reads any audio. It only sees whether Claude Code is using the mic.
2. **Muting Discord.** Discord has a menu bar icon, and its menu has a Mute item. DictateMute presses that item using the macOS Accessibility API, the same system that screen readers like VoiceOver use. It then checks the checkmark on that item to confirm you really are muted, and tries again if not.
3. **Unmuting.** When Claude Code has stopped using the mic for a little over half a second, DictateMute presses Mute again to unmute you.

### Why it uses Discord's menu bar icon

We tried other ways first, and they did not hold up:

- **Pressing the Mute button inside the Discord window.** This works while Discord is in front. But when Discord is full screen on another desktop, Discord pauses that window. Presses arrived late, and the mute state it reported was out of date. I got stuck muted.
- **A Discord keyboard shortcut.** Discord ignores key presses that come from software, so an app cannot trigger a Discord keybind.

Discord's menu bar icon is handled by Discord's main process, so it responds right away, wherever the Discord window is.

## What it can access

- **Accessibility permission.** Needed to press Mute in Discord's menu bar icon menu. DictateMute does not read or press anything else.
- **Microphone use list.** It reads which apps are using the mic. It does not ask for microphone permission because it never uses the microphone.
- **Network.** Only to check GitHub for app updates, through Sparkle. You can turn that off. There are no analytics and no tracking.

## Install

1. Download the latest `DictateMute.zip` from [Releases](https://github.com/taylorarndt/DictateMute/releases/latest).
2. Unzip it and move DictateMute to your Applications folder.
3. Open it. A mic icon appears in the menu bar.
4. When macOS asks, turn on DictateMute in System Settings, Privacy and Security, Accessibility.
5. Click the mic icon and turn on Launch at Login if you want it running all the time.

Releases are signed and notarized by Apple, and DictateMute updates itself through Sparkle.

## Requirements

- macOS 14.2 or later
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) with voice dictation
- The Discord desktop app, with its menu bar icon turned on (it is on by default)

## Using it

Click the mic icon in the menu bar to open DictateMute. The window has:

- **Mute Discord while Claude Code is listening.** The main on and off switch.
- **Status.** Tells you if it is ready, if Discord is muted for dictation, or if something needs your attention.
- **Launch at Login.**
- **Check for Updates Automatically.**
- **The gear menu,** with Check for Updates, About, and Quit.

While Discord is muted for dictation, the menu bar icon changes to a crossed-out mic.

Everything works with VoiceOver and the keyboard. I'm blind and use VoiceOver every day, so that is not optional.

## If something goes wrong

- **Stuck muted?** Press Command Shift M while you are in Discord, or use Mute in Discord's menu bar icon menu.
- **Nothing happens when you dictate?** Check that DictateMute has Accessibility permission, and that Discord's menu bar icon is on.
- **Logs.** Open Console and filter by `com.taylorarndt.DictateMute`, or run:

      log stream --predicate 'subsystem == "com.taylorarndt.DictateMute"'

## What's next

Version 1 does one thing: Claude Code and Discord. I would love help adding other dictation tools and other call apps. Please open an issue first so we can talk about how each one should work.

## Build from source

    brew install xcodegen
    git clone https://github.com/taylorarndt/DictateMute.git
    cd DictateMute
    xcodegen generate
    open DictateMute.xcodeproj

See [CONTRIBUTING.md](CONTRIBUTING.md) for more.

## Contributing

Contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) and the [Code of Conduct](CODE_OF_CONDUCT.md). To report a security problem, see [SECURITY.md](SECURITY.md).

## Contributors

Thank you to everyone who has helped make DictateMute better.

[![Contributors](https://contrib.rocks/image?repo=taylorarndt/DictateMute)](https://github.com/taylorarndt/DictateMute/graphs/contributors)

## Built with Claude

I built DictateMute together with Claude, in Claude Code. I described the problem, tested every version with VoiceOver, and reported what went wrong. Claude wrote the code and worked through the dead ends with me.

## About me

I'm Taylor Arndt, COO of [Techopolis](https://techopolisonline.com). I'm blind, and I build accessible apps for Apple platforms with AI. I write about accessibility, AI, and building apps on my Substack.

- Substack: [taylorarndt.substack.com](https://taylorarndt.substack.com)
- GitHub: [taylorarndt](https://github.com/taylorarndt)

## License

MIT. See [LICENSE](LICENSE).
