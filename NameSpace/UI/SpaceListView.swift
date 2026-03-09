import SwiftUI
import AppKit

struct SpaceListView: View {
    @ObservedObject var spaceManager: SpaceManager
    @ObservedObject var store: SpaceNamesStore

    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(spaceManager.spaces) { space in
                        SpaceRowView(
                            space: space,
                            isCurrent: space.id == spaceManager.currentSpaceID,
                            onSelect: {
                                let spaceID = space.id
                                onDismiss()
                                // Small delay so popover fully closes before keyboard event fires
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    spaceManager.switchToSpace(id: spaceID)
                                }
                            },
                            store: store,
                            onRename: { spaceManager.fetchSpaces() }
                        )
                    }
                }
                .padding(.vertical, 6)
            }
            .frame(maxHeight: 300)
            .fixedSize(horizontal: false, vertical: true)

            Divider()
                .padding(.horizontal, 8)

            VStack(spacing: 0) {
                Button("Help") {
                    onDismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        openHelp()
                    }
                }
                .buttonStyle(MenuRowButtonStyle())

                Button("Settings...") {
                    onDismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        openSettings()
                    }
                }
                .buttonStyle(MenuRowButtonStyle())

                Button("Quit NameSpace") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(MenuRowButtonStyle())
            }
            .padding(.vertical, 4)
        }
        .frame(width: 220)
        .padding(.horizontal, 4)
    }

    private func openHelp() {
        NotificationCenter.default.post(name: .showNameSpaceHelp, object: nil)
    }

    private func openSettings() {
        NotificationCenter.default.post(name: .showSpaceRenamerSettings, object: nil)
    }
}

// MARK: - Footer button style

private struct MenuRowButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13))
            .foregroundStyle(Color.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                (configuration.isPressed || isHovered)
                    ? Color.accentColor.opacity(0.12)
                    : Color.clear
            )
            .cornerRadius(6)
            .onHover { isHovered = $0 }
    }
}
