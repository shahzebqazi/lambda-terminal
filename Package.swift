// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "lambda-terminal",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "LambdaTerminalCore", targets: ["LambdaTerminalCore"]),
        .executable(name: "LambdaTerminal", targets: ["LambdaTerminal"]),
        .executable(name: "xdg", targets: ["XDGAuditCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", from: "1.12.0"),
    ],
    targets: [
        .target(
            name: "LambdaTerminalCore",
            path: "Sources/LambdaTerminalCore"
        ),
        .executableTarget(
            name: "LambdaTerminal",
            dependencies: [
                "LambdaTerminalCore",
                .product(name: "SwiftTerm", package: "SwiftTerm"),
            ],
            path: "Sources/LambdaTerminal"
        ),
        .executableTarget(
            name: "XDGAuditCLI",
            dependencies: ["LambdaTerminalCore"],
            path: "Sources/XDGAuditCLI"
        ),
        .testTarget(
            name: "LambdaTerminalCoreTests",
            dependencies: ["LambdaTerminalCore"],
            path: "Tests/LambdaTerminalCoreTests"
        ),
    ]
)
