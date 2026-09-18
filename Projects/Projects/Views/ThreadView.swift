import SwiftUI

struct ThreadView: View {
    @EnvironmentObject private var model: AppModel
    @Binding var showActivity: Bool
    @FocusState.Binding var composerFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            Hairline()
            ZStack {
                TranscriptView(
                    messages: model.messages,
                    streamingID: model.streamingMessageID,
                    streamingText: model.streamingText
                )
                .opacity(showsTranscript ? 1 : 0)

                if let line = quietLine {
                    Text(line)
                        .font(AppTheme.chrome)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            ComposerView(composerFocused: $composerFocused)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .padding(.top, 8)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            if let project = model.selectedProject {
                ProjectMark(look: model.look(for: project), size: 16)
                Text(project.name)
                    .font(AppTheme.chromeMedium)
                    .lineLimit(1)
            } else {
                Text("Foreman")
                    .font(AppTheme.chromeMedium)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                showActivity.toggle()
            } label: {
                Image(systemName: "sidebar.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(showActivity ? AppTheme.accent : Color.secondary)
                    .frame(width: 28, height: 22)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(showActivity ? AppTheme.rowSelect : Color.clear)
                    )
            }
            .buttonStyle(.plain)
            .help("Activity")
        }
        .padding(.leading, 16)
        .padding(.trailing, 12)
        .frame(height: AppTheme.trafficLights)
    }

    private var showsTranscript: Bool {
        quietLine == nil
    }

    private var quietLine: String? {
        if model.connectionStatus == "Connecting" {
            return "Connecting"
        }
        if !model.isConnected {
            return "Not connected"
        }
        if model.selectedProjectID == nil {
            return "Create a project to start"
        }
        if model.threadLoading && model.messages.isEmpty && model.streamingText.isEmpty {
            return "Loading"
        }
        if model.messages.isEmpty && model.streamingText.isEmpty {
            return "Send a message to plan work"
        }
        return nil
    }
}
