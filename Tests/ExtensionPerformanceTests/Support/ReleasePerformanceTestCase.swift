//
//  ReleasePerformanceTestCase.swift
//
//
//  Created by zeewanderer on 12.08.2026.
//

import XCTest

class ReleasePerformanceTestCase: XCTestCase
{
    override func setUpWithError() throws
    {
        #if DEBUG
        throw XCTSkip("Performance measurements are intentionally release-only; use swift test -c release --filter PerformanceTests")
        #endif
    }

    var measurementOptions: XCTMeasureOptions
    {
        let options = XCTMeasureOptions()
        options.iterationCount = 5
        return options
    }
}
