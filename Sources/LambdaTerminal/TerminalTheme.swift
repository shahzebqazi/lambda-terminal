import AppKit
import LambdaTerminalCore
import SwiftTerm

enum TerminalTheme {
    static func apply(to terminal: LocalProcessTerminalView, chrome: TerminalChrome) {
        apply(to: terminal, preset: chrome.theme, fontSize: chrome.fontSize)
    }

    static func apply(to terminal: LocalProcessTerminalView, preset: ThemePreset, fontSize: Double) {
        apply(to: terminal, preset: preset)
        applyFontSize(CGFloat(fontSize), to: terminal)
    }

    static func apply(to terminal: LocalProcessTerminalView, preset: ThemePreset) {
        switch preset {
        case .dracula:
            terminal.nativeBackgroundColor = NSColor(red: 0.157, green: 0.165, blue: 0.212, alpha: 1)
            terminal.nativeForegroundColor = NSColor(red: 0.945, green: 0.980, blue: 1.0, alpha: 1)
        case .system:
            terminal.configureNativeColors()
        }
    }

    static func applyFontSize(_ size: CGFloat, to terminal: LocalProcessTerminalView) {
        terminal.font = NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
    }
}
