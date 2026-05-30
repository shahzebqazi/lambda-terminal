import SwiftUI

/// Opens SwiftUI windows when `AppModel.pendingWindowIDToOpen` is set (menus, sheets).
struct PendingWindowOpener: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onChange(of: appModel.pendingWindowIDToOpen) { _, windowID in
                guard let windowID else { return }
                openWindow(id: "terminal-window", value: windowID)
                appModel.pendingWindowIDToOpen = nil
            }
    }
}
