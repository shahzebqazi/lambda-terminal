import Foundation

public enum ThemePreset: String, Codable, CaseIterable, Sendable, Identifiable {
    case dracula
    case system

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .dracula: return "Dracula"
        case .system: return "System"
        }
    }
}

public struct AppSettings: Codable, Equatable, Sendable {
    public var version: Int
    public var defaultProfileID: String
    public var fontSize: Double
    public var theme: ThemePreset
    /// Last working directory per profile id (path strings).
    public var lastWorkingDirectoryByProfile: [String: String]

    public init(
        version: Int = 1,
        defaultProfileID: String = "dev",
        fontSize: Double = 13,
        theme: ThemePreset = .dracula,
        lastWorkingDirectoryByProfile: [String: String] = [:]
    ) {
        self.version = version
        self.defaultProfileID = defaultProfileID
        self.fontSize = fontSize
        self.theme = theme
        self.lastWorkingDirectoryByProfile = lastWorkingDirectoryByProfile
    }
}

public final class SettingsStore: @unchecked Sendable {
    private let fileManager: FileManager
    private let settingsURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(
        settingsURL: URL = AppPaths.settingsFile(),
        fileManager: FileManager = .default
    ) {
        self.settingsURL = settingsURL
        self.fileManager = fileManager
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    public func load() throws -> AppSettings {
        if fileManager.fileExists(atPath: settingsURL.path) {
            let data = try Data(contentsOf: settingsURL)
            return try decoder.decode(AppSettings.self, from: data)
        }
        let defaults = AppSettings()
        try save(defaults)
        return defaults
    }

    public func save(_ settings: AppSettings) throws {
        try fileManager.createDirectory(
            at: settingsURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try encoder.encode(settings)
        try data.write(to: settingsURL, options: .atomic)
    }

    public func rememberWorkingDirectory(profileID: String, path: URL, settings: inout AppSettings) {
        settings.lastWorkingDirectoryByProfile[profileID] = path.path
    }

    public func resolvedWorkingDirectory(
        for profile: TerminalProfile,
        settings: AppSettings,
        home: URL = FileManager.default.homeDirectoryForCurrentUser
    ) -> URL {
        if let remembered = settings.lastWorkingDirectoryByProfile[profile.id] {
            let url = URL(fileURLWithPath: remembered, isDirectory: true)
            if fileManager.fileExists(atPath: url.path) {
                return url
            }
        }
        return profile.resolvedWorkingDirectory(home: home)
    }
}
