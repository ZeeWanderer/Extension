//
//  LogSubsystemTests.swift
//
//  Created by zeewanderer on 27.01.2026.
//

import XCTest
import osExtension

#if canImport(os)
final class LoggingPublicAPITests: XCTestCase {
    private enum TestLog: LogSubsystemProtocol {
        nonisolated static let logger = makeLogger()
        nonisolated static let signposter = makeSignposter()
    }

    func testProtocolDefaultsResolveTheCurrentBundle() {
        let expected = Bundle.main.bundleIdentifier ?? "unknown"
        XCTAssertEqual(TestLog.bundle, expected)
        XCTAssertFalse(TestLog.bundle.isEmpty)
        XCTAssertEqual(TestLog.logScope, "[TestLog]")
        XCTAssertEqual(TestLog.subsystem, "\(expected).TestLog")
    }
}
#endif
