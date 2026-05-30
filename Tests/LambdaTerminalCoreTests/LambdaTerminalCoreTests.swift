import Foundation
import LambdaTerminalCore
import XCTest

final class TerminalProfileTests: XCTestCase {
    func testProfileCodableRoundTrip() throws {
        let profile = TerminalProfile(
            id: "dev",
            displayName: "Dev",
            workingDirectory: "~/Git",
            environment: ["DOTFILES_XONSH_PROFILE": "dev"],
            injectXDGEnvironment: true
        )
        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(TerminalProfile.self, from: data)
        XCTAssertEqual(decoded, profile)
    }

    func testTabTitleTemplate() {
        let profile = TerminalProfile(id: "ai", displayName: "AI", tabTitleTemplate: "λ {profile} — {cwd}")
        let title = profile.tabTitle(cwd: URL(fileURLWithPath: "/Users/test/Git/lambda-terminal"))
        XCTAssertEqual(title, "λ ai — lambda-terminal")
    }

    func testResolvedWorkingDirectoryExpandsTilde() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let profile = TerminalProfile(id: "default", displayName: "Default", workingDirectory: "~")
        XCTAssertEqual(profile.resolvedWorkingDirectory(home: home).path, home.path)
    }
}

final class ProfilesDocumentTests: XCTestCase {
    func testProfilesDocumentEncodeDecode() throws {
        let doc = ProfilesDocument(version: 1, profiles: ProfileStore.builtInProfiles())
        let data = try JSONEncoder().encode(doc)
        let decoded = try JSONDecoder().decode(ProfilesDocument.self, from: data)
        XCTAssertEqual(decoded.version, 1)
        XCTAssertEqual(decoded.profiles.count, 4)
    }

    func testBuiltInProfileIDs() {
        let ids = Set(ProfileStore.builtInProfiles().map(\.id))
        XCTAssertEqual(ids, ["default", "dev", "lightweight", "ai"])
    }

    func testDevProfileInjectsXDG() {
        let dev = ProfileStore.builtInProfiles().first { $0.id == "dev" }
        XCTAssertTrue(dev?.injectXDGEnvironment == true)
        XCTAssertEqual(dev?.environment["DOTFILES_XONSH_PROFILE"], "dev")
    }

    func testLightweightProfileIsMinimal() {
        let lightweight = ProfileStore.builtInProfiles().first { $0.id == "lightweight" }
        XCTAssertEqual(lightweight?.injectXDGEnvironment, false)
        XCTAssertEqual(lightweight?.environment["DOTFILES_XONSH_PROFILE"], "lightweight")
    }
}

final class XDGPathsTests: XCTestCase {
    func testDefaultXDGPathsUnderHome() {
        let home = URL(fileURLWithPath: "/Users/test")
        let xdg = XDGPaths(home: home, overrides: [:])
        XCTAssertEqual(xdg.configHome.path, "/Users/test/.config")
        XCTAssertEqual(xdg.cacheHome.path, "/Users/test/.cache")
        XCTAssertEqual(xdg.dataHome.path, "/Users/test/.local/share")
        XCTAssertEqual(xdg.stateHome.path, "/Users/test/.local/state")
    }

    func testXDGOverridesWin() {
        let home = URL(fileURLWithPath: "/Users/test")
        let xdg = XDGPaths(home: home, overrides: ["XDG_CONFIG_HOME": "/custom/config"])
        XCTAssertEqual(xdg.configHome.path, "/custom/config")
    }

    func testEnvironmentVariablesMap() {
        let home = URL(fileURLWithPath: "/Users/test")
        let xdg = XDGPaths(home: home, overrides: [:])
        XCTAssertEqual(xdg.environmentVariables["XDG_CONFIG_HOME"], "/Users/test/.config")
    }
}

final class SessionEnvironmentTests: XCTestCase {
    func testProfileEnvOverridesXDGDefaults() {
        let home = URL(fileURLWithPath: "/Users/test")
        let profile = TerminalProfile(
            id: "dev",
            displayName: "Dev",
            workingDirectory: home.path,
            environment: ["XDG_CONFIG_HOME": "/override/config"],
            injectXDGEnvironment: true
        )
        let session = SessionEnvironment(profile: profile, inherited: [:], home: home)
        XCTAssertEqual(session.merged["XDG_CONFIG_HOME"], "/override/config")
    }

