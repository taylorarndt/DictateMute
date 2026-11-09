import ServiceManagement
import Sparkle
import SwiftUI

/// The window that opens from the menu bar icon.
/// Follows the Techopolis menu bar standard for the header and gear menu.
/// The standard's "New" and "Open in Main Window" buttons are left out on purpose:
/// DictateMute has no documents and no main window.
struct MenuBarView: View {
    @ObservedObject var engine: MuteEngine
    let updater: SPUUpdater

    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?
    @AppStorage("automaticallyChecksForUpdates") private var autoUpdates = true

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
                .padding(14)
        }
        .frame(width: 340)
        .onAppear {
            updater.automaticallyChecksForUpdates = autoUpdates
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle().fill(LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                Image(systemName: "mic.slash.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 22, height: 22)
            .accessibilityHidden(true)

            Text("DictateMute")
                .font(.subheadline.weight(.semibold))
                .accessibilityAddTraits(.isHeader)

            Spacer()

            Menu {
                Button("Check for Updates…") { updater.checkForUpdates() }
                    .disabled(!updater.canCheckForUpdates)
                Button("About DictateMute") {
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.orderFrontStandardAboutPanel(nil)
                }
                Divider()
                Button("Quit DictateMute") { NSApp.terminate(nil) }
                    .keyboardShortcut("q")
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 14, weight: .medium))
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("Settings and app options")
            .accessibilityLabel("Settings and app options")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }

    // MARK: Content

    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Mute Discord while Claude Code is listening", isOn: $engine.isEnabled)
                .toggleStyle(.switch)

            Text(engine.status.text)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Status: \(engine.status.text)")

            if !engine.hasPermission {
                VStack(alignment: .leading, spacing: 6) {
                    Text("DictateMute needs Accessibility permission to press Mute in Discord's menu bar icon.")
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Grant Accessibility Permission") { engine.requestPermission() }
                        .accessibilityHint("Opens a macOS prompt. Turn on DictateMute in Privacy and Security, Accessibility.")
                }
            }

            Divider()

            Toggle("Launch at Login", isOn: $launchAtLogin)
                .toggleStyle(.switch)
                .onChange(of: launchAtLogin) { _, newValue in setLaunchAtLogin(newValue) }

            if let loginError {
                Text(loginError).font(.caption).foregroundStyle(.red)
            }

            Toggle("Check for Updates Automatically", isOn: $autoUpdates)
                .toggleStyle(.switch)
                .onChange(of: autoUpdates) { _, newValue in updater.automaticallyChecksForUpdates = newValue }
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            loginError = nil
        } catch {
            loginError = "Could not change Launch at Login: \(error.localizedDescription)"
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
