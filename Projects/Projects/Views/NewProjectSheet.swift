import SwiftUI

struct NewProjectSheet: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var looks: ProjectAppearanceStore
    @State private var name = ""
    @State private var repoURL = ""
    @State private var branch = "main"
    @State private var coordinator = "stub"
    @State private var worker = "stub"
    @State private var swatch: ProjectSwatch = .steer
    @State private var icon: PixelGlyph = .chip

    var body: some View {
        ZStack {
            HUDTheme.canvas.opacity(0.82)
                .ignoresSafeArea()
                .onTapGesture { model.showNewProject = false }
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HUDLabel(text: "New Project", color: HUDTheme.text, size: 10)
                    Spacer()
                    PixelIconView(glyph: icon, color: swatch.color, pixel: 2)
                }
                Text("Creates a coordinator thread. Workers and git worktrees land at M1. Color and icon stay on this Mac.")
                    .font(HUDFont.mono(11))
                    .foregroundStyle(HUDTheme.dim)
                    .fixedSize(horizontal: false, vertical: true)

                HUDField(title: "Name", text: $name, placeholder: "Foreman demo")
                HUDField(title: "Repo", text: $repoURL, placeholder: "https://…")
                HStack(spacing: 8) {
                    HUDField(title: "Branch", text: $branch)
                    HUDField(title: "Coord", text: $coordinator)
                    HUDField(title: "Worker", text: $worker)
                }

                HUDLabel(text: "Color")
                HStack(spacing: 6) {
                    ForEach(ProjectSwatch.allCases) { item in
                        Button {
                            swatch = item
                        } label: {
                            Rectangle()
                                .fill(item.color)
                                .frame(width: 22, height: 14)
                                .overlay(Rectangle().stroke(swatch == item ? HUDTheme.text : HUDTheme.line, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }

                HUDLabel(text: "Icon")
                HStack(spacing: 8) {
                    ForEach(PixelGlyph.allCases) { glyph in
                        Button {
                            icon = glyph
                        } label: {
                            PixelIconView(glyph: glyph, color: swatch.color, pixel: 1.5)
                                .padding(4)
                                .background(icon == glyph ? HUDTheme.raised : Color.clear)
                                .overlay(Rectangle().stroke(icon == glyph ? HUDTheme.accent : HUDTheme.line, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack {
                    Spacer()
                    Button("Cancel") { model.showNewProject = false }
                        .buttonStyle(HUDButtonStyle(kind: .plain, compact: true))
                        .keyboardShortcut(.cancelAction)
                    Button("Create") {
                        Task {
                            if let created = await model.createProject(
                                name: name,
                                repoURL: repoURL,
                                branch: branch,
                                coordinator: coordinator,
                                worker: worker
                            ) {
                                looks.set(ProjectLook(swatch: swatch, icon: icon), for: created.id)
                            }
                        }
                    }
                    .buttonStyle(HUDButtonStyle(kind: .accent, compact: true))
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(16)
            .frame(width: 560)
            .background(HUDTheme.panel)
            .overlay(Rectangle().stroke(HUDTheme.accent, lineWidth: 1))
        }
    }
}
