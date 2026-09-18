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
        context.coordinator.update(
            messages: messages,
            streamingID: streamingID,
            streamingText: streamingText
        )
        _ = nsView
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
            textView.drawsBackground = true
            textView.backgroundColor = NSColor(srgbRed: 0.08, green: 0.085, blue: 0.09, alpha: 0.2)
            textView.textContainerInset = NSSize(width: 18, height: 16)
            textView.textContainer?.widthTracksTextView = true
            textView.textContainer?.lineFragmentPadding = 0
            textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
            textView.minSize = NSSize(width: 0, height: 0)
            textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            textView.appearance = NSAppearance(named: .darkAqua)
            textView.font = FontRegistry.ns(13)
            textView.textColor = Self.bodyColor
            textView.insertionPointColor = NSColor.fromHex("6B9EDB") ?? .systemBlue
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
                    textView.textStorage?.append(NSAttributedString(string: extra, attributes: Self.streamAttrs))
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
                storage.append(Self.block(heading: Self.heading(message.role), body: message.content, streaming: false))
            }
            if let streamingID, !streamingText.isEmpty, !messages.contains(where: { $0.id == streamingID }) {
                storage.append(Self.block(heading: "Foreman", body: streamingText, streaming: true))
            }
            textView.textStorage?.setAttributedString(storage)
            scrollToEnd()
        }

        private func scrollToEnd() {
            guard let storage = textView.textStorage, storage.length > 0 else { return }
            if let container = textView.textContainer {
                textView.layoutManager?.ensureLayout(for: container)
            }
            let last = NSRange(location: storage.length - 1, length: 1)
            textView.scrollRangeToVisible(last)
        }

        private static func heading(_ role: MessageRole) -> String {
            switch role {
            case .user: return "You"
            case .coordinator: return "Foreman"
            case .system: return "System"
            }
        }

        private static let bodyColor = NSColor(srgbRed: 0.90, green: 0.91, blue: 0.93, alpha: 1)
        private static let mutedColor = NSColor(srgbRed: 0.62, green: 0.65, blue: 0.70, alpha: 1)
        private static let userHeadingColor = NSColor(srgbRed: 0.56, green: 0.70, blue: 0.86, alpha: 1)

        private static var streamAttrs: [NSAttributedString.Key: Any] {
            [
                .font: FontRegistry.ns(13),
                .foregroundColor: mutedColor,
            ]
        }

        private static func block(heading: String, body: String, streaming: Bool) -> NSAttributedString {
            let out = NSMutableAttributedString()
            let headingColor = heading == "You" ? userHeadingColor : mutedColor
            out.append(NSAttributedString(string: heading + "\n", attributes: [
                .font: FontRegistry.ns(11, weight: .medium),
                .foregroundColor: headingColor,
            ]))
            out.append(NSAttributedString(string: body + "\n\n", attributes: [
                .font: FontRegistry.ns(13),
                .foregroundColor: streaming ? mutedColor : bodyColor,
            ]))
            return out
        }
    }
}
