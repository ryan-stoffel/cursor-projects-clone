import SwiftUI

struct UsageStripView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        HStack(spacing: 20) {
            stat("Tok", "--")
            stat("Cur", "--")
            HStack(spacing: 8) {
                HUDLabel(text: "Best", size: 7)
                Text("--")
                    .font(HUDFont.display(10))
                    .foregroundStyle(HUDTheme.warn)
            }
            Spacer()
            HUDLabel(text: "Usage M4", size: 7)
            Text(model.connectionStatus == "Connected" ? "LINK OK" : "LINK OFF")
                .font(HUDFont.display(8))
                .foregroundStyle(model.connectionStatus == "Connected" ? HUDTheme.text : HUDTheme.bad)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(HUDTheme.panel)
    }

    private func stat(_ title: String, _ value: String) -> some View {
        HStack(spacing: 8) {
            HUDLabel(text: title, size: 7)
            Text(value)
                .font(HUDFont.display(10))
                .foregroundStyle(HUDTheme.text)
        }
    }
}

struct MachinesPlaceholderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HUDLabel(text: "Machines", color: HUDTheme.text, size: 10)
            Text("This Mac is the only machine until M2. Add an SSH host with machine.add; install projectd agent with scripts/install-remote.sh. The app never stores keys; it uses your ~/.ssh/config.")
                .font(HUDFont.mono(12))
                .foregroundStyle(HUDTheme.dim)
                .frame(maxWidth: 560, alignment: .leading)
            HStack(spacing: 10) {
                Rectangle()
                    .fill(HUDTheme.ok)
                    .frame(width: 10, height: 10)
                VStack(alignment: .leading, spacing: 4) {
                    HUDLabel(text: "This Mac", color: HUDTheme.text)
                    Text("local  ·  online")
                        .font(HUDFont.mono(11))
                        .foregroundStyle(HUDTheme.dim)
                }
                Spacer()
            }
            .padding(10)
            .background(HUDTheme.raised)
            .overlay(Rectangle().stroke(HUDTheme.line, lineWidth: 1))
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(HUDTheme.canvas)
    }
}

struct SettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HUDLabel(text: "Settings", color: HUDTheme.text, size: 10)
            settingBlock(title: "Gateway", rows: [
                ("File", "~/Library/Application Support/projectd/providers.toml"),
                ("Note", "OpenAI-compatible only. Copy projectd/providers.toml.example or set PROJECTD_STUB_PROVIDER=1."),
            ])
            settingBlock(title: "Daemon", rows: [
                ("Sock", "~/Library/Application Support/projectd/projectd.sock"),
                ("Db", "~/Library/Application Support/projectd/projectd.sqlite"),
            ])
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(HUDTheme.canvas)
    }

    private func settingBlock(title: String, rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HUDLabel(text: title, color: HUDTheme.text)
            ForEach(rows, id: \.0) { row in
                HStack(alignment: .top, spacing: 12) {
                    HUDLabel(text: row.0, size: 7)
                        .frame(width: 48, alignment: .leading)
                    Text(row.1)
                        .font(HUDFont.mono(12))
                        .foregroundStyle(HUDTheme.dim)
                        .textSelection(.enabled)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: 720, alignment: .leading)
        .background(HUDTheme.panel)
        .overlay(Rectangle().stroke(HUDTheme.line, lineWidth: 1))
    }
}
