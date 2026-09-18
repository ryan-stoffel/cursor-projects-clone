import SwiftUI

struct ComposerView: View {
    @EnvironmentObject private var model: AppModel
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(footerStatus)
                .font(AppTheme.caption)
                .foregroundStyle(.tertiary)
                .textSelection(.enabled)

            HStack(alignment: .bottom, spacing: 10) {
                TextField("Message the coordinator", text: $model.draft, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(AppTheme.composer)
                    .lineLimit(1...8)
                    .focused($focused)
                    .disabled(!canCompose)
                    .onSubmit {
                        Task { await model.sendDraft() }
                    }

                Button {
                    Task { await model.sendDraft() }
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(canSend ? Color.white : Color.secondary)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle().fill(canSend ? AppTheme.accent : Color.white.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
                .help("Send (Return)")
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(focused ? AppTheme.accent.opacity(0.45) : AppTheme.hairline, lineWidth: 1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.clear)
    }

    private var canCompose: Bool {
        model.isConnected && model.selectedProjectID != nil && !model.sending
    }

    private var canSend: Bool {
        canCompose && !model.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var footerStatus: String {
        if !model.isConnected {
            if model.connectionStatus == "Connecting" {
                return "Connecting to projectd…"
            }
            return "Offline. The composer stays disabled until the daemon answers."
        }
        if model.selectedProjectID == nil {
            return "Create a project to send a message."
        }
        if model.sending {
            return "Sending…"
        }
        return "Connected to projectd. Return or Command-Return sends."
    }
}
