import AppKit
import SwiftUI

struct TranscriptView: NSViewRepresentable {
    var messages: [Message]
    var streamingID: String?
    var streamingText: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSScrollView {
        context.coordinator.makeScrollView()
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let textView = context.coordinator.textView
        let usable = max(320, nsView.contentSize.width - textView.textContainerInset.width * 2)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: usable, height: CGFloat.greatestFiniteMagnitude)
        context.coordinator.update(
            messages: messages,
            streamingID: streamingID,
            streamingText: streamingText
        )
    }

    final class Coordinator {
        let textView = NSTextView()
        let scrollView = NSScrollView()
        private var lastIDs: [String] = []
        private var lastStreamID: String?
        private var lastStreamLen = 0

        func makeScrollView() -> NSScrollView {
            scrollView.hasVerticalScroller = true
            scrollView.hasHorizontalScroller = false
            scrollView.drawsBackground = false
            scrollView.borderType = .noBorder
            scrollView.autohidesScrollers = true
            scrollView.backgroundColor = .clear
            scrollView.appearance = NSAppearance(named: .darkAqua)

            textView.isEditable = false
            textView.isRichText = true
            textView.isHorizontallyResizable = false
            textView.isVerticallyResizable = true
            textView.drawsBackground = false
            textView.backgroundColor = .clear
            textView.textContainerInset = NSSize(width: 28, height: 20)
            textView.textContainer?.widthTracksTextView = true
            textView.textContainer?.lineFragmentPadding = 0
            textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
            textView.minSize = NSSize(width: 0, height: 0)
            textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            textView.appearance = NSAppearance(named: .darkAqua)
            textView.font = FontRegistry.ns(13.5)
            textView.textColor = TranscriptRichText.assistantColor
            textView.isAutomaticQuoteSubstitutionEnabled = false
            textView.isAutomaticTextReplacementEnabled = false
            textView.isAutomaticDashSubstitutionEnabled = false
            textView.isAutomaticSpellingCorrectionEnabled = false
            textView.autoresizingMask = [.width]
            scrollView.documentView = textView
            return scrollView
        }

        func update(messages: [Message], streamingID: String?, streamingText: String) {
            let ids = messages.map(\.id)
            let canAppend = ids == lastIDs
                && streamingID == lastStreamID
                && streamingID != nil
                && streamingText.count >= lastStreamLen
            if canAppend {
                let extra = String(streamingText.dropFirst(lastStreamLen))
                if !extra.isEmpty {
                    textView.textStorage?.append(NSAttributedString(string: extra, attributes: TranscriptRichText.streamAttrs))
                    lastStreamLen = streamingText.count
                    scrollToEnd()
                }
                return
            }
            rebuild(messages: messages, streamingID: streamingID, streamingText: streamingText)
            lastIDs = ids
            lastStreamID = streamingID
            lastStreamLen = streamingText.count
        }

        private func rebuild(messages: [Message], streamingID: String?, streamingText: String) {
            let storage = NSMutableAttributedString()
            for message in messages {
                storage.append(TranscriptRichText.block(role: message.role, text: message.content, streaming: false))
            }
            if let streamingID, !streamingText.isEmpty, !messages.contains(where: { $0.id == streamingID }) {
                storage.append(TranscriptRichText.block(role: .coordinator, text: streamingText, streaming: true))
            }
            textView.textStorage?.setAttributedString(storage)
            scrollToEnd()
        }

        private func scrollToEnd() {
            guard let storage = textView.textStorage, storage.length > 0 else { return }
            if let container = textView.textContainer {
                textView.layoutManager?.ensureLayout(for: container)
            }
            textView.scrollRangeToVisible(NSRange(location: storage.length - 1, length: 1))
        }
    }
}

enum TranscriptRichText {
    static let assistantColor = NSColor(srgbRed: 0.82, green: 0.82, blue: 0.84, alpha: 1)
    static let userColor = NSColor(srgbRed: 0.93, green: 0.93, blue: 0.94, alpha: 1)
    static let mutedColor = NSColor(srgbRed: 0.55, green: 0.56, blue: 0.58, alpha: 1)
    static let codeColor = NSColor(srgbRed: 0.78, green: 0.84, blue: 0.72, alpha: 1)
    static let userBg = NSColor(srgbRed: 0.18, green: 0.18, blue: 0.185, alpha: 1)
    static let codeBg = NSColor(srgbRed: 0.09, green: 0.09, blue: 0.095, alpha: 1)

    static var streamAttrs: [NSAttributedString.Key: Any] {
        [
            .font: FontRegistry.ns(13.5),
            .foregroundColor: assistantColor,
            .paragraphStyle: assistantStyle,
        ]
    }

    static func block(role: MessageRole, text: String, streaming: Bool) -> NSAttributedString {
        let out = NSMutableAttributedString()
        if role == .user {
            out.append(userBlock(text))
        } else if streaming {
            out.append(plain(text + "\n", attrs: streamAttrs))
        } else {
            out.append(markdown(text))
            out.append(plain("\n", attrs: streamAttrs))
        }
        return out
    }

