import AppKit
import SwiftTerm
import SwiftUI

struct LocalTerminalView: NSViewRepresentable {
    let configuration: SessionLaunchConfiguration
    var onTitleChange: ((String) -> Void)?

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let view = LocalProcessTerminalView(frame: .zero)
        view.wantsLayer = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.processDelegate = context.coordinator
        context.coordinator.onTitleChange = onTitleChange
        context.coordinator.terminalView = view
        return view
    }

    func updateNSView(_ nsView: LocalProcessTerminalView, context: Context) {
        context.coordinator.onTitleChange = onTitleChange
        context.coordinator.startIfNeeded(view: nsView, configuration: configuration)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, LocalProcessTerminalViewDelegate {
        weak var terminalView: LocalProcessTerminalView?
        var onTitleChange: ((String) -> Void)?
        var startedConfiguration: SessionLaunchConfiguration?

        func startIfNeeded(view: LocalProcessTerminalView, configuration: SessionLaunchConfiguration) {
            guard startedConfiguration != configuration else { return }
            startedConfiguration = configuration
            TerminalTheme.apply(to: view, preset: configuration.theme)
            TerminalTheme.applyFontSize(CGFloat(configuration.fontSize), to: view)

            // startProcess needs a laid-out view; defer one run loop turn.
            DispatchQueue.main.async {
                let envArray = configuration.environment.map { "\($0.key)=\($0.value)" }
                view.startProcess(
                    executable: configuration.shell,
                    args: ["-l"],
                    environment: envArray,
                    execName: nil,
                    currentDirectory: configuration.currentDirectory
                )
            }
        }

        func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

        func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
            onTitleChange?(title)
        }

        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}

        func processTerminated(source: TerminalView, exitCode: Int32?) {}
    }
}
