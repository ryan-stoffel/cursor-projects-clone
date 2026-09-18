import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var looks: ProjectAppearanceStore
    @Binding var selection: NavItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HUDLabel(text: "Projects")
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)

            if model.projects.isEmpty {
                HUDLabel(text: "None", color: HUDTheme.dim, size: 7)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                Text("Create a project to open a coordinator thread on This Mac.")
                    .font(HUDFont.mono(11))
                    .foregroundStyle(HUDTheme.dim)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(model.projects) { project in
                            projectRow(project)
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }

            Spacer(minLength: 8)

            Button {
                model.showNewProject = true
            } label: {
                Text("New")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(HUDButtonStyle(kind: .accent, compact: true))
            .padding(.horizontal, 12)
            .padding(.bottom, 12)

            HUDHairline()
            navButton("Machines", item: .machines)
            navButton("Settings", item: .settings)
                .padding(.bottom, 8)
        }
        .background(HUDTheme.panel)
    }

    private func projectRow(_ project: Project) -> some View {
        let look = looks.look(for: project.id)
        let selected = model.selectedProjectID == project.id && (selection == .projects || selection == .thisMac)
        return Button {
            selection = .projects
            Task { await model.selectProject(project.id) }
        } label: {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(look.swatch.color)
                    .frame(width: 6, height: 24)
                PixelIconView(glyph: look.icon, color: look.swatch.color, pixel: 1.5)
                Text(project.name)
                    .font(HUDFont.mono(12))
                    .foregroundStyle(selected ? HUDTheme.text : HUDTheme.dim)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.trailing, 6)
            .background(selected ? HUDTheme.raised : Color.clear)
            .overlay(Rectangle().stroke(selected ? HUDTheme.accent : Color.clear, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Menu("Color") {
                ForEach(ProjectSwatch.allCases) { swatch in
                    Button(swatch.rawValue.uppercased()) {
                        looks.set(ProjectLook(swatch: swatch, icon: look.icon), for: project.id)
                    }
                }
            }
            Menu("Icon") {
                ForEach(PixelGlyph.allCases) { glyph in
                    Button(glyph.rawValue.uppercased()) {
                        looks.set(ProjectLook(swatch: look.swatch, icon: glyph), for: project.id)
                    }
                }
            }
        }
    }

    private func navButton(_ title: String, item: NavItem) -> some View {
        Button {
            selection = item
        } label: {
            HStack {
                HUDLabel(text: title, color: selection == item ? HUDTheme.text : HUDTheme.dim)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(selection == item ? HUDTheme.raised : Color.clear)
        }
        .buttonStyle(.plain)
    }
}
