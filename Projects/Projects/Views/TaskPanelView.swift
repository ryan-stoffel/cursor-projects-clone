import SwiftUI

struct TaskPanelView: View {
    private let lanes: [(String, Color)] = [
        ("Q", HUDTheme.dim),
        ("Run", HUDTheme.accent),
        ("Blk", HUDTheme.warn),
        ("Rev", HUDTheme.ok),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HUDLabel(text: "Tasks")
                .padding(12)
            HUDHairline()
            HStack(alignment: .bottom, spacing: 14) {
                ForEach(lanes, id: \.0) { lane in
                    HUDBarMeter(title: lane.0, fill: 0.08, color: lane.1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 16)
            .padding(.bottom, 8)

            HUDHairline()
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 10) {
                meterLine("Queued", "0")
                meterLine("Running", "0")
                meterLine("Blocked", "0")
                meterLine("Review", "0")
            }
            .padding(12)

            Spacer()

            Text("Cards show machine, model, branch, and elapsed time at M1. Merge, Changes, and Discard land in the thread.")
                .font(HUDFont.mono(11))
                .foregroundStyle(HUDTheme.dim)
                .fixedSize(horizontal: false, vertical: true)
                .padding(12)
        }
        .background(HUDTheme.panel)
    }

    private func meterLine(_ title: String, _ value: String) -> some View {
        HStack {
            HUDLabel(text: title, size: 7)
            Spacer()
            Text(value)
                .font(HUDFont.display(10))
                .foregroundStyle(HUDTheme.text)
        }
    }
}
