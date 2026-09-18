import SwiftUI

struct UsageStripView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 7, height: 7)
                Text(model.connectionStatus)
                    .font(AppTheme.captionMedium)
                    .foregroundStyle(.secondary)
            }

            HairlineVertical()

            Text("Usage")
                .font(AppTheme.captionMedium)
                .foregroundStyle(.secondary)
            Text("No token counts yet")
                .font(AppTheme.caption)
                .foregroundStyle(.tertiary)

            Spacer()

            if let project = model.selectedProject {
                Text(project.coordinatorModel)
                    .font(AppTheme.caption)
                    .foregroundStyle(.tertiary)
                HairlineVertical()
            }

            Text("Per-subscription usage from the gateway lands at M4")
                .font(AppTheme.caption)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .frame(height: 28)
        .background(.bar)
        .overlay(alignment: .top) { Hairline() }
    }

    private var statusColor: Color {
        switch model.connectionStatus {
        case "Connected":
            return Color(red: 0.45, green: 0.72, blue: 0.55)
        case "Connecting":
            return Color(red: 0.82, green: 0.7, blue: 0.35)
        default:
            return Color.secondary.opacity(0.6)
        }
    }
}

struct HairlineVertical: View {
    var body: some View {
        Rectangle()
            .fill(AppTheme.hairline)
            .frame(width: 1, height: 12)
    }
}
