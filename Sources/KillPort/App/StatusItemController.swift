import AppKit
import SwiftUI

@MainActor
final class StatusItemController: NSObject, NSMenuDelegate, NSPopoverDelegate {
    private let store = PortMonitorStore()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let popover = NSPopover()
    private lazy var contextMenu = makeContextMenu()
    private var outsideClickMonitor: Any?

    override init() {
        super.init()
        configureStatusItem()
        configurePopover()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "KillPort")
        button.imagePosition = .imageOnly
        button.target = self
        button.action = #selector(handleStatusItemClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = false
        popover.contentSize = MenuBarContentView.preferredSize
        popover.delegate = self

        let hostingController = NSHostingController(
            rootView: MenuBarContentView(
                store: store,
                onBeforeKill: { [weak self] in
                    self?.closePopoverBeforeProcessTermination()
                }
            )
                .environment(\.colorScheme, .dark)
        )
        hostingController.view.appearance = NSAppearance(named: .darkAqua)
        popover.contentViewController = hostingController
    }

    private func makeContextMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        menu.items.forEach { item in
            item.target = self
        }
        return menu
    }

    @objc private func handleStatusItemClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else {
            togglePopover(sender)
            return
        }

        switch event.type {
        case .rightMouseUp:
            showContextMenu()
        default:
            togglePopover(sender)
        }
    }

    private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
            return
        }

        store.refresh()
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        installOutsideClickMonitor()
    }

    private func showContextMenu() {
        popover.performClose(nil)
        statusItem.menu = contextMenu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func closePopoverBeforeProcessTermination() {
        guard popover.isShown else {
            return
        }

        popover.performClose(nil)
    }

    func popoverDidClose(_ notification: Notification) {
        removeOutsideClickMonitor()
    }

    private func installOutsideClickMonitor() {
        guard outsideClickMonitor == nil else {
            return
        }

        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.closePopoverFromOutsideClick()
            }
        }
    }

    private func removeOutsideClickMonitor() {
        guard let outsideClickMonitor else {
            return
        }

        NSEvent.removeMonitor(outsideClickMonitor)
        self.outsideClickMonitor = nil
    }

    private func closePopoverFromOutsideClick() {
        guard popover.isShown else {
            removeOutsideClickMonitor()
            return
        }

        popover.performClose(nil)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
