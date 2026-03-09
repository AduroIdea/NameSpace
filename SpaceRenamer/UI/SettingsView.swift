import SwiftUI
import ServiceManagement

// MARK: - Display Mode

enum DisplayMode: String, CaseIterable {
    case single = "single"
    case multi  = "multi"
}

// MARK: - AppSettings

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var displayMode: DisplayMode {
        didSet { UserDefaults.standard.set(displayMode.rawValue, forKey: "displayMode") }
    }

    @Published var launchAtLogin: Bool {
        didSet { applyLaunchAtLogin() }
    }

    private init() {
        let raw = UserDefaults.standard.string(forKey: "displayMode") ?? DisplayMode.single.rawValue
        displayMode = DisplayMode(rawValue: raw) ?? .single
        launchAtLogin = (try? SMAppService.mainApp.status == .enabled) ?? false
    }

    private func applyLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Permission denied or service unavailable — silently ignore
        }
    }
}

// MARK: - SettingsView

struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared

    var body: some View {
        Form {
            Picker("Menu bar display:", selection: $settings.displayMode) {
                Text("Current workspace name").tag(DisplayMode.single)
                Text("All workspace names").tag(DisplayMode.multi)
            }
            .pickerStyle(.radioGroup)

            Toggle("Launch at login", isOn: $settings.launchAtLogin)
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 340)
    }
}
