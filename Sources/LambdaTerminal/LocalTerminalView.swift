import AppKit
import LambdaTerminalCore
import SwiftTerm
import SwiftUI

struct LocalTerminalView: NSViewRepresentable {
    let process: ProcessLaunchConfiguration
    let chrome: TerminalChrome
    var onTitleChange: ((String) -> Void)?

    init(launchPlan: SessionLaunchPlan, onTitleChange: ((String) -> Void)? = nil) {
        self.process = launchPlan.process
        self.chrome = launchPlan.chrome
        self.onTitleChange = onTitleChange
    }

    init(
        process: ProcessLaunchConfiguration,
        chrome: TerminalChrome,
        onTitleChange: ((String) -> Void)? = nil
    ) {
        self.process = process
        self.chrome = chrome
        self.onTitleChange = onTitleChange
    }

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
        context.coordinator.update(view: nsView, process: process, chrome: chrome)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, LocalProcessTerminalViewDelegate {
        weak var terminalView: LocalProcessTerminalView?
        var onTitleChange: ((String) -> Void)?
        var startedProcess: ProcessLaunchConfiguration?
        var appliedChrome: TerminalChrome?

        func update(
            view: LocalProcessTerminalView,
            process: ProcessLaunchConfiguration,
            chrome: TerminalChrome
        ) {
            if startedProcess != process {
                startedProcess = process
                appliedChrome = chrome
                TerminalTheme.apply(to: view, chrome: chrome)

                // startProcess needs a laid-out view; defer one run loop turn.
                DispatchQueue.main.async {
                    let envArray = process.environment.map { "\($0.key)=\($0.value)" }
                    view.startProcess(
                        executable: process.shell,
                        args: ["-l"],
                        environment: envArray,
                        execName: nil,
                        currentDirectory: process.currentDirectory
                    )
                }
                return
            }

            if appliedChrome != chrome {
                appliedChrome = chrome
                TerminalTheme.apply(to: view, chrome: chrome)
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
