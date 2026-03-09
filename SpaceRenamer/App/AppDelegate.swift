import AppKit
import SwiftUI

extension Notification.Name {
    static let showSpaceRenamerSettings = Notification.Name("showSpaceRenamerSettings")
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let store = SpaceNamesStore()
        let spaceManager = SpaceManager(store: store)
        statusBarController = StatusBarController(spaceManager: spaceManager, store: store)
        statusBarController?.setup()
        requestAccessibilityIfNeeded()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showSettings),
            name: .showSpaceRenamerSettings,
            object: nil
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    // MARK: - Settings window

    @objc func showSettings() {
        NSApp.setActivationPolicy(.regular)

        if settingsWindow == nil {
            let win = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 240),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            win.title = "SpaceRenamer Settings"
            win.contentView = NSHostingView(rootView: SettingsView())
            win.center()
            win.isReleasedWhenClosed = false
            win.delegate = self
            settingsWindow = win
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Accessibility

    private func requestAccessibilityIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "SpaceRenamer needs Accessibility access to switch desktops.\n\nClick OK to open System Settings, then enable SpaceRenamer under Privacy & Security → Accessibility."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")
        if alert.runModal() == .alertFirstButtonReturn {
            let key = kAXTrustedCheckOptionPrompt.takeRetainedValue() as String
            AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
        }
    }
}

// MARK: - NSWindowDelegate

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
