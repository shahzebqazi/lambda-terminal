import Foundation

public struct TerminalProfile: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var displayName: String
    public var description: String
    /// nil means use the user's login shell ($SHELL).
    public var shellPath: String?
    public var workingDirectory: String
    public var environment: [String: String]
    public var tabTitleTemplate: String
    /// When true, inject standard XDG base-directory variables at launch.
    public var injectXDGEnvironment: Bool

    public init(
        id: String,
        displayName: String,
        description: String = "",
        shellPath: String? = nil,
        workingDirectory: String = "~",
        environment: [String: String] = [:],
        tabTitleTemplate: String = "λ {profile} — {cwd}",
        injectXDGEnvironment: Bool = false
    ) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.shellPath = shellPath
        self.workingDirectory = workingDirectory
        self.environment = environment
        self.tabTitleTemplate = tabTitleTemplate
        self.injectXDGEnvironment = injectXDGEnvironment
    }

    public func resolvedWorkingDirectory(home: URL = FileManager.default.homeDirectoryForCurrentUser) -> URL {
        let expanded = (workingDirectory as NSString).expandingTildeInPath
        return URL(fileURLWithPath: expanded, isDirectory: true).standardizedFileURL
    }

    public func tabTitle(cwd: URL) -> String {
        tabTitleTemplate
            .replacingOccurrences(of: "{profile}", with: id)
            .replacingOccurrences(of: "{cwd}", with: cwd.lastPathComponent)
    }
}

public struct ProfilesDocument: Codable, Equatable, Sendable {
    public var version: Int
    public var profiles: [TerminalProfile]

    public init(version: Int = 1, profiles: [TerminalProfile]) {
        self.version = version
        self.profiles = profiles
    }
}
