import AppKit
import SwiftUI
import Combine

@MainActor
final class StatusBarController {
    private let spaceManager: SpaceManager
    private let store: SpaceNamesStore
    private let settings = AppSettings.shared

    // Single mode
    private var singleItem: NSStatusItem?
    private var popover: NSPopover?

    // Multi mode
    private var multiItems: [NSStatusItem] = []

    // Auto mode
    private var autoIsMulti = false
    private var autoGeneration = 0  // incremented to cancel stale async builds

    private static let menuBarItemFont    = NSFont.systemFont(ofSize: 13)
    private static let menuBarItemPadding = CGFloat(28)
    private static let autoFitMargin      = CGFloat(250)  // buffer for left-side app menus
    private static let autoHysteresis     = CGFloat(40)   // extra slack to prevent single↔multi oscillation

    private var cancellables = Set<AnyCancellable>()

    init(spaceManager: SpaceManager, store: SpaceNamesStore) {
        self.spaceManager = spaceManager
        self.store = store
    }

    func setup() {
        buildItems()

        // Rebuild when spaces list changes
        spaceManager.$spaces
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshItems() }
            .store(in: &cancellables)

        // Update title / bold in single mode when active space changes
        spaceManager.$currentSpaceID
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshItems() }
            .store(in: &cancellables)

        // Rebuild entirely when display mode changes
        settings.$displayMode
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { [weak self] _ in
                self?.tearDownItems()
                self?.buildItems()
            }
            .store(in: &cancellables)

        // Re-evaluate auto mode when the active app changes (different apps have different menu bar widths)
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didActivateApplicationNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.handleWorkspaceChange() }
            .store(in: &cancellables)
    }

    // MARK: - Build

    private func buildItems() {
        switch settings.displayMode {
        case .automatic: buildAutoItems()
        case .single:    buildSingleItem()
        case .multi:     buildMultiItems()
        }
    }

    private func buildSingleItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        singleItem = item
        updateSingleTitle()

        if let button = item.button {
            button.target = self
            button.action = #selector(togglePopover(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            applyBorder(to: button, active: true)
        }

        let pop = NSPopover()
        pop.contentSize = NSSize(width: 220, height: 320)
        pop.behavior = .transient
        pop.contentViewController = NSHostingController(
            rootView: SpaceListView(
                spaceManager: spaceManager,
                store: store,
                onDismiss: { [weak self] in self?.closePopover() }
            )
        )
        popover = pop
    }

    private func buildMultiItems() {
        let spaces = spaceManager.spaces
        let currentID = spaceManager.currentSpaceID

        multiItems = spaces.map { space in
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            let isCurrent = space.id == currentID

            let title = space.name
            item.button?.attributedTitle = NSAttributedString(
                string: title,
                attributes: [.font: Self.menuBarItemFont]
            )

            // Border outline for active space
            if let button = item.button {
                button.wantsLayer = true
                if isCurrent {
                    button.layer?.borderColor = NSColor.white.cgColor
                    button.layer?.borderWidth = 1.0
                    button.layer?.cornerRadius = 3.0
                } else {
                    button.layer?.borderWidth = 0
                }
            }

            let spaceID = space.id
            item.button?.target = self
            item.button?.action = #selector(multiItemClicked(_:))
            item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
            item.button?.tag = spaceID
            return item
        }
    }

    // MARK: - Auto mode

    private func buildAutoItems() {
        autoGeneration += 1
        let generation = autoGeneration
        buildSingleItem()
        autoIsMulti = false
        // Start with single to measure available space, then upgrade if multi fits.
        // 0.15s delay gives the status bar time to assign real frame coordinates.
        // The generation guard cancels this block if tearDownItems() fires before it runs.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self,
                  self.settings.displayMode == .automatic,
                  self.autoGeneration == generation else { return }
            guard let f = self.singleItem?.button?.window?.frame, f.origin.x > 0 else { return }
            if self.canFitMulti() {
                self.tearDownItems()
                self.buildMultiItems()
                self.autoIsMulti = true
            }
        }
    }

    /// Total pixel width needed to display all spaces as multi items.
    private func requiredMultiWidth() -> CGFloat {
        spaceManager.spaces.reduce(CGFloat(0)) { sum, space in
            let w = (space.name as NSString)
                .size(withAttributes: [.font: Self.menuBarItemFont]).width
            return sum + w + Self.menuBarItemPadding
        }
    }

    /// Right edge (in points) of the frontmost app's menu bar items, measured via AX.
    private func appMenuRightEdge() -> CGFloat {
        guard AXIsProcessTrusted() else { return Self.autoFitMargin }
        guard let app = NSWorkspace.shared.menuBarOwningApplication else { return 0 }
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var raw: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axApp, "AXMenuBar" as CFString, &raw) == .success,
              let menuBar = raw else { return 0 }
        guard CFGetTypeID(menuBar) == AXUIElementGetTypeID() else { return 0 }
        let menuBarElement = menuBar as! AXUIElement
        var childRaw: CFTypeRef?
        guard AXUIElementCopyAttributeValue(menuBarElement, "AXChildren" as CFString, &childRaw) == .success,
              let childArr = childRaw,
              CFGetTypeID(childArr) == CFArrayGetTypeID() else { return 0 }
        let arr = childArr as! CFArray
        // NSScreen.screens.first is always the menu bar screen (index 0), unlike NSScreen.main
        let screenMid = (NSScreen.screens.first?.frame.width ?? 1440) / 2
        var rightEdge: CGFloat = 0
        for i in 0..<CFArrayGetCount(arr) {
            guard let ptr = CFArrayGetValueAtIndex(arr, i) else { continue }
            let child = Unmanaged<AXUIElement>.fromOpaque(ptr).takeUnretainedValue()
            var fRaw: CFTypeRef?
            guard AXUIElementCopyAttributeValue(child, "AXFrame" as CFString, &fRaw) == .success,
                  let fv = fRaw,
                  CFGetTypeID(fv) == AXValueGetTypeID() else { continue }
            var rect = CGRect.zero
            guard AXValueGetValue(fv as! AXValue, .cgRect, &rect) else { continue }
            if rect.origin.x < screenMid { rightEdge = max(rightEdge, rect.maxX) }
        }
        return rightEdge
    }

    /// True while multi is showing and the leftmost item clears the app menu.
    private func multiItemsFit() -> Bool {
        guard let leftmost = multiItems.last,
              let window = leftmost.button?.window else { return false }
        let leftmostX = window.frame.origin.x
        guard leftmostX > 0 else { return true }  // not yet positioned, assume fits
        let menuEdge = appMenuRightEdge()
        return leftmostX > menuEdge + Self.autoHysteresis
    }

    /// True when single is showing and multi items would fit in the available space.
    /// Estimated leftmost multi item = singleX + singleWidth - needed.
    /// Items fit when that position > menuEdge + hysteresis.
    private func canFitMulti() -> Bool {
        guard let window = singleItem?.button?.window else { return false }
        let menuEdge = appMenuRightEdge()
        let needed = requiredMultiWidth()
        let estimatedLeftmost = window.frame.origin.x + window.frame.width - needed
        return estimatedLeftmost > menuEdge + Self.autoHysteresis
    }

    private var isPopoverShown: Bool { popover?.isShown == true }

    private func handleWorkspaceChange() {
        guard settings.displayMode == .automatic, !isPopoverShown else { return }
        if autoIsMulti {
            if !multiItemsFit() {
                tearDownItems()
                buildAutoItems()  // self-heals: re-evaluates after 150ms
            }
        } else {
            if canFitMulti() {
                tearDownItems()
                buildMultiItems()
                autoIsMulti = true
            }
        }
    }

    // MARK: - Refresh (without full rebuild)

    private func refreshItems() {
        switch settings.displayMode {
        case .automatic:
            if autoIsMulti {
                if spaceManager.spaces.count != multiItems.count {
                    tearDownItems()
                    buildAutoItems()
                } else {
                    updateMultiStyles()
                    if !isPopoverShown && !multiItemsFit() {
                        tearDownItems()
                        buildSingleItem()
                        autoIsMulti = false
                    }
                }
            } else {
                updateSingleTitle()
                if !isPopoverShown && canFitMulti() {
                    tearDownItems()
                    buildMultiItems()
                    autoIsMulti = true
                }
            }
        case .single:
            updateSingleTitle()
        case .multi:
            // Only full rebuild if space count changed; otherwise just restyle in place
            if spaceManager.spaces.count != multiItems.count {
                tearDownItems()
                buildMultiItems()
            } else {
                updateMultiStyles()
            }
        }
    }

    private func updateMultiStyles() {
        let currentID = spaceManager.currentSpaceID
        for (item, space) in zip(multiItems, spaceManager.spaces) {
            guard let button = item.button else { continue }
            button.tag = space.id
            button.attributedTitle = NSAttributedString(
                string: space.name,
                attributes: [.font: Self.menuBarItemFont]
            )
            applyBorder(to: button, active: space.id == currentID)
        }
    }

    private func updateSingleTitle() {
        guard let item = singleItem else { return }
        let name = spaceManager.spaces
            .first(where: { $0.id == spaceManager.currentSpaceID })?
            .name ?? "Spaces"
        item.button?.title = "\(name) ▾"
    }

    // MARK: - Teardown

    private func tearDownItems() {
        autoGeneration += 1  // cancel any pending buildAutoItems async block
        closePopover()
        popover = nil
        if let item = singleItem {
            NSStatusBar.system.removeStatusItem(item)
            singleItem = nil
        }
        for item in multiItems {
            NSStatusBar.system.removeStatusItem(item)
        }
        multiItems = []
    }

    // MARK: - Actions

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        guard let popover, let button = singleItem?.button else { return }
        if popover.isShown {
            closePopover()
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    @objc private func multiItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showMultiPopover(from: sender)
        } else {
            let spaceID = sender.tag
            // Immediately restyle so border jumps to clicked item without waiting for poll
            applyBorder(to: sender, active: true)
            for item in multiItems where item.button !== sender {
                if let btn = item.button { applyBorder(to: btn, active: false) }
            }
            spaceManager.switchToSpace(id: spaceID)
        }
    }

    private func applyBorder(to button: NSStatusBarButton, active: Bool) {
        button.wantsLayer = true
        if active {
            button.layer?.borderColor = NSColor.white.cgColor
            button.layer?.borderWidth = 1.0
            button.layer?.cornerRadius = 3.0
        } else {
            button.layer?.borderWidth = 0
        }
    }

    private func showMultiPopover(from button: NSStatusBarButton) {
        if popover == nil {
            let pop = NSPopover()
            pop.contentSize = NSSize(width: 220, height: 320)
            pop.behavior = .transient
            pop.contentViewController = NSHostingController(
                rootView: SpaceListView(
                    spaceManager: spaceManager,
                    store: store,
                    onDismiss: { [weak self] in self?.closePopover() }
                )
            )
            popover = pop
        }
        if popover?.isShown == true {
            closePopover()
        } else {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover?.contentViewController?.view.window?.makeKey()
        }
    }

    private func closePopover() {
        popover?.performClose(nil)
    }
}
