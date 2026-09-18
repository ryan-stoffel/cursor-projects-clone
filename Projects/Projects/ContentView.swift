import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var looks: ProjectAppearanceStore
    @State private var selectedNav: NavItem = .projects
    @State private var taskPanelVisible = true

    var body: some View {
        ZStack {
            HUDTheme.canvas.ignoresSafeArea()
            VStack(spacing: 0) {
                HUDTopBar(taskPanelVisible: $taskPanelVisible)
                HUDHairline()
                HStack(spacing: 0) {
                    SidebarView(selection: $selectedNav)
                        .frame(width: 248)
                    HUDVLine()
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    if taskPanelVisible, selectedNav == .projects || selectedNav == .thisMac {
                        HUDVLine()
                        TaskPanelView()
                            .frame(width: 268)
                    }
                }
                HUDHairline()
                UsageStripView()
            }
            if model.showNewProject {
                NewProjectSheet()
            }
        }
        .foregroundStyle(HUDTheme.text)
        .tint(HUDTheme.accent)
    }
}

struct HUDTopBar: View {
    @EnvironmentObject private var model: AppModel
    @Binding var taskPanelVisible: Bool

    var body: some View {
        HStack(spacing: 16) {
            HUDLabel(text: "Foreman", color: HUDTheme.text, size: 10)
            HUDTickRow(colors: ProjectSwatch.allCases.prefix(6).map(\.color))
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                HUDLabel(text: "Host", size: 7)
                Text(hostCaption)
                    .font(HUDFont.mono(12))
                    .foregroundStyle(HUDTheme.text)
            }
            VStack(alignment: .trailing, spacing: 2) {
                HUDLabel(text: "Link", size: 7)
                Text(model.connectionStatus == "Connected" ? "OK" : "OFF")
                    .font(HUDFont.display(10))
                    .foregroundStyle(model.connectionStatus == "Connected" ? HUDTheme.warn : HUDTheme.bad)
            }
            Button(taskPanelVisible ? "Bay On" : "Bay Off") {
                taskPanelVisible.toggle()
            }
            .buttonStyle(HUDButtonStyle(kind: .plain, compact: true))
            .help("Show or hide the task bay")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(HUDTheme.panel)
    }

    private var hostCaption: String {
        if let project = model.selectedProject {
            let machine = model.machines.first { $0.id == project.primaryMachineID }?.name ?? "This Mac"
            return machine.uppercased()
        }
        return "THIS MAC"
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
        .environmentObject(ProjectAppearanceStore())
}
