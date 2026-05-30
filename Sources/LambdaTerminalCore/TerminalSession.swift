import Foundation

public struct TerminalSession: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var profile: TerminalProfile
    public var workingDirectory: URL
    public var title: String

    public init(id: UUID = UUID(), profile: TerminalProfile, workingDirectory: URL) {
        self.id = id
        self.profile = profile
        self.workingDirectory = workingDirectory
        self.title = profile.tabTitle(cwd: workingDirectory)
    }

    public func launchPlan(settings: AppSettings, inherited: [String: String] = [:]) -> SessionLaunchPlan {
        SessionLaunchBuilder.build(
            profile: profile,
            workingDirectory: workingDirectory,
            settings: settings,
            inherited: inherited
        )
    }
}

public struct WindowSessionBundle: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var tabs: [TerminalSession]
    public var selectedTabID: UUID?

    public init(id: UUID = UUID(), tabs: [TerminalSession], selectedTabID: UUID? = nil) {
        self.id = id
        self.tabs = tabs
        self.selectedTabID = selectedTabID ?? tabs.first?.id
    }

    public var selectedTab: TerminalSession? {
        guard let selectedTabID else { return tabs.first }
        return tabs.first { $0.id == selectedTabID } ?? tabs.first
    }

    public mutating func selectTab(id: UUID) {
        guard tabs.contains(where: { $0.id == id }) else { return }
        selectedTabID = id
    }
}
