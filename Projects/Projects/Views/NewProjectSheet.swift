import SwiftUI

struct NewProjectSheet: View {
    @EnvironmentObject private var model: AppModel
    @State private var name = ""
    @State private var repoURL = ""
    @State private var branch = "main"
    @State private var coordinator = "stub"
    @State private var worker = "stub"
    @State private var look = ProjectLook.fallback
    @State private var creating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                ProjectMark(look: look, size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text("New project")
                        .font(AppTheme.title)
                    Text("Opens a coordinator thread. Workers and git worktrees land at M1.")
                        .font(AppTheme.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text("Point coordinator_model at a model your providers.toml gateway serves, or use stub with PROJECTD_STUB_PROVIDER=1.")
                .font(AppTheme.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Form {
                TextField("Name", text: $name)
                TextField("Repository URL", text: $repoURL)
                TextField("Default branch", text: $branch)
                TextField("Coordinator model", text: $coordinator)
                TextField("Worker model", text: $worker)
            }
            .formStyle(.grouped)
            .font(AppTheme.body)
            .scrollContentBackground(.hidden)
            .frame(minHeight: 220)

            ProjectLookPicker(look: $look)

            if let error = model.sheetError {
                Text(error)
                    .font(AppTheme.caption)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    model.sheetError = nil
                    model.showNewProject = false
                }
                .keyboardShortcut(.cancelAction)
                Button {
                    creating = true
                    Task {
                        await model.createProject(
                            name: name,
                            repoURL: repoURL,
                            branch: branch,
                            coordinator: coordinator,
                            worker: worker,
                            look: look
                        )
                        creating = false
                    }
                } label: {
                    if creating {
                        ProgressView()
                            .controlSize(.small)
                            .frame(width: 52)
                    } else {
                        Text("Create")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || creating)
            }
        }
        .padding(20)
        .frame(width: 520)
        .font(AppTheme.body)
        .onAppear {
            look = ProjectLook.inferred(from: UUID().uuidString)
            model.sheetError = nil
        }
    }
}
