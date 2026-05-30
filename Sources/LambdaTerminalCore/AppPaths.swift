import Foundation

/// XDG-aligned paths for lambda-terminal configuration and state.
public enum AppPaths {
    public static func configDirectory(overrides: [String: String] = ProcessInfo.processInfo.environment) -> URL {
        XDGPaths.configHome(overrides: overrides)
            .appendingPathComponent("lambda-terminal", isDirectory: true)
    }

    public static func stateDirectory(overrides: [String: String] = ProcessInfo.processInfo.environment) -> URL {
        XDGPaths.stateHome(overrides: overrides)
            .appendingPathComponent("lambda-terminal", isDirectory: true)
    }

    public static func profilesFile(overrides: [String: String] = ProcessInfo.processInfo.environment) -> URL {
        configDirectory(overrides: overrides).appendingPathComponent("profiles.json")
    }

    public static func settingsFile(overrides: [String: String] = ProcessInfo.processInfo.environment) -> URL {
        configDirectory(overrides: overrides).appendingPathComponent("settings.json")
    }

    public static func xdgReportFile(overrides: [String: String] = ProcessInfo.processInfo.environment) -> URL {
        stateDirectory(overrides: overrides).appendingPathComponent("xdg-report.md")
    }

    public static func defaultProjectRoot(home: URL = FileManager.default.homeDirectoryForCurrentUser) -> URL {
        let git = home.appendingPathComponent("Git", isDirectory: true)
        if FileManager.default.fileExists(atPath: git.path) {
            return git
        }
        return home
    }
}
