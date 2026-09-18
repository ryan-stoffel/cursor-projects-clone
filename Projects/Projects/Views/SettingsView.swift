import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel

    private var supportDir: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/projectd")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Settings")
                .font(AppTheme.chromeMedium)
                .padding(.horizontal, 20)
                .frame(height: AppTheme.trafficLights)
            Hairline()
            Form {
                Section("Gateway") {
                    LabeledContent("Config") {
                        Text(supportDir.appendingPathComponent("providers.toml").path)
                            .textSelection(.enabled)
                            .font(AppTheme.monoSmall)
                    }
                    Text("Copy projectd/providers.toml.example here, or set PROJECTD_STUB_PROVIDER=1.")
                        .font(AppTheme.chromeSmall)
                        .foregroundStyle(.secondary)
                }
                Section("Daemon") {
                    LabeledContent("Socket") {
                        Text(supportDir.appendingPathComponent("projectd.sock").path)
                            .textSelection(.enabled)
                            .font(AppTheme.monoSmall)
                    }
                    LabeledContent("Database") {
                        Text(supportDir.appendingPathComponent("projectd.sqlite").path)
                            .textSelection(.enabled)
                            .font(AppTheme.monoSmall)
                    }
                    Button("Reveal Support Folder") {
                        try? FileManager.default.createDirectory(at: supportDir, withIntermediateDirectories: true)
                        NSWorkspace.shared.activateFileViewerSelecting([supportDir])
                    }
                    .font(AppTheme.chromeSmall)
                }
                Section("Machines") {
                    if model.machines.isEmpty {
                        Text("No machines reported")
                            .font(AppTheme.chromeSmall)
                            .foregroundStyle(.tertiary)
                    } else {
                        ForEach(model.machines) { machine in
                            LabeledContent(machine.name) {
                                Text(machine.kind == .local ? "local" : (machine.sshHost ?? "ssh"))
                                    .foregroundStyle(.secondary)
                            }
                            .font(AppTheme.chrome)
                        }
                    }
                    Text("SSH hosts land at M2. The app never stores keys.")
                        .font(AppTheme.chromeSmall)
                        .foregroundStyle(.tertiary)
                }
                Section("Type") {
                    LabeledContent("Messages") {
                        Text(FontRegistry.family)
                            .font(AppTheme.monoSmall)
                    }
                    Text("San Francisco for chrome. JetBrains Mono for composer, code, and message bodies.")
                        .font(AppTheme.chromeSmall)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .font(AppTheme.chrome)
            .scrollContentBackground(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppTheme.main.opacity(0.9))
    }
}
