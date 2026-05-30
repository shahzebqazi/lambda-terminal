import Foundation

/// Builds the environment dictionary passed to the shell PTY.
/// Profile-specific keys win over XDG defaults; inherited process env is preserved unless overridden.
public struct SessionEnvironment: Equatable, Sendable {
    public let merged: [String: String]

    public init(
        profile: TerminalProfile,
        inherited: [String: String] = ProcessInfo.processInfo.environment,
        home: URL = FileManager.default.homeDirectoryForCurrentUser
    ) {
        var env = inherited
        let xdg = XDGPaths(overrides: inherited)

        if profile.injectXDGEnvironment {
            for (key, value) in xdg.environmentVariables {
                env[key] = value
            }
            env.merge(Self.standardToolPaths(xdg: xdg)) { _, new in new }
        }

        // Profile keys override defaults (including XDG injection).
        for (key, value) in profile.environment {
            env[key] = value
        }

        env["LAMBDA_TERMINAL_PROFILE"] = profile.id
        env["PWD"] = profile.resolvedWorkingDirectory(home: home).path

        merged = env
    }

    /// Tool paths commonly used with XDG layouts (no user-specific model directories).
    public static func standardToolPaths(xdg: XDGPaths) -> [String: String] {
        [
            "WAKATIME_HOME": xdg.configHome.appendingPathComponent("wakatime").path,
            "CURSOR_CONFIG_DIR": xdg.configHome.appendingPathComponent("cursor").path,
            "DOCKER_CONFIG": xdg.configHome.appendingPathComponent("docker").path,
            "LM_STUDIO_HOME": xdg.configHome.appendingPathComponent("lm-studio").path,
            "NPM_CONFIG_USERCONFIG": xdg.configHome.appendingPathComponent("npm/npmrc").path,
            "NPM_CONFIG_CACHE": xdg.cacheHome.appendingPathComponent("npm").path,
        ]
    }

    public static func loginShellPath(inherited: [String: String] = ProcessInfo.processInfo.environment) -> String {
        if let shell = inherited["SHELL"], !shell.isEmpty {
            return shell
        }
        return "/bin/zsh"
    }

    public func resolvedShell(for profile: TerminalProfile) -> String {
        if let override = profile.shellPath, !override.isEmpty {
            return override
        }
        return Self.loginShellPath(inherited: merged)
    }

    public static func xonshProfileEnv(for profileID: String, shellPath: String) -> [String: String]? {
        guard shellPath.contains("xonsh") else { return nil }
        return ["DOTFILES_XONSH_PROFILE": profileID]
    }
}
