import AppKit
import SwiftUI

struct DampedScrollView<Content: View>: NSViewRepresentable {
    let scrollScale: CGFloat
    private let content: Content

    init(scrollScale: CGFloat = 0.82, @ViewBuilder content: () -> Content) {
        self.scrollScale = scrollScale
        self.content = content()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> DampedNSScrollView {
        let scrollView = DampedNSScrollView()
        scrollView.scrollScale = scrollScale
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear
        scrollView.contentView.drawsBackground = false
        scrollView.contentView.backgroundColor = .clear
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.verticalScrollElasticity = .allowed
        scrollView.horizontalScrollElasticity = .none
        scrollView.verticalLineScroll = 7
        scrollView.verticalPageScroll = 90

        let hostingView = NSHostingView(rootView: content)
        hostingView.autoresizingMask = [.width]
        hostingView.frame = NSRect(origin: .zero, size: NSSize(width: 1, height: 1))

        scrollView.documentView = hostingView
        context.coordinator.hostingView = hostingView
        scrollView.onLayout = { [weak coordinator = context.coordinator] scrollView in
            coordinator?.resizeDocument(in: scrollView)
        }

        return scrollView
    }

    func updateNSView(_ scrollView: DampedNSScrollView, context: Context) {
        scrollView.scrollScale = scrollScale
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear
        scrollView.contentView.drawsBackground = false
        scrollView.contentView.backgroundColor = .clear
        context.coordinator.hostingView?.rootView = content
        context.coordinator.resizeDocument(in: scrollView)

        DispatchQueue.main.async {
            context.coordinator.resizeDocument(in: scrollView)
        }
    }

    final class Coordinator {
        var hostingView: NSHostingView<Content>?

        func resizeDocument(in scrollView: NSScrollView) {
            guard let hostingView else {
                return
            }

            let width = max(scrollView.contentView.bounds.width, 1)
            hostingView.frame.size.width = width
            hostingView.layoutSubtreeIfNeeded()

            let fittingHeight = hostingView.fittingSize.height
            let height = max(fittingHeight, scrollView.contentView.bounds.height)
            hostingView.frame = NSRect(x: 0, y: 0, width: width, height: height)
        }
    }
}

final class DampedNSScrollView: NSScrollView {
    var scrollScale: CGFloat = 0.82
    var onLayout: ((DampedNSScrollView) -> Void)?

    override func layout() {
        super.layout()
        onLayout?(self)
    }

    override func scrollWheel(with event: NSEvent) {
        guard documentView != nil else {
            super.scrollWheel(with: event)
            return
        }

        let deltaX = normalizedDeltaX(from: event) * scrollScale
        let deltaY = -normalizedDeltaY(from: event) * scrollScale

        guard deltaX != 0 || deltaY != 0 else {
            super.scrollWheel(with: event)
            return
        }

        scrollBy(x: deltaX, y: deltaY)
    }

    private func normalizedDeltaX(from event: NSEvent) -> CGFloat {
        if event.hasPreciseScrollingDeltas {
            return event.scrollingDeltaX
        }

        return event.scrollingDeltaX * horizontalLineScroll
    }

    private func normalizedDeltaY(from event: NSEvent) -> CGFloat {
        if event.hasPreciseScrollingDeltas {
            return event.scrollingDeltaY
        }

        return event.scrollingDeltaY * verticalLineScroll
    }

    private func scrollBy(x deltaX: CGFloat, y deltaY: CGFloat) {
        guard let documentView else {
            return
        }

        let visibleBounds = contentView.bounds
        let documentFrame = documentView.frame
        let maxX = max(documentFrame.width - visibleBounds.width, 0)
        let maxY = max(documentFrame.height - visibleBounds.height, 0)

        var nextOrigin = visibleBounds.origin
        nextOrigin.x = (nextOrigin.x + deltaX).clamped(to: 0...maxX)

        if documentView.isFlipped {
            nextOrigin.y = (nextOrigin.y + deltaY).clamped(to: 0...maxY)
        } else {
            nextOrigin.y = (nextOrigin.y - deltaY).clamped(to: 0...maxY)
        }

        contentView.scroll(to: nextOrigin)
        reflectScrolledClipView(contentView)
    }
}
