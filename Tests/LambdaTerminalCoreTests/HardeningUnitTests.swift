import Foundation
import LambdaTerminalCore
import XCTest

// MARK: - Unit: Session launch split (process vs chrome)

final class SessionLaunchBuilderUnitTests: XCTestCase {
    func testPWDMatchesExplicitWorkingDirectoryNotProfileDefault() {
        let profile = TerminalProfile(
            id: "dev",
            displayName: "Dev",
            workingDirectory: "/Users/test/default-from-profile"
        )
        let sessionCWD = URL(fileURLWithPath: "/Users/test/project-root", isDirectory: true)
        let plan = SessionLaunchBuilder.build(
            profile: profile,
            workingDirectory: sessionCWD,
            settings: AppSettings(),
            inherited: [:],
            home: URL(fileURLWithPath: "/Users/test")
        )
        XCTAssertEqual(plan.process.environment["PWD"], sessionCWD.path)
        XCTAssertEqual(plan.process.currentDirectory, sessionCWD.path)
        XCTAssertNotEqual(plan.process.environment["PWD"], profile.workingDirectory)
    }

    func testChromeChangeDoesNotAlterProcessConfiguration() {
        let profile = TerminalProfile(id: "default", displayName: "Default", workingDirectory: "/tmp")
        let cwd = URL(fileURLWithPath: "/tmp")
        let dracula = SessionLaunchBuilder.build(
            profile: profile,
            workingDirectory: cwd,
            settings: AppSettings(fontSize: 13, theme: .dracula),
            inherited: [:]
        )
        let system = SessionLaunchBuilder.build(
            profile: profile,
            workingDirectory: cwd,
            settings: AppSettings(fontSize: 18, theme: .system),
            inherited: [:]
        )
        XCTAssertEqual(dracula.process, system.process)
        XCTAssertNotEqual(dracula.chrome, system.chrome)
    }

    func testFontSizeChangeDoesNotAlterProcessConfiguration() {
        let profile = TerminalProfile(id: "default", displayName: "Default", workingDirectory: "/tmp")
        let cwd = URL(fileURLWithPath: "/tmp")
        let small = SessionLaunchBuilder.build(
            profile: profile,
            workingDirectory: cwd,
            settings: AppSettings(fontSize: 11),
            inherited: [:]
        )
        let large = SessionLaunchBuilder.build(
            profile: profile,
            workingDirectory: cwd,
            settings: AppSettings(fontSize: 22),
            inherited: [:]
        )
        XCTAssertEqual(small.process, large.process)
    }
}

// MARK: - Unit: Window focus resolution

final class WindowFocusResolverUnitTests: XCTestCase {
    private func bundle(_ id: UUID) -> WindowSessionBundle {
        WindowSessionBundle(
            id: id,
            tabs: [TerminalSession(profile: TerminalProfile(id: "default", displayName: "D"), workingDirectory: URL(fileURLWithPath: "/tmp"))]
        )
    }

    func testCommandTargetPrefersFocusedWindowOverLast() {
        let first = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let second = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let windows = [bundle(first), bundle(second)]
        let target = WindowFocusResolver.commandTarget(focusedWindowID: first, windows: windows)
        XCTAssertEqual(target, first)
    }

    func testCommandTargetDoesNotDefaultToLastWhenFocusIsSet() {
        let first = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let second = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let windows = [bundle(first), bundle(second)]
        let target = WindowFocusResolver.commandTarget(focusedWindowID: first, windows: windows)
        XCTAssertNotEqual(target, second, "Must not use windows.last when focus is explicit")
    }

    func testCommandTargetFallsBackToSoleWindow() {
        let only = UUID(uuidString: "00000000-0000-0000-0000-000000000099")!
        let target = WindowFocusResolver.commandTarget(focusedWindowID: nil, windows: [bundle(only)])
        XCTAssertEqual(target, only)
    }
}

// MARK: - Unit: Stable tab selection

final class TabSelectionUnitTests: XCTestCase {
    func testSelectTabDoesNotReorderTabs() {
        let tabA = TerminalSession(id: UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!, profile: TerminalProfile(id: "default", displayName: "D"), workingDirectory: URL(fileURLWithPath: "/a"))
        let tabB = TerminalSession(id: UUID(uuidString: "00000000-0000-0000-0000-0000000000B1")!, profile: TerminalProfile(id: "default", displayName: "D"), workingDirectory: URL(fileURLWithPath: "/b"))
        var bundle = WindowSessionBundle(id: UUID(), tabs: [tabA, tabB], selectedTabID: tabA.id)
        let orderBefore = bundle.tabs.map(\.id)
        bundle.selectTab(id: tabB.id)
        XCTAssertEqual(bundle.tabs.map(\.id), orderBefore)
        XCTAssertEqual(bundle.selectedTabID, tabB.id)
    }

    func testSelectTabIgnoresUnknownID() {
        let tabA = TerminalSession(profile: TerminalProfile(id: "default", displayName: "D"), workingDirectory: URL(fileURLWithPath: "/a"))
        var bundle = WindowSessionBundle(tabs: [tabA])
        bundle.selectTab(id: UUID())
        XCTAssertEqual(bundle.selectedTabID, tabA.id)
    }
}

// MARK: - Unit: SessionEnvironment working directory contract

final class SessionEnvironmentWorkingDirectoryUnitTests: XCTestCase {
    func testExplicitWorkingDirectoryOverridesProfilePathInPWD() {
        let profile = TerminalProfile(id: "dev", displayName: "Dev", workingDirectory: "~")
        let sessionPath = URL(fileURLWithPath: "/Users/test/Git/my-app", isDirectory: true)
        let env = SessionEnvironment(
            profile: profile,
            workingDirectory: sessionPath,
            inherited: [:],
            home: URL(fileURLWithPath: "/Users/test")
        )
        XCTAssertEqual(env.merged["PWD"], sessionPath.path)
    }
}
