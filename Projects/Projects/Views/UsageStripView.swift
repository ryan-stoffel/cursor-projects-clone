import SwiftUI

struct UsageStripView: View {
    var body: some View {
        HStack(spacing: 16) {
            Text("Usage")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("No token counts yet")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
            Text("Per-model totals land at M4")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .background(.bar)
    }
}

struct MachinesPlaceholderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Machines")
                .font(.title2)
            Text("This Mac is the only machine until M2. Add an SSH host with machine.add; install projectd agent with scripts/install-remote.sh. The app never stores keys; it uses your ~/.ssh/config.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: 520, alignment: .leading)
            HStack(spacing: 8) {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
                Text("This Mac")
                Text("local")
                    .foregroundStyle(.tertiary)
            }
            .padding(10)
            .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct SettingsView: View {
    var body: some View {
        Form {
            Section("Gateway") {
                LabeledContent("Config file") {
                    Text("~/Library/Application Support/projectd/providers.toml")
                        .textSelection(.enabled)
                }
                Text("Every model call uses your OpenAI-compatible gateway. No vendor SDK is linked. Configure providers after M0.")
                    .foregroundStyle(.secondary)
            }
            Section("Daemon") {
                LabeledContent("Socket (macOS)") {
                    Text("~/Library/Application Support/projectd/projectd.sock")
                        .textSelection(.enabled)
                }
                LabeledContent("Database") {
                    Text("~/Library/Application Support/projectd/projectd.sqlite")
                        .textSelection(.enabled)
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
