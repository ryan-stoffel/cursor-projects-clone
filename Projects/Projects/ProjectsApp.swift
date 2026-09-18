import AppKit
import SwiftUI

@main
struct ProjectsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("Foreman") {
            ContentView()
                .environmentObject(model)
                .preferredColorScheme(.dark)
                .tint(AppTheme.accent)
                .font(AppTheme.body)
                .frame(minWidth: 980, minHeight: 640)
                .background(WindowBackdrop())
                .background(WindowChromeInstall())
                .containerBackground(.clear, for: .window)
                .task { await model.start() }
        }
        .defaultSize(width: 1320, height: 860)
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified)
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
