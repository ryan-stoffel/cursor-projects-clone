import Foundation

/// JSON-RPC client stub. Real unix-socket / SSH transport starts at M3.
struct RPCClient: Sendable {
    var socketPath: String {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home
            .appendingPathComponent("Library/Application Support/projectd/projectd.sock")
            .path
    }

    var isConnected: Bool { false }

    func connect() throws {
        throw RPCClientError.notImplemented
    }
}

enum RPCClientError: Error, LocalizedError {
    case notImplemented

    var errorDescription: String? {
        "RPC client is a scaffold. JSON-RPC over the unix socket is M0 on the daemon and M3 in this app."
    }
}
