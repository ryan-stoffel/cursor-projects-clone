import SwiftUI

struct ThreadView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            threadHeader
            Hairline()
            ZStack {
                TranscriptView(
                    messages: model.messages,
                    streamingID: model.streamingMessageID,
                    streamingText: model.streamingText
                )
                .opacity(showsTranscript ? 1 : 0)

                overlay
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Hairline()
            ComposerView()
        }
        .background(Color.white.opacity(0.03))
        .navigationTitle(model.selectedProject?.name ?? "Foreman")
        .navigationSubtitle(runOnCaption)
    }

    private var threadHeader: some View {
        HStack(alignment: .center, spacing: 10) {
            if let project = model.selectedProject {
                ProjectMark(look: model.look(for: project), size: 22)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(model.selectedProject?.name ?? "Coordinator")
                    .font(AppTheme.bodyMedium)
                Text(runOnCaption)
                    .font(AppTheme.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Steer") {}
                .disabled(true)
                .help("thread.steer pauses new task creation. Available at M4.")
                .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.clear)
    }

    private var runOnCaption: String {
        if let project = model.selectedProject {
            let machine = model.machines.first { $0.id == project.primaryMachineID }?.name ?? project.primaryMachineID
            return "Run on \(machine)  ·  \(project.coordinatorModel)"
        }
        return "Run on This Mac"
    }

    private var showsTranscript: Bool {
        model.isConnected
            && model.selectedProjectID != nil
            && model.connectionStatus != "Connecting"
            && !(model.messages.isEmpty && model.streamingText.isEmpty)
    }

    @ViewBuilder
    private var overlay: some View {
        if model.connectionStatus == "Connecting" {
            EmptyStateView(
                systemImage: "ellipsis.circle",
                title: "Starting projectd",
                message: "Connecting to the local daemon over the unix socket. This usually takes a moment on first launch."
            ) {
                ProgressView()
                    .controlSize(.small)
            }
        } else if !model.isConnected {
            EmptyStateView(
                systemImage: "wifi.slash",
                title: "Not connected",
                message: "Start projectd with PROJECTD_STUB_PROVIDER=1 or a providers.toml gateway. Set PROJECTD_BIN if the binary is not bundled with the app."
            ) {
                Button("Try again") {
                    Task { await model.refresh() }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        } else if model.selectedProjectID == nil {
            EmptyStateView(
                systemImage: "folder.badge.plus",
                title: "No project selected",
                message: "Create a project to open a coordinator thread. The coordinator proposes work and never edits code. Workers land in git worktrees at M1."
            ) {
                Button("New Project") {
                    model.showNewProject = true
                }
                .keyboardShortcut("n", modifiers: .command)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        } else if model.threadLoading && model.messages.isEmpty && model.streamingText.isEmpty {
            EmptyStateView(
                systemImage: "text.alignleft",
                title: "Loading thread",
                message: "Fetching the coordinator transcript for this project."
            ) {
                ProgressView()
                    .controlSize(.small)
            }
        } else if model.messages.isEmpty && model.streamingText.isEmpty {
            EmptyStateView(
                systemImage: "text.bubble",
                title: "No messages yet",
                message: "Send a message to plan work. The coordinator proposes tasks and never edits code. You review Merge, Changes, or Discard from this thread when workers finish."
            )
        }
    }
}

struct EmptyStateView<Action: View>: View {
    var systemImage: String
    var title: String
    var message: String
    @ViewBuilder var action: () -> Action

    init(
        systemImage: String,
        title: String,
        message: String,
        @ViewBuilder action: @escaping () -> Action
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.action = action
    }

    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(AppTheme.title)
            Text(message)
                .font(AppTheme.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
            action()
                .padding(.top, 4)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(true)
    }
}

extension EmptyStateView where Action == EmptyView {
    init(systemImage: String, title: String, message: String) {
        self.init(systemImage: systemImage, title: title, message: message) {
            EmptyView()
        }
    }
}
