import LambdaTerminalCore
import SwiftUI

@main
struct LambdaTerminalApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appModel = AppModel()
    @State private var showNewWindowSheet = false

    var body: some Scene {
        WindowGroup(id: "terminal-window", for: UUID.self) { $windowID in
            Group {
                if let windowID {
                    TerminalWindowView(windowID: windowID)
                } else {
                    LaunchPlaceholderView()
                }
            }
            .environmentObject(appModel)
            .background(PendingWindowOpener())
            .sheet(isPresented: $showNewWindowSheet) {
                NewWindowSheet(
                    defaultProfileID: appModel.settings.defaultProfileID,
                    defaultDirectory: AppPaths.defaultProjectRoot().path
                )
                .environmentObject(appModel)
            }
            .sheet(isPresented: $appModel.showXDGAuditSheet) {
                if let markdown = appModel.xdgAuditMarkdown {
                    XDGAuditSheet(markdown: markdown)
                }
            }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Window…") {
                    showNewWindowSheet = true
                }
                .keyboardShortcut("n", modifiers: [.command])
            }

            CommandMenu("Session") {
                Button("New Tab") {
                    newTab()
                }
                .keyboardShortcut("t", modifiers: [.command])

                Button("Open in Project…") {
                    openProjectDirectory()
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
            }

            CommandMenu("Developer") {
                Button("XDG Home Audit…") {
                    appModel.runXDGAudit()
                }
            }
        }
        .defaultSize(width: 960, height: 560)

        Settings {
            SettingsView()
                .environmentObject(appModel)
        }
    }

    private func newTab() {
        if let windowID = appModel.openNewTabInCommandTarget() {
            appModel.requestOpenWindow(id: windowID)
        }
    }

    private func openProjectDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Choose a project root for this terminal session"
        if panel.runModal() == .OK, let url = panel.url, let windowID = appModel.openInProject(directory: url) {
            appModel.requestOpenWindow(id: windowID)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
