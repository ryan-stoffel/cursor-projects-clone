import SwiftUI

struct HUDLabel: View {
    var text: String
    var color: Color = HUDTheme.dim
    var size: CGFloat = 8

    var body: some View {
        Text(text.uppercased())
            .font(HUDFont.display(size))
            .foregroundStyle(color)
            .lineLimit(1)
    }
}

struct HUDHairline: View {
    var body: some View {
        Rectangle()
            .fill(HUDTheme.line)
            .frame(height: 1)
    }
}

struct HUDVLine: View {
    var body: some View {
        Rectangle()
            .fill(HUDTheme.line)
            .frame(width: 1)
    }
}

struct HUDButtonStyle: ButtonStyle {
    enum Kind {
        case plain
        case accent
        case ghost
    }

    var kind: Kind = .plain
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        let bg: Color = {
            switch kind {
            case .plain: return HUDTheme.raised
            case .accent: return HUDTheme.accent
            case .ghost: return .clear
            }
        }()
        let fg: Color = kind == .accent ? HUDTheme.canvas : HUDTheme.text
        configuration.label
            .font(HUDFont.display(8))
            .foregroundStyle(fg.opacity(configuration.isPressed ? 0.7 : 1))
            .padding(.horizontal, compact ? 8 : 12)
            .padding(.vertical, compact ? 5 : 7)
            .background(bg)
            .overlay(Rectangle().stroke(kind == .ghost ? HUDTheme.line : HUDTheme.line, lineWidth: 1))
    }
}

struct HUDField: View {
    var title: String
    @Binding var text: String
    var placeholder = ""

    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HUDLabel(text: title)
            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(HUDTheme.dim))
                .textFieldStyle(.plain)
                .font(HUDFont.mono(13))
                .foregroundStyle(HUDTheme.text)
                .padding(.horizontal, 8)
                .padding(.vertical, 7)
                .background(HUDTheme.raised)
                .overlay(Rectangle().stroke(focused ? HUDTheme.accent : HUDTheme.line, lineWidth: 1))
                .focused($focused)
                .tint(HUDTheme.accent)
        }
    }
}

struct HUDSteerMeter: View {
    var body: some View {
        VStack(spacing: 4) {
            HUDLabel(text: "Steer", color: HUDTheme.text)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(HUDTheme.raised)
                    Rectangle()
                        .fill(HUDTheme.line)
                        .frame(width: 1, height: geo.size.height)
                        .offset(x: geo.size.width / 2)
                    Rectangle()
                        .fill(HUDTheme.accent)
                        .frame(width: 6, height: geo.size.height)
                        .offset(x: geo.size.width / 2 - 3)
                }
                .overlay(Rectangle().stroke(HUDTheme.line, lineWidth: 1))
            }
            .frame(height: 12)
            HStack {
                HUDLabel(text: "-1", size: 7)
                Spacer()
                HUDLabel(text: "+1", size: 7)
            }
        }
        .help("thread.steer pauses new task creation. Available at M4.")
        .opacity(0.95)
    }
}

struct HUDBarMeter: View {
    var title: String
    var fill: CGFloat
    var color: Color

    var body: some View {
        VStack(spacing: 4) {
            HUDLabel(text: title, size: 7)
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    Rectangle().fill(HUDTheme.raised)
                    Rectangle()
                        .fill(color)
                        .frame(height: max(2, geo.size.height * fill))
                }
                .overlay(Rectangle().stroke(HUDTheme.line, lineWidth: 1))
            }
            .frame(width: 18, height: 52)
        }
    }
}

struct HUDTickRow: View {
    var colors: [Color]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(colors.enumerated()), id: \.offset) { _, color in
                Rectangle()
                    .fill(color)
                    .frame(width: 18, height: 6)
            }
        }
    }
}

struct HUDErrorBanner: View {
    var message: String
    var onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            HUDLabel(text: "Err", color: HUDTheme.warn)
            Text(message)
                .font(HUDFont.mono(12))
                .foregroundStyle(HUDTheme.text)
                .lineLimit(2)
            Spacer()
            Button("OK") { onDismiss() }
                .buttonStyle(HUDButtonStyle(kind: .plain, compact: true))
        }
        .padding(8)
        .background(HUDTheme.raised)
        .overlay(Rectangle().stroke(HUDTheme.warn, lineWidth: 1))
    }
}
