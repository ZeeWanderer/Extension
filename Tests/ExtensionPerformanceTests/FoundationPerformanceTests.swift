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
    private struct JSONPerformanceValue: Codable, Sendable
    {
        let id: Int
        let name: String
        let scores: [Double]
    }

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

    func testJSONCodingRoundTripPerformance()
    {
        let values = (0..<10_000).map
        {
            JSONPerformanceValue(
                id: $0,
                name: "Value \($0)",
                scores: [Double($0), Double($0) / 2, Double($0) / 3]
            )
        }
        let coding = JSONCoding()
        let repetitions = 3
        var decodedCount = 0

        measure(metrics: [XCTCPUMetric()], options: measurementOptions)
        {
            var count = 0
            for _ in 0..<repetitions
            {
                do
                {
                    let data = try coding.encode(values)
                    count += try coding.decode(
                        [JSONPerformanceValue].self,
                        from: data
                    ).count
                }
                catch
                {
                    XCTFail("JSON round trip failed: \(error)")
                }
            }
            decodedCount = count
        }

        XCTAssertEqual(decodedCount, values.count * repetitions)
    }
}
