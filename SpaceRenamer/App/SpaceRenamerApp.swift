import SwiftUI

@main
struct SpaceRenamerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        // Settings window — opened via "Settings..." menu item
        Settings {
            SettingsView()
        }
    }
}
