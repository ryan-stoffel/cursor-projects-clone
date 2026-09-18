import SwiftUI

struct TaskPanelView: View {
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Activity")
                    .font(AppTheme.chromeSmallMedium)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.plain)
                .help("Hide activity")
            }
            .padding(.horizontal, 12)
            .frame(height: AppTheme.trafficLights)

            Hairline()

            Text("No tasks yet")
                .font(AppTheme.chromeSmall)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 12)
                .padding(.top, 12)

            Spacer()
        }
    }
}
