import SwiftUI

struct ComposerView: View {
    @EnvironmentObject private var model: AppModel
    @FocusState.Binding var composerFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Plan work for this project", text: $model.draft, axis: .vertical)
                .textFieldStyle(.plain)
                .font(AppTheme.mono)
                .lineLimit(1...8)
                .focused($composerFocused)
                .disabled(!canCompose)
                .onSubmit {
                    Task { await model.sendDraft() }
                }

            HStack(spacing: 8) {
                if let project = model.selectedProject {
                    HStack(spacing: 4) {
                        Image(systemName: "cpu")
                            .font(.system(size: 10, weight: .semibold))
                        Text(project.coordinatorModel == "stub" ? "Coordinator" : project.coordinatorModel)
                            .font(AppTheme.chromeSmall)
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.05), in: Capsule())
                    .help("Coordinator model")
                }

                Spacer()

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
                .help("Send")
                .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(AppTheme.well.opacity(0.92), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(composerFocused ? AppTheme.accent.opacity(0.35) : AppTheme.hairline, lineWidth: 1)
        }
    }

    private var canCompose: Bool {
        model.isConnected && model.selectedProjectID != nil && !model.sending
    }

    private var canSend: Bool {
        canCompose && !model.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
