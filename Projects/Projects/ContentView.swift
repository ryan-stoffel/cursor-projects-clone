import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showSettings = false
    @State private var showActivity = false
    @FocusState private var composerFocused: Bool

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(showSettings: $showSettings, composerFocused: $composerFocused)
                .frame(width: AppTheme.sidebarWidth)
                .background(AppTheme.sidebar.opacity(0.94))

            HairlineVertical()

            ZStack {
                if showSettings {
                    SettingsView()
                } else {
                    ThreadView(showActivity: $showActivity, composerFocused: $composerFocused)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.main.opacity(0.90))

            if showActivity, !showSettings {
                HairlineVertical()
                TaskPanelView { showActivity = false }
                    .frame(width: AppTheme.activityWidth)
                    .background(AppTheme.sidebar.opacity(0.94))
            }
        }
        .ignoresSafeArea(.container, edges: .top)
        .overlay(alignment: .top) {
            if let message = model.errorMessage {
                StatusBanner(message: message) {
                    model.errorMessage = nil
                } retry: {
                    Task { await model.refresh() }
                }
                .padding(.top, 10)
                .padding(.horizontal, 16)
            }
        }
        .sheet(isPresented: $model.showNewProject) {
            NewProjectSheet()
                .environmentObject(model)
        }
    }
}

struct StatusBanner: View {
    var message: String
    var dismiss: () -> Void
    var retry: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(message)
                .font(AppTheme.chromeSmall)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .lineLimit(2)
            Spacer(minLength: 8)
            Button("Retry", action: retry)
                .font(AppTheme.chromeSmallMedium)
                .buttonStyle(.bordered)
                .controlSize(.mini)
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(AppTheme.well.opacity(0.92), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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
