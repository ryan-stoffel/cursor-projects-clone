import Foundation

/// Codable mirrors of `projectd/crates/protocol`. Change both in the same PR.

enum MachineKind: String, Codable, Sendable {
    case local
    case ssh
}

struct Machine: Codable, Sendable, Identifiable, Hashable {
    var id: String
    var name: String
    var kind: MachineKind
    var sshHost: String?
    var sshUser: String?
    var sshPort: UInt16?
    var workspaceRoot: String
    var maxParallel: UInt32
    var status: String

    enum CodingKeys: String, CodingKey {
        case id, name, kind, status
        case sshHost = "ssh_host"
        case sshUser = "ssh_user"
        case sshPort = "ssh_port"
        case workspaceRoot = "workspace_root"
        case maxParallel = "max_parallel"
    }
}

struct Project: Codable, Sendable, Identifiable, Hashable {
    var id: String
    var name: String
    var repoURL: String
    var defaultBranch: String
    var primaryMachineID: String
    var coordinatorModel: String
    var workerModel: String
    var createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, name
        case repoURL = "repo_url"
        case defaultBranch = "default_branch"
        case primaryMachineID = "primary_machine_id"
        case coordinatorModel = "coordinator_model"
        case workerModel = "worker_model"
        case createdAt = "created_at"
    }
}

struct Thread: Codable, Sendable, Identifiable, Hashable {
    var id: String
    var projectID: String
    var rollingSummary: String
    var pinnedFacts: String

    enum CodingKeys: String, CodingKey {
        case id
        case projectID = "project_id"
        case rollingSummary = "rolling_summary"
        case pinnedFacts = "pinned_facts"
    }
}

enum MessageRole: String, Codable, Sendable {
    case user
    case coordinator
    case system
}

struct Message: Codable, Sendable, Identifiable, Hashable {
    var id: String
    var threadID: String
    var role: MessageRole
    var content: String
    var card: String?
    var createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, role, content, card
        case threadID = "thread_id"
        case createdAt = "created_at"
    }
}

enum TaskStatus: String, Codable, Sendable {
    case queued, running, blocked, review, merged, discarded
}

struct Task: Codable, Sendable, Identifiable, Hashable {
    var id: String
    var projectID: String
    var parentTaskID: String?
    var title: String
    var spec: String
    var status: TaskStatus
    var machineID: String
    var worktreePath: String?
    var branch: String?
    var resultSummary: String?
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, title, spec, status, branch
        case projectID = "project_id"
        case parentTaskID = "parent_task_id"
        case machineID = "machine_id"
        case worktreePath = "worktree_path"
        case resultSummary = "result_summary"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct AgentRun: Codable, Sendable, Identifiable, Hashable {
    var id: String
    var taskID: String
    var model: String
    var backend: String
    var startedAt: String
    var endedAt: String?
    var promptTokens: UInt64?
    var completionTokens: UInt64?
    var exitReason: String?
    var transcriptPath: String

    enum CodingKeys: String, CodingKey {
        case id, model, backend
        case taskID = "task_id"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case exitReason = "exit_reason"
        case transcriptPath = "transcript_path"
    }
}

enum ContextKind: String, Codable, Sendable {
    case research
    case artifact
    case convention
    case testRecipe = "test_recipe"
}

struct ContextEntry: Codable, Sendable, Identifiable, Hashable {
    var id: String
    var projectID: String
    var path: String
    var kind: ContextKind
    var author: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, path, kind, author
        case projectID = "project_id"
        case updatedAt = "updated_at"
    }
}

enum TriggerKind: String, Codable, Sendable {
    case schedule
    case webhook
    case repoEvent = "repo_event"
}

struct Trigger: Codable, Sendable, Identifiable, Hashable {
    var id: String
    var projectID: String
    var kind: TriggerKind
    var config: String
    var lastFiredAt: String?

    enum CodingKeys: String, CodingKey {
        case id, kind, config
        case projectID = "project_id"
        case lastFiredAt = "last_fired_at"
    }
}

enum ExitReason: String, Codable, Sendable {
    case finished
    case cancelled
    case timeout
    case error
    case modelRefused = "model_refused"
}

struct ProjectCreateParams: Codable, Sendable {
    var name: String
    var repoURL: String
    var defaultBranch: String
    var primaryMachineID: String
    var coordinatorModel: String
    var workerModel: String

    enum CodingKeys: String, CodingKey {
        case name
        case repoURL = "repo_url"
        case defaultBranch = "default_branch"
        case primaryMachineID = "primary_machine_id"
        case coordinatorModel = "coordinator_model"
        case workerModel = "worker_model"
    }
}

struct ThreadSendParams: Codable, Sendable {
    var projectID: String
    var content: String

    enum CodingKeys: String, CodingKey {
        case projectID = "project_id"
        case content
    }
}

struct ThreadGetParams: Codable, Sendable {
    var projectID: String
    var afterMessageID: String?

    enum CodingKeys: String, CodingKey {
        case projectID = "project_id"
        case afterMessageID = "after_message_id"
    }
}

struct MessageDeltaEvent: Codable, Sendable {
    var messageID: String
    var text: String

    enum CodingKeys: String, CodingKey {
        case messageID = "message_id"
        case text
    }
}

struct MessageAppendedEvent: Codable, Sendable {
    var message: Message
}

enum RPCMethod {
    static let machineList = "machine.list"
    static let projectList = "project.list"
    static let projectCreate = "project.create"
    static let threadGet = "thread.get"
    static let threadSend = "thread.send"
}

enum RPCEvent {
    static let messageAppended = "message.appended"
    static let messageDelta = "message.delta"
}
