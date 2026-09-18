import Combine
import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var machines: [Machine] = []
    @Published var projects: [Project] = []
    @Published var selectedProjectID: String?
    @Published var messages: [Message] = []
    @Published var streamingMessageID: String?
    @Published var streamingText = ""
    @Published var draft = ""
    @Published var connectionStatus = "Disconnected"
    @Published var errorMessage: String?
    @Published var showNewProject = false
    @Published var sending = false

    let rpc = RPCClient()
    private var started = false

    var selectedProject: Project? {
        projects.first { $0.id == selectedProjectID }
    }

    func start() async {
        guard !started else { return }
        started = true
        rpc.onNotification = { [weak self] method, data in
            Task { @MainActor in
                self?.handleNotification(method: method, data: data)
            }
        }
        DaemonProcess.ensureRunning(socketPath: rpc.socketPath)
        await connectWithRetry()
        if ProcessInfo.processInfo.environment["PROJECTS_CI_SCREENSHOT"] == "1" {
            await runScreenshotDemo()
            Self.writeReadyMarker()
        }
    }

    func stop() {
        rpc.disconnect()
        DaemonProcess.stopIfOwned()
        connectionStatus = "Disconnected"
    }

    func refresh() async {
        do {
            machines = try await rpc.call(method: RPCMethod.machineList, params: EmptyParams())
            projects = try await rpc.call(method: RPCMethod.projectList, params: EmptyParams())
            if selectedProjectID == nil {
                selectedProjectID = projects.first?.id
            }
            if let id = selectedProjectID {
                await loadThread(projectID: id)
            }
            connectionStatus = "Connected"
            errorMessage = nil
        } catch {
            connectionStatus = "Disconnected"
            errorMessage = error.localizedDescription
        }
    }

    func selectProject(_ id: String) async {
        selectedProjectID = id
        streamingMessageID = nil
        streamingText = ""
        await loadThread(projectID: id)
    }

    func createProject(name: String, repoURL: String, branch: String, coordinator: String, worker: String) async -> Project? {
        do {
            let created: Project = try await rpc.call(
                method: RPCMethod.projectCreate,
                params: ProjectCreateParams(
                    name: name,
                    repoURL: repoURL,
                    defaultBranch: branch.isEmpty ? "main" : branch,
                    primaryMachineID: "local",
                    coordinatorModel: coordinator.isEmpty ? "stub" : coordinator,
                    workerModel: worker.isEmpty ? coordinator : worker
                )
            )
            showNewProject = false
            await refresh()
            await selectProject(created.id)
            return created
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func sendDraft() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let projectID = selectedProjectID, !text.isEmpty, !sending else { return }
        sending = true
        defer { sending = false }
        do {
            let user: Message = try await rpc.call(
                method: RPCMethod.threadSend,
                params: ThreadSendParams(projectID: projectID, content: text)
            )
            draft = ""
            if !messages.contains(where: { $0.id == user.id }) {
                messages.append(user)
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadThread(projectID: String) async {
        do {
            messages = try await rpc.call(
                method: RPCMethod.threadGet,
                params: ThreadGetParams(projectID: projectID, afterMessageID: nil)
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func handleNotification(method: String, data: Data) {
        let decoder = JSONDecoder()
        if method == RPCEvent.messageDelta {
            guard let ev = try? decoder.decode(MessageDeltaEvent.self, from: data) else { return }
            if streamingMessageID != ev.messageID {
                streamingMessageID = ev.messageID
                streamingText = ""
            }
            streamingText += ev.text
            return
        }
        if method == RPCEvent.messageAppended {
            guard let ev = try? decoder.decode(MessageAppendedEvent.self, from: data) else { return }
            if ev.message.role == .user || ev.message.role == .coordinator {
                if selectedProjectID != nil, !messages.contains(where: { $0.id == ev.message.id }) {
                    messages.append(ev.message)
                }
            }
            if ev.message.id == streamingMessageID {
                streamingMessageID = nil
                streamingText = ""
            }
        }
    }

    private func connectWithRetry() async {
        for _ in 0..<40 {
            do {
                try rpc.connect()
                await refresh()
                if connectionStatus == "Connected" {
                    return
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            try? await Task.sleep(nanoseconds: 80_000_000)
        }
        connectionStatus = "Disconnected"
    }

    private func runScreenshotDemo() async {
        guard connectionStatus == "Connected" else { return }
        if projects.isEmpty {
            await createProject(
                name: "Foreman demo",
                repoURL: "https://github.com/ryan-stoffel/cursor-projects-clone.git",
                branch: "develop",
                coordinator: "stub",
                worker: "stub"
            )
            let demoID = selectedProjectID
            await createProject(
                name: "Worktree",
                repoURL: "https://example.com/worktree.git",
                branch: "main",
                coordinator: "stub",
                worker: "stub"
            )
            if let demoID {
                await selectProject(demoID)
            }
        }
        if messages.isEmpty, selectedProjectID != nil {
            draft = "Plan a README pass on this repo. What would you inspect first?"
            await sendDraft()
            for _ in 0..<50 where streamingText.isEmpty && !messages.contains(where: { $0.role == .coordinator }) {
                try? await Task.sleep(nanoseconds: 80_000_000)
            }
            try? await Task.sleep(nanoseconds: 400_000_000)
        }
    }

    private static func writeReadyMarker() {
        guard let path = ProcessInfo.processInfo.environment["PROJECTS_CI_READY_PATH"] else {
            return
        }
        try? "ready".write(toFile: path, atomically: true, encoding: .utf8)
    }
}

struct EmptyParams: Encodable {}
