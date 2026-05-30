import LambdaTerminalCore
import SwiftUI

struct TerminalWindowView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.openWindow) private var openWindow
    let windowID: UUID

    private var bundleIndex: Int? {
        appModel.windows.firstIndex { $0.id == windowID }
    }

    var body: some View {
        if let index = bundleIndex {
            TabView(selection: tabSelectionBinding(index: index)) {
                ForEach(appModel.windows[index].tabs) { session in
                    TerminalTabView(session: session, windowID: windowID)
                        .tabItem {
                            Text(session.title)
                        }
                        .tag(session.id)
                }
            }
            .frame(minWidth: 720, minHeight: 420)
            .onReceive(NotificationCenter.default.publisher(for: .openTerminalWindow)) { notification in
                if let id = notification.object as? UUID {
                    openWindow(id: "terminal-window", value: id)
                }
            }
        } else {
            Text("Window closed")
        }
    }

    private func tabSelectionBinding(index: Int) -> Binding<UUID> {
        Binding(
            get: { appModel.windows[index].tabs.last?.id ?? UUID() },
            set: { newID in
                guard let tabIndex = appModel.windows[index].tabs.firstIndex(where: { $0.id == newID }) else {
                    return
                }
                let tab = appModel.windows[index].tabs.remove(at: tabIndex)
                appModel.windows[index].tabs.append(tab)
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
            configuration: session.launchConfiguration(settings: appModel.settings),
            onTitleChange: { title in
                updateTitle(title)
            }
        )
        .background(Color(nsColor: .textBackgroundColor))
    }

    private func updateTitle(_ title: String) {
        guard let windowIndex = appModel.windows.firstIndex(where: { $0.id == windowID }),
              let tabIndex = appModel.windows[windowIndex].tabs.firstIndex(where: { $0.id == session.id }) else {
            return
        }
        if !title.isEmpty {
            appModel.windows[windowIndex].tabs[tabIndex].title = title
        }
    }
}

struct NewWindowSheet: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProfileID: String
    @State private var workingDirectory: String

    init(defaultProfileID: String, defaultDirectory: String) {
        _selectedProfileID = State(initialValue: defaultProfileID)
        _workingDirectory = State(initialValue: defaultDirectory)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Terminal Window")
                .font(.title2)

            Picker("Profile", selection: $selectedProfileID) {
                ForEach(appModel.profiles) { profile in
                    Text(profile.displayName).tag(profile.id)
                }
            }

            HStack {
                Text("Working directory")
                TextField("~/Git", text: $workingDirectory)
                Button("Choose…") {
                    chooseDirectory()
                }
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Open") {
                    let url = URL(fileURLWithPath: (workingDirectory as NSString).expandingTildeInPath, isDirectory: true)
                    if let id = appModel.openNewWindow(profileID: selectedProfileID, workingDirectory: url) {
                        NotificationCenter.default.post(name: .openTerminalWindow, object: id)
                    }
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 480)
    }

    private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: (workingDirectory as NSString).expandingTildeInPath, isDirectory: true)
        if panel.runModal() == .OK, let url = panel.url {
            workingDirectory = url.path
        }
    }
}

struct XDGAuditSheet: View {
    let markdown: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("XDG Home Audit")
                .font(.title2)
            ScrollView {
                Text(markdown)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            HStack {
                Spacer()
                Button("Close") { dismiss() }
            }
        }
        .padding(20)
        .frame(width: 640, height: 480)
    }
}
