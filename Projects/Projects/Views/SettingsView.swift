import AppKit
import SwiftUI

struct SettingsView: View {
    private var supportDir: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/projectd")
    }

    var body: some View {
        Form {
            Section("Appearance") {
                LabeledContent("UI font") {
                    Text(FontRegistry.family)
                        .textSelection(.enabled)
                }
                Text("JetBrainsMono Nerd Font is bundled when it registers; otherwise JetBrains Mono. Both are SIL Open Font License. SF Symbols are used for chrome icons.")
                    .font(AppTheme.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Gateway") {
                LabeledContent("Config file") {
                    Text(supportDir.appendingPathComponent("providers.toml").path)
                        .textSelection(.enabled)
                        .font(AppTheme.caption)
                }
                Text("Every model call uses your OpenAI-compatible gateway. Copy projectd/providers.toml.example into this path, or set PROJECTD_STUB_PROVIDER=1 for canned coordinator replies.")
                    .font(AppTheme.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Daemon") {
                LabeledContent("Socket (macOS)") {
                    Text(supportDir.appendingPathComponent("projectd.sock").path)
                        .textSelection(.enabled)
                        .font(AppTheme.caption)
                }
                LabeledContent("Database") {
                    Text(supportDir.appendingPathComponent("projectd.sqlite").path)
                        .textSelection(.enabled)
                        .font(AppTheme.caption)
                }
                Button("Reveal Support Folder") {
                    let url = supportDir
                    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
            }
        }
        .formStyle(.grouped)
        .font(AppTheme.body)
        .scrollContentBackground(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.clear)
        .navigationTitle("Settings")
        .navigationSubtitle("Gateway and daemon paths")
    }
}
