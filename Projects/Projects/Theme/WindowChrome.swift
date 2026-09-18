import AppKit
import SwiftUI

/// Transparent, vibrancy-backed window: desktop and apps behind show through as a frost.
enum WindowChrome {
    static let effectID = NSUserInterfaceItemIdentifier("foreman.root.vibrancy")

    static func apply(to window: NSWindow) {
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.titlebarSeparatorStyle = .none
        window.toolbarStyle = .unified
        if !window.styleMask.contains(.fullSizeContentView) {
            window.styleMask.insert(.fullSizeContentView)
        }
        window.hasShadow = true
        window.invalidateShadow()

        guard let content = window.contentView else { return }
        content.wantsLayer = true
        content.layer?.isOpaque = false
        content.layer?.backgroundColor = NSColor.clear.cgColor

        if !content.subviews.contains(where: { $0.identifier == effectID }) {
            let effect = NSVisualEffectView(frame: content.bounds)
            effect.identifier = effectID
            effect.autoresizingMask = [.width, .height]
            configure(effect, material: .underWindowBackground)
            content.addSubview(effect, positioned: .below, relativeTo: nil)
        }

        retargetEffects(in: content)
    }

    static func configure(_ effect: NSVisualEffectView, material: NSVisualEffectView.Material) {
        effect.material = material
        effect.blendingMode = .behindWindow
        effect.state = .active
        effect.isEmphasized = true
        effect.appearance = NSAppearance(named: .darkAqua)
        effect.wantsLayer = true
        effect.layer?.isOpaque = false
    }

    private static func retargetEffects(in view: NSView) {
        if let effect = view as? NSVisualEffectView {
            effect.blendingMode = .behindWindow
            effect.state = .active
            effect.appearance = NSAppearance(named: .darkAqua)
            if effect.identifier != effectID {
                switch effect.material {
                case .windowBackground, .contentBackground, .underWindowBackground, .fullScreenUI:
                    effect.material = .underWindowBackground
                default:
                    break
                }
            }
        }
        for child in view.subviews {
            retargetEffects(in: child)
        }
    }
}

struct BehindWindowMaterial: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        WindowChrome.configure(view, material: .underWindowBackground)
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        WindowChrome.configure(nsView, material: .underWindowBackground)
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
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            apply()
        }

        override func viewDidMoveToSuperview() {
            super.viewDidMoveToSuperview()
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
