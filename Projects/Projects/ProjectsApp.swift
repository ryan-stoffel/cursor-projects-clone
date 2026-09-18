import AppKit
import SwiftUI

@main
struct ProjectsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ZStack {
                WindowBackdrop()
                ContentView()
                    .environmentObject(model)
            }
            .preferredColorScheme(.dark)
            .tint(AppTheme.accent)
            .frame(minWidth: 900, minHeight: 600)
            .background(WindowChromeInstall().frame(width: 0, height: 0))
            .task { await model.start() }
        }
        .defaultSize(width: 1180, height: 780)
        .windowStyle(.hiddenTitleBar)
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
    func applicationWillFinishLaunching(_ notification: Notification) {
        FontRegistry.registerBundledFonts()
        NSApp.appearance = NSAppearance(named: .darkAqua)
    }

    func applicationWillTerminate(_ notification: Notification) {
        DaemonProcess.stopIfOwned()
    }
}
