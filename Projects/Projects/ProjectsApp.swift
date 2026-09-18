import SwiftUI

@main
struct ProjectsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()
    @StateObject private var looks = ProjectAppearanceStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .environmentObject(looks)
                .preferredColorScheme(.dark)
                .frame(minWidth: 1100, minHeight: 680)
        .background(HUDTheme.canvas)
        .task { await model.start() }
        .onAppear { HUDFont.register() }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1280, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Project") {
                    model.showNewProject = true
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.appearance = NSAppearance(named: .darkAqua)
        HUDFont.register()
    }

    func applicationWillTerminate(_ notification: Notification) {
        DaemonProcess.stopIfOwned()
    }
}
