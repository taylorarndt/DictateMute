import AppKit
import Sparkle
import SwiftUI

@main
struct DictateMuteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(engine: appDelegate.engine, updater: appDelegate.updater)
        } label: {
            MenuBarIcon(engine: appDelegate.engine)
        }
        .menuBarExtraStyle(.window)
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
    let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    var updater: SPUUpdater { updaterController.updater }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if !engine.hasPermission { engine.requestPermission() }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Never leave someone muted because the app quit mid-dictation.
        engine.releaseMute()
    }
}
