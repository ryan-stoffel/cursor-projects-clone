import SwiftUI

struct ThreadView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.selectedProject?.name ?? "Coordinator")
                        .font(.headline)
                    Text(runOnCaption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Steer") {}
                    .disabled(true)
                    .help("thread.steer pauses new task creation. Available at M4.")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            ZStack {
                TranscriptView(
                    messages: model.messages,
                    streamingID: model.streamingMessageID,
                    streamingText: model.streamingText
                )
                if model.messages.isEmpty && model.streamingText.isEmpty {
                    emptyState
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text(footerStatus)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                HStack(alignment: .bottom, spacing: 8) {
                    TextField("Message the coordinator", text: $model.draft, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(1...6)
                        .disabled(!canSend)
                    Button("Send") {
                        Task { await model.sendDraft() }
                    }
                    .disabled(!canSend || model.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .keyboardShortcut(.return, modifiers: .command)
                }
            }
            .padding(12)
        }
        .background(.background)
    }

    private var canSend: Bool {
        model.connectionStatus == "Connected" && model.selectedProjectID != nil && !model.sending
    }

    private var runOnCaption: String {
        if let project = model.selectedProject {
            let machine = model.machines.first { $0.id == project.primaryMachineID }?.name ?? project.primaryMachineID
            return "Run on \(machine) · \(project.coordinatorModel)"
        }
        return "Run on This Mac"
    }

    private var footerStatus: String {
        if model.connectionStatus != "Connected" {
            return "Not connected to projectd. Start the daemon with PROJECTD_STUB_PROVIDER=1 or a providers.toml gateway, and set PROJECTD_BIN if the binary is not bundled."
        }
        if model.selectedProjectID == nil {
            return "Create a project to send a message."
        }
        return "Connected to projectd."
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "text.bubble")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text("No messages yet")
                .font(.title3)
            Text("Send a message to plan work. The coordinator proposes tasks and never edits code. Workers run in git worktrees; you review Merge, Changes, or Discard from this thread.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }
}
