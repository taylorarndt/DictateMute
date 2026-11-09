import ApplicationServices
import Foundation
import os

/// Watches for Claude Code dictation and keeps Discord muted while it lasts.
///
/// Rules:
/// - When Claude Code starts listening and Discord is not muted, mute it.
/// - When Claude Code stops, unmute, but only if DictateMute was the one that muted it.
///   If you were already muted, you stay muted.
@MainActor
final class MuteEngine: ObservableObject {
    enum Status: Equatable {
        case off
        case needsPermission
        case waiting          // on, nothing happening
        case discordNotRunning
        case mutedForDictation
        case problem(String)

        var text: String {
            switch self {
            case .off: return "Off"
            case .needsPermission: return "Needs Accessibility permission"
            case .waiting: return "Ready. Discord will mute when Claude Code listens."
            case .discordNotRunning: return "Ready. Discord is not running."
            case .mutedForDictation: return "Claude Code is listening. Discord is muted."
            case .problem(let message): return message
            }
        }
    }

    @Published private(set) var status: Status = .off
    @Published private(set) var hasPermission = AXIsProcessTrusted()
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "enabled")
            let value = isEnabled
            enabledFlag.withLock { $0 = value }
        }
    }

    // Only used on `queue`.
    private nonisolated(unsafe) let muter = DiscordMuter()
    private let queue = DispatchQueue(label: "DictateMute.engine", qos: .userInitiated)
    private let log = Logger(subsystem: "com.taylorarndt.DictateMute", category: "engine")
    private var timer: DispatchSourceTimer?
    /// Copy of isEnabled the background queue can read without waiting on the main thread.
    private let enabledFlag = OSAllocatedUnfairLock(initialState: true)

    // Only touched on `queue`.
    private nonisolated(unsafe) var dictating = false
    private nonisolated(unsafe) var weMuted = false
    private nonisolated(unsafe) var quietSince: Date?

    init() {
        let saved = UserDefaults.standard.object(forKey: "enabled") as? Bool ?? true
        isEnabled = saved
        enabledFlag.withLock { $0 = saved }
        start()
    }

    func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        hasPermission = AXIsProcessTrustedWithOptions(options)
    }

    /// Releases a mute DictateMute made, for example when quitting or turning it off.
    nonisolated func releaseMute() {
        queue.sync {
            if weMuted { muter.setMuted(false) }
            weMuted = false
            dictating = false
        }
    }

    private func start() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: .milliseconds(200))
        timer.setEventHandler { [weak self] in self?.tick() }
        timer.resume()
        self.timer = timer
    }

    private nonisolated func tick() {
        let trusted = AXIsProcessTrusted()
        let enabled = enabledFlag.withLock { $0 }

        guard enabled else {
            if weMuted { muter.setMuted(false); weMuted = false }
            dictating = false
            publish(.off, trusted)
            return
        }
        guard trusted else { publish(.needsPermission, trusted); return }

        if MicMonitor.claudeCodeIsListening() {
            quietSince = nil
            if !dictating {
                dictating = true
                startedListening()
            }
        } else if dictating {
            // A short gap in recording should not unmute you.
            if quietSince == nil { quietSince = Date() }
            if let since = quietSince, Date().timeIntervalSince(since) >= 0.6 {
                dictating = false
                quietSince = nil
                stoppedListening()
            }
        } else {
            publish(muter.isDiscordRunning ? .waiting : .discordNotRunning, trusted)
        }
    }

    private nonisolated func startedListening() {
        guard muter.isDiscordRunning else {
            publish(.discordNotRunning, true)
            return
        }
        switch muter.isMuted() {
        case .some(true):
            log.notice("Claude Code started listening. Discord was already muted.")
            publish(.waiting, true)
        case .some(false):
            if muter.setMuted(true) {
                weMuted = true
                log.notice("Claude Code started listening. Muted Discord.")
                publish(.mutedForDictation, true)
            } else {
                publish(.problem("Could not mute Discord."), true)
            }
        case .none:
            publish(.problem("Could not find Mute in Discord's menu bar icon. Is the icon turned on?"), true)
        }
    }

    private nonisolated func stoppedListening() {
        guard weMuted else { return }
        weMuted = false
        if muter.setMuted(false) {
            log.notice("Claude Code stopped listening. Unmuted Discord.")
            publish(.waiting, true)
        } else {
            publish(.problem("Could not unmute Discord. Press Command Shift M in Discord."), true)
        }
    }

    private nonisolated func publish(_ status: Status, _ trusted: Bool) {
        let log = self.log
        DispatchQueue.main.async {
            if self.status != status {
                log.notice("Status: \(status.text, privacy: .public)")
                self.status = status
            }
            if self.hasPermission != trusted { self.hasPermission = trusted }
        }
    }
}
