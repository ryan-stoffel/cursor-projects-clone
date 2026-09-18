import AppKit
import CoreText
import SwiftUI

/// Bundled JetBrains Mono / JetBrainsMono Nerd Font (OFL). Prefer the Nerd Font family when it registers.
enum FontRegistry {
    private static var didRegister = false
    private static var resolvedFamily: String?

    static func registerBundledFonts() {
        guard !didRegister else { return }
        didRegister = true
        let urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts")
            ?? Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil)
            ?? []
        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
        resolvedFamily = pickFamily()
    }

    static var family: String {
        if let resolvedFamily { return resolvedFamily }
        registerBundledFonts()
        return resolvedFamily ?? "JetBrains Mono"
    }

    static func ns(_ size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
        let postscript: [String]
        switch weight {
        case .medium:
            postscript = ["JetBrainsMonoNF-Medium", "JetBrainsMonoNF-Regular", "JetBrainsMono-Regular"]
        case .semibold, .bold, .heavy, .black:
            postscript = ["JetBrainsMonoNF-Bold", "JetBrainsMono-Bold", "JetBrainsMonoNF-Regular"]
        default:
            postscript = ["JetBrainsMonoNF-Regular", "JetBrainsMono-Regular"]
        }
        for name in postscript {
            if let font = NSFont(name: name, size: size) {
                return font
            }
        }
        let familyName = family
        let traits: NSFontTraitMask = weight >= .semibold ? .boldFontMask : []
        if let font = NSFontManager.shared.font(
            withFamily: familyName,
            traits: traits,
            weight: managerWeight(weight),
            size: size
        ) {
            return font
        }
        return NSFont.monospacedSystemFont(ofSize: size, weight: weight)
    }

    static func ui(_ size: CGFloat, weight: NSFont.Weight = .regular) -> Font {
        let base = Font.custom(family, size: size)
        switch weight {
        case .medium:
            return base.weight(.medium)
        case .semibold, .bold, .heavy, .black:
            return base.weight(.semibold)
        default:
            return base
        }
    }

    private static func pickFamily() -> String {
        let preferred = [
            "JetBrainsMono NF",
            "JetBrainsMono Nerd Font",
            "JetBrains Mono",
        ]
        let families = Set(NSFontManager.shared.availableFontFamilies)
        for name in preferred where families.contains(name) {
            return name
        }
        let postscript = [
            "JetBrainsMonoNF-Regular",
            "JetBrainsMonoNerdFont-Regular",
            "JetBrainsMono-Regular",
        ]
        for name in postscript {
            if let familyName = NSFont(name: name, size: 13)?.familyName {
                return familyName
            }
        }
        return NSFont.monospacedSystemFont(ofSize: 13, weight: .regular).familyName ?? "Menlo"
    }

    private static func managerWeight(_ weight: NSFont.Weight) -> Int {
        switch weight {
        case .ultraLight: return 2
        case .thin: return 3
        case .light: return 4
        case .regular: return 5
        case .medium: return 6
        case .semibold: return 8
        case .bold: return 9
        case .heavy: return 10
        case .black: return 11
        default: return 5
        }
    }
}
