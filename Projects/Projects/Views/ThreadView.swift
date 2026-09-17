import SwiftUI

struct ThreadView: View {
    @State private var draft = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Coordinator")
                        .font(.headline)
                    Text("Run on This Mac")
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

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Daemon is not connected. projectd starts listening at M0.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                HStack(alignment: .bottom, spacing: 8) {
                    TextField("Message the coordinator", text: $draft, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(1...6)
                        .disabled(true)
                    Button("Send") {}
                        .disabled(true)
                        .keyboardShortcut(.return, modifiers: .command)
                }
            }
            .padding(12)
        }
        .background(.background)
    }
}
