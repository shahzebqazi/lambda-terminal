import Combine
import Foundation
import LambdaTerminalCore
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var settings: AppSettings
    @Published var profilesDocument: ProfilesDocument
    @Published var windows: [WindowSessionBundle] = []
    @Published var focusedWindowID: UUID?
    @Published private(set) var persistenceError: String?
    @Published var pendingWindowIDToOpen: UUID?
    @Published var xdgAuditMarkdown: String?
    @Published var showXDGAuditSheet = false

    private var state: TerminalAppState
    private var isSyncingFromState = false
    private let profileStore: ProfileStore
    private let settingsStore: SettingsStore

    init(
        profileStore: ProfileStore = ProfileStore(),
        settingsStore: SettingsStore = SettingsStore()
    ) {
        self.profileStore = profileStore
        self.settingsStore = settingsStore

        var initialState = TerminalAppState()
        do {
            initialState.settings = try settingsStore.load()
        } catch {
            initialState.recordPersistenceFailure(error)
        }
        do {
            initialState.profilesDocument = try profileStore.load()
        } catch {
            initialState.recordPersistenceFailure(error)
        }

        state = initialState
        settings = initialState.settings
        profilesDocument = initialState.profilesDocument
        windows = initialState.windows
        focusedWindowID = initialState.focusedWindowID
        persistenceError = initialState.persistenceError
    }

    var profiles: [TerminalProfile] {
        state.profiles
    }

    func profile(id: String) -> TerminalProfile? {
        state.profile(id: id)
    }

    func commandTargetWindowID() -> UUID? {
        state.commandTargetWindowID()
    }

    func setFocusedWindow(_ id: UUID?) {
        mutateState { $0.setFocusedWindow(id) }
    }

    func requestOpenWindow(id: UUID) {
        pendingWindowIDToOpen = id
    }

    func updateSessionTitle(windowID: UUID, sessionID: UUID, title: String) {
        guard !title.isEmpty,
              let windowIndex = state.windows.firstIndex(where: { $0.id == windowID }),
              let tabIndex = state.windows[windowIndex].tabs.firstIndex(where: { $0.id == sessionID }) else {
            return
        }
        mutateState { $0.windows[windowIndex].tabs[tabIndex].title = title }
    }

    func persistSettings() {
        state.settings = settings
        do {
            try settingsStore.save(settings)
            state.clearPersistenceError()
            persistenceError = nil
        } catch {
            state.recordPersistenceFailure(error)
            persistenceError = state.persistenceError
        }
    }

    @discardableResult
    func openNewWindow(profileID: String, workingDirectory: URL? = nil) -> UUID? {
        var windowID: UUID?
        mutateState {
            windowID = $0.openNewWindow(
                profileID: profileID,
                workingDirectory: workingDirectory,
                settingsStore: settingsStore
            )
        }
        persistSettings()
        return windowID
    }

    func openNewTab(in windowID: UUID, workingDirectory: URL? = nil) {
        mutateState {
            _ = $0.openNewTab(in: windowID, workingDirectory: workingDirectory, settingsStore: settingsStore)
        }
        persistSettings()
    }

    @discardableResult
    func openNewTabInCommandTarget(workingDirectory: URL? = nil) -> UUID? {
        mutateState {
            _ = $0.openNewTabInCommandTarget(workingDirectory: workingDirectory)
        }
        persistSettings()
        return state.focusedWindowID
    }

    @discardableResult
    func openInProject(directory: URL) -> UUID? {
        mutateState {
            _ = $0.openInProject(directory: directory, settingsStore: settingsStore)
        }
        persistSettings()
        return state.focusedWindowID
    }

    func selectTab(windowID: UUID, tabID: UUID) {
        mutateState { $0.selectTab(windowID: windowID, tabID: tabID) }
    }

    func runXDGAudit() {
        do {
            let xdg = XDGPaths()
            let result = try XDGAuditor.runAudit(xdg: xdg)
            let score = auditScore(for: result)
            let markdown = XDGAuditor.buildReport(xdg: xdg, result: result, score: score)
            let destination = AppPaths.xdgReportFile()
            try FileManager.default.createDirectory(
                at: destination.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try markdown.write(to: destination, atomically: true, encoding: .utf8)
            xdgAuditMarkdown = markdown
            showXDGAuditSheet = true
        } catch {
            xdgAuditMarkdown = "Audit failed: \(error.localizedDescription)"
            showXDGAuditSheet = true
        }
    }

    private func mutateState(_ body: (inout TerminalAppState) -> Void) {
        body(&state)
        publishFromState()
    }

    private func publishFromState() {
        isSyncingFromState = true
        settings = state.settings
        profilesDocument = state.profilesDocument
        windows = state.windows
        focusedWindowID = state.focusedWindowID
        persistenceError = state.persistenceError
        isSyncingFromState = false
    }
}
