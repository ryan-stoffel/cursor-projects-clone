import SwiftUI

enum AppTheme {
    static let accent = Color(red: 0.51, green: 0.70, blue: 0.96)

    static let sidebar = Color(red: 20 / 255, green: 20 / 255, blue: 20 / 255)
    static let main = Color(red: 26 / 255, green: 26 / 255, blue: 26 / 255)
    static let well = Color(red: 14 / 255, green: 14 / 255, blue: 14 / 255)
    static let wash = Color(red: 14 / 255, green: 14 / 255, blue: 14 / 255).opacity(0.84)
    static let hairline = Color.white.opacity(0.07)
    static let rowSelect = Color.white.opacity(0.08)
    static let userFill = Color.white.opacity(0.05)

    static let trafficLights: CGFloat = 52
    static let sidebarWidth: CGFloat = 244
    static let activityWidth: CGFloat = 216

    static let chrome = Font.system(size: 13)
    static let chromeMedium = Font.system(size: 13, weight: .medium)
    static let chromeSmall = Font.system(size: 11)
    static let chromeSmallMedium = Font.system(size: 11, weight: .medium)
    static let chromeMicro = Font.system(size: 10, weight: .medium)

    static var mono: Font { FontRegistry.ui(13) }
    static var monoSmall: Font { FontRegistry.ui(12) }
}

struct Hairline: View {
    var body: some View {
        Rectangle()
            .fill(AppTheme.hairline)
            .frame(height: 1)
            .allowsHitTesting(false)
    }
}

struct HairlineVertical: View {
    var body: some View {
        Rectangle()
            .fill(AppTheme.hairline)
            .frame(width: 1)
            .allowsHitTesting(false)
    }
}
