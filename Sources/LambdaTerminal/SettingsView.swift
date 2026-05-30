import LambdaTerminalCore
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        Form {
            Picker("Default profile", selection: $appModel.settings.defaultProfileID) {
                ForEach(appModel.profiles) { profile in
                    Text(profile.displayName).tag(profile.id)
                }
            }

            Slider(value: $appModel.settings.fontSize, in: 10...22, step: 1) {
                Text("Font size")
            }

            Picker("Theme", selection: $appModel.settings.theme) {
                ForEach(ThemePreset.allCases) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }
        }
        .padding(20)
        .frame(width: 420)
        .onChange(of: appModel.settings.defaultProfileID) { _, _ in appModel.persistSettings() }
        .onChange(of: appModel.settings.fontSize) { _, _ in appModel.persistSettings() }
        .onChange(of: appModel.settings.theme) { _, _ in appModel.persistSettings() }
    }
}
