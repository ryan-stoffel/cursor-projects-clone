import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var model: AppModel
    @Binding var selection: NavItem

    var body: some View {
        List(selection: $selection) {
            Section("This Mac") {
                Label("This Mac", systemImage: "desktopcomputer")
                    .tag(NavItem.thisMac)
                Label("Projects", systemImage: "folder")
                    .tag(NavItem.projects)
                ForEach(model.projects) { project in
                    Button {
                        selection = .projects
                        Task { await model.selectProject(project.id) }
                    } label: {
                        Label(project.name, systemImage: "bubble.left.and.bubble.right")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(model.selectedProjectID == project.id ? .primary : .secondary)
                }
            }
            Section("Fleet") {
                Label("Machines", systemImage: "server.rack")
                    .tag(NavItem.machines)
            }
            Section {
                Label("Settings", systemImage: "gear")
                    .tag(NavItem.settings)
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    model.showNewProject = true
                } label: {
                    Label("New project", systemImage: "plus")
                }
                .buttonStyle(.bordered)
                if model.projects.isEmpty {
                    Text("No projects yet. Create one to open a coordinator thread on This Mac.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
    }
}
