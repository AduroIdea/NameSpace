import SwiftUI

struct SpaceRowView: View {
    let space: Space
    let isCurrent: Bool
    let onSelect: () -> Void

    @ObservedObject var store: SpaceNamesStore
    // Callback to refresh SpaceManager after rename
    let onRename: () -> Void

    @State private var isEditing = false
    @State private var editText = ""

    var body: some View {
        HStack(spacing: 8) {
            // Active indicator
            Circle()
                .fill(isCurrent ? Color.accentColor : Color.clear)
                .overlay(Circle().stroke(Color.secondary.opacity(0.4), lineWidth: 1))
                .frame(width: 8, height: 8)

            if isEditing {
                TextField("Name", text: $editText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .onSubmit { commitEdit() }
                    .onExitCommand { cancelEdit() }
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(space.name)
                    .font(isCurrent ? .system(size: 13, weight: .semibold) : .system(size: 13))
                    .foregroundStyle(Color.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture { onSelect() }
            }

            Button {
                if isEditing {
                    commitEdit()
                } else {
                    editText = space.name
                    isEditing = true
                }
            } label: {
                Image(systemName: isEditing ? "checkmark" : "pencil")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(
            isCurrent
                ? Color.accentColor.opacity(0.12)
                : Color.clear
        )
        .cornerRadius(6)
    }

    private func commitEdit() {
        let trimmed = editText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            store.setName(trimmed, for: space.id)
            onRename()
        }
        isEditing = false
    }

    private func cancelEdit() {
        isEditing = false
        editText = ""
    }
}
