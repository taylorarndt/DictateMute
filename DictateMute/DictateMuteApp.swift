import AppKit
import ServiceManagement
import Sparkle
import SwiftUI

@main
struct DictateMuteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarMenu(engine: appDelegate.engine, updater: appDelegate.updater) { appDelegate.showWindow() }
        } label: {
            MenuBarIcon(engine: appDelegate.engine)
        }
        // A standard menu, so VoiceOver can open it. The window style did not open with VoiceOver.
        .menuBarExtraStyle(.menu)
    }
}

/// The icon in the menu bar. It shows a crossed-out mic while Discord is muted for dictation.
struct MenuBarIcon: View {
    @ObservedObject var engine: MuteEngine

    var body: some View {
        let muted = engine.status == .mutedForDictation
        Image(systemName: muted ? "mic.slash.fill" : "mic")
            .accessibilityLabel(muted ? "DictateMute, Discord muted for dictation" : "DictateMute")
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let engine = MuteEngine()

    /// Sparkle checks the appcast on GitHub for new versions.
    private let userDriverDelegate = UpdateDialogDelegate()
    lazy var updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: userDriverDelegate)
    var updater: SPUUpdater { updaterController.updater }

    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let defaults = UserDefaults.standard
        let firstLaunch = !defaults.bool(forKey: "didFirstLaunch")
        if firstLaunch {
            defaults.set(true, forKey: "didFirstLaunch")
            // DictateMute only helps if it is always running, so Launch at Login starts on.
            // Only for an installed copy, so test builds never add themselves.
            if Bundle.main.bundlePath.hasPrefix("/Applications/") {
                try? SMAppService.mainApp.register()
            }
            showWindow()
        }
        if !engine.hasPermission { engine.requestPermission() }
    }

    /// Opening DictateMute again (Spotlight, Finder, Launchpad) shows its window.
    /// This is the way in when the menu bar is full and macOS hides the icon.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showWindow()
        return true
    }

    func showWindow() {
        if window == nil {
            let window = NSWindow(contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.title = "DictateMute"
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: MenuBarView(engine: engine, updater: updater))
            window.center()
            self.window = window
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Never leave someone muted because the app quit mid-dictation.
        engine.releaseMute()
    }
}

/// Customizes Sparkle's update dialog.
final class UpdateDialogDelegate: NSObject, SPUStandardUserDriverDelegate {
    /// No Version History button. Taylor's rule for every app: never show one.
    func standardUserDriverShouldShowVersionHistory(for item: SUAppcastItem) -> Bool { false }
}
