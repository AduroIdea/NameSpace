import SwiftUI

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                // ── Getting Started ───────────────────
                HelpSection(title: "Getting Started") {
                    HelpItem(
                        icon: "rectangle.3.group",
                        title: "Switching desktops",
                        description: "Click the NameSpace icon in the menu bar to open the dropdown. Click any desktop name to switch to it instantly."
                    )
                    HelpItem(
                        icon: "pencil",
                        title: "Renaming desktops",
                        description: "Open the dropdown and click the ✏️ icon next to any desktop. Type a new name and press Enter. Names persist across app restarts."
                    )
                    HelpItem(
                        icon: "menubar.rectangle",
                        title: "Single vs All workspaces mode",
                        description: "In Single mode, the menu bar shows only the current desktop name. In All mode, every desktop appears as a separate item — the active one is highlighted with a white border. Switch between modes in Settings."
                    )
                    HelpItem(
                        icon: "contextualmenu.and.cursorarrow",
                        title: "Opening the menu in All mode",
                        description: "Right-click any desktop name in the menu bar to open the full dropdown with Settings and Quit."
                    )
                }

                // ── Requirements ─────────────────────
                HelpSection(title: "Requirements") {
                    HelpItem(
                        icon: "accessibility",
                        title: "Accessibility permission",
                        description: "NameSpace needs Accessibility access to switch desktops using keyboard simulation. On first launch you'll be prompted automatically. You can also grant it in System Settings → Privacy & Security → Accessibility."
                    )
                    HelpItem(
                        icon: "plus.rectangle.on.rectangle",
                        title: "Creating desktops",
                        description: "Open Mission Control (F3 or Ctrl+↑), then click the + button in the top-right corner to add new desktops. NameSpace detects them automatically."
                    )
                    HelpItem(
                        icon: "keyboard",
                        title: "Creating keyboard shortcuts for desktops",
                        description: "Go to System Settings → Keyboard → Keyboard Shortcuts → Mission Control. Enable the \"Switch to Desktop N\" shortcuts for each desktop you've created. Close System Settings completely before creating new desktops — otherwise macOS may not register the new shortcuts."
                    )
                    HelpItem(
                        icon: "arrow.left.arrow.right",
                        title: "Recommended Mission Control setting",
                        description: "Disable \"Automatically rearrange Spaces based on most recent use\" in System Settings → Desktop & Dock → Mission Control. Otherwise macOS reorders desktops and switching may target the wrong one."
                    )
                }

                // ── Troubleshooting ───────────────────
                HelpSection(title: "Troubleshooting") {
                    HelpItem(
                        icon: "exclamationmark.triangle",
                        title: "Switch doesn't work",
                        description: "Make sure Accessibility permission is granted (Settings → General → Accessibility Status). If you're running a debug build from Xcode, permission resets on every new build — re-grant it each time."
                    )
                    HelpItem(
                        icon: "macwindow.on.rectangle",
                        title: "App windows follow me to a new desktop",
                        description: "The app is set to appear on all desktops. Right-click its Dock icon → Options → Assign To → This Desktop."
                    )
                }
            }
            .padding(24)
        }
        .frame(width: 520, height: 500)
    }
}

// MARK: - Components

private struct HelpSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
    }
}

private struct HelpItem: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(.blue)
                    .frame(width: 22)
                    .padding(.top, 1)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()
                .padding(.leading, 48)
        }
    }
}
