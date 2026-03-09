import AppKit
import SwiftUI

extension Notification.Name {
    static let showSpaceRenamerSettings = Notification.Name("showSpaceRenamerSettings")
    static let showNameSpaceHelp = Notification.Name("showNameSpaceHelp")
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    private var settingsWindow: NSWindow?
    private var helpWindow: NSWindow?

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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showHelp),
            name: .showNameSpaceHelp,
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
                contentRect: NSRect(x: 0, y: 0, width: 660, height: 420),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            win.title = "NameSpace Settings"
            win.contentView = NSHostingView(rootView: SettingsView())
            win.center()
            win.isReleasedWhenClosed = false
            win.delegate = self
            settingsWindow = win
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Help window

    @objc func showHelp() {
        NSApp.setActivationPolicy(.regular)

        if helpWindow == nil {
            let win = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 520, height: 500),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            win.title = "NameSpace Help"
            win.contentView = NSHostingView(rootView: HelpView())
            win.center()
            win.isReleasedWhenClosed = false
            win.delegate = self
            helpWindow = win
        }

        helpWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Accessibility

    private func requestAccessibilityIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "NameSpace needs Accessibility access to switch desktops.\n\nClick OK to open System Settings, then enable NameSpace under Privacy & Security → Accessibility."
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
        // Only hide app when all our windows are closed
        let settingsOpen = settingsWindow?.isVisible ?? false
        let helpOpen = helpWindow?.isVisible ?? false
        let closingSettings = (notification.object as? NSWindow) === settingsWindow
        let closingHelp = (notification.object as? NSWindow) === helpWindow
        let anyStillOpen = (settingsOpen && !closingSettings) || (helpOpen && !closingHelp)
        if !anyStillOpen {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
