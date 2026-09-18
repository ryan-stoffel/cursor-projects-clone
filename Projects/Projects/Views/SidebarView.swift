import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var model: AppModel
    @Binding var selection: SidebarItem

    var body: some View {
        List(selection: $selection) {
            Section {
                Label("This Mac", systemImage: "desktopcomputer")
                    .tag(SidebarItem.thisMac)
                    .font(AppTheme.body)
            } header: {
                Text("This Mac")
                    .font(AppTheme.captionMedium)
            }

            Section {
                if model.projects.isEmpty {
                    Text("No projects yet")
                        .font(AppTheme.caption)
                        .foregroundStyle(.tertiary)
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(model.projects) { project in
                        SidebarProjectRow(project: project)
                            .tag(SidebarItem.project(project.id))
                            .contextMenu {
                                lookMenu(for: project)
                            }
                    }
                }
            } header: {
                HStack {
                    Text("Projects")
                        .font(AppTheme.captionMedium)
                    Spacer()
                    Button {
                        model.showNewProject = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                    .help("New project")
                    .accessibilityLabel("New project")
                }
            }

            Section {
                Label("Machines", systemImage: "server.rack")
                    .tag(SidebarItem.machines)
                    .font(AppTheme.body)
            } header: {
                Text("Fleet")
                    .font(AppTheme.captionMedium)
            }

            Section {
                Label("Settings", systemImage: "gear")
                    .tag(SidebarItem.settings)
                    .font(AppTheme.body)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .bottom) {
            sidebarFooter
        }
    }

    private var sidebarFooter: some View {
        VStack(alignment: .leading, spacing: 8) {
            if model.projects.isEmpty {
                Text("Create a project to open a coordinator thread on This Mac.")
                    .font(AppTheme.caption)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button {
                model.showNewProject = true
            } label: {
                Label("New Project", systemImage: "plus")
                    .font(AppTheme.captionMedium)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .keyboardShortcut("n", modifiers: .command)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) { Hairline() }
    }

    @ViewBuilder
    private func lookMenu(for project: Project) -> some View {
        Menu("Color") {
            ForEach(ProjectLook.palette) { swatch in
                Button(swatch.name) {
                    var look = model.look(for: project)
                    look.hex = swatch.hex
                    model.setLook(look, for: project.id)
                }
            }
        }
        Menu("Icon") {
            ForEach(ProjectLook.symbols, id: \.self) { symbol in
                Button {
                    var look = model.look(for: project)
                    look.symbol = symbol
                    model.setLook(look, for: project.id)
                } label: {
                    Label(symbol.replacingOccurrences(of: ".fill", with: "").replacingOccurrences(of: ".", with: " "), systemImage: symbol)
                }
            }
        }
    }
}

struct SidebarProjectRow: View {
    @EnvironmentObject private var model: AppModel
    var project: Project

    var body: some View {
        HStack(spacing: 8) {
            ProjectMark(look: model.look(for: project), size: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(project.name)
                    .font(AppTheme.bodyMedium)
                    .lineLimit(1)
                Text(project.coordinatorModel)
                    .font(AppTheme.micro)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
        .help(project.repoURL)
    }
}
