import SwiftUI

struct ThreadView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var looks: ProjectAppearanceStore
    @FocusState private var composerFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            HUDHairline()
            if let err = model.errorMessage {
                HUDErrorBanner(message: err) { model.errorMessage = nil }
                    .padding(8)
            }
            ZStack {
                TranscriptView(
                    messages: model.messages,
                    streamingID: model.streamingMessageID,
                    streamingText: model.streamingText
                )
                if model.connectionStatus != "Connected" {
                    statusBoard(
                        title: "No Link",
                        body: "Start projectd with PROJECTD_STUB_PROVIDER=1 or a providers.toml gateway. Set PROJECTD_BIN if the binary is not bundled."
                    )
                } else if model.selectedProjectID == nil {
                    statusBoard(
                        title: "No Project",
                        body: "Create a project to send a message. The coordinator plans and never edits code."
                    )
                } else if model.messages.isEmpty && model.streamingText.isEmpty {
                    statusBoard(
                        title: "No Msg",
                        body: "Send a message to plan work. Workers run in git worktrees. Review Merge, Changes, or Discard from this thread."
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            HUDHairline()
            composer
        }
        .background(HUDTheme.canvas)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            if let project = model.selectedProject {
                let look = looks.look(for: project.id)
                PixelIconView(glyph: look.icon, color: look.swatch.color, pixel: 2)
                VStack(alignment: .leading, spacing: 4) {
                    HUDLabel(text: project.name, color: HUDTheme.text)
                    Text(runOnCaption)
                        .font(HUDFont.mono(11))
                        .foregroundStyle(HUDTheme.dim)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HUDLabel(text: "Coordinator", color: HUDTheme.text)
                    Text("Run on This Mac")
                        .font(HUDFont.mono(11))
                        .foregroundStyle(HUDTheme.dim)
                }
            }
            Spacer()
            HUDSteerMeter()
                .frame(width: 180)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(HUDTheme.panel)
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HUDLabel(text: "Msg")
                Spacer()
                HUDLabel(text: footerStatus, size: 7)
            }
            HStack(alignment: .bottom, spacing: 8) {
                TextField("", text: $model.draft, prompt: Text("Message the coordinator").foregroundColor(HUDTheme.dim), axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(HUDFont.mono(13))
                    .foregroundStyle(HUDTheme.text)
                    .lineLimit(1...6)
                    .padding(8)
                    .background(HUDTheme.raised)
                    .overlay(Rectangle().stroke(composerFocused ? HUDTheme.accent : HUDTheme.line, lineWidth: 1))
                    .focused($composerFocused)
                    .disabled(!canSend)
                    .tint(HUDTheme.accent)
                Button("Send") {
                    Task { await model.sendDraft() }
                }
                .buttonStyle(HUDButtonStyle(kind: .accent, compact: true))
                .disabled(!canSend || model.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .padding(10)
        .background(HUDTheme.panel)
    }

    private var canSend: Bool {
        model.connectionStatus == "Connected" && model.selectedProjectID != nil && !model.sending
    }

    private var runOnCaption: String {
        if let project = model.selectedProject {
            let machine = model.machines.first { $0.id == project.primaryMachineID }?.name ?? project.primaryMachineID
            return "RUN \(machine.uppercased())  ·  \(project.coordinatorModel)"
        }
        return "RUN THIS MAC"
    }

    private var footerStatus: String {
        if model.connectionStatus != "Connected" { return "Link off" }
        if model.selectedProjectID == nil { return "Need project" }
        if model.sending { return "Sync" }
        return "Link ok"
    }

    private func statusBoard(title: String, body: String) -> some View {
        VStack(spacing: 12) {
            HUDLabel(text: title, color: HUDTheme.text, size: 10)
            Text(body)
                .font(HUDFont.mono(12))
                .foregroundStyle(HUDTheme.dim)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
        }
        .padding(24)
        .overlay(Rectangle().stroke(HUDTheme.line, lineWidth: 1))
        .allowsHitTesting(false)
    }
}
