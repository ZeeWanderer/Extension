//
//  GeneralExtensionsPublicAPITests.swift
//
//
//  Created by zeewanderer on 12.08.2026.
//

import GeneralExtensions
import XCTest

final class GeneralExtensionsPublicAPITests: XCTestCase {
    func testRuntimeConfigurationValuesRemainConsistent() {
        XCTAssertEqual(
            Config.isTestFlightOrDebug,
            Config.isTestFlight || Config.isDebug
        )

        switch Config.appConfiguration {
        case .Debug:
            XCTAssertTrue(Config.isDebug)
        case .TestFlight:
            XCTAssertFalse(Config.isDebug)
            XCTAssertTrue(Config.isTestFlight)
        case .AppStore:
            XCTAssertFalse(Config.isDebug)
            XCTAssertFalse(Config.isTestFlight)
        }
    }
}
