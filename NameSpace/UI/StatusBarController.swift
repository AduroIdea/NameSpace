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
    }

    // MARK: - Build

    private func buildItems() {
        switch settings.displayMode {
        case .single: buildSingleItem()
        case .multi:  buildMultiItems()
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
                attributes: [.font: NSFont.systemFont(ofSize: 13)]
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

    // MARK: - Refresh (without full rebuild)

    private func refreshItems() {
        switch settings.displayMode {
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
                attributes: [.font: NSFont.systemFont(ofSize: 13)]
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
