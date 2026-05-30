#!/usr/bin/env swift
/*
 xdg.swift — thin launcher for lambda-terminal XDG audit (v0.1: audit + check).

 Prefer: swift run xdg …
 This script delegates to Tools/xdg/xdg bash wrapper when executed from the repo.
*/
import Foundation

let script = URL(fileURLWithPath: CommandLine.arguments[0])
let repoRoot = script.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
let wrapper = repoRoot.appendingPathComponent("Tools/xdg/xdg")

guard FileManager.default.isExecutableFile(atPath: wrapper.path) else {
    fputs("ERR: run from repo root: swift run xdg [audit|check]\n", stderr)
    exit(1)
}

let task = Process()
task.executableURL = wrapper
task.arguments = Array(CommandLine.arguments.dropFirst())
let pipe = Pipe()
task.standardOutput = pipe
task.standardError = pipe
try task.run()
task.waitUntilExit()
let data = pipe.fileHandleForReading.readDataToEndOfFile()
if let output = String(data: data, encoding: .utf8) {
    print(output, terminator: "")
}
exit(task.terminationStatus)
