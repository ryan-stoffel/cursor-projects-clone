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
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ProjectMark(look: look, size: 28)
                Text("New project")
                    .font(AppTheme.chromeMedium)
            }

            Form {
                TextField("Name", text: $name)
                TextField("Repository URL", text: $repoURL)
                TextField("Default branch", text: $branch)
                TextField("Coordinator model", text: $coordinator)
                TextField("Worker model", text: $worker)
            }
            .formStyle(.grouped)
            .font(AppTheme.chrome)
            .scrollContentBackground(.hidden)
            .frame(minHeight: 210)

            ProjectLookPicker(look: $look)

            if let error = model.sheetError {
                Text(error)
                    .font(AppTheme.chromeSmall)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    model.sheetError = nil
                    model.showNewProject = false
                }
                .font(AppTheme.chrome)
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
                .font(AppTheme.chrome)
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || creating)
            }
        }
        .padding(20)
        .frame(width: 480)
        .onAppear {
            look = ProjectLook.inferred(from: UUID().uuidString)
            model.sheetError = nil
        }
    }
}
