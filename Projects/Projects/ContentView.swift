import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selectedNav: NavItem = .projects
    @State private var taskPanelVisible = true

    var body: some View {
        VSplitView {
            HSplitView {
                SidebarView(selection: $selectedNav)
                    .frame(minWidth: 220, idealWidth: 260, maxWidth: 320)

                Group {
                    switch selectedNav {
                    case .projects, .thisMac:
                        ThreadView()
                    case .machines:
                        MachinesPlaceholderView()
                    case .settings:
                        SettingsView()
                    }
                }
                .frame(minWidth: 420)

                if taskPanelVisible, selectedNav == .projects || selectedNav == .thisMac {
                    TaskPanelView()
                        .frame(minWidth: 260, idealWidth: 320, maxWidth: 420)
                }
            }

            UsageStripView()
                .frame(minHeight: 36, maxHeight: 44)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Toggle(isOn: $taskPanelVisible) {
                    Label("Task panel", systemImage: "sidebar.right")
                }
                .help("Show or hide the task panel")
            }
        }
        .sheet(isPresented: $model.showNewProject) {
            NewProjectSheet()
                .environmentObject(model)
        }
        .alert("projectd", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }
}

enum NavItem: Hashable {
    case thisMac
    case projects
    case machines
    case settings
}

#Preview {
    ContentView()
        .environmentObject(AppModel())
}
