import Foundation
import LambdaTerminalCore

struct TerminalSession: Identifiable, Equatable {
    let id: UUID
    var profile: TerminalProfile
    var workingDirectory: URL
    var title: String

    init(id: UUID = UUID(), profile: TerminalProfile, workingDirectory: URL) {
        self.id = id
        self.profile = profile
        self.workingDirectory = workingDirectory
        self.title = profile.tabTitle(cwd: workingDirectory)
    }

    func launchConfiguration(settings: AppSettings) -> SessionLaunchConfiguration {
        var profileForLaunch = profile
        profileForLaunch.workingDirectory = workingDirectory.path
        let sessionEnv = SessionEnvironment(profile: profileForLaunch)
        let shell = sessionEnv.resolvedShell(for: profileForLaunch)
        var env = sessionEnv.merged
        if let xonshEnv = SessionEnvironment.xonshProfileEnv(for: profile.id, shellPath: shell) {
            env.merge(xonshEnv) { _, new in new }
        }
        return SessionLaunchConfiguration(
            shell: shell,
            environment: env,
            currentDirectory: workingDirectory.path,
            fontSize: settings.fontSize,
            theme: settings.theme
        )
    }
}

struct SessionLaunchConfiguration: Equatable {
    let shell: String
    let environment: [String: String]
    let currentDirectory: String
    let fontSize: Double
    let theme: ThemePreset
}

struct WindowSessionBundle: Identifiable, Equatable {
    let id: UUID
    var tabs: [TerminalSession]

    init(id: UUID = UUID(), tabs: [TerminalSession]) {
        self.id = id
        self.tabs = tabs
    }
}
