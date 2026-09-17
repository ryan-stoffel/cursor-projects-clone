import Darwin
import Foundation

/// JSON-RPC 2.0 client over a newline-delimited unix socket.
final class RPCClient: @unchecked Sendable {
    private let lock = NSLock()
    private var fd: Int32 = -1
    private var nextID: UInt64 = 1
    private var pending: [UInt64: CheckedContinuation<Result<Data, Error>, Never>] = [:]
    private var readerThread: Foundation.Thread?
    private var buffer = Data()

    var onNotification: (@Sendable (String, Data) -> Void)?

    var socketPath: String {
        if let override = ProcessInfo.processInfo.environment["PROJECTD_SOCKET"], !override.isEmpty {
            return override
        }
        if let home = ProcessInfo.processInfo.environment["PROJECTD_HOME"], !home.isEmpty {
            return URL(fileURLWithPath: home).appendingPathComponent("projectd.sock").path
        }
        let support = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/projectd")
        return support.appendingPathComponent("projectd.sock").path
    }

    var isConnected: Bool {
        lock.lock()
        defer { lock.unlock() }
        return fd >= 0
    }

    func connect() throws {
        disconnect()
        let path = socketPath
        let newFD = try Self.connectUnix(path: path)
        lock.lock()
        fd = newFD
        lock.unlock()
        startReader()
    }

    func disconnect() {
        lock.lock()
        let old = fd
        fd = -1
        let waiting = pending
        pending.removeAll()
        lock.unlock()
        if old >= 0 {
            Darwin.close(old)
        }
        for (_, cont) in waiting {
            cont.resume(returning: .failure(RPCClientError.disconnected))
        }
    }

    deinit {
        disconnect()
    }

    func call<P: Encodable, R: Decodable>(method: String, params: P) async throws -> R {
        let data = try await callRaw(method: method, params: params)
        return try JSONDecoder().decode(R.self, from: data)
    }

    func callRaw<P: Encodable>(method: String, params: P) async throws -> Data {
        let id: UInt64 = {
            lock.lock()
            defer { lock.unlock() }
            let id = nextID
            nextID += 1
            return id
        }()
        let payload = RPCRequest(id: id, method: method, params: params)
        let encoded = try JSONEncoder().encode(payload)
        guard var line = String(data: encoded, encoding: .utf8) else {
            throw RPCClientError.encoding
        }
        line.append("\n")
        try writeLine(line)
        return try await withCheckedContinuation { continuation in
            lock.lock()
            pending[id] = continuation
            lock.unlock()
        }.get()
    }

    private func writeLine(_ line: String) throws {
        lock.lock()
        let current = fd
        lock.unlock()
        guard current >= 0 else { throw RPCClientError.disconnected }
        try line.utf8CString.withUnsafeBufferPointer { buf in
            // utf8CString includes the trailing NUL; skip it.
            let count = buf.count - 1
            var sent = 0
            while sent < count {
                let n = Darwin.write(current, buf.baseAddress!.advanced(by: sent), count - sent)
                if n <= 0 {
                    throw RPCClientError.writeFailed(errno)
                }
                sent += n
            }
        }
    }

    private func startReader() {
        let thread = Foundation.Thread { [weak self] in
            self?.readLoop()
        }
        thread.name = "projectd.rpc"
        readerThread = thread
        thread.start()
    }

    private func readLoop() {
        var chunk = [UInt8](repeating: 0, count: 4096)
        while true {
            lock.lock()
            let current = fd
            lock.unlock()
            if current < 0 {
                return
            }
            let n = Darwin.read(current, &chunk, chunk.count)
            if n <= 0 {
                failAll(RPCClientError.disconnected)
                return
            }
            lock.lock()
            buffer.append(contentsOf: chunk[0..<n])
            var lines: [Data] = []
            while let nl = buffer.firstIndex(of: 10) {
                let line = buffer.subdata(in: buffer.startIndex..<nl)
                buffer.removeSubrange(buffer.startIndex...nl)
                lines.append(line)
            }
            lock.unlock()
            for line in lines where !line.isEmpty {
                handleLine(line)
            }
        }
    }

