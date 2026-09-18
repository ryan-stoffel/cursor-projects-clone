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
            scrollView.drawsBackground = true
            scrollView.backgroundColor = HUDTheme.canvasNS
            scrollView.borderType = .noBorder
            scrollView.autohidesScrollers = true

            textView.isEditable = false
            textView.isRichText = true
            textView.isHorizontallyResizable = false
            textView.isVerticallyResizable = true
            textView.drawsBackground = true
            textView.backgroundColor = HUDTheme.canvasNS
            textView.textContainerInset = NSSize(width: 14, height: 12)
            textView.textContainer?.widthTracksTextView = true
            textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
            textView.minSize = NSSize(width: 0, height: 0)
            textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            textView.font = HUDFont.monoNS(13)
            textView.textColor = HUDTheme.textNS
            textView.isAutomaticQuoteSubstitutionEnabled = false
            textView.isAutomaticTextReplacementEnabled = false
            textView.insertionPointColor = HUDTheme.accentNS
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
                storage.append(Self.block(heading: "FOREMAN", body: streamingText, streaming: true))
            }
            textView.textStorage?.setAttributedString(storage)
            scrollToEnd()
        }

        private func scrollToEnd() {
            textView.scrollToEndOfDocument(nil)
        }

        private static func heading(_ role: MessageRole) -> String {
            switch role {
            case .user: return "YOU"
            case .coordinator: return "FOREMAN"
            case .system: return "SYS"
            }
        }

        private static var streamAttrs: [NSAttributedString.Key: Any] {
            [
                .font: HUDFont.monoNS(13),
                .foregroundColor: HUDTheme.accentNS,
            ]
        }

        private static func block(heading: String, body: String, streaming: Bool) -> NSAttributedString {
            let out = NSMutableAttributedString()
            out.append(NSAttributedString(string: heading + "\n", attributes: [
                .font: HUDFont.displayNS(8),
                .foregroundColor: HUDTheme.dimNS,
            ]))
            out.append(NSAttributedString(string: body + "\n\n", attributes: [
                .font: HUDFont.monoNS(13),
                .foregroundColor: streaming ? HUDTheme.accentNS : HUDTheme.textNS,
            ]))
            return out
        }
    }
}