    private static func userBlock(_ text: String) -> NSAttributedString {
        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = 1.4
        style.paragraphSpacing = 6
        style.paragraphSpacingBefore = 18
        style.lineBreakMode = .byWordWrapping
        let attrs: [NSAttributedString.Key: Any] = [
            .font: FontRegistry.ns(13),
            .foregroundColor: userColor,
            .paragraphStyle: style,
            .backgroundColor: userBg,
        ]
        return plain(text.trimmingCharacters(in: .newlines) + "\n", attrs: attrs)
    }

    private static var assistantStyle: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = 1.5
        style.paragraphSpacing = 8
        style.paragraphSpacingBefore = 14
        return style
    }

    private static func markdown(_ raw: String) -> NSAttributedString {
        let out = NSMutableAttributedString()
        var remaining = raw.replacingOccurrences(of: "\r\n", with: "\n")
        while let start = remaining.range(of: "```") {
            let before = String(remaining[..<start.lowerBound])
            if !before.isEmpty {
                out.append(markdownBlocks(before))
            }
            remaining = String(remaining[start.upperBound...])
            if let end = remaining.range(of: "```") {
                var code = String(remaining[..<end.lowerBound])
                if code.hasPrefix("\n") { code.removeFirst() }
                if !code.hasSuffix("\n") { code.append("\n") }
                out.append(codeBlock(code))
                remaining = String(remaining[end.upperBound...])
                if remaining.hasPrefix("\n") { remaining.removeFirst() }
            } else {
                out.append(codeBlock(remaining))
                remaining = ""
            }
        }
        if !remaining.isEmpty {
            out.append(markdownBlocks(remaining))
        }
        return out
    }

    private static func markdownBlocks(_ text: String) -> NSAttributedString {
        let out = NSMutableAttributedString()
        let paragraphs = text.components(separatedBy: "\n")
        for line in paragraphs {
            if line.hasPrefix("### ") {
                out.append(heading(String(line.dropFirst(4)), size: 14))
            } else if line.hasPrefix("## ") {
                out.append(heading(String(line.dropFirst(3)), size: 15.5))
            } else if line.hasPrefix("# ") {
                out.append(heading(String(line.dropFirst(2)), size: 17))
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                out.append(listItem(String(line.dropFirst(2))))
            } else if line.isEmpty {
                out.append(plain("\n", attrs: [
                    .font: FontRegistry.ns(8),
                    .paragraphStyle: assistantStyle,
                ]))
            } else {
                out.append(inline(line + "\n", size: 13.5, weight: .regular, color: assistantColor, style: assistantStyle))
            }
        }
        return out
    }

    private static func heading(_ text: String, size: CGFloat) -> NSAttributedString {
        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = 1.25
        style.paragraphSpacing = 8
        style.paragraphSpacingBefore = 16
        return inline(text + "\n", size: size, weight: .medium, color: userColor, style: style)
    }

    private static func listItem(_ text: String) -> NSAttributedString {
        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = 1.45
        style.paragraphSpacing = 4
        style.headIndent = 22
        style.firstLineHeadIndent = 10
        return inline("•  " + text + "\n", size: 13.5, weight: .regular, color: assistantColor, style: style)
    }

    private static func codeBlock(_ text: String) -> NSAttributedString {
        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = 1.35
        style.paragraphSpacing = 10
        style.paragraphSpacingBefore = 8
        let attrs: [NSAttributedString.Key: Any] = [
            .font: FontRegistry.ns(12.5),
            .foregroundColor: codeColor,
            .paragraphStyle: style,
            .backgroundColor: codeBg,
        ]
        return NSAttributedString(string: text, attributes: attrs)
    }

    private static func inline(
        _ text: String,
        size: CGFloat,
        weight: NSFont.Weight,
        color: NSColor,
        style: NSParagraphStyle
    ) -> NSAttributedString {
        let base: [NSAttributedString.Key: Any] = [
            .font: FontRegistry.ns(size, weight: weight),
            .foregroundColor: color,
            .paragraphStyle: style,
        ]
        let out = NSMutableAttributedString(string: text, attributes: base)
        applyInlineMarker(out, marker: "`", attrs: [
            .font: FontRegistry.ns(max(11, size - 1)),
            .foregroundColor: codeColor,
            .backgroundColor: codeBg,
        ])
        applyInlineMarker(out, marker: "**", attrs: [
            .font: FontRegistry.ns(size, weight: .semibold),
            .foregroundColor: color,
        ])
        return out
    }

    private static func applyInlineMarker(
        _ storage: NSMutableAttributedString,
        marker: String,
        attrs: [NSAttributedString.Key: Any]
    ) {
        var search = 0
        while true {
            let value = storage.string as NSString
            if search >= value.length { break }
            let first = value.range(of: marker, options: [], range: NSRange(location: search, length: value.length - search))
            if first.location == NSNotFound { break }
            let after = first.location + first.length
            guard after < value.length else { break }
            let second = value.range(of: marker, options: [], range: NSRange(location: after, length: value.length - after))
            if second.location == NSNotFound { break }
            let inner = NSRange(location: after, length: second.location - after)
            storage.addAttributes(attrs, range: inner)
            storage.replaceCharacters(in: second, with: "")
            storage.replaceCharacters(in: first, with: "")
            search = first.location + inner.length
        }
    }

    private static func plain(_ text: String, attrs: [NSAttributedString.Key: Any]) -> NSAttributedString {
        NSAttributedString(string: text, attributes: attrs)
    }
}
