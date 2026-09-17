import SwiftUI

@main
struct ProjectsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 960, minHeight: 600)
        }
        .defaultSize(width: 1280, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }

    init() {
        if ProcessInfo.processInfo.environment["PROJECTS_CI_SCREENSHOT"] == "1" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                ProjectsApp.writeReadyMarker()
            }
        }
    }

    private static func writeReadyMarker() {
        guard let path = ProcessInfo.processInfo.environment["PROJECTS_CI_READY_PATH"] else {
            return
        }
        try? "ready".write(toFile: path, atomically: true, encoding: .utf8)
    }
}
