import SwiftUI
import ServiceManagement

// MARK: - Display Mode + AppSettings (unchanged)

enum DisplayMode: String, CaseIterable {
    case single = "single"
    case multi  = "multi"
}

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
            if launchAtLogin { try SMAppService.mainApp.register() }
            else             { try SMAppService.mainApp.unregister() }
        } catch {}
    }
}

// MARK: - Tabs

enum SettingsTab: String, CaseIterable, Identifiable {
    case general, about
    var id: String { rawValue }
    var title: String {
        switch self {
        case .general: return "General"
        case .about:   return "About"
        }
    }
    var icon: String {
        switch self {
        case .general: return "gear"
        case .about:   return "info.circle"
        }
    }
}

// MARK: - Root SettingsView

struct SettingsView: View {
    @State private var selection: SettingsTab? = .general

    var body: some View {
        HStack(spacing: 0) {
            // ── Sidebar ──────────────────────────────
            List(SettingsTab.allCases, selection: $selection) { tab in
                Label(tab.title, systemImage: tab.icon)
                    .tag(tab)
                    .padding(.vertical, 2)
            }
            .listStyle(.sidebar)
            .frame(width: 180)

            Divider()

            // ── Detail ───────────────────────────────
            VStack(alignment: .leading, spacing: 0) {
                // Header bar
                HStack(alignment: .center) {
                    Text((selection ?? .general).title)
                        .font(.title2.bold())
                    Spacer()
                    Button("Quit NameSpace") { NSApp.terminate(nil) }
                        .buttonStyle(.bordered)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)

                Divider()

                // Content
                Group {
                    switch selection ?? .general {
                    case .general: GeneralSettingsView()
                    case .about:   AboutSettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .frame(width: 660, height: 420)
    }
}

// MARK: - General

struct GeneralSettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @State private var axTrusted = AXIsProcessTrusted()

    var body: some View {
        Form {
            Section("Menu Bar") {
                Picker("Display mode", selection: $settings.displayMode) {
                    Text("Current desktop name").tag(DisplayMode.single)
                    Text("All desktop names").tag(DisplayMode.multi)
                }
                .pickerStyle(.radioGroup)
            }

            Section("System") {
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
            }

            Section("Accessibility") {
                HStack {
                    Text("Status")
                    Spacer()
                    if axTrusted {
                        Label("Granted", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Label("Not granted", systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
                if !axTrusted {
                    Button("Open System Settings") {
                        let key = kAXTrustedCheckOptionPrompt.takeRetainedValue() as String
                        AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear { axTrusted = AXIsProcessTrusted() }
    }
}

// MARK: - About

struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "rectangle.3.group")
                .font(.system(size: 56))
                .foregroundStyle(.blue)

            VStack(spacing: 6) {
                Text("NameSpace")
                    .font(.largeTitle.bold())
                Text("Version 1.0")
                    .foregroundStyle(.secondary)
            }

            Text("Name your macOS desktops.\nSwitch between them in a click.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Divider()
                .frame(width: 260)

            Text("Built with Swift using private CGS framework APIs.\nNot available on the App Store.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
