import AppKit
import ApplicationServices

/// Mutes and unmutes Discord by pressing "Mute" in Discord's own menu bar icon menu,
/// through the macOS Accessibility API.
///
/// Why the menu bar icon: Discord handles that menu in its main process, so it responds
/// right away even when the Discord window is full screen on another desktop. Pressing the
/// Mute switch inside the window was unreliable there, because Discord pauses that window
/// and presses arrived late. Discord also ignores software key presses for its keybinds.
final class DiscordMuter {
    static let bundleIDs = ["com.hnc.Discord", "com.hnc.DiscordPTB", "com.hnc.DiscordCanary"]

    var isDiscordRunning: Bool { discordApp() != nil }

    /// true = muted, false = not muted, nil = Discord or its Mute item could not be found.
    func isMuted() -> Bool? {
        guard let item = muteItem() else { return nil }
        let mark = (attribute(item, "AXMenuItemMarkChar") as? String) ?? ""
        return !mark.isEmpty
    }

    /// Presses Mute until Discord confirms the wanted state. It waits before retrying,
    /// so a late press can never flip the state back.
    @discardableResult
    func setMuted(_ want: Bool) -> Bool {
        for _ in 0..<3 {
            guard let current = isMuted() else { return false }
            if current == want { return true }
            guard let item = muteItem(),
                  AXUIElementPerformAction(item, kAXPressAction as CFString) == .success else { return false }
            for _ in 0..<10 {
                Thread.sleep(forTimeInterval: 0.25)
                if isMuted() == want { return true }
            }
        }
        return false
    }

    // MARK: Finding the menu item

    /// Discord rebuilds this menu every time the mute state changes, so a saved copy of
    /// the item goes stale and shows the old checkmark. Always look it up fresh.
    /// The menu is also sometimes missing from Accessibility for a moment, so keep trying
    /// for up to about three seconds.
    private func muteItem(patience: Int = 12) -> AXUIElement? {
        for attempt in 0..<patience {
            if let item = findMuteItem() { return item }
            if attempt < patience - 1 { Thread.sleep(forTimeInterval: 0.25) }
        }
        return nil
    }

    private func findMuteItem() -> AXUIElement? {
        guard let app = discordApp() else { return nil }
        let root = AXUIElementCreateApplication(app.processIdentifier)
        guard let bar = attribute(root, "AXExtrasMenuBar") else { return nil }
        // swiftlint:disable:next force_cast
        let barElement = bar as! AXUIElement
        for icon in children(barElement) {
            for menu in children(icon) {
                for item in children(menu) where (attribute(item, kAXTitleAttribute) as? String) == "Mute" {
                    return item
                }
            }
        }
        return nil
    }

    private func discordApp() -> NSRunningApplication? {
        NSWorkspace.shared.runningApplications.first { Self.bundleIDs.contains($0.bundleIdentifier ?? "") }
    }

    private func children(_ element: AXUIElement) -> [AXUIElement] {
        (attribute(element, kAXChildrenAttribute) as? [AXUIElement]) ?? []
    }

    private func attribute(_ element: AXUIElement, _ name: String) -> AnyObject? {
        var value: AnyObject?
        return AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success ? value : nil
    }
}
