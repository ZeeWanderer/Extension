//
//  DebugViewCompilerTests.swift
//  Extension
//
//  Created by zeewanderer on 21.09.2026.
//

import XCTest

#if os(macOS) && canImport(Macros)
import Foundation
import Darwin

@MainActor
final class DebugViewCompilerTests: XCTestCase
{
    func testDefaultBudgetExposesTheActualErrorWithoutAcceptingInvalidCode() async throws
    {
        // The unsplit, invalid expression deliberately exhausts the solver on some toolchains.
        let original = try await P_DebugViewCompiler.compile("ModifierChain", conditions: ["DEBUG"], timeout: .seconds(180))
        XCTAssertNotEqual(original.status, 0, original.output)
        // A newer compiler improving the baseline diagnostic is welcome.
        XCTAssertTrue(original.output.contains("unable to type-check") || original.output.contains("has no member 'p_missingColor'"), original.output)

        let rewritten = try await P_DebugViewCompiler.compile("ModifierChain", conditions: ["DEBUG", "DIAGNOSTIC"])
        XCTAssertNotEqual(rewritten.status, 0, rewritten.output)
        XCTAssertTrue(rewritten.output.contains("has no member 'p_missingColor'"), rewritten.output)
        XCTAssertTrue(rewritten.output.contains("ModifierChain.swift:"), rewritten.output)
        XCTAssertFalse(rewritten.output.contains("unable to type-check"), rewritten.output)
        XCTAssertTrue(rewritten.output.contains("@debug_view is temporary"), rewritten.output)
    }

    func testReducedBudgetValidChainFailsBeforeSplittingAndCompilesAfterward() async throws
    {
        let original = try await P_DebugViewCompiler.compile("ModifierChain", conditions: ["DEBUG", "FIXED"], scopeLimit: 100)
        XCTAssertNotEqual(original.status, 0, original.output)
        XCTAssertTrue(original.output.contains("unable to type-check"), original.output)

        let rewritten = try await P_DebugViewCompiler.compile("ModifierChain", conditions: ["DEBUG", "FIXED", "DIAGNOSTIC"], scopeLimit: 100)
        XCTAssertEqual(rewritten.status, 0, rewritten.output)
        XCTAssertFalse(rewritten.output.contains("original body is unchanged"), rewritten.output)
    }

    func testCorrectedCodeCompilesWithAndWithoutMacro() async throws
    {
        for conditions: Set<String> in [["DEBUG", "FIXED"], ["DEBUG", "FIXED", "DIAGNOSTIC"], ["FIXED", "DIAGNOSTIC"]] {
            let result = try await P_DebugViewCompiler.compile("ModifierChain", conditions: conditions)
            XCTAssertEqual(result.status, 0, "Conditions: \(conditions.sorted())\n\(result.output)")
        }
    }

    func testClientWithoutDEBUGRetainsOriginalBodyRegardlessOfPluginBuild() async throws
    {
        let result = try await P_DebugViewCompiler.compile("ModifierChain", conditions: ["FIXED", "DIAGNOSTIC"], scopeLimit: 100, extra: ["-dump-macro-expansions"])
        XCTAssertNotEqual(result.status, 0, result.output)
        XCTAssertTrue(result.output.contains("unable to type-check"), result.output)
        XCTAssertTrue(result.output.contains("@debug_view is temporary"), result.output)
        XCTAssertFalse(result.output.contains("p_debug_view"), result.output)
    }

    func testDEBUGIsTheGateNotOptimizationLevel() async throws
    {
        let result = try await P_DebugViewCompiler.compile("ModifierChain", conditions: ["DEBUG", "FIXED", "DIAGNOSTIC"], scopeLimit: 100, extra: ["-O"])
        XCTAssertEqual(result.status, 0, result.output)
    }

    func testBuilderFormsControlFlowAndUntouchedActionsCompileInBothModes() async throws
    {
        for conditions: Set<String> in [["DEBUG"], ["DEBUG", "DIAGNOSTIC"], ["DIAGNOSTIC"]] {
            let result = try await P_DebugViewCompiler.compile("BuilderForms", conditions: conditions)
            XCTAssertEqual(result.status, 0, "Conditions: \(conditions.sorted())\n\(result.output)")
            if conditions.contains("DIAGNOSTIC") {
                XCTAssertTrue(result.output.contains("@debug_view is temporary"), result.output)
            }
        }
    }
}

@MainActor
internal enum P_DebugViewCompiler
{
    struct Result {
        let status: Int32
        let output: String
    }

    struct Failure: Error, CustomStringConvertible {
        let description: String
    }

