import SwiftUI

struct MachinesView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        SettingsView()
            .environmentObject(model)
    }
}
