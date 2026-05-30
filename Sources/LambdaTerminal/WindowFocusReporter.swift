import AppKit
import SwiftUI

/// Notifies when the hosting `NSWindow` becomes key (multi-window focus tracking).
struct WindowFocusReporter: NSViewRepresentable {
    let onBecomeKey: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            context.coordinator.observe(window: view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.onBecomeKey = onBecomeKey
        context.coordinator.observe(window: nsView.window)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var onBecomeKey: () -> Void = {}
        private var observer: NSObjectProtocol?
        private weak var observedWindow: NSWindow?

        func observe(window: NSWindow?) {
            guard window !== observedWindow else { return }
            if let observer {
                NotificationCenter.default.removeObserver(observer)
                self.observer = nil
            }
            observedWindow = window
            guard let window else { return }
            observer = NotificationCenter.default.addObserver(
                forName: NSWindow.didBecomeKeyNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                self?.onBecomeKey()
            }
            if window.isKeyWindow {
                onBecomeKey()
            }
        }

        deinit {
            if let observer {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}
