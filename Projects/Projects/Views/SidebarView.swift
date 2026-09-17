import SwiftUI

struct SidebarView: View {
    @Binding var selection: NavItem

    var body: some View {
        List(selection: $selection) {
            Section("This Mac") {
                Label("This Mac", systemImage: "desktopcomputer")
                    .tag(NavItem.thisMac)
                Label("Projects", systemImage: "folder")
                    .tag(NavItem.projects)
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
            VStack(alignment: .leading, spacing: 6) {
                Text("No projects yet")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text("Create a project after M0 lands. The coordinator thread lives here, grouped by the machine that runs it.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
        }
    }
}
