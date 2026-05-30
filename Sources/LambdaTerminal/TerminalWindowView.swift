import LambdaTerminalCore
import SwiftUI

struct TerminalWindowView: View {
    @EnvironmentObject private var appModel: AppModel
    let windowID: UUID

    private var bundleIndex: Int? {
        appModel.windows.firstIndex { $0.id == windowID }
    }

    var body: some View {
        if let index = bundleIndex {
            TabView(selection: selectedTabBinding(index: index)) {
                ForEach(appModel.windows[index].tabs) { session in
                    TerminalTabView(session: session, windowID: windowID)
                        .tabItem {
                            Text(session.title)
                        }
                        .tag(session.id)
                }
            }
            .frame(minWidth: 720, minHeight: 420)
            .onAppear {
                appModel.setFocusedWindow(windowID)
            }
            .background {
                WindowFocusReporter {
                    appModel.setFocusedWindow(windowID)
                }
            }
        } else {
            Text("Window closed")
        }
    }

    private func selectedTabBinding(index: Int) -> Binding<UUID> {
        Binding(
            get: {
                appModel.windows[index].selectedTabID
                    ?? appModel.windows[index].tabs.first?.id
                    ?? UUID()
            },
            set: { newID in
                appModel.selectTab(windowID: windowID, tabID: newID)
            }
        )
    }
}

struct TerminalTabView: View {
    @EnvironmentObject private var appModel: AppModel
    let session: TerminalSession
    let windowID: UUID

    var body: some View {
        LocalTerminalView(
            launchPlan: session.launchPlan(settings: appModel.settings),
            onTitleChange: { title in
                updateTitle(title)
            }
        )
        .background(Color(nsColor: .textBackgroundColor))
    }

    private func updateTitle(_ title: String) {
        appModel.updateSessionTitle(windowID: windowID, sessionID: session.id, title: title)
    }
}
