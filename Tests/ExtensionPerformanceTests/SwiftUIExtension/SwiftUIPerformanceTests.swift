//
//  SwiftUIPerformanceTests.swift
//
//
//  Created by zeewanderer on 12.08.2026.
//

import XCTest
import SwiftUIExtension

private enum RouterPerformanceDestination: RouterDestination
{
    case value(Int)
}

@MainActor
private final class PerformanceRouter: SinglePathRouterProtocol
{
    typealias Destination = RouterPerformanceDestination

    var path: [Destination] = []
}

final class SwiftUIPerformanceTests: ReleasePerformanceTestCase
{
    @MainActor
    func testRouterMutationThroughputPerformance()
    {
        let destinationCount = 100_000
        var resultingCount = 0

        measure(metrics: [XCTClockMetric()], options: measurementOptions)
        {
            let router = PerformanceRouter()
            for value in 0..<destinationCount
            {
                router.push(.value(value))
            }
            resultingCount = router.path.count
            router.popAll()
        }

        XCTAssertEqual(resultingCount, destinationCount)
    }
}
