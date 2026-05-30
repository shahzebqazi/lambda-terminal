import Foundation
import LambdaTerminalCore
import XCTest

/// Acceptance tests for multi-window and settings behavior — real state, no mocks.
final class MultiWindowAcceptanceTests: XCTestCase {
    private func makeState(twoWindows: Bool) -> TerminalAppState {
        var state = TerminalAppState()
        let profile = TerminalProfile(id: "dev", displayName: "Dev", workingDirectory: "/tmp")
        let tab = TerminalSession(profile: profile, workingDirectory: URL(fileURLWithPath: "/window-a"))
        let windowA = WindowSessionBundle(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000AAA1")!,
            tabs: [tab]
        )
        state.windows = [windowA]
        if twoWindows {
            let tabB = TerminalSession(profile: profile, workingDirectory: URL(fileURLWithPath: "/window-b"))
            let windowB = WindowSessionBundle(
                id: UUID(uuidString: "00000000-0000-0000-0000-00000000BBB2")!,
                tabs: [tabB]
            )
            state.windows.append(windowB)
        }
        return state
    }

    func testNewTabTargetsFocusedWindowNotLast() {
        var state = makeState(twoWindows: true)
        let windowA = state.windows[0].id
        let windowB = state.windows[1].id
        state.setFocusedWindow(windowA)
        let tabsBeforeB = state.windows[1].tabs.count
        _ = state.openNewTabInCommandTarget()
        XCTAssertEqual(state.windows[0].tabs.count, 2, "Tab must be added to focused window A")
        XCTAssertEqual(state.windows[1].tabs.count, tabsBeforeB, "Tab must not be added to unfocused window B")
        XCTAssertNotEqual(state.commandTargetWindowID(), windowB)
    }

    func testOpenInProjectUsesFocusedWindow() {
        var state = makeState(twoWindows: true)
        let windowA = state.windows[0].id
        state.setFocusedWindow(windowA)
        let project = URL(fileURLWithPath: "/Users/test/project", isDirectory: true)
        _ = state.openInProject(directory: project)
        XCTAssertEqual(state.windows[0].tabs.count, 2)
        XCTAssertEqual(state.windows[0].tabs.last?.workingDirectory.path, project.path)
        XCTAssertEqual(state.windows[1].tabs.count, 1)
    }

    func testFocusMovesToWindowWhenOpeningNewWindow() {
        var state = makeState(twoWindows: true)
        state.setFocusedWindow(state.windows[0].id)
        let newID = state.openNewWindow(profileID: "dev", workingDirectory: URL(fileURLWithPath: "/new"))
        XCTAssertEqual(state.focusedWindowID, newID)
    }

    func testTabOrderStableAfterMultipleSelections() {
        var state = makeState(twoWindows: false)
        let windowID = state.windows[0].id
        let profile = TerminalProfile(id: "default", displayName: "D", workingDirectory: "/tmp")
        let tab1 = TerminalSession(id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!, profile: profile, workingDirectory: URL(fileURLWithPath: "/1"))
        let tab2 = TerminalSession(id: UUID(uuidString: "00000000-0000-0000-0000-000000000022")!, profile: profile, workingDirectory: URL(fileURLWithPath: "/2"))
        let tab3 = TerminalSession(id: UUID(uuidString: "00000000-0000-0000-0000-000000000033")!, profile: profile, workingDirectory: URL(fileURLWithPath: "/3"))
        state.windows[0].tabs = [tab1, tab2, tab3]
        let expectedOrder = [tab1.id, tab2.id, tab3.id]
        state.selectTab(windowID: windowID, tabID: tab2.id)
        state.selectTab(windowID: windowID, tabID: tab3.id)
        state.selectTab(windowID: windowID, tabID: tab1.id)
        XCTAssertEqual(state.windows[0].tabs.map(\.id), expectedOrder)
    }
}

final class SettingsChromeAcceptanceTests: XCTestCase {
    func testChangingSettingsDoesNotChangeExistingProcessPlan() {
        let profile = TerminalProfile(id: "dev", displayName: "Dev", workingDirectory: "/tmp")
        let cwd = URL(fileURLWithPath: "/tmp")
        var settings = AppSettings(fontSize: 13, theme: .dracula)
        let session = TerminalSession(profile: profile, workingDirectory: cwd)
        let planBefore = session.launchPlan(settings: settings, inherited: ["SHELL": "/bin/zsh"])
        settings.fontSize = 20
        settings.theme = .system
        let planAfter = session.launchPlan(settings: settings, inherited: ["SHELL": "/bin/zsh"])
        XCTAssertEqual(planBefore.process, planAfter.process)
        XCTAssertNotEqual(planBefore.chrome, planAfter.chrome)
    }

    func testPersistenceErrorCanBeClearedAfterRecovery() {
        var state = TerminalAppState()
        state.recordPersistenceFailure(PersistenceError.writeFailed(path: "/x", underlying: "denied"))
        XCTAssertNotNil(state.persistenceError)
        state.clearPersistenceError()
        XCTAssertNil(state.persistenceError)
    }
}