    private func handleLine(_ line: Data) {
        guard let obj = try? JSONSerialization.jsonObject(with: line) as? [String: Any] else {
            return
        }
        if let idNumber = jsonID(obj["id"]) {
            lock.lock()
            let cont = pending.removeValue(forKey: idNumber)
            lock.unlock()
            if let err = obj["error"] as? [String: Any] {
                let message = err["message"] as? String ?? "rpc error"
                cont?.resume(returning: .failure(RPCClientError.remote(message)))
                return
            }
            let result = obj["result"] ?? NSNull()
            guard JSONSerialization.isValidJSONObject(result) || result is NSNull else {
                cont?.resume(returning: .failure(RPCClientError.encoding))
                return
            }
            do {
                let data: Data
                if result is NSNull {
                    data = Data("null".utf8)
                } else {
                    data = try JSONSerialization.data(withJSONObject: result)
                }
                cont?.resume(returning: .success(data))
            } catch {
                cont?.resume(returning: .failure(error))
            }
            return
        }
        if let method = obj["method"] as? String {
            let params = obj["params"] ?? [:]
            if JSONSerialization.isValidJSONObject(params),
               let data = try? JSONSerialization.data(withJSONObject: params) {
                onNotification?(method, data)
            }
        }
    }

    private func failAll(_ error: Error) {
        lock.lock()
        let waiting = pending
        pending.removeAll()
        fd = -1
        lock.unlock()
        for (_, cont) in waiting {
            cont.resume(returning: .failure(error))
        }
    }

    private func jsonID(_ raw: Any?) -> UInt64? {
        if let n = raw as? UInt64 { return n }
        if let n = raw as? Int { return UInt64(n) }
        if let n = raw as? NSNumber { return n.uint64Value }
        if let s = raw as? String { return UInt64(s) }
        return nil
    }

    private static func connectUnix(path: String) throws -> Int32 {
        let fd = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
        if fd < 0 {
            throw RPCClientError.connectFailed("socket errno \(errno)")
        }
        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let maxLen = MemoryLayout.size(ofValue: addr.sun_path)
        let copied: Bool = path.withCString { cstr in
            if strlen(cstr) >= maxLen {
                return false
            }
            withUnsafeMutablePointer(to: &addr.sun_path) { raw in
                let p = UnsafeMutableRawPointer(raw).assumingMemoryBound(to: CChar.self)
                _ = strncpy(p, cstr, maxLen)
            }
            return true
        }
        if !copied {
            Darwin.close(fd)
            throw RPCClientError.connectFailed("socket path too long: \(path)")
        }
        let len = socklen_t(MemoryLayout<sockaddr_un>.size)
        let rc = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sap in
                Darwin.connect(fd, sap, len)
            }
        }
        if rc != 0 {
            let e = errno
            Darwin.close(fd)
            throw RPCClientError.connectFailed("connect \(path): errno \(e)")
        }
        return fd
    }
}

private struct RPCRequest<P: Encodable>: Encodable {
    let jsonrpc = "2.0"
    let id: UInt64
    let method: String
    let params: P
}

enum RPCClientError: Error, LocalizedError {
    case notImplemented
    case disconnected
    case encoding
    case writeFailed(Int32)
    case connectFailed(String)
    case remote(String)

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "RPC client method is not implemented."
        case .disconnected:
            return "Disconnected from projectd."
        case .encoding:
            return "Could not encode or decode a JSON-RPC payload."
        case .writeFailed(let code):
            return "Write to projectd failed (errno \(code))."
        case .connectFailed(let detail):
            return "Could not connect to projectd: \(detail)"
        case .remote(let message):
            return message
        }
    }
}
