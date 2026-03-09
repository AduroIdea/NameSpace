import AppKit
import Combine

final class SpaceManager: ObservableObject {
    @Published var spaces: [Space] = []
    @Published var currentSpaceID: Int = 0

    private var displayForSpace: [Int: String] = [:]
    private let store: SpaceNamesStore
    private var timer: Timer?

    init(store: SpaceNamesStore) {
        self.store = store
        fetchSpaces()
        startPolling()
    }

    deinit { timer?.invalidate() }

    // MARK: - Fetch

    func fetchSpaces() {
        let cid = CGSMainConnectionID()
        let displayArray = CGSCopyManagedDisplaySpaces(cid) as? [[String: Any]] ?? []

        var index = 1
        var newSpaces: [Space] = []
        var newDisplayForSpace: [Int: String] = [:]

        for display in displayArray {
            guard
                let uuid = display["Display Identifier"] as? String,
                let spaceDicts = display["Spaces"] as? [[String: Any]]
            else { continue }

            for dict in spaceDicts {
                guard let rawID = dict["id64"] as? Int else { continue }
                let spaceType = dict["type"] as? Int ?? 0
                newDisplayForSpace[rawID] = uuid
                let name = store.getName(for: rawID, defaultIndex: index)
                newSpaces.append(Space(id: rawID, index: index, name: name, type: spaceType))
                index += 1
            }
        }

        let activeID = Int(CGSGetActiveSpace(cid))
        displayForSpace = newDisplayForSpace
        if newSpaces != spaces { spaces = newSpaces }
        if activeID != currentSpaceID { currentSpaceID = activeID }
    }

    // MARK: - Switch
    // Strategy: keyboard simulation (Ctrl+Number) is the only reliable way to
    // visually switch spaces in a regular (non-SIP-disabled) app.
    // CGSManagedDisplaySetCurrentSpace updates internal WindowServer state but
    // does not trigger the Mission Control visual transition.

    func switchToSpace(id: Int) {
        guard let space = spaces.first(where: { $0.id == id }) else { return }

        // Fullscreen (type=1) and tiled (type=4) spaces don't have Mission Control
        // Ctrl+N keyboard shortcuts — use CGS direct switch for them.
        if space.type != 0 {
            cgsSwitch(id: id)
        } else if space.index <= 9 && AXIsProcessTrusted() {
            postKeyboardSwitch(index: space.index)
        } else {
            cgsSwitch(id: id)
        }
    }

    // MARK: - Private

    private func postKeyboardSwitch(index: Int) {
        let keyCodes: [Int: CGKeyCode] = [
            1: 18, 2: 19, 3: 20, 4: 21, 5: 23, 6: 22, 7: 26, 8: 28, 9: 25
        ]
        guard let keyCode = keyCodes[index] else { return }

        let src = CGEventSource(stateID: .hidSystemState)
        let down = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: true)
        let up   = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: false)
        down?.flags = .maskControl
        up?.flags   = .maskControl
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }

    /// CGS switch — updates internal state but no animation; fallback for >9 spaces.
    private func cgsSwitch(id: Int) {
        let cid = CGSMainConnectionID()
        let spaceID = CGSSpaceID(id)
        let uuidString = displayForSpace[id]
            ?? (CGSCopyManagedDisplayForSpace(cid, spaceID) as String?)
        guard let uuid = uuidString else { return }
        CGSManagedDisplaySetCurrentSpace(cid, uuid as CFString, spaceID)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.fetchSpaces()
        }
    }

    private func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.fetchSpaces()
        }
    }
}
