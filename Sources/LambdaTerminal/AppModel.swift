import Combine
import Foundation
import LambdaTerminalCore
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var settings: AppSettings
    @Published var profilesDocument: ProfilesDocument
    @Published var windows: [WindowSessionBundle] = []
    @Published var xdgAuditMarkdown: String?
    @Published var showXDGAuditSheet = false

    private let profileStore: ProfileStore
    private let settingsStore: SettingsStore

    init(
        profileStore: ProfileStore = ProfileStore(),
        settingsStore: SettingsStore = SettingsStore()
    ) {
        self.profileStore = profileStore
        self.settingsStore = settingsStore
        settings = (try? settingsStore.load()) ?? AppSettings()
        profilesDocument = (try? profileStore.load()) ?? ProfilesDocument(version: 1, profiles: ProfileStore.builtInProfiles())
    }

    var profiles: [TerminalProfile] {
        profilesDocument.profiles
    }

    func profile(id: String) -> TerminalProfile? {
        profiles.first { $0.id == id }
    }

    func persistSettings() {
        try? settingsStore.save(settings)
    }

    func openInitialWindowIfNeeded() {
        if windows.isEmpty {
            openNewWindow(profileID: settings.defaultProfileID)
        }
    }

    @discardableResult
    func openNewWindow(profileID: String, workingDirectory: URL? = nil) -> UUID? {
        guard let profile = profile(id: profileID) else { return nil }
        let cwd = workingDirectory ?? settingsStore.resolvedWorkingDirectory(for: profile, settings: settings)
        settingsStore.rememberWorkingDirectory(profileID: profile.id, path: cwd, settings: &settings)
        persistSettings()
        let bundle = WindowSessionBundle(tabs: [TerminalSession(profile: profile, workingDirectory: cwd)])
        windows.append(bundle)
        return bundle.id
    }

    func openNewTab(in windowID: UUID, workingDirectory: URL? = nil) {
        guard let index = windows.firstIndex(where: { $0.id == windowID }),
              let active = windows[index].tabs.last else { return }
        let cwd = workingDirectory ?? active.workingDirectory
        let session = TerminalSession(profile: active.profile, workingDirectory: cwd)
        windows[index].tabs.append(session)
        settingsStore.rememberWorkingDirectory(profileID: active.profile.id, path: cwd, settings: &settings)
        persistSettings()
    }

    func openInProject(windowID: UUID?, directory: URL) {
        if let windowID, let index = windows.firstIndex(where: { $0.id == windowID }),
           let active = windows[index].tabs.last {
            let session = TerminalSession(profile: active.profile, workingDirectory: directory)
            windows[index].tabs.append(session)
            settingsStore.rememberWorkingDirectory(profileID: active.profile.id, path: directory, settings: &settings)
            persistSettings()
            return
        }
        _ = openNewWindow(profileID: settings.defaultProfileID, workingDirectory: directory)
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
}
