import Darwin
import Foundation

enum DaemonProcess {
    private static var child: Process?
    private static var owned = false

    static func findBinary() -> String? {
        if let env = ProcessInfo.processInfo.environment["PROJECTD_BIN"], !env.isEmpty {
            return env
        }
        if let bundled = Bundle.main.path(forResource: "projectd", ofType: nil) {
            return bundled
        }
        let sibling = (Bundle.main.bundlePath as NSString)
            .appendingPathComponent("Contents/MacOS/projectd")
        if FileManager.default.isExecutableFile(atPath: sibling) {
            return sibling
        }
        return nil
    }

    static func ensureRunning(socketPath: String) {
        if canConnect(socketPath: socketPath) {
            return
        }
        guard let bin = findBinary() else {
            return
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: bin)
        process.arguments = ["--role", "both"]
        var env = ProcessInfo.processInfo.environment
        if env["PROJECTS_CI_SCREENSHOT"] == "1" {
            env["PROJECTD_STUB_PROVIDER"] = "1"
        }
        process.environment = env
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            return
        }
        child = process
        owned = true
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            if canConnect(socketPath: socketPath) {
                return
            }
            Thread.sleep(forTimeInterval: 0.05)
        }
    }

    static func stopIfOwned() {
        guard owned else { return }
        child?.terminate()
        child = nil
        owned = false
    }

    private static func canConnect(socketPath: String) -> Bool {
        let fd = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
        if fd < 0 { return false }
        defer { Darwin.close(fd) }
        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let maxLen = MemoryLayout.size(ofValue: addr.sun_path)
        let ok: Bool = socketPath.withCString { cstr in
            if strlen(cstr) >= maxLen { return false }
            withUnsafeMutablePointer(to: &addr.sun_path) { raw in
                let p = UnsafeMutableRawPointer(raw).assumingMemoryBound(to: CChar.self)
                _ = strncpy(p, cstr, maxLen)
            }
            return true
        }
        guard ok else { return false }
        let len = socklen_t(MemoryLayout<sockaddr_un>.size)
        let rc = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sap in
                Darwin.connect(fd, sap, len)
            }
        }
        return rc == 0
    }
}
