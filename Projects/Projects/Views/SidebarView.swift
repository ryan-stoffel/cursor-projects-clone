import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var model: AppModel
    @Binding var showSettings: Bool
    @FocusState.Binding var composerFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: AppTheme.trafficLights)

            HStack {
                Text("Projects")
                    .font(AppTheme.chromeSmallMedium)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    model.showNewProject = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("New Project")
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)

            if model.projects.isEmpty {
                Text("No projects")
                    .font(AppTheme.chromeSmall)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(model.projects) { project in
                            SidebarProjectRow(project: project, selected: isSelected(project))
                                .onTapGesture {
                                    showSettings = false
                                    Task { await model.selectProject(project.id) }
                                }
                                .contextMenu { lookMenu(for: project) }
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }

            Hairline()
                .padding(.top, 6)

            VStack(spacing: 2) {
                SidebarAction(title: "New Project", systemImage: "plus") {
                    model.showNewProject = true
                }
                SidebarAction(title: "New chat", systemImage: "square.and.pencil") {
                    showSettings = false
                    composerFocused = true
                }
                .help("One coordinator thread per project")
                SidebarAction(title: "Settings", systemImage: "gear") {
                    showSettings = true
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                    Text(model.isConnected ? "Connected" : model.connectionStatus)
                        .font(AppTheme.chromeMicro)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.top, 6)
                .padding(.bottom, 10)
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
        }
    }

    private func isSelected(_ project: Project) -> Bool {
        !showSettings && model.selectedProjectID == project.id
    }

    private var statusColor: Color {
        switch model.connectionStatus {
        case "Connected":
            return Color(red: 0.42, green: 0.70, blue: 0.48)
        case "Connecting":
            return Color(red: 0.82, green: 0.68, blue: 0.32)
        default:
            return Color.secondary.opacity(0.5)
        }
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
    var selected: Bool

    var body: some View {
        HStack(spacing: 8) {
            ProjectMark(look: model.look(for: project), size: 18)
            Text(project.name)
                .font(AppTheme.chrome)
                .foregroundStyle(selected ? Color.primary : Color.secondary)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(selected ? AppTheme.rowSelect : Color.clear)
        )
        .contentShape(Rectangle())
        .help(project.repoURL)
    }
}

struct SidebarAction: View {
    var title: String
    var systemImage: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .medium))
                    .frame(width: 16)
                Text(title)
                    .font(AppTheme.chromeSmall)
                Spacer()
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
