import Foundation

public struct AuditResult: Sendable {
    public var total = 0
    public var exempt = 0
    public var xdgRoot = 0
    public var convention = 0
    public var viol = 0
    public var unknown = 0
    public var extn = 0
    public var violNames: [String] = []
    public var unknownNames: [String] = []
    public var extNames: [String] = []
    public var inventory: [(String, DotKind)] = []

    public init() {}
}

public func auditScore(for result: AuditResult) -> Int {
    guard result.total > 0 else { return 100 }
    var score = (100 * result.exempt) / result.total
    score -= 12 * result.viol
    return max(0, score)
}

public enum XDGAuditor {
    public static func runAudit(
        xdg: XDGPaths = XDGPaths(),
        home: URL = FileManager.default.homeDirectoryForCurrentUser,
        fileManager: FileManager = .default
    ) throws -> AuditResult {
        var result = AuditResult()
        let paths = XDGRelocationPaths(xdg: xdg, home: home)
        let items = try fileManager.contentsOfDirectory(at: home, includingPropertiesForKeys: nil)
        var names = items.map(\.lastPathComponent).filter { $0.hasPrefix(".") && $0 != "." }
        names.sort()

        for name in names {
            let kind = classify(name: name)
            if kind == .skip { continue }
            result.total += 1
            result.inventory.append((name, kind))
            switch kind {
            case .xdgRoot:
                result.xdgRoot += 1
                result.exempt += 1
            case .exemptSsh, .exemptMacos:
                result.exempt += 1
            case .conventionShell, .conventionHistory, .conventionGit, .conventionNode, .conventionZshCache,
                 .conventionEditor, .conventionTooling:
                result.convention += 1
                result.exempt += 1
            case .xdgCompatSymlink:
                let entry = home.appendingPathComponent(name)
                if resolvesUnderConfig(entry, config: paths.config, fileManager: fileManager) {
                    result.exempt += 1
                } else {
                    result.viol += 1
                    result.violNames.append(name)
                }
            case .relocatableCore:
                if coreViolation(name: name, paths: paths, fileManager: fileManager) {
                    result.viol += 1
                    result.violNames.append(name)
                } else {
                    result.exempt += 1
                }
            case .relocatableExtended:
                if extendedPresent(name: name, paths: paths, fileManager: fileManager) {
                    result.extn += 1
                    result.extNames.append(name)
                }
            case .unknown:
                result.unknown += 1
                result.unknownNames.append(name)
            case .skip:
                break
            }
        }
        return result
    }

    public static func buildReport(
        xdg: XDGPaths = XDGPaths(),
        home: URL = FileManager.default.homeDirectoryForCurrentUser,
        result: AuditResult,
        score: Int,
        generatedAt: Date = Date()
    ) -> String {
        let paths = XDGRelocationPaths(xdg: xdg, home: home)
        let iso = ISO8601DateFormatter().string(from: generatedAt).replacingOccurrences(of: "+00:00", with: "Z")

        var md = ""
        md += "# XDG-style home compliance (macOS)\n\n"
        md += "**Score: \(score)/100** — exempt coverage (− **12 ×** core relocatables still under `$HOME`).\n\n"
        md += "_Generated: \(iso) · Tool: lambda-terminal xdg audit_\n\n"
        md += "## Summary\n\n| Metric | Count |\n|--------|-------|\n"
        md += "| Dot entries (depth 1) | \(result.total) |\n"
        md += "| Compliant / exempt | \(result.exempt) |\n"
        md += "| — XDG roots (.config / .cache / .local) | \(result.xdgRoot) |\n"
        md += "| — Conventions (shell, editors, …) | \(result.convention) |\n"
        md += "| **Core relocatable violations** | **\(result.viol)** |\n"
        md += "| Extended relocatables (.cargo, …) | \(result.extn) |\n"
        md += "| Unknown / review | \(result.unknown) |\n\n"

        md += "## Core relocatable violations\n\n"
        if result.violNames.isEmpty {
            md += "_None — no core relocatable dirs left at `$HOME` (or already merged)._\n\n"
        } else {
            md += "| Path | Note |\n|------|------|\n"
            for name in result.violNames {
                let src = home.appendingPathComponent(name).path
                md += "| `\(src)` | Relocate under XDG config/cache; see `docs/PROFILES.md` |\n"
            }
            md += "\n"
        }

        md += "## Extended relocatables (informational)\n\n"
        if result.extNames.isEmpty {
            md += "_None detected._\n\n"
        } else {
            md += "| Path | Note |\n|------|------|\n"
            for name in result.extNames {
                md += "| `\(home.appendingPathComponent(name).path)` | Set tool-specific `*_HOME` env vars when ready. |\n"
            }
            md += "\n"
        }

        md += "## Unknown / review\n\n"
        if result.unknownNames.isEmpty {
            md += "_None._\n\n"
        } else {
            md += "| Path | Note |\n|------|------|\n"
            for name in result.unknownNames {
                md += "| `\(home.appendingPathComponent(name).path)` | Add to classifier or document as exempt. |\n"
            }
            md += "\n"
        }

        md += "## Full inventory (depth 1)\n\n| Name | Classification |\n|------|----------------|\n"
        for (name, kind) in result.inventory.sorted(by: { $0.0 < $1.0 }) {
            md += "| `\(name)` | \(kind.rawValue) |\n"
        }

        md += "\n## Environment snapshot\n\n```\n"
        md += "XDG_CONFIG_HOME=\(paths.config.path)\n"
        md += "XDG_CACHE_HOME=\(paths.cache.path)\n"
        md += "XDG_DATA_HOME=\(xdg.dataHome.path)\n"
        md += "XDG_STATE_HOME=\(xdg.stateHome.path)\n```\n"
        return md
    }

    public static func runCheckReport(
        xdg: XDGPaths = XDGPaths(),
        home: URL = FileManager.default.homeDirectoryForCurrentUser,
        fileManager: FileManager = .default
    ) -> String {
        let paths = XDGRelocationPaths(xdg: xdg, home: home)
        var lines: [String] = []
        lines.append("XDG_CONFIG_HOME=\(xdg.configHome.path)")
        lines.append("XDG_CACHE_HOME=\(xdg.cacheHome.path)")
        lines.append("XDG_DATA_HOME=\(xdg.dataHome.path)")
        lines.append("XDG_STATE_HOME=\(xdg.stateHome.path)")
        lines.append("")
        lines.append(contentsOf: checkPair(label: "Bun", src: paths.bunSrc, dst: paths.bunDst, fileManager: fileManager))
        lines.append(contentsOf: checkPair(label: "LM Studio", src: paths.lmSrc, dst: paths.lmDst, fileManager: fileManager))
        lines.append(contentsOf: checkPair(label: "Cursor", src: paths.cursorSrc, dst: paths.cursorDst, fileManager: fileManager))
        lines.append(contentsOf: checkPair(label: "npm", src: paths.npmSrc, dst: paths.npmDst, fileManager: fileManager))
        lines.append(contentsOf: checkPair(label: "Docker", src: paths.dockerSrc, dst: paths.dockerDst, fileManager: fileManager))
        return lines.joined(separator: "\n")
    }

    private static func checkPair(
        label: String,
        src: URL,
        dst: URL,
        fileManager: FileManager
    ) -> [String] {
        if fileManager.fileExists(atPath: src.path) {
            if fileManager.fileExists(atPath: dst.path) {
                return ["WARN: \(label): \(src.path) and \(dst.path) both exist"]
            }
            return ["OK: \(label): would migrate \(src.path) -> \(dst.path)"]
        }
        return ["  \(label): (no \(src.path))"]
    }
}