    func testLambdaTerminalProfileSet() {
        let profile = TerminalProfile(id: "default", displayName: "Default", workingDirectory: "/tmp")
        let session = SessionEnvironment(profile: profile, inherited: [:], home: URL(fileURLWithPath: "/Users/test"))
        XCTAssertEqual(session.merged["LAMBDA_TERMINAL_PROFILE"], "default")
    }

    func testXonshProfileEnvOnlyForXonshShell() {
        XCTAssertEqual(SessionEnvironment.xonshProfileEnv(for: "dev", shellPath: "/usr/local/bin/xonsh")?["DOTFILES_XONSH_PROFILE"], "dev")
        XCTAssertNil(SessionEnvironment.xonshProfileEnv(for: "dev", shellPath: "/bin/zsh"))
    }

    func testLoginShellFallback() {
        XCTAssertEqual(SessionEnvironment.loginShellPath(inherited: ["SHELL": "/bin/fish"]), "/bin/fish")
        XCTAssertEqual(SessionEnvironment.loginShellPath(inherited: [:]), "/bin/zsh")
    }
}

final class DotfileClassifierTests: XCTestCase {
    func testXDGRoots() {
        XCTAssertEqual(classify(name: ".config"), .xdgRoot)
        XCTAssertEqual(classify(name: ".cache"), .xdgRoot)
    }

    func testShellConventions() {
        XCTAssertEqual(classify(name: ".zshrc"), .conventionShell)
        XCTAssertEqual(classify(name: ".xonshrc"), .conventionShell)
    }

    func testRelocatableCore() {
        XCTAssertEqual(classify(name: ".cursor"), .xdgCompatSymlink)
        XCTAssertEqual(classify(name: ".bun"), .relocatableCore)
    }

    func testUnknownDotfile() {
        XCTAssertEqual(classify(name: ".something_new"), .unknown)
    }

    func testZcompdumpPattern() {
        XCTAssertEqual(classify(name: ".zcompdump-MacBook-5.9"), .conventionZshCache)
    }
}

final class XDGAuditTests: XCTestCase {
    func testAuditScorePerfectWhenEmpty() {
        let score = auditScore(for: AuditResult())
        XCTAssertEqual(score, 100)
    }

    func testAuditScorePenalizesViolations() {
        var result = AuditResult()
        result.total = 10
        result.exempt = 10
        result.viol = 1
        XCTAssertEqual(auditScore(for: result), 88)
    }

    func testBuildReportContainsScore() {
        let xdg = XDGPaths(home: URL(fileURLWithPath: "/Users/test"), overrides: [:])
        let markdown = XDGAuditor.buildReport(xdg: xdg, home: URL(fileURLWithPath: "/Users/test"), result: AuditResult(), score: 100)
        XCTAssertTrue(markdown.contains("Score: 100/100"))
    }

    func testCheckReportListsXDGPaths() {
        let report = XDGAuditor.runCheckReport(
            xdg: XDGPaths(home: URL(fileURLWithPath: "/Users/test"), overrides: [:]),
            home: URL(fileURLWithPath: "/Users/test")
        )
        XCTAssertTrue(report.contains("XDG_CONFIG_HOME=/Users/test/.config"))
    }
}

final class SettingsTests: XCTestCase {
    func testSettingsRoundTrip() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = SettingsStore(settingsURL: directory.appendingPathComponent("settings.json"))
        var settings = AppSettings(defaultProfileID: "ai", fontSize: 15, theme: .dracula)
        try store.save(settings)
        settings = try store.load()
        XCTAssertEqual(settings.defaultProfileID, "ai")
        XCTAssertEqual(settings.fontSize, 15)
        XCTAssertEqual(settings.theme, .dracula)
    }
}

final class AppPathsTests: XCTestCase {
    func testConfigDirectoryUsesXDG() {
        let home = URL(fileURLWithPath: "/Users/test")
        let overrides = ["XDG_CONFIG_HOME": "/Users/test/.config"]
        let path = AppPaths.configDirectory(overrides: overrides)
        XCTAssertTrue(path.path.hasSuffix("/lambda-terminal"))
    }
}
