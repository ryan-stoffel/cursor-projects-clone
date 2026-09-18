import SwiftUI

struct NewProjectSheet: View {
    @EnvironmentObject private var model: AppModel
    @State private var name = ""
    @State private var repoURL = ""
    @State private var branch = "main"
    @State private var coordinator = "stub"
    @State private var worker = "stub"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New project")
                .font(.title2)
            Text("Creates a coordinator thread. Workers and git worktrees land at M1. Point coordinator_model at a model your providers.toml gateway serves, or use stub with PROJECTD_STUB_PROVIDER=1.")
                .font(.callout)
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
            .frame(minHeight: 220)
            HStack {
                Spacer()
                Button("Cancel") { model.showNewProject = false }
                    .keyboardShortcut(.cancelAction)
                Button("Create") {
                    Task {
                        await model.createProject(
                            name: name,
                            repoURL: repoURL,
                            branch: branch,
                            coordinator: coordinator,
                            worker: worker
                        )
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 480)
    }
}
