import LambdaTerminalCore
import SwiftUI

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
                        appModel.requestOpenWindow(id: id)
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
