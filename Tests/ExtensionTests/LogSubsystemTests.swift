//
//  LogSubsystemTests.swift
//
//  Created by zeewanderer on 27.01.2026.
//

import XCTest
@testable import osExtension

#if canImport(os)
final class LogSubsystemTests: XCTestCase
{
    private enum TestLog: LogSubsystemProtocol
    {
        nonisolated static let logger = makeLogger()
        nonisolated static let signposter = makeSignposter()
    }
    
    func testBundleResolves()
    {
        let expected = Bundle.main.bundleIdentifier ?? "unknown"
        XCTAssertEqual(TestLog.bundle, expected)
        XCTAssertFalse(TestLog.bundle.isEmpty)
    }
}
#endif
