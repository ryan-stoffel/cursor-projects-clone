import SwiftUI

struct TaskPanelView: View {
    private let columns: [(title: String, symbol: String, hint: String)] = [
        ("Queued", "tray", "Drag reorders queued work at M1."),
        ("Running", "play.circle", "Live agent runs appear here."),
        ("Blocked", "pause.circle", "Waiting on you or a dependency."),
        ("Review", "eye", "Merge, Changes, and Discard land in the thread."),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Tasks")
                    .font(AppTheme.bodyMedium)
                Spacer()
                Text("M1")
                    .font(AppTheme.micro)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.raised, in: Capsule())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Hairline()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(columns, id: \.title) { column in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: column.symbol)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                Text(column.title)
                                    .font(AppTheme.captionMedium)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("0")
                                    .font(AppTheme.micro)
                                    .foregroundStyle(.tertiary)
                            }
                            VStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.quaternary)
                                Text("Empty")
                                    .font(AppTheme.caption)
                                    .foregroundStyle(.tertiary)
                                Text(column.hint)
                                    .font(AppTheme.micro)
                                    .foregroundStyle(.quaternary)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 10)
                            .background(AppTheme.raised, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                                    .foregroundStyle(AppTheme.hairline)
                            }
                        }
                    }
                    Text("Cards will show machine, model, branch, and elapsed time. The coordinator never edits code; workers run in git worktrees.")
                        .font(AppTheme.caption)
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
            }
            .scrollContentBackground(.hidden)
        }
        .background(.ultraThinMaterial)
    }
}
