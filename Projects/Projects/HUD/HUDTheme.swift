import AppKit
import SwiftUI

enum HUDTheme {
    static let canvas = Color(red: 0.043, green: 0.047, blue: 0.055)
    static let panel = Color(red: 0.070, green: 0.075, blue: 0.086)
    static let raised = Color(red: 0.102, green: 0.110, blue: 0.125)
    static let line = Color(red: 0.173, green: 0.188, blue: 0.208)
    static let text = Color(red: 0.925, green: 0.925, blue: 0.918)
    static let dim = Color(red: 0.490, green: 0.510, blue: 0.545)
    static let accent = Color(red: 0.239, green: 0.545, blue: 1.000)
    static let warn = Color(red: 0.902, green: 0.769, blue: 0.298)
    static let ok = Color(red: 0.227, green: 0.478, blue: 0.290)
    static let bad = Color(red: 0.706, green: 0.235, blue: 0.235)

    static var canvasNS: NSColor { ns(0.043, 0.047, 0.055) }
    static var textNS: NSColor { ns(0.925, 0.925, 0.918) }
    static var dimNS: NSColor { ns(0.490, 0.510, 0.545) }
    static var accentNS: NSColor { ns(0.239, 0.545, 1.000) }

    private static func ns(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> NSColor {
        NSColor(srgbRed: r, green: g, blue: b, alpha: 1)
    }
}

enum HUDFont {
    static let pixelName = "Press Start 2P"
    static let monoName = "JetBrains Mono"

    static var resolvedPixel = pixelName
    static var resolvedMono = monoName

    static func register() {
        let names = ["PressStart2P-Regular", "JetBrainsMono-Regular"]
        for name in names {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else {
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
        if NSFont(name: pixelName, size: 8) == nil, NSFont(name: "PressStart2P", size: 8) != nil {
            resolvedPixel = "PressStart2P"
        }
        if NSFont(name: monoName, size: 12) == nil, NSFont(name: "JetBrainsMono-Regular", size: 12) != nil {
            resolvedMono = "JetBrainsMono-Regular"
        }
    }

    static func display(_ size: CGFloat) -> Font {
        .custom(resolvedPixel, size: size)
    }

    static func mono(_ size: CGFloat) -> Font {
        .custom(resolvedMono, size: size)
    }

    static func monoNS(_ size: CGFloat) -> NSFont {
        NSFont(name: resolvedMono, size: size)
            ?? NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
    }

    static func displayNS(_ size: CGFloat) -> NSFont {
        NSFont(name: resolvedPixel, size: size)
            ?? NSFont.monospacedSystemFont(ofSize: size, weight: .medium)
    }
}

enum ProjectSwatch: String, CaseIterable, Codable, Identifiable {
    case steer
    case moss
    case olive
    case wine
    case navy
    case rust
    case gold
    case ice

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .steer: return HUDTheme.accent
        case .moss: return Color(red: 0.18, green: 0.38, blue: 0.24)
        case .olive: return Color(red: 0.29, green: 0.35, blue: 0.16)
        case .wine: return Color(red: 0.42, green: 0.16, blue: 0.18)
        case .navy: return Color(red: 0.16, green: 0.24, blue: 0.40)
        case .rust: return Color(red: 0.55, green: 0.18, blue: 0.16)
        case .gold: return HUDTheme.warn
        case .ice: return Color(red: 0.45, green: 0.72, blue: 0.78)
        }
    }
}

struct ProjectLook: Codable, Equatable {
    var swatch: ProjectSwatch
    var icon: PixelGlyph

    static func hashed(_ id: String) -> ProjectLook {
        let h = id.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        let swatches = ProjectSwatch.allCases
        let icons = PixelGlyph.allCases
        return ProjectLook(
            swatch: swatches[h % swatches.count],
            icon: icons[(h / swatches.count) % icons.count]
        )
    }
}

@MainActor
final class ProjectAppearanceStore: ObservableObject {
    @Published private var saved: [String: ProjectLook] = [:]
    private let defaultsKey = "projectd.projectLooks.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode([String: ProjectLook].self, from: data) {
            saved = decoded
        }
    }

    func look(for id: String) -> ProjectLook {
        saved[id] ?? ProjectLook.hashed(id)
    }

    func set(_ look: ProjectLook, for id: String) {
        saved[id] = look
        persist()
        objectWillChange.send()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(saved) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }
}
