import Foundation

/// Testable session/window orchestration (SwiftUI `AppModel` delegates here).
public struct TerminalAppState: Equatable, Sendable {
    public var settings: AppSettings
    public var profilesDocument: ProfilesDocument
    public var windows: [WindowSessionBundle]
    public var focusedWindowID: UUID?
    public var persistenceError: String?

    public init(
        settings: AppSettings = AppSettings(),
        profilesDocument: ProfilesDocument = ProfilesDocument(version: 1, profiles: ProfileStore.builtInProfiles()),
        windows: [WindowSessionBundle] = [],
        focusedWindowID: UUID? = nil,
        persistenceError: String? = nil
    ) {
        self.settings = settings
        self.profilesDocument = profilesDocument
        self.windows = windows
        self.focusedWindowID = focusedWindowID
        self.persistenceError = persistenceError
    }

    public var profiles: [TerminalProfile] {
        profilesDocument.profiles
    }

    public func profile(id: String) -> TerminalProfile? {
        profiles.first { $0.id == id }
    }

    public mutating func setFocusedWindow(_ id: UUID?) {
        guard id == nil || windows.contains(where: { $0.id == id }) else { return }
        focusedWindowID = id
    }

    public func commandTargetWindowID() -> UUID? {
        WindowFocusResolver.commandTarget(focusedWindowID: focusedWindowID, windows: windows)
    }

    @discardableResult
    public mutating func openNewWindow(
        profileID: String,
        workingDirectory: URL? = nil,
        settingsStore: SettingsStore = SettingsStore(),
        home: URL = FileManager.default.homeDirectoryForCurrentUser
    ) -> UUID? {
        guard let profile = profile(id: profileID) else { return nil }
        let cwd = workingDirectory ?? settingsStore.resolvedWorkingDirectory(for: profile, settings: settings, home: home)
        settingsStore.rememberWorkingDirectory(profileID: profile.id, path: cwd, settings: &settings)
        let session = TerminalSession(profile: profile, workingDirectory: cwd)
        let bundle = WindowSessionBundle(tabs: [session])
        windows.append(bundle)
        focusedWindowID = bundle.id
        return bundle.id
    }

    public mutating func openNewTab(
        in windowID: UUID,
        workingDirectory: URL? = nil,
        settingsStore: SettingsStore = SettingsStore()
    ) -> UUID? {
        guard let index = windows.firstIndex(where: { $0.id == windowID }),
              let active = windows[index].selectedTab else { return nil }
        let cwd = workingDirectory ?? active.workingDirectory
        let session = TerminalSession(profile: active.profile, workingDirectory: cwd)
        windows[index].tabs.append(session)
        windows[index].selectTab(id: session.id)
        settingsStore.rememberWorkingDirectory(profileID: active.profile.id, path: cwd, settings: &settings)
        focusedWindowID = windowID
        return session.id
    }

    public mutating func openNewTabInCommandTarget(workingDirectory: URL? = nil) -> UUID? {
        guard let windowID = commandTargetWindowID() else {
            return openNewWindow(profileID: settings.defaultProfileID, workingDirectory: workingDirectory)
        }
        return openNewTab(in: windowID, workingDirectory: workingDirectory)
    }

    public mutating func openInProject(
        directory: URL,
        settingsStore: SettingsStore = SettingsStore()
    ) -> UUID? {
        if let windowID = commandTargetWindowID(),
           let index = windows.firstIndex(where: { $0.id == windowID }),
           let active = windows[index].selectedTab {
            let session = TerminalSession(profile: active.profile, workingDirectory: directory)
            windows[index].tabs.append(session)
            windows[index].selectTab(id: session.id)
            settingsStore.rememberWorkingDirectory(profileID: active.profile.id, path: directory, settings: &settings)
            focusedWindowID = windowID
            return session.id
        }
        return openNewWindow(profileID: settings.defaultProfileID, workingDirectory: directory)
    }

    public mutating func selectTab(windowID: UUID, tabID: UUID) {
        guard let index = windows.firstIndex(where: { $0.id == windowID }) else { return }
        let tabOrderBefore = windows[index].tabs.map(\.id)
        windows[index].selectTab(id: tabID)
        let tabOrderAfter = windows[index].tabs.map(\.id)
        assert(tabOrderBefore == tabOrderAfter, "Tab selection must not reorder tabs")
        focusedWindowID = windowID
    }

    public mutating func recordPersistenceFailure(_ error: Error) {
        persistenceError = error.localizedDescription
    }

    public mutating func clearPersistenceError() {
        persistenceError = nil
    }
}
