import AppKit
import SwiftUI

struct PortRowView: View {
    let entry: PortProcess
    let onKill: () -> Void
    @State private var isHovering = false
    @State private var isConfirmingKill = false

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                LiveDot()

                Text(verbatim: entry.portLabel)
                    .font(PortTypography.sfPro(size: 14, weight: .medium))
                    .foregroundStyle(PortPalette.primaryText)
                    .lineLimit(1)
                    .frame(width: 66, alignment: .leading)

                Text(entry.displayName)
                    .font(PortTypography.sfPro(size: 12, weight: .medium))
                    .foregroundStyle(PortPalette.primaryText)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: openPortInBrowser)

            ZStack(alignment: .trailing) {
                Text(entry.pidLabel)
                    .font(PortTypography.sfPro(size: 10, weight: .regular))
                    .foregroundStyle(PortPalette.secondaryText)
                    .lineLimit(1)
                    .opacity(isHovering || isConfirmingKill ? 0 : 1)

                InlineKillControl(
                    isConfirming: $isConfirmingKill,
                    isVisible: isHovering || isConfirmingKill,
                    help: "Kill \(entry.processName) on :\(entry.port)"
                ) {
                    isConfirmingKill = false
                    onKill()
                }
            }
            .frame(width: 58, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .frame(height: 31)
        .background(isHovering ? PortPalette.elevated : Color.clear)
        .contentShape(Rectangle())
        .onHover { isHovering in
            self.isHovering = isHovering
            if !isHovering {
                isConfirmingKill = false
            }
        }
        .contextMenu {
            Button("Kill PID \(entry.pid)", role: .destructive, action: onKill)
            Text(entry.endpoint)
        }
    }

    private func openPortInBrowser() {
        guard let url = URL(string: "http://localhost:\(entry.port)") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}

struct LiveDot: View {
    var body: some View {
        Circle()
            .fill(PortPalette.liveGreen)
            .frame(width: 6, height: 6)
    }
}

struct InlineKillControl: View {
    @Binding var isConfirming: Bool
    let isVisible: Bool
    let help: String
    let onConfirm: () -> Void

    var body: some View {
        Group {
            if isConfirming {
                Button(role: .destructive, action: onConfirm) {
                    Text("Kill")
                        .font(PortTypography.sfPro(size: 10, weight: .medium))
                        .foregroundStyle(PortPalette.danger)
                        .padding(.horizontal, 8)
                        .frame(height: 19)
                        .background {
                            Capsule()
                                .fill(PortPalette.dangerFill)
                        }
                        .overlay {
                            Capsule()
                                .stroke(PortPalette.danger.opacity(0.42), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .help("Confirm \(help)")
            } else {
                Button {
                    withAnimation(.snappy(duration: 0.12)) {
                        isConfirming = true
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(PortTypography.sfPro(size: 14, weight: .regular))
                        .foregroundStyle(PortPalette.danger)
                }
                .buttonStyle(.plain)
                .help(help)
            }
        }
        .opacity(isVisible ? 1 : 0)
        .animation(.snappy(duration: 0.12), value: isConfirming)
        .animation(.snappy(duration: 0.12), value: isVisible)
    }
}
