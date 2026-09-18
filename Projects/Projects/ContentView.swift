import SwiftUI

enum SidebarItem: Hashable {
    case thisMac
    case project(String)
    case machines
    case settings
}

struct ContentView: View {
    @EnvironmentObject private var model: AppModel
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var sidebarItem: SidebarItem = .thisMac
    @State private var inspectorPresented = true

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selection: $sidebarItem)
                .navigationSplitViewColumnWidth(min: 200, ideal: 236, max: 300)
        } detail: {
            detail
                .toolbarBackground(.ultraThinMaterial, for: .windowToolbar)
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Toggle(isOn: $inspectorPresented) {
                            Label("Tasks", systemImage: "checklist")
                        }
                        .help("Show or hide the task panel")
                        .disabled(!showsTaskInspector)
                    }
                    ToolbarItem(placement: .automatic) {
                        Button {
                            model.showNewProject = true
                        } label: {
                            Label("New Project", systemImage: "plus")
                        }
                        .help("Create a project")
                    }
                }
        }
        .navigationSplitViewStyle(.balanced)
        .inspector(isPresented: inspectorBinding) {
            TaskPanelView()
                .inspectorColumnWidth(min: 248, ideal: 300, max: 400)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            UsageStripView()
        }
        .overlay(alignment: .top) {
            if let message = model.errorMessage {
                StatusBanner(message: message) {
                    model.errorMessage = nil
                } retry: {
                    Task { await model.refresh() }
                }
                .padding(.top, 8)
                .padding(.horizontal, 16)
            }
        }
        .sheet(isPresented: $model.showNewProject) {
            NewProjectSheet()
                .environmentObject(model)
        }
        .onChange(of: sidebarItem) { _, item in
            if case .project(let id) = item {
                Task { await model.selectProject(id) }
            }
        }
        .onChange(of: model.selectedProjectID) { _, id in
            guard let id else { return }
            if case .project = sidebarItem, sidebarItem != .project(id) {
                sidebarItem = .project(id)
            }
        }
        .background(.clear)
    }

    private var sidebarShowsThread: Bool {
        switch sidebarItem {
        case .thisMac, .project: return true
        case .machines, .settings: return false
        }
    }

    private var showsTaskInspector: Bool {
        sidebarShowsThread
    }

    private var inspectorBinding: Binding<Bool> {
        Binding(
            get: { inspectorPresented && showsTaskInspector },
            set: { inspectorPresented = $0 }
        )
    }

    @ViewBuilder
    private var detail: some View {
        switch sidebarItem {
        case .thisMac, .project:
            ThreadView()
        case .machines:
            MachinesView()
        case .settings:
            SettingsView()
        }
    }
}

struct StatusBanner: View {
    var message: String
    var dismiss: () -> Void
    var retry: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 12))
                .padding(.top, 1)
            Text(message)
                .font(AppTheme.caption)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Retry", action: retry)
                .font(AppTheme.captionMedium)
                .buttonStyle(.bordered)
                .controlSize(.small)
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Dismiss")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(AppTheme.hairline, lineWidth: 1)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppModel())
}
