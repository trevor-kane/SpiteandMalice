#if canImport(AppKit)
import SwiftUI
import AppKit

/// A background configurator that applies window-level policies for macOS.
struct WindowConfigurator: NSViewRepresentable {
    let minSize: NSSize

    init(minSize: NSSize = NSSize(width: 800, height: 600)) {
        self.minSize = minSize
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async { configureWindow(for: view) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { configureWindow(for: nsView) }
    }

    private func configureWindow(for view: NSView) {
        guard let window = view.window else { return }
        // Ensure the window is resizable and supports full screen.
        window.styleMask.insert([.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView])
        window.collectionBehavior.insert(.fullScreenPrimary)
        window.isMovableByWindowBackground = false
        window.isRestorable = true
        window.tabbingMode = .preferred
        window.minSize = minSize
        // Keep the title bar visible with standard traffic lights and resizing indicators.
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
    }
}
#endif
