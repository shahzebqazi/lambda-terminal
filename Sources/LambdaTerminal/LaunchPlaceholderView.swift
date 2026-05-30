import LambdaTerminalCore
import SwiftUI

struct LaunchPlaceholderView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Starting λ Terminal…")
                .foregroundStyle(.secondary)
        }
        .frame(width: 320, height: 160)
        .onAppear(perform: bootstrap)
    }

    private func bootstrap() {
        guard appModel.windows.isEmpty else {
            if let id = appModel.windows.first?.id {
                openWindow(id: "terminal-window", value: id)
            }
            return
        }
        if let id = appModel.openNewWindow(profileID: appModel.settings.defaultProfileID) {
            openWindow(id: "terminal-window", value: id)
        }
    }
}
