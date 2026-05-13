import AppKit
import SwiftUI

struct MenuBarContentView: View {
    static let preferredSize = NSSize(width: 286, height: 410)

    @ObservedObject var store: PortMonitorStore
    let onBeforeKill: () -> Void
    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            MenuHeaderSpacer()

            PortContentView(store: store, onBeforeKill: onBeforeKill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            MenuFooterView(store: store, onBeforeKill: onBeforeKill)
        }
        .frame(width: Self.preferredSize.width, height: Self.preferredSize.height)
        .background {
            ZStack {
                VisualEffectBackground()
                Rectangle().fill(PortPalette.backgroundTint)
            }
        }
        .environment(\.colorScheme, .dark)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.035), lineWidth: 1)
        }
        .task {
            guard !hasAppeared else {
                return
            }

            hasAppeared = true
            await store.refreshNow()
        }
        .alert(
            "Port Action Failed",
            isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        store.clearError()
                    }
                }
            )
        ) {
            Button("OK") {
                store.clearError()
            }
        } message: {
            Text(store.errorMessage ?? "")
        }
        .confirmationDialog(
            "Kill all listed processes?",
            isPresented: $store.isShowingKillAllConfirmation,
            titleVisibility: .visible
        ) {
            Button(killAllConfirmationTitle, role: .destructive) {
                onBeforeKill()
                store.killAll()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This sends SIGTERM first, then SIGKILL if a process is still alive.")
        }
    }

    private var killAllConfirmationTitle: String {
        store.uniqueProcessCount == 1 ? "Kill 1 Process" : "Kill \(store.uniqueProcessCount) Processes"
    }
}

private struct MenuHeaderSpacer: View {
    var body: some View {
        Color.clear
            .frame(height: 4)
    }
}

private struct PortContentView: View {
    @ObservedObject var store: PortMonitorStore
    let onBeforeKill: () -> Void

    var body: some View {
        Group {
            if store.ports.isEmpty {
                EmptyPortsView(isLoading: store.isLoading)
            } else {
                DampedScrollView(scrollScale: 0.28) {
                    VStack(spacing: 0) {
                        ForEach(store.ports) { entry in
                            PortRowView(entry: entry) {
                                onBeforeKill()
                                store.kill(entry)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }
}

private struct EmptyPortsView: View {
    let isLoading: Bool

    var body: some View {
        VStack(spacing: 12) {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .tint(PortPalette.secondaryText)
            } else {
                Image(systemName: "checkmark.circle")
                    .font(PortTypography.sfPro(size: 22, weight: .regular))
                    .foregroundStyle(PortPalette.liveGreen)
            }

            Text(isLoading ? "Scanning local ports" : "No listening ports")
                .font(PortTypography.sfPro(size: 12, weight: .medium))
                .foregroundStyle(PortPalette.primaryText)

            Text(isLoading ? "Looking for TCP listeners." : "Everything visible to lsof is quiet.")
                .font(PortTypography.sfPro(size: 10, weight: .regular))
                .foregroundStyle(PortPalette.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct MenuFooterView: View {
    @ObservedObject var store: PortMonitorStore
    let onBeforeKill: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            DividerLine()

            Button {
                store.refresh()
            } label: {
                MenuActionRow(symbol: "arrow.clockwise", title: "Refresh", shortcut: "⌘R")
            }
            .buttonStyle(.plain)
            .keyboardShortcut("r", modifiers: .command)

            Button(role: .destructive) {
                store.isShowingKillAllConfirmation = true
            } label: {
                MenuActionRow(symbol: "xmark.circle", title: "Kill All", shortcut: "⌘K", isDestructive: true)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("k", modifiers: .command)
            .disabled(store.ports.isEmpty)
            .opacity(store.ports.isEmpty ? 0.45 : 1.0)

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                MenuActionRow(symbol: "power", title: "Quit", shortcut: "⌘Q")
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding(.bottom, 5)
        .background(PortPalette.footerTint)
    }
}

private struct MenuActionRow: View {
    let symbol: String
    let title: String
    let shortcut: String
    var isDestructive = false
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: symbol)
                .font(PortTypography.sfPro(size: 13, weight: .regular))
                .frame(width: 15)

            Text(title)
                .font(PortTypography.sfPro(size: 12, weight: .medium))

            Spacer()

            Text(shortcut)
                .font(PortTypography.sfPro(size: 10, weight: .regular))
                .foregroundStyle(PortPalette.secondaryText)
        }
        .foregroundStyle(isDestructive ? PortPalette.danger : PortPalette.primaryText)
        .padding(.horizontal, 13)
        .frame(height: 29)
        .background(isHovering ? PortPalette.elevated : Color.clear)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
    }
}

private struct DividerLine: View {
    var body: some View {
        Rectangle()
            .fill(PortPalette.divider)
            .frame(height: 1)
    }
}
