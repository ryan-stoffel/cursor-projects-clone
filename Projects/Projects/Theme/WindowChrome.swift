import AppKit
import SwiftUI

/// Transparent window so SwiftUI `NSVisualEffectView` materials can frost the desktop.
enum WindowChrome {
    static func apply(to window: NSWindow) {
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.titlebarSeparatorStyle = .none
        window.toolbarStyle = .unified
        window.appearance = NSAppearance(named: .darkAqua)
        if !window.styleMask.contains(.fullSizeContentView) {
            window.styleMask.insert(.fullSizeContentView)
        }
        window.hasShadow = true
        window.invalidateShadow()
        if let content = window.contentView {
            content.wantsLayer = true
            content.layer?.isOpaque = false
            content.layer?.backgroundColor = NSColor.clear.cgColor
        }
    }
}

struct BehindWindowMaterial: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .underWindowBackground
        view.blendingMode = .behindWindow
        view.state = .active
        view.isEmphasized = true
        view.appearance = NSAppearance(named: .darkAqua)
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = .underWindowBackground
        nsView.blendingMode = .behindWindow
        nsView.state = .active
        nsView.appearance = NSAppearance(named: .darkAqua)
    }
}

struct WindowChromeInstall: NSViewRepresentable {
    func makeNSView(context: Context) -> InstallerView {
        InstallerView()
    }

    func updateNSView(_ nsView: InstallerView, context: Context) {
        nsView.apply()
    }

    final class InstallerView: NSView {
        override var intrinsicContentSize: NSSize { NSSize(width: 1, height: 1) }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            apply()
        }

        func apply() {
            guard let window else { return }
            WindowChrome.apply(to: window)
            DispatchQueue.main.async { [weak self] in
                guard let window = self?.window else { return }
                WindowChrome.apply(to: window)
            }
        }
    }
}

struct WindowBackdrop: View {
    var body: some View {
        ZStack {
            BehindWindowMaterial()
            AppTheme.wash
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
