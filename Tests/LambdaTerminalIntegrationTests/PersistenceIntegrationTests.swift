import Foundation
import LambdaTerminalCore
import XCTest

/// Integration tests using real temporary directories — no mocks.
final class PersistenceIntegrationTests: XCTestCase {
    private var tempRoot: URL!

    override func setUp() {
        super.setUp()
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("lambda-terminal-it-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempRoot)
        super.tearDown()
    }

    func testSettingsStoreRoundTripOnRealDisk() throws {
        let url = tempRoot.appendingPathComponent("settings.json")
        let store = SettingsStore(settingsURL: url)
        var settings = AppSettings(defaultProfileID: "ai", fontSize: 16, theme: .system)
        try store.save(settings)
        settings = try store.load()
        XCTAssertEqual(settings.defaultProfileID, "ai")
        XCTAssertEqual(settings.fontSize, 16)
        XCTAssertEqual(settings.theme, .system)
    }

    func testProfileStoreCreatesDefaultsOnRealDisk() throws {
        let url = tempRoot.appendingPathComponent("profiles.json")
        let store = ProfileStore(profilesURL: url)
        let doc = try store.load()
        XCTAssertEqual(doc.profiles.count, 4)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func testRememberedWorkingDirectorySurvivesSaveLoad() throws {
        let settingsURL = tempRoot.appendingPathComponent("settings.json")
        let store = SettingsStore(settingsURL: settingsURL)
        var settings = try store.load()
        let project = tempRoot.appendingPathComponent("project", isDirectory: true)
        try FileManager.default.createDirectory(at: project, withIntermediateDirectories: true)
        store.rememberWorkingDirectory(profileID: "dev", path: project, settings: &settings)
        try store.save(settings)
        let reloaded = try store.load()
        XCTAssertEqual(reloaded.lastWorkingDirectoryByProfile["dev"], project.path)
    }

    func testCorruptSettingsJSONSurfacesDecodeError() throws {
        let url = tempRoot.appendingPathComponent("settings.json")
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try "{ not valid json".write(to: url, atomically: true, encoding: .utf8)
        let store = SettingsStore(settingsURL: url)
        XCTAssertThrowsError(try store.load())
    }

    func testTerminalAppStateRecordsPersistenceFailureFromRealError() {
        var state = TerminalAppState()
        let error = PersistenceError.decodeFailed(path: "/tmp/settings.json", underlying: "invalid")
        state.recordPersistenceFailure(error)
        XCTAssertNotNil(state.persistenceError)
        XCTAssertTrue(state.persistenceError?.contains("settings.json") == true)
    }
}

final class SessionLaunchIntegrationTests: XCTestCase {
    func testLaunchPlanUsesRealHomeDirectoryLayout() throws {
        let home = FileManager.default.temporaryDirectory
            .appendingPathComponent("lambda-terminal-home-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: home) }

        let git = home.appendingPathComponent("Git", isDirectory: true)
        try FileManager.default.createDirectory(at: git, withIntermediateDirectories: true)
        let profile = TerminalProfile(id: "dev", displayName: "Dev", workingDirectory: git.path, injectXDGEnvironment: true)
        let plan = SessionLaunchBuilder.build(
            profile: profile,
            workingDirectory: git,
            settings: AppSettings(),
            inherited: [:],
            home: home
        )
        XCTAssertTrue(plan.process.environment["XDG_CONFIG_HOME"]?.hasSuffix("/.config") == true)
        XCTAssertEqual(plan.process.currentDirectory, git.path)
    }
}
