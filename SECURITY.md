# Security Policy

## Supported versions

Only the latest release of DictateMute gets security fixes. Please update to the latest release before reporting a problem.

## Reporting a vulnerability

Please do not open a public issue for security problems.

Report privately through GitHub:

1. Go to the Security tab of the [DictateMute repository](https://github.com/taylorarndt/DictateMute/security).
2. Choose Report a vulnerability.
3. Describe the problem, the steps to reproduce it, and the impact.

You will get a reply as soon as possible. Once a fix is ready, it will be released and the advisory will be published with credit to you, unless you prefer not to be named.

## What DictateMute accesses

- **Accessibility.** DictateMute uses the macOS Accessibility API only to open Discord's menu bar icon menu and press Mute or Unmute.
- **Microphone usage information.** DictateMute reads which processes are using the microphone, through Core Audio. It never records, reads, or stores any audio.
- **Network.** DictateMute makes no network requests except Sparkle update checks to GitHub.

DictateMute does not collect analytics or send any data about you.
