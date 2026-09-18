import AppKit
import SwiftUI

struct ProjectLook: Codable, Equatable, Hashable {
    var hex: String
    var symbol: String

    static let fallback = ProjectLook(hex: "6B8CAF", symbol: "cube.fill")

    static let symbols = [
        "cube.fill",
        "folder.fill",
        "terminal.fill",
        "doc.text.fill",
        "hammer.fill",
        "shippingbox.fill",
        "cpu.fill",
        "book.closed.fill",
    ]

    static let palette: [Swatch] = [
        Swatch(name: "Steel", hex: "6B8CAF"),
        Swatch(name: "Sage", hex: "5B8E7D"),
        Swatch(name: "Slate", hex: "5D7A8C"),
        Swatch(name: "Dust", hex: "7A6F8A"),
        Swatch(name: "Clay", hex: "8A6A5A"),
        Swatch(name: "Moss", hex: "6A8A6A"),
        Swatch(name: "Khaki", hex: "8B7E66"),
        Swatch(name: "Bronze", hex: "8A7A5A"),
    ]

    var color: Color {
        Color(nsColor: NSColor.fromHex(hex) ?? NSColor(srgbRed: 0.42, green: 0.55, blue: 0.69, alpha: 1))
    }

    static func inferred(from id: String) -> ProjectLook {
        var hash = 0
        for unit in id.utf8 {
            hash = hash &* 31 &+ Int(unit)
        }
        let swatch = palette[abs(hash) % palette.count]
        let symbol = symbols[abs(hash / 17) % symbols.count]
        return ProjectLook(hex: swatch.hex, symbol: symbol)
    }

    struct Swatch: Identifiable, Hashable {
        var name: String
        var hex: String
        var id: String { hex }
        var color: Color {
            Color(nsColor: NSColor.fromHex(hex) ?? .systemBlue)
        }
    }
}

final class ProjectLooks {
    private let key = "foreman.projectLooks.v1"
    private var items: [String: ProjectLook]

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([String: ProjectLook].self, from: data) {
            items = decoded
        } else {
            items = [:]
        }
    }

    func resolved(for id: String) -> ProjectLook {
        items[id] ?? ProjectLook.inferred(from: id)
    }

    func set(_ look: ProjectLook, for id: String) {
        items[id] = look
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

struct ProjectMark: View {
    var look: ProjectLook
    var size: CGFloat = 22

    var body: some View {
        let radius = size * 0.28
        ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(look.color.opacity(0.22))
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(look.color.opacity(0.5), lineWidth: 1)
            Image(systemName: look.symbol)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(look.color)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct ProjectLookPicker: View {
    @Binding var look: ProjectLook

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Color")
                .font(AppTheme.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(ProjectLook.palette) { swatch in
                    Button {
                        look.hex = swatch.hex
                    } label: {
                        Circle()
                            .fill(swatch.color)
                            .frame(width: 16, height: 16)
                            .overlay {
                                Circle()
                                    .strokeBorder(
                                        Color.white.opacity(look.hex == swatch.hex ? 0.92 : 0.18),
                                        lineWidth: look.hex == swatch.hex ? 2 : 1
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                    .help(swatch.name)
                    .accessibilityLabel(swatch.name)
                }
            }
            Text("Icon")
                .font(AppTheme.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            HStack(spacing: 6) {
                ForEach(ProjectLook.symbols, id: \.self) { symbol in
                    Button {
                        look.symbol = symbol
                    } label: {
                        Image(systemName: symbol)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(look.symbol == symbol ? Color.white : AppTheme.accent)
                            .frame(width: 26, height: 26)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(look.symbol == symbol ? AppTheme.accent.opacity(0.9) : AppTheme.raised)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .strokeBorder(AppTheme.hairline, lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(symbol)
                }
            }
        }
    }
}

extension NSColor {
    static func fromHex(_ hex: String) -> NSColor? {
        var raw = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.hasPrefix("#") {
            raw.removeFirst()
        }
        guard raw.count == 6, let value = UInt32(raw, radix: 16) else { return nil }
        let r = CGFloat((value >> 16) & 0xFF) / 255
        let g = CGFloat((value >> 8) & 0xFF) / 255
        let b = CGFloat(value & 0xFF) / 255
        return NSColor(srgbRed: r, green: g, blue: b, alpha: 1)
    }
}
