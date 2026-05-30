import Foundation

public enum ProfileStoreError: Error, LocalizedError {
    case profileNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .profileNotFound(let id):
            return "Profile not found: \(id)"
        }
    }
}

public final class ProfileStore: @unchecked Sendable {
    private let fileManager: FileManager
    private let profilesURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(
        profilesURL: URL = AppPaths.profilesFile(),
        fileManager: FileManager = .default
    ) {
        self.profilesURL = profilesURL
        self.fileManager = fileManager
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    public func load() throws -> ProfilesDocument {
        if fileManager.fileExists(atPath: profilesURL.path) {
            let data = try Data(contentsOf: profilesURL)
            return try decoder.decode(ProfilesDocument.self, from: data)
        }
        let defaults = Self.builtInProfiles()
        try save(ProfilesDocument(version: 1, profiles: defaults))
        return ProfilesDocument(version: 1, profiles: defaults)
    }

    public func save(_ document: ProfilesDocument) throws {
        try fileManager.createDirectory(
            at: profilesURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try encoder.encode(document)
        try data.write(to: profilesURL, options: .atomic)
    }

    public func profile(id: String, in document: ProfilesDocument) throws -> TerminalProfile {
        guard let profile = document.profiles.first(where: { $0.id == id }) else {
            throw ProfileStoreError.profileNotFound(id)
        }
        return profile
    }

    public static func builtInProfiles(projectRoot: URL = AppPaths.defaultProjectRoot()) -> [TerminalProfile] {
        let projectPath = projectRoot.path
        return [
            TerminalProfile(
                id: "default",
                displayName: "Default",
                description: "Interactive baseline with minimal injection.",
                workingDirectory: "~",
                tabTitleTemplate: "λ default — {cwd}"
            ),
            TerminalProfile(
                id: "dev",
                displayName: "Dev",
                description: "MacBook daily driver — XDG tool paths and xonsh dev profile.",
                workingDirectory: projectPath,
                environment: ["DOTFILES_XONSH_PROFILE": "dev"],
                tabTitleTemplate: "λ dev — {cwd}",
                injectXDGEnvironment: true
            ),
            TerminalProfile(
                id: "lightweight",
                displayName: "Lightweight",
                description: "SSH / Pi mindset — minimal env, fast startup.",
                workingDirectory: "~",
                environment: ["DOTFILES_XONSH_PROFILE": "lightweight"],
                tabTitleTemplate: "λ lightweight — {cwd}"
            ),
            TerminalProfile(
                id: "ai",
                displayName: "AI / Agent",
                description: "Cursor and agent sessions — quiet, traceback-friendly env.",
                workingDirectory: projectPath,
                environment: [
                    "DOTFILES_XONSH_PROFILE": "ai",
                    "DOTFILES_SHELL_CONTEXT": "ai",
                ],
                tabTitleTemplate: "λ ai — {cwd}",
                injectXDGEnvironment: true
            ),
        ]
    }
}
