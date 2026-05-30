import Foundation
import LambdaTerminalCore

enum XDGAuditCommand {
    case audit(stdout: Bool, outPath: URL?)
    case check
}

func parseArguments(_ argv: [String]) throws -> XDGAuditCommand {
    guard let command = argv.first else {
        return .audit(stdout: false, outPath: nil)
    }

    switch command {
    case "audit":
        var stdout = false
        var outPath: URL?
        var index = 1
        while index < argv.count {
            switch argv[index] {
            case "--stdout":
                stdout = true
            case "--out":
                guard index + 1 < argv.count else {
                    throw NSError(domain: "xdg", code: 2, userInfo: [NSLocalizedDescriptionKey: "--out needs path"])
                }
                index += 1
                outPath = URL(fileURLWithPath: (argv[index] as NSString).expandingTildeInPath)
            default:
                throw NSError(domain: "xdg", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unknown flag: \(argv[index])"])
            }
            index += 1
        }
        return .audit(stdout: stdout, outPath: outPath)
    case "check":
        return .check
    case "-h", "--help", "help":
        print("""
        xdg — XDG home audit (lambda-terminal)

          swift run xdg audit [--stdout] [--out PATH]
          swift run xdg check

        Default report path: ~/.local/state/lambda-terminal/xdg-report.md
        """)
        exit(0)
    default:
        throw NSError(domain: "xdg", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unknown command: \(command)"])
    }
}

@main
struct XDGAuditCLI {
    static func main() {
        do {
            let argv = Array(CommandLine.arguments.dropFirst())
            let parsed = try parseArguments(argv.isEmpty ? ["audit"] : argv)
            switch parsed {
            case .audit(let stdout, let outPath):
                let xdg = XDGPaths()
                let result = try XDGAuditor.runAudit(xdg: xdg)
                let score = auditScore(for: result)
                let markdown = XDGAuditor.buildReport(xdg: xdg, result: result, score: score)
                if stdout {
                    print(markdown)
                } else {
                    let destination = outPath ?? AppPaths.xdgReportFile()
                    try FileManager.default.createDirectory(
                        at: destination.deletingLastPathComponent(),
                        withIntermediateDirectories: true
                    )
                    try markdown.write(to: destination, atomically: true, encoding: .utf8)
                    fputs("OK: wrote \(destination.path)\n", stderr)
                    fputs("Score: \(score)/100\n", stderr)
                }
            case .check:
                let report = XDGAuditor.runCheckReport()
                fputs(report + "\n", stderr)
            }
        } catch {
            fputs("ERR: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }
}
