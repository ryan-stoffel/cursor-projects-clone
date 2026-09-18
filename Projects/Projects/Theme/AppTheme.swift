import SwiftUI

enum AppTheme {
    /// Cool blue-gray, close to an editor accent rather than a neon HUD.
    static let accent = Color(red: 0.42, green: 0.62, blue: 0.86)
    /// Dark wash over behind-window vibrancy so the chrome is nearly solid.
    static let wash = Color(red: 0.07, green: 0.075, blue: 0.08).opacity(0.68)
    static let hairline = Color.white.opacity(0.08)
    static let raised = Color.white.opacity(0.045)
    static let inset = Color.black.opacity(0.22)

    static var body: Font { FontRegistry.ui(13) }
    static var bodyMedium: Font { FontRegistry.ui(13, weight: .medium) }
    static var caption: Font { FontRegistry.ui(11) }
    static var captionMedium: Font { FontRegistry.ui(11, weight: .medium) }
    static var title: Font { FontRegistry.ui(15, weight: .medium) }
    static var micro: Font { FontRegistry.ui(10) }
    static var composer: Font { FontRegistry.ui(13) }
}

struct Hairline: View {
    var body: some View {
        Rectangle()
            .fill(AppTheme.hairline)
            .frame(height: 1)
            .allowsHitTesting(false)
    }
}
