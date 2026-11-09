import ServiceManagement
import Sparkle
import SwiftUI

/// The menu that opens from the menu bar icon.
/// A standard menu, not a window, because VoiceOver and Accessibility can open and read
/// a standard menu reliably. The full window (MenuBarView) opens from "Open DictateMute".
struct MenuBarMenu: View {
    @ObservedObject var engine: MuteEngine
    let updater: SPUUpdater
    let openWindow: () -> Void

    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Text(engine.status.text)

        Divider()

        Toggle("Mute Discord While Claude Code Is Listening", isOn: $engine.isEnabled)

        Toggle("Launch at Login", isOn: Binding(
            get: { launchAtLogin },
            set: { newValue in
                if newValue { try? SMAppService.mainApp.register() } else { try? SMAppService.mainApp.unregister() }
                launchAtLogin = SMAppService.mainApp.status == .enabled
            }))

        if !engine.hasPermission {
            Button("Grant Accessibility Permission…") { engine.requestPermission() }
        }

        Divider()

        Button("Open DictateMute…") { openWindow() }
        Button("Check for Updates…") { updater.checkForUpdates() }
            .disabled(!updater.canCheckForUpdates)

        Divider()

        Button("Quit DictateMute") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}
