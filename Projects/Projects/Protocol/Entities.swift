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
