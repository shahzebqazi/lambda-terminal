import Foundation

/// PTY process parameters only — changes here require a shell restart.
public struct ProcessLaunchConfiguration: Equatable, Sendable {
    public let shell: String
    public let environment: [String: String]
    public let currentDirectory: String

    public init(shell: String, environment: [String: String], currentDirectory: String) {
        self.shell = shell
        self.environment = environment
        self.currentDirectory = currentDirectory
    }
}

/// Visual presentation — must not trigger PTY restart when changed alone.
public struct TerminalChrome: Equatable, Sendable {
    public let fontSize: Double
    public let theme: ThemePreset

    public init(fontSize: Double, theme: ThemePreset) {
        self.fontSize = fontSize
        self.theme = theme
    }

    public static func from(settings: AppSettings) -> TerminalChrome {
        TerminalChrome(fontSize: settings.fontSize, theme: settings.theme)
    }
}

public struct SessionLaunchPlan: Equatable, Sendable {
    public let process: ProcessLaunchConfiguration
    public let chrome: TerminalChrome

    public init(process: ProcessLaunchConfiguration, chrome: TerminalChrome) {
        self.process = process
        self.chrome = chrome
    }
}

public enum SessionLaunchBuilder {
    public static func build(
        profile: TerminalProfile,
        workingDirectory: URL,
        settings: AppSettings,
        inherited: [String: String] = [:],
        home: URL = FileManager.default.homeDirectoryForCurrentUser
    ) -> SessionLaunchPlan {
        let sessionEnv = SessionEnvironment(
            profile: profile,
            workingDirectory: workingDirectory,
            inherited: inherited,
            home: home
        )
        let shell = sessionEnv.resolvedShell(for: profile)
        var env = sessionEnv.merged
        if let xonshEnv = SessionEnvironment.xonshProfileEnv(for: profile.id, shellPath: shell) {
            env.merge(xonshEnv) { _, new in new }
        }
        let process = ProcessLaunchConfiguration(
            shell: shell,
            environment: env,
            currentDirectory: workingDirectory.path
        )
        return SessionLaunchPlan(process: process, chrome: .from(settings: settings))
    }
}
