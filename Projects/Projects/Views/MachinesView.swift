import SwiftUI

struct MachinesView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Hairline()
            if model.machines.isEmpty {
                EmptyStateView(
                    systemImage: "server.rack",
                    title: model.isConnected ? "No machines reported" : "Machines unavailable",
                    message: "This Mac is the only machine until M2. Add an SSH host with machine.add and install projectd agent with scripts/install-remote.sh. The app never stores keys; it uses your ~/.ssh/config."
                ) {
                    if !model.isConnected {
                        Button("Try again") {
                            Task { await model.refresh() }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This Mac is the only machine until M2. Remote SSH hosts land later. The app never stores keys.")
                            .font(AppTheme.caption)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 8)
                        ForEach(model.machines) { machine in
                            MachineCard(machine: machine)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: 640, alignment: .leading)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .background(.clear)
        .navigationTitle("Machines")
        .navigationSubtitle("Local mode until M2")
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Machines")
                    .font(AppTheme.bodyMedium)
                Text("Workers run where you tell them to.")
                    .font(AppTheme.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct MachineCard: View {
    var machine: Machine

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: machine.kind == .local ? "desktopcomputer" : "network")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 28, height: 28)
                .background(AppTheme.raised, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(machine.name)
                    .font(AppTheme.bodyMedium)
                Text(subtitle)
                    .font(AppTheme.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(machine.status)
                .font(AppTheme.micro)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(AppTheme.raised, in: Capsule())
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(AppTheme.hairline, lineWidth: 1)
        }
    }

    private var subtitle: String {
        if machine.kind == .local {
            return "local  ·  \(machine.workspaceRoot)"
        }
        let host = machine.sshHost ?? "ssh"
        return "ssh  ·  \(host)"
    }
}
