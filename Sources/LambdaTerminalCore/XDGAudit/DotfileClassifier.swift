import Foundation

public enum DotKind: String, Codable, Sendable {
    case skip
    case xdgRoot = "xdg_root"
    case exemptSsh = "exempt_ssh"
    case exemptMacos = "exempt_macos"
    case conventionShell = "convention_shell"
    case conventionHistory = "convention_history"
    case conventionGit = "convention_git"
    case conventionNode = "convention_node"
    case conventionZshCache = "convention_zsh_cache"
    case conventionEditor = "convention_editor"
    case conventionTooling = "convention_tooling"
    case xdgCompatSymlink = "xdg_compat_symlink"
    case relocatableCore = "relocatable_core"
    case relocatableExtended = "relocatable_extended"
    case unknown
}

private let conventionTooling: Set<String> = [
    ".vscode", ".ipython", ".jupyter", ".matplotlib", ".keras", ".aws", ".azure", ".bundle", ".gradle", ".m2",
    ".swiftpm", ".cocoapods", ".conda", ".dotnet", ".nuget", ".templateengine", ".aspnet", ".mono", ".android",
    ".skiko", ".pyenv", ".rbenv", ".nvm", ".oh-my-zsh", ".gem", ".redhat", ".parallel", ".parallelcache", ".dotnet_tools",
]

/// Classifies a depth-1 dot entry in the user's home directory.
public func classify(name: String) -> DotKind {
    switch name {
    case ".", "..": return .skip
    case ".config", ".cache", ".local": return .xdgRoot
    case ".ssh": return .exemptSsh
    case ".Trash", ".DS_Store", ".CFUserTextEncoding", ".localized": return .exemptMacos
    case ".zshrc", ".zshenv", ".zprofile", ".zlogin", ".bashrc", ".bash_profile", ".profile", ".bash_history",
         ".zsh_history", ".xonshrc", ".inputrc", ".editrc", ".hushlogin":
        return .conventionShell
    case ".viminfo", ".lesshst", ".wget-hsts", ".python_history", ".history": return .conventionHistory
    case ".amp", ".gitlab", ".cups", ".SoulseekQt", ".emulator_console_auth_token", ".userchain", ".sentry ":
        return .conventionTooling
    case ".gitconfig", ".gitignore_global": return .conventionGit
    case ".npmrc", ".yarnrc", ".yarnrc.yml", ".node_repl_history": return .conventionNode
    case ".vim", ".emacs.d", ".tmux.conf", ".tmux": return .conventionEditor
    case ".ollama", ".wakatime", ".cursor": return .xdgCompatSymlink
    case ".bun", ".npm", ".docker", ".lmstudio": return .relocatableCore
    case ".cargo", ".rustup", ".kube", ".steam": return .relocatableExtended
    default:
        if name.hasPrefix(".zcompdump") { return .conventionZshCache }
        if conventionTooling.contains(name) { return .conventionTooling }
        return .unknown
    }
}

public struct XDGRelocationPaths: Equatable, Sendable {
    public let home: URL
    public let config: URL
    public let cache: URL
    public let bunSrc: URL
    public let bunDst: URL
    public let lmSrc: URL
    public let lmDst: URL
    public let cursorSrc: URL
    public let cursorDst: URL
    public let npmSrc: URL
    public let npmDst: URL
    public let dockerSrc: URL
    public let dockerDst: URL

    public init(xdg: XDGPaths, home: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.home = home
        config = xdg.configHome
        cache = xdg.cacheHome
        bunSrc = home.appendingPathComponent(".bun")
        bunDst = config.appendingPathComponent("bun")
        lmSrc = home.appendingPathComponent(".lmstudio")
        lmDst = config.appendingPathComponent("lm-studio")
        cursorSrc = home.appendingPathComponent(".cursor")
        cursorDst = config.appendingPathComponent("cursor")
        npmSrc = home.appendingPathComponent(".npm")
        npmDst = cache.appendingPathComponent("npm")
        dockerSrc = home.appendingPathComponent(".docker")
        dockerDst = config.appendingPathComponent("docker")
    }
}

public func resolvesUnderConfig(_ url: URL, config: URL, fileManager: FileManager = .default) -> Bool {
    guard let dest = try? fileManager.destinationOfSymbolicLink(atPath: url.path) else {
        return false
    }
    let resolved = URL(fileURLWithPath: (dest as NSString).expandingTildeInPath).standardizedFileURL
    return resolved.path.hasPrefix(config.standardizedFileURL.path)
}

public func coreViolation(name: String, paths: XDGRelocationPaths, fileManager: FileManager = .default) -> Bool {
    switch name {
    case ".bun": return fileManager.fileExists(atPath: paths.bunSrc.path)
    case ".lmstudio": return fileManager.fileExists(atPath: paths.lmSrc.path)
    case ".cursor":
        if resolvesUnderConfig(paths.cursorSrc, config: paths.config, fileManager: fileManager) { return false }
        return fileManager.fileExists(atPath: paths.cursorSrc.path)
    case ".npm": return fileManager.fileExists(atPath: paths.npmSrc.path)
    case ".docker": return fileManager.fileExists(atPath: paths.dockerSrc.path)
    default: return false
    }
}

public func extendedPresent(name: String, paths: XDGRelocationPaths, fileManager: FileManager = .default) -> Bool {
    switch name {
    case ".cargo", ".rustup", ".kube", ".steam":
        return fileManager.fileExists(atPath: paths.home.appendingPathComponent(name).path)
    default: return false
    }
}
