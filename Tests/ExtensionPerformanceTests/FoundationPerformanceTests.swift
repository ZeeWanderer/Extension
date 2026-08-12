//
//  FoundationPerformanceTests.swift
//
//
//  Created by zeewanderer on 12.08.2026.
//

import XCTest
import FoundationExtension

final class FoundationPerformanceTests: ReleasePerformanceTestCase
{
    func testBinaryArrayRoundTripPerformance()
    {
        let values = (0..<2_500_000).map(Int64.init)
        let repetitions = 10
        var decodedCount = 0

        measure(metrics: [XCTCPUMetric()], options: measurementOptions) {
            var count = 0
            for _ in 0..<repetitions {
                let encoded = values.data
                count += Array<Int64>(data: encoded).count
            }
            decodedCount = count
        }

        XCTAssertEqual(decodedCount, values.count * repetitions)
    }

    func testSetRoundTripPerformance()
    {
        let values = Set((0..<100_000).map(Int64.init))
        let repetitions = 5
        var decodedCount = 0

        measure(metrics: [XCTCPUMetric()], options: measurementOptions) {
            var count = 0
            for _ in 0..<repetitions {
                count += Set<Int64>(data: values.data).count
            }
            decodedCount = count
        }

        XCTAssertEqual(decodedCount, values.count * repetitions)
    }

    func testStableSetEncodingPerformance()
    {
        let values = Set((0..<100_000).map(Int64.init))
        let repetitions = 3
        var encodedByteCount = 0

        measure(metrics: [XCTCPUMetric()], options: measurementOptions) {
            var count = 0
            for _ in 0..<repetitions {
                count += values.stableData(sortedBy: <).count
            }
            encodedByteCount = count
        }

        XCTAssertEqual(
            encodedByteCount,
            values.count * MemoryLayout<Int64>.stride * repetitions
        )
    }
}
