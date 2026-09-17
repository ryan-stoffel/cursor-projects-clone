import SwiftUI

struct TaskPanelView: View {
    private let columns = ["Queued", "Running", "Blocked", "Review"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Tasks")
                .font(.headline)
                .padding(12)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(columns, id: \.self) { column in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(column)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Empty")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                                .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    Text("Cards show machine, model, branch, and elapsed time. Drag reorders queued tasks. Merge, Changes, and Discard land in the thread at M1.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
            }
        }
        .background(.background)
    }
}
