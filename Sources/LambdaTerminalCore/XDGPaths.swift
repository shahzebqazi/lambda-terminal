import Foundation

/// Resolves standard XDG base directories (macOS-friendly defaults).
public struct XDGPaths: Equatable, Sendable {
    public let configHome: URL
    public let cacheHome: URL
    public let dataHome: URL
    public let stateHome: URL

    public init(home: URL, overrides: [String: String]) {
        configHome = Self.resolve(key: "XDG_CONFIG_HOME", defaultRelative: ".config", home: home, overrides: overrides)
        cacheHome = Self.resolve(key: "XDG_CACHE_HOME", defaultRelative: ".cache", home: home, overrides: overrides)
        dataHome = Self.resolve(key: "XDG_DATA_HOME", defaultRelative: ".local/share", home: home, overrides: overrides)
        stateHome = Self.resolve(key: "XDG_STATE_HOME", defaultRelative: ".local/state", home: home, overrides: overrides)
    }

    public init(overrides: [String: String] = ProcessInfo.processInfo.environment) {
        self.init(home: FileManager.default.homeDirectoryForCurrentUser, overrides: overrides)
    }

    public var environmentVariables: [String: String] {
        [
            "XDG_CONFIG_HOME": configHome.path,
            "XDG_CACHE_HOME": cacheHome.path,
            "XDG_DATA_HOME": dataHome.path,
            "XDG_STATE_HOME": stateHome.path,
        ]
    }

    public static func configHome(overrides: [String: String], home: URL = FileManager.default.homeDirectoryForCurrentUser) -> URL {
        resolve(key: "XDG_CONFIG_HOME", defaultRelative: ".config", home: home, overrides: overrides)
    }

    public static func cacheHome(overrides: [String: String], home: URL = FileManager.default.homeDirectoryForCurrentUser) -> URL {
        resolve(key: "XDG_CACHE_HOME", defaultRelative: ".cache", home: home, overrides: overrides)
    }

    public static func dataHome(overrides: [String: String], home: URL = FileManager.default.homeDirectoryForCurrentUser) -> URL {
        resolve(key: "XDG_DATA_HOME", defaultRelative: ".local/share", home: home, overrides: overrides)
    }

    public static func stateHome(overrides: [String: String], home: URL = FileManager.default.homeDirectoryForCurrentUser) -> URL {
        resolve(key: "XDG_STATE_HOME", defaultRelative: ".local/state", home: home, overrides: overrides)
    }

    private static func resolve(key: String, defaultRelative: String, home: URL, overrides: [String: String]) -> URL {
        if let value = overrides[key], !value.isEmpty {
            return URL(fileURLWithPath: (value as NSString).expandingTildeInPath).standardizedFileURL
        }
        return home.appendingPathComponent(defaultRelative, isDirectory: true).standardizedFileURL
    }
}