    static func compile(_ fixture: String, conditions: Set<String>, scopeLimit: Int? = nil, extra: [String] = [], timeout: Duration = .seconds(45)) async throws -> Result
    {
        let compiler = try await run(URL(fileURLWithPath: "/usr/bin/xcrun"), arguments: ["--find", "swiftc"])
        let sdk = try await run(URL(fileURLWithPath: "/usr/bin/xcrun"), arguments: ["--sdk", "macosx", "--show-sdk-path"])
        guard compiler.status == 0, sdk.status == 0 else {
            throw Failure(description: "Cannot locate the host Swift compiler/SDK: \(compiler.output)\n\(sdk.output)")
        }
        let compilerURL = URL(fileURLWithPath: compiler.output.trimmingCharacters(in: .whitespacesAndNewlines))
        let sdkPath = sdk.output.trimmingCharacters(in: .whitespacesAndNewlines)
        let resources = try XCTUnwrap(Bundle.module.resourceURL).appendingPathComponent("Fixtures")
        let plugin = try pluginURL()
        var arguments = [
            "-frontend", "-typecheck", "-swift-version", "6", "-sdk", sdkPath,
            "-enable-upcoming-feature", "NonisolatedNonsendingByDefault",
            "-load-plugin-executable", "\(plugin.path)#Macros",
        ]
        // The driver normally supplies SDK macro discovery. Calling the frontend
        // directly keeps the compiler within our timeout's process boundary, so
        // supply the SDK's standard macro server explicitly (e.g. SwiftUI State).
        let platformDeveloper = URL(fileURLWithPath: sdkPath).deletingLastPathComponent().deletingLastPathComponent()
        let server = platformDeveloper.appendingPathComponent("usr/bin/swift-plugin-server")
        let sdkPlugins = platformDeveloper.appendingPathComponent("usr/lib/swift/host/plugins")
        if FileManager.default.isExecutableFile(atPath: server.path) {
            arguments += ["-external-plugin-path", "\(sdkPlugins.path)#\(server.path)"]
        }
        for condition in conditions.sorted() { arguments += ["-D", condition] }
        if let scopeLimit { arguments.append("-solver-scope-threshold=\(scopeLimit)") }
        arguments += extra
        arguments += [resources.appendingPathComponent("MacroDeclaration.swift").path, resources.appendingPathComponent("\(fixture).swift").path]
        return try await run(compilerURL, arguments: arguments, timeout: timeout)
    }

    static func pluginURL() throws -> URL
    {
        let fileManager = FileManager.default
        if let override = ProcessInfo.processInfo.environment["EXTENSION_MACRO_PLUGIN_PATH"] {
            guard fileManager.isExecutableFile(atPath: override) else {
                throw Failure(description: "EXTENSION_MACRO_PLUGIN_PATH is not an executable: \(override)")
            }
            return URL(fileURLWithPath: override)
        }
        // Covers both SwiftPM backends and Xcode's macOS product layout. Do not
        // guess a .build path: it can select a stale plugin or wrong configuration.
        var directory = Bundle(for: DebugViewCompilerTests.self).bundleURL.deletingLastPathComponent()
        for _ in 0..<6 {
            for name in ["Macros", "Macros-tool"] {
                let candidate = directory.appendingPathComponent(name)
                if fileManager.isExecutableFile(atPath: candidate.path),
                   (try? candidate.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true {
                    return candidate
                }
            }
            directory.deleteLastPathComponent()
        }
        throw Failure(description: "The built Macros plugin was not found beside the test products. Set EXTENSION_MACRO_PLUGIN_PATH to its executable path.")
    }

    static func run(_ executable: URL, arguments: [String], timeout: Duration = .seconds(45)) async throws -> Result
    {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("Extension-debug-view-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let outputURL = directory.appendingPathComponent("compiler-output.txt")
        FileManager.default.createFile(atPath: outputURL.path, contents: nil)
        let output = try FileHandle(forWritingTo: outputURL)
        defer { try? output.close() }

        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.standardOutput = output
        process.standardError = output
        try process.run()
        defer { if process.isRunning { process.terminate() } }

        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        while process.isRunning {
            try Task.checkCancellation()
            guard clock.now < deadline else {
                process.terminate()
                try await Task.sleep(for: .milliseconds(200))
                if process.isRunning { kill(process.processIdentifier, SIGKILL) }
                throw Failure(description: "Compiler exceeded its safety timeout (\(timeout)): \(arguments)")
            }
            try await Task.sleep(for: .milliseconds(20))
        }
        let data = try Data(contentsOf: outputURL)
        return Result(status: process.terminationStatus, output: String(decoding: data, as: UTF8.self))
    }
}
#endif
